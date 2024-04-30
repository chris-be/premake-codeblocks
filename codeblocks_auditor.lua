--
-- Name:		codeblocks/codeblocks_auditor.lua
-- Purpose:		Check configurations consistency
-- Copyright:	See attached license file
--

	-- Premake libraries
	local p = premake
	local project = p.project
	-- local config = p.config
	local tree = p.tree

	-- Load needed libraries (must be done here)
	local main = require("codeblocks_main")

	-- CodeBlocks "auditor" library
	local M = {}

	-- Compare table lists side by side
	local function compareTableList(list1, list2, comparator)
		if #list1 ~= #list2 then return false end
		local i1, v1 = next(list1, nil)
		local i2, v2 = next(list2, nil)
		while i1 ~= nil do
			if not comparator(v1, v2) then
				return false
			end
			i1, v1 = next(list1, i1)
			i2, v2 = next(list2, i2)
		end
		return true
	end

	local function warnIfNotConsistentConfigs(prj, node)

		local function checkFilecfgs(filecfg1, filecfg2)
			if filecfg1.buildmessage ~= filecfg2.buildmessage then
				return false, "buildmessage"
			end
			if not table.equals(filecfg1.buildcommands or {}, filecfg2.buildcommands or {}) then
				return false, "buildcommands"
			end
			if #filecfg1.buildcommands == 0 and not filecfg1.buildmessage then
				return true, nil
			end
			if not table.equals(filecfg1.buildoutputs or {}, filecfg2.buildoutputs or {}) then
				return false, "buildoutputs"
			end
			if filecfg1.compilebuildoutputs ~= filecfg2.compilebuildoutputs then
				return false, "compilebuildoutputs"
			end
			return false, nil
		end

		---@return string? Error message (nil: no error)
		local function checkCfgs(cfg1, cfg2)
			if cfg1 == cfg2 then return nil end

			local toolset1 = main.getCompiler(cfg1)
			local toolset2 = main.getCompiler(cfg2)
			if toolset1 ~= toolset2 then return "toolset" end

			local filecfg1 = p.fileconfig.getconfig(node, cfg1)
			local filecfg2 = p.fileconfig.getconfig(node, cfg2)

			local hasFileSettings1 = p.fileconfig.hasFileSettings(filecfg1)
			local hasFileSettings2 = p.fileconfig.hasFileSettings(filecfg2)
			if hasFileSettings1 ~= hasFileSettings2 then return "filtering" end
			if not hasFileSettings1 then return nil end

			if main.shouldCompileAsC(cfg1, node) then
				local tmp1 = main.listCFlags(toolset1, cfg1, filecfg1)
				local tmp2 = main.listCFlags(toolset2, cfg2, filecfg2)
				if not compareTableList(tmp1, tmp2, table.equals) then return "cflags" end
			elseif main.shouldCompileAsCpp(cfg1, node) then
				local tmp1 = main.listCxxFlags(toolset1, cfg1, filecfg1)
				local tmp2 = main.listCxxFlags(toolset2, cfg2, filecfg2)
				if not compareTableList(tmp1, tmp2, table.equals) then return "cxxflags" end
			end

			local cont, err = checkFilecfgs(filecfg1, filecfg2) -- custom build
			if err then return err end

			if cont then -- rule
				local rule = p.global.getRuleForFile(node.name, prj.rules)
				if not rule then return nil end

				local environ1 = table.shallowcopy(filecfg1.environ)
				local environ2 = table.shallowcopy(filecfg2.environ)

				if rule.propertydefinition then
					p.rule.prepareEnvironment(rule, environ1, cfg1)
					p.rule.prepareEnvironment(rule, environ1, filecfg1)
					p.rule.prepareEnvironment(rule, environ2, cfg2)
					p.rule.prepareEnvironment(rule, environ2, filecfg2)
				end

				-- TODO unused rulecfg(1,2) ??
				local rulecfg1 = p.context.extent(rule, environ1)
				local rulecfg2 = p.context.extent(rule, environ2)

				local _, rule_err = checkFilecfgs(filecfg1, filecfg2)
				if rule_err then return "rule " .. rule_err end
			end
			return nil
		end -- checkCfgs

		local iter_cfg = project.eachconfig(prj)
		local first_cfg = iter_cfg() -- take first one as default
		if first_cfg == nil then
			p.warn("Project '%s' has no configuration", prj.name)
			return
		end

		while true do
			local cfg = iter_cfg()
			if cfg == nil then break end

			local err_field = checkCfgs(first_cfg, cfg)
			if err_field then
				p.warnOnce(main.WARN_KEY_AUDITOR, "Code::Blocks doesn't support custom build different by configuration. You might try using Token (i.e '%%%%{cfg.buildcfg}') to bypass that issue.")
				p.warn("Not consistent config (%s) for file %s. Keeping config %s", err_field, node.name, first_cfg.name)
				return
			end
		end -- while
	end

	-- Check configurations for all files of project
	---@param prj _ Checked project
	function M.checkFiles(prj)
		verbosef("%s: check project '%s'", main.AUDITOR_TITLE, prj.name)
		local checkedNodeNb = 0
		local clockStart = os.clock()

		local tr = project.getsourcetree(prj)
		tree.traverse(tr, {
			-- source files are handled at the leaves
			onleaf = function(node, depth)
				if node.generated then
					return
				end
				-- Debug only
				-- verbosef("%s: check node '%s'", main.AUDITOR_TITLE, node.name)
				checkedNodeNb = checkedNodeNb + 1
				warnIfNotConsistentConfigs(prj, node)
			end
		}, false, 1)

		local elapsed = os.clock() - clockStart
		local avg;
		if checkedNodeNb > 0 then
			avg = string.format(" => %.2fs average", elapsed / checkedNodeNb)
		else
			avg = ""
		end
		verbosef("%s: check done, took %.2fs for %i files%s", main.AUDITOR_TITLE, elapsed, checkedNodeNb, avg)
	end

return M
