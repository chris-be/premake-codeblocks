--
-- Name:		codeblocks/codeblocks_cbp.lua
-- Purpose:		Generate a Code::Blocks C/C++ project.
-- Copyright:	See attached license file
--

	-- Premake libraries
	---@module 'premake5'
	local p = premake
	local project = p.project
	local config = p.config
	local tree = p.tree

	-- Load needed libraries (must be done here)
	local main = require("codeblocks_main")
	local auditor = require("codeblocks_auditor")

	-- CodeBlocks "project" code
	local codeblocks = p.modules.codeblocks
	local m = codeblocks.project

	-- weights for generated files
	-- lower weight means build first (default is 50)
	m.weights = {
		[".h"]   = 35, -- generated header files are built before others generated source files
		[".hh"]  = 35,
		[".hpp"] = 35,
		[".hxx"] = 35,
		_        = 40, -- fallback
	}

	m.elements = {}

	-- Concat everything through tables
	local function tablesToString(tableList)
		local s = ""
		for _, tbl in pairs(tableList) do
			if #tbl > 0 then
				s = s .. " " .. table.concat(tbl, " ")
			end
		end
		return s
	end

	-- Generate c flags
	function m.getCFlags(toolset, cfg, filecfg)
		local tblList = main.listCFlags(toolset, cfg, filecfg)
		return tablesToString(tblList)
	end

	-- Generate cpp flags
	function m.getCppFlags(toolset, cfg, filecfg)
		local tblList = main.listCxxFlags(toolset, cfg, filecfg)
		return tablesToString(tblList)
	end

