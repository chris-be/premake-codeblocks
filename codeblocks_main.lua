--
-- Name:		codeblocks/codeblocks_main.lua
-- Purpose:		Some common things for CodeBlocks libraries.
-- Copyright:	See attached license file
--

	-- Premake libraries
	local p = premake
	local tools = p.tools

	-- CodeBlocks "main" library
	local M = {}

-- Defines
-- -------
	M.AUDITOR_TITLE    = "codeblocks_auditor"
	M.WARN_KEY_AUDITOR = "codeblocks_check_configs"

	-- Initialized on first need
	local auditorEnabled = nil

	-- Check "codeblocks-check" option
	M.isAuditorEnabled = function()
		if auditorEnabled == nil then
			-- newoption handles default value (no need to add test 'or "true"')
			auditorEnabled = (_OPTIONS["codeblocks-check"]) == "true"

			local msg
			if auditorEnabled then
				msg = "enabled"
			else
				msg = "disabled"
			end
			verbosef(M.AUDITOR_TITLE .. ": %s", msg)
		end

		return auditorEnabled
	end

-- Toolset
-- -------
	M.Tools = {
		-- Note: Code::Blocks does not distinguish c compiler from cpp compiler
		CB_TOOL_NAMES = {
			[tools.clang] = "clang",
			[tools.gcc]   = "gcc",
			[tools.msc]   = "Visual C++",
		},

		-- Get compiler for toolset and language
		getCompilerName = function(toolset, language)
			local self = M.Tools
			if p.languages.isc(language) or p.languages.iscpp(language) then
				return self.CB_TOOL_NAMES[toolset]
			else
				error("Unsupported language")
			end
		end
	}

	-- Get toolset name from config
	-- Priority: _OPTIONS, cfg then default: gcc
	function M.getToolsetFromCfg(cfg)
		local toolset_name = _OPTIONS.cc or cfg.toolset or p.GCC
		local toolset, _ = tools.canonical(toolset_name)
		if not toolset then
			error("Invalid toolset '" + toolset_name + "'")
		end
		return toolset
	end

	-- Get compiler name to use in Code::Blocks depending on toolset
	function M.getCompilerName(cfg)
		local toolset = M.getToolsetFromCfg(cfg)
		return M.Tools.getCompilerName(toolset, cfg.language)
	end

	-- Find out p.tools[]
	function M.getCompiler(cfg)
		return M.getToolsetFromCfg(cfg)
	end

-- Compile flags
-- -------------

	-- List tables used for generating c flags
	function M.listCFlags(toolset, cfg, filecfg)
		-- Keep order ! buildopt .. cppflags .. cflags .. defines .. includes .. forceincludes
		return {
			filecfg.buildoptions,
			toolset.getcppflags(filecfg), toolset.getcflags(filecfg),
			toolset.getdefines(filecfg.defines), toolset.getundefines(filecfg.undefines),
			toolset.getincludedirs(cfg, filecfg.includedirs, filecfg.externalincludedirs, filecfg.frameworkdirs, filecfg.includedirsafter),
			toolset.getforceincludes(cfg)
		};
	end

	-- List tables used for generating cxx flags
	function M.listCxxFlags(toolset, cfg, filecfg)
		-- Keep order ! buildopt .. cppflags .. cxxflags .. defines .. includes .. forceincludes
		return {
			filecfg.buildoptions,
			toolset.getcppflags(filecfg), toolset.getcxxflags(filecfg),
			toolset.getdefines(filecfg.defines), toolset.getundefines(filecfg.undefines),
			toolset.getincludedirs(cfg, filecfg.includedirs, filecfg.externalincludedirs, filecfg.frameworkdirs, filecfg.includedirsafter),
			toolset.getforceincludes(cfg)
		};
	end

	-- Find compileas from cfg and node
	-- Priority: node, cfg then config for (node, cfg)
	local function getCompileAs(cfg, node)
		if node.compileas and node.compileas ~= "Default" then
			return true, node.compileas
		end
		if cfg.compileas and cfg.compileas ~= "Default" then
			return true, cfg.compileas
		end
		local filecfg = p.fileconfig.getconfig(node, cfg)
		if filecfg.compileas and filecfg.compileas ~= "Default" then
			return true, filecfg.compileas
		end
		return false, nil
	end

	function M.shouldCompileAsC(cfg, node)
		local found, compileas = getCompileAs(cfg, node)
		if found == true then
			return p.languages.isc(compileas)
		end
		-- Use file
		return path.iscfile(node.abspath)
	end

	function M.shouldCompileAsCpp(cfg, node)
		local found, compileas = getCompileAs(cfg, node)
		if found == true then
			return p.languages.iscpp(compileas)
		end
		-- Use file
		return path.iscppfile(node.abspath)
	end

return M
