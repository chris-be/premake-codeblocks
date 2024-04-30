--
-- Name:		codeblocks/codeblocks_main.lua
-- Purpose:		Some common things for CodeBlocks libraries.
-- Copyright:	See attached license file
--

	-- Premake libraries
	local p = premake
	local tools = p.tools

	-- CodeBlocks "main" library
	local codeblocks = p.modules.codeblocks
	codeblocks.main = {}
	local m = codeblocks.main

-- Defines
-- -------
	m.AUDITOR_TITLE    = "codeblocks_auditor"
	m.WARN_KEY_AUDITOR = "codeblocks_check_configs"

-- Toolset
-- -------
	m.Tools = {
		-- Note: Code::Blocks does not distinguish c compiler from cpp compiler
		CB_TOOL_NAMES = {
			[tools.clang] = "clang",
			[tools.gcc]   = "gcc",
			[tools.msc]   = "Visual C++",
		},

		-- Get compiler for toolset and language
		getCompilerName = function(toolset, language)
			local self = m.Tools
			if p.languages.isc(language) or p.languages.iscpp(language) then
				return self.CB_TOOL_NAMES[toolset]
			else
				error("Unsupported language")
			end
		end
	}

	-- Get toolset name from config
	-- Priority: _OPTIONS, cfg then default: gcc
	function m.getToolsetFromCfg(cfg)
		local toolset_name = _OPTIONS.cc or cfg.toolset or p.GCC
		local toolset, _ = tools.canonical(toolset_name)
		if not toolset then
			error("Invalid toolset '" + toolset_name + "'")
		end
		return toolset
	end

	-- Get compiler name to use in Code::Blocks depending on toolset
	function m.getCompilerName(cfg)
		local toolset = m.getToolsetFromCfg(cfg)
		return m.Tools.getCompilerName(toolset, cfg.language)
	end

	-- Find out p.tools[]
	function m.getCompiler(cfg)
		return m.getToolsetFromCfg(cfg)
	end

-- Compile flags
-- -------------
	local function tostring(value)
		if #value > 0 then
			return " " .. table.concat(value, " ")
		else
			return ""
		end
	end

	function m.getCFlags(toolset, cfg, filecfg)
		local buildopt = tostring(filecfg.buildoptions)
		local cppflags = tostring(toolset.getcppflags(filecfg))
		local cflags = tostring(toolset.getcflags(filecfg))
		local defines = tostring(table.join(toolset.getdefines(filecfg.defines), toolset.getundefines(filecfg.undefines)))
		local includes = tostring(toolset.getincludedirs(cfg, filecfg.includedirs, filecfg.externalincludedirs))
		local forceincludes = tostring(toolset.getforceincludes(cfg))

		return buildopt .. cppflags .. cflags .. defines .. includes .. forceincludes
	end

	function m.getCppFlags(toolset, cfg, filecfg)
		local buildopt = tostring(filecfg.buildoptions)
		local cppflags = tostring(toolset.getcppflags(filecfg))
		local cxxflags = tostring(toolset.getcxxflags(filecfg))
		local defines = tostring(table.join(toolset.getdefines(filecfg.defines), toolset.getundefines(filecfg.undefines)))
		local includes = tostring(toolset.getincludedirs(cfg, filecfg.includedirs, filecfg.externalincludedirs))
		local forceincludes = tostring(toolset.getforceincludes(cfg))
		return buildopt .. cppflags .. cxxflags .. defines .. includes .. forceincludes
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

	function m.shouldCompileAsC(cfg, node)
		local found, compileas = getCompileAs(cfg, node)
		if found == true then
			return p.languages.isc(compileas)
		end
		-- Use file
		return path.iscfile(node.abspath)
	end

	function m.shouldCompileAsCpp(cfg, node)
		local found, compileas = getCompileAs(cfg, node)
		if found == true then
			return p.languages.iscpp(compileas)
		end
		-- Use file
		return path.iscppfile(node.abspath)
	end

	-- Initialized on first need
	local auditorEnabled = nil

	-- Check "codeblocks-check" option
	m.isAuditorEnabled = function()
		if auditorEnabled == nil then
			-- newoption handles default value (no need to add test 'or "true"')
			auditorEnabled = (_OPTIONS["codeblocks-check"]) == "true"

			local msg
			if auditorEnabled then
				msg = "enabled"
			else
				msg = "disabled"
			end
			verbosef(m.AUDITOR_TITLE .. ": %s", msg)
		end

		return auditorEnabled
	end