-- Files generation
-- ----------------
	m.elements.project = function(prj)
		return {
			m.header,
			m.configurations,
			m.files,
			m.extensions,
			m.footer
		}
	end

	-- Generate the CodeBlocks project file.
	function m.generate(prj)
		if  main.isAuditorEnabled() then
			-- Audit files before generating
			auditor.checkFiles(prj)
		end

		-- Generation
		p.utf8()
		p.callArray(m.elements.project, prj)
	end

	-- Write header
	function m.header(prj)
		_p('<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>')
		_p('<CodeBlocks_project_file>')
		_p(1,'<FileVersion major="1" minor="6" />')

		-- write project block header
		_p(1,'<Project>')
		_p(2,'<Option title="%s" />', prj.name)
		_p(2,'<Option pch_mode="2" />')
		_p(2,'<Option compiler="%s" />', main.getCompilerName(prj))
	end

	-- Write footer
	function m.footer(prj)
		-- write project block footer
		_p(1,'</Project>')
		_p('</CodeBlocks_project_file>')
	end

	-- Write configuration blocks
	function m.configurations(prj)
		_p(2,'<Build>')
		local platforms = {}
		for cfg in project.eachconfig(prj) do
			local found = false
			for _,v in pairs(platforms) do
				if (v.platform == cfg.platform) then
					table.insert(v.configs, cfg)
					found = true
					break
				end
			end

			if (not found) then
				table.insert(platforms, {platform = cfg.platform, configs = {cfg}})
			end
		end

		for _,platform in pairs(platforms) do
			for _,cfg in pairs(platform.configs) do
				local compiler = main.getCompiler(cfg)

				_p(3,'<Target title="%s">', cfg.longname)

				_p(4,'<Option output="%s" prefix_auto="0" extension_auto="0" />', p.esc(cfg.buildtarget.relpath))

				if cfg.debugdir then
					_p(4,'<Option working_dir="%s" />', p.esc(path.getrelative(prj.location, cfg.debugdir)))
				end

				_p(4,'<Option object_output="%s" />', p.esc(path.getrelative(prj.location, cfg.objdir)))

				-- identify the type of binary
				local types = { WindowedApp = 0, ConsoleApp = 1, StaticLib = 2, SharedLib = 3 }
				_p(4,'<Option type="%d" />', types[cfg.kind])

				_p(4,'<Option compiler="%s" />', main.getCompilerName(cfg))

				if (cfg.kind == "SharedLib") then
					_p(4,'<Option createDefFile="0" />')
					_p(4,'<Option createStaticLib="%s" />', iif(cfg.flags.NoImportLib, 0, 1))
				end

				-- begin compiler block --
				_p(4,'<Compiler>')
				for _,flag in ipairs(table.join(compiler.getcflags(cfg), compiler.getcxxflags(cfg), compiler.getdefines(cfg.defines), compiler.getundefines(cfg.undefines), cfg.buildoptions)) do
					_p(5,'<Add option="%s" />', p.esc(flag))
				end
				if not cfg.flags.NoPCH and cfg.pchheader then
					_p(5,'<Add option="-Winvalid-pch" />')
					_p(5,'<Add option="-include &quot;%s&quot;" />', p.esc(cfg.pchheader))
				end
				for _, forceincludedir in ipairs(compiler.getforceincludes(cfg)) do
					_p(5,'<Add option="%s" />', forceincludedir)
				end
				for _, externalincludedirs in ipairs(compiler.getincludedirs(cfg, {}, cfg.externalincludedirs, cfg.frameworkdirs, cfg.includedirsafter)) do
					_p(5,'<Add option="%s" />', externalincludedirs)
				end
				for _,v in ipairs(cfg.includedirs) do
					_p(5,'<Add directory="%s" />', p.esc(path.getrelative(prj.location, v)))
				end
				_p(4,'</Compiler>')
				-- end compiler block --

				-- begin linker block --
				_p(4,'<Linker>')
				for _,v in ipairs(config.getlinks(cfg, "all", "directory")) do
					_p(5,'<Add directory="%s" />', p.esc(v))
				end
				if cfg.linkgroups == p.ON and compiler ~= p.tools.msc then
					_p(5,'<Add option="-Wl,--start-group" />')
						for _,flag in ipairs(table.join(compiler.getldflags(cfg), cfg.linkoptions, compiler.getlinks(cfg))) do
							_p(5,'<Add option="%s" />', p.esc(flag))
						end
					_p(5,'<Add option="-Wl,--end-group" />')
				else
					for _,flag in ipairs(table.join(compiler.getldflags(cfg), cfg.linkoptions)) do
						_p(5,'<Add option="%s" />', p.esc(flag))
					end
					for _,v in ipairs(config.getlinks(cfg, "all", "basename")) do
						_p(5,'<Add library="%s" />', p.esc(v))
					end
				end
				_p(4,'</Linker>')
				-- end linker block --

				-- begin resource compiler block --
				if config.findfile(cfg, ".rc") then
					_p(4,'<ResourceCompiler>')
					for _,v in ipairs(cfg.includedirs) do
						_p(5,'<Add directory="%s" />', p.esc(v))
					end
					for _,v in ipairs(cfg.resincludedirs) do
						_p(5,'<Add directory="%s" />', p.esc(v))
					end
					_p(4,'</ResourceCompiler>')
				end
				-- end resource compiler block --

				-- begin build steps --
				if cfg.prebuildmessage or cfg.prelinkmessage or cfg.postbuildmessage or #cfg.prebuildcommands > 0 or #cfg.prelinkcommands or #cfg.postbuildcommands > 0 then
					_p(4,'<ExtraCommands>')
					if cfg.prebuildmessage then
						_p(5,'<Add before="%s" />', p.esc(os.translateCommandsAndPaths("{ECHO} ".. cfg.prebuildmessage, cfg.project.basedir, cfg.project.location)))
					end
					for _,v in ipairs(cfg.prebuildcommands) do
						_p(5,'<Add before="%s" />', p.esc(os.translateCommandsAndPaths(v, cfg.project.basedir, cfg.project.location)))
					end

					if cfg.prelinkmessage then
						_p(5,'<Add before="%s" />', p.esc(os.translateCommandsAndPaths("{ECHO} ".. cfg.prelinkmessage, cfg.project.basedir, cfg.project.location)))
					end
					if #cfg.prelinkcommands > 0 then
						p.warnOnce("codeblocks_prelink", "prelinkcommands is treated as prebuildcommands for Code::Blocks")
						for _,v in ipairs(cfg.prelinkcommands) do
							_p(5,'<Add before="%s" />', p.esc(os.translateCommandsAndPaths(v, cfg.project.basedir, cfg.project.location)))
						end
					end

					if cfg.postbuildmessage then
						_p(5,'<Add after="%s" />', p.esc(os.translateCommandsAndPaths("{ECHO} ".. cfg.postbuildmessage,  cfg.project.basedir, cfg.project.location)))
					end
					for _,v in ipairs(cfg.postbuildcommands) do
						_p(5,'<Add after="%s" />', p.esc(os.translateCommandsAndPaths(v, cfg.project.basedir, cfg.project.location)))
					end
					_p(4,'</ExtraCommands>')
				end
				-- end build steps --

				_p(3,'</Target>')
			end
		end
		_p(2,'</Build>')
	end

	-- Write out a list of the source code files in the project.
	function m.files(prj)
		local pchheader
		if (prj.pchheader) then
			pchheader = path.getrelative(prj.location, prj.pchheader)
		end

		local tr = project.getsourcetree(prj)
		tree.traverse(tr, {
			-- source files are handled at the leaves
			onleaf = function(node, depth)
				if node.generated then
					return
				end
				if node.relpath == node.vpath then
					_p(2,'<Unit filename="%s">', node.relpath)
				else
					_p(2,'<Unit filename="%s">', node.relpath)
					_p(3,'<Option virtualFolder="%s" />', path.getdirectory(node.vpath))
				end

				local cfg = project.getfirstconfig(prj) -- take first one as default
				local filecfg = p.fileconfig.getconfig(node, cfg)
				if path.isresourcefile(node.name) then
					_p(3,'<Option compilerVar="WINDRES" />')
				elseif filecfg.flags.ExcludeFromBuild or filecfg.buildaction == "None" then
					_p(3, '<Option compile="0" />')
					_p(3, '<Option link="0" />')
				elseif (node.compileas and node.compileas ~= "Default") or p.fileconfig.hasFileSettings(filecfg) then
					local toolset = main.getCompiler(cfg)
					local default_compiler = main.getCompilerName(cfg)
					if main.shouldCompileAsC(cfg, node) then
						_p(3,'<Option compilerVar="CC" />')
						_p(3,'<Option compile="1" />')
						_p(3,'<Option link="1" />')
						_p(3,'<Option compiler="%s" use="1" buildCommand="$compiler $options $includes %s -c -x c $file -o $object" />', default_compiler, m.getCFlags(toolset, cfg, filecfg))
					elseif main.shouldCompileAsCpp(cfg, node) then
						_p(3,'<Option compilerVar="CPP" />')
						_p(3,'<Option compile="1" />')
						_p(3,'<Option link="1" />')
						_p(3,'<Option compiler="%s" use="1" buildCommand="$compiler $options $includes %s -c -x c++ $file -o $object" />', default_compiler, m.getCppFlags(toolset, cfg, filecfg))
					end
				elseif path.iscfile(node.name) and prj.language == "C++" then
					_p(3,'<Option compilerVar="CC" />')
				end
				if not prj.flags.NoPCH and node.name == pchheader then
					_p(3,'<Option compilerVar="%s" />', iif(prj.language == "C", "CC", "CPP"))
					_p(3,'<Option compile="1" />')
					_p(3,'<Option weight="0" />')
					_p(3,'<Add option="-x c++-header" />')
				end

				local function addrule(cfg, filecfg)
					if #filecfg.buildcommands == 0 and not filecfg.buildmessage then
						return false
					end
					local buildmessage = ""
					if filecfg.buildmessage then
						buildmessage = "{ECHO} " .. filecfg.buildmessage .. "\n"
					end
					local commands = table.implode(filecfg.buildcommands,"","\n","")
					_p(3, '<Option compile="1" />')
					local compile = ""
					if #filecfg.buildoutputs ~= 0 and filecfg.compilebuildoutputs then
						compile = "$compiler $options $includes -c " .. project.getrelative(cfg.project, filecfg.buildoutputs[1]) .. " -o $object"
						_p(3, '<Option link="1" />')
					end
					local ext = ""
					if #filecfg.buildoutputs ~= 0 then
						ext = path.getextension(filecfg.buildoutputs[1]):lower()
					end
					_p(3, '<Option weight="%d" />', m.weights[ext] or m.weights["_"])
					_p(3, '<Option compiler="%s" use="1" buildCommand="%s" />', main.getCompilerName(cfg), p.esc(os.translateCommandsAndPaths(buildmessage .. commands .. compile, cfg.project.basedir, cfg.project.location):gsub('\n', '\\n')))
					return true
				end

				local rule = p.global.getRuleForFile(node.name, prj.rules)
				if not addrule(cfg, filecfg) and rule then
					local environ = table.shallowcopy(filecfg.environ)

					if rule.propertydefinition then
						p.rule.prepareEnvironment(rule, environ, cfg)
						p.rule.prepareEnvironment(rule, environ, filecfg)
					end
					local rulecfg = p.context.extent(rule, environ)
					addrule(cfg, rulecfg)
				end

				-- TODO No need to be generated if all targets are selected for file
				for _,fsub in pairs(node.configs) do
					_p(3, '<Option target="%s" />', fsub.config.longname)
				end
				_p(2,'</Unit>')

			end,
		}, false, 1)
	end

	function m.extensions(prj)
		for cfg in project.eachconfig(prj) do
			if cfg.debugenvs and #cfg.debugenvs > 0 then
				--Assumption: if gcc is being used then so is gdb although this section will be ignored by
				--other debuggers. If using gcc and not gdb it will silently not pass the
				--environment arguments to the debugger
				if main.getCompilerName(cfg) == "gcc" then
					_p(3,'<debugger>')
						_p(4,'<remote_debugging target="%s">', p.esc(cfg.longname))
							local args = ''
							local sz = #cfg.debugenvs
							for idx, v in ipairs(cfg.debugenvs) do
								args = args .. 'set env ' .. v
								if sz ~= idx then args = args .. '&#x0A;' end
							end
							_p(5,'<options additional_cmds_before="%s" />',args)
						_p(4,'</remote_debugging>')
					_p(3,'</debugger>')
				else
					 error('Sorry at this moment there is no support for debug environment variables with this debugger and codeblocks')
				end
			end
		end
	end
