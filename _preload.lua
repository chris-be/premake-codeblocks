--
-- Name:		codeblocks/_preload.lua
-- Purpose:		Define Code::Blocks action (and its options).
-- Copyright:	See attached license file
--

	local p = premake

	newaction {
		trigger         = "codeblocks",
		shortname       = "Code::Blocks",
		description     = "Generate Code::Blocks project files",
		toolset         = "gcc",

		valid_kinds     = { "ConsoleApp", "WindowedApp", "StaticLib", "SharedLib" },
		valid_languages = { "C", "C++" },
		valid_tools     = {
			cc	= { "clang", "gcc", "msc" },
		},

		pathVars        = {
			["wks.location"]             = { absolute = true,  token = "$(WORKSPACE_DIR)" },
			["wks.name"]                 = { absolute = false, token = "$(WORKSPACE_NAME)" },
			["sln.location"]             = { absolute = true,  token = "$(WORKSPACE_DIR)" },
			["sln.name"]                 = { absolute = false, token = "$(WORKSPACE_NAME)" },
			["prj.location"]             = { absolute = true,  token = "$(PROJECT_DIR)" },
			["prj.name"]                 = { absolute = false, token = "$(PROJECT_NAME)" },
			["cfg.targetdir"]            = { absolute = true,  token = "$(PROJECT_DIR)$(TARGET_OUTPUT_DIR)" },
			["cfg.buildcfg"]             = { absolute = false, token = "$(TARGET_NAME)" },
			["cfg.buildtarget.basename"] = { absolute = false, token = "$(TARGET_OUTPUT_BASENAME)" },
			["cfg.buildtarget.relpath"]  = { absolute = false, token = "$(TARGET_OUTPUT_FILE)" },
			["file.directory"]           = { absolute = true,  token = "$file_dir" },
			["file.basename"]            = { absolute = false, token = "$file_name" },
			["file.abspath"]             = { absolute = true,  token = "$file" },
		},

		onWorkspace = function(wks)
			p.modules.codeblocks.generateWorkspace(wks)
		end,

		onProject = function(prj)
			p.modules.codeblocks.generateProject(prj)
		end,

		onCleanWorkspace = function(wks)
			p.modules.codeblocks.cleanWorkspace(wks)
		end,

		onCleanProject = function(prj)
			p.modules.codeblocks.cleanProject(prj)
		end,

		onCleanTarget = function(tgt)
			p.modules.codeblocks.cleanTarget(tgt)
		end
	}

	newoption {
		trigger = "codeblocks-check",
		value = "ENABLE",
		description = "codeblocks: check configuration consistency",
		allowed = {
			{ "true", "Enabled (*)" }, { "false", "Disabled" }
		},
		default = "true"
	}

	-- Decide when the full module should be loaded.
	return function(cfg)
		return (_ACTION == "codeblocks")
	end
