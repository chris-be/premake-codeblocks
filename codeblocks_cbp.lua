--
-- Name:		codeblocks/codeblocks_cbp.lua
-- Purpose:		Generate a Code::Blocks C/C++ project.
-- Author:		Ryan Pusztai
-- Modified by:	
-- Created:		
-- Copyright:	(c) 2009-2018 Jason Perkins and the Premake project
--

	local p = premake

	local codeblocks = p.modules.codeblocks

	local project = p.project
	local config = p.config
	local tree = p.tree

	local m = codeblocks.project

	-- weights for generated files
	-- lower weight means build first (default is 50)
	m.weights = {
		[".h"] = 35, -- generated header files are built before others generated source files
		[".hh"] = 35,
		[".hpp"] = 35,
		[".hxx"] = 35,
		_ = 40 -- fallback
	}

	m.elements = {}

	m.ctools =
	{
		  clang	= "clang"
		, gcc	= "gcc"
		, msc	= "Visual C++"
	}

	function m.getcompilername(cfg)
		local tool = _OPTIONS.cc or cfg.toolset or p.GCC

		local toolset = p.tools[tool]
		if not toolset then
			error("Invalid toolset '" + (_OPTIONS.cc or cfg.toolset) + "'")
		end

		return m.ctools[tool]
	end

	function m.getcompiler(cfg)
		local toolset = p.tools[_OPTIONS.cc or cfg.toolset or p.GCC]
		if not toolset then
			error("Invalid toolset '" + (_OPTIONS.cc or cfg.toolset) + "'")
		end
		return toolset
	end

	function m.header(prj)
		_p('<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>')
		_p('<CodeBlocks_project_file>')
		_p(1,'<FileVersion major="1" minor="6" />')

		-- write project block header
		_p(1,'<Project>')
		_p(2,'<Option title="%s" />', prj.name)
		_p(2,'<Option pch_mode="2" />')
		_p(2,'<Option compiler="%s" />', m.getcompilername(prj))
	end

	function m.footer(prj)
		-- write project block footer
		_p(1,'</Project>')
		_p('</CodeBlocks_project_file>')
	end

	m.elements.project = function(prj)
		return
		{
			m.header,
			m.configurations,
			m.files,
			m.extensions,
			m.footer
		}
	end

--
-- Project: Generate the CodeBlocks project file.
--
	function m.generate(prj)
		p.utf8()

		p.callArray(m.elements.project, prj)
	end

	function m.configurations(prj)
		-- write configuration blocks
		_p(2,'<Build>')
		local platforms = {}
		for cfg in project.eachconfig(prj) do
			local found = false
			for k,v in pairs(platforms) do
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

		for k,platform in pairs(platforms) do
			for k,cfg in pairs(platform.configs) do
				local compiler = m.getcompiler(cfg)

				_p(3,'<Target title="%s">', cfg.longname)

				_p(4,'<Option output="%s" prefix_auto="0" extension_auto="0" />', p.esc(cfg.buildtarget.relpath))

				if cfg.debugdir then
					_p(4,'<Option working_dir="%s" />', p.esc(path.getrelative(prj.location, cfg.debugdir)))
				end

				_p(4,'<Option object_output="%s" />', p.esc(path.getrelative(prj.location, cfg.objdir)))

				-- identify the type of binary
				local types = { WindowedApp = 0, ConsoleApp = 1, StaticLib = 2, SharedLib = 3 }
				_p(4,'<Option type="%d" />', types[cfg.kind])

				_p(4,'<Option compiler="%s" />', m.getcompilername(cfg))

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
				for _, externalincludedirs in ipairs(compiler.getincludedirs(cfg, {}, cfg.externalincludedirs)) do
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
				if cfg.linkgroups and compiler ~= p.tools.msc then
						_p(5,'<Add option="-Wl,--start-group" />')
							for _,flag in ipairs(table.join(compiler.getldflags(cfg), cfg.linkoptions, compiler.getlinks(cfg))) do
								_p(5,'<Add option="%s" />', p.esc(flag))
							end
						_p(5,'<Add option="-Wl,--end-group" />', p.esc(flag))
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

	local function tostring(value)
		if #value > 0 then
			return " " .. table.concat(value, " ")
		else
			return ""
		end
	end

	local function getcflags(toolset, cfg, filecfg)
		local buildopt = tostring(filecfg.buildoptions)
		local cppflags = tostring(toolset.getcppflags(filecfg))
		local cflags = tostring(toolset.getcflags(filecfg))
		local defines = tostring(table.join(toolset.getdefines(filecfg.defines), toolset.getundefines(filecfg.undefines)))
		local includes = tostring(toolset.getincludedirs(cfg, filecfg.includedirs, filecfg.externalincludedirs))
		local forceincludes = tostring(toolset.getforceincludes(cfg))

		return buildopt .. cppflags .. cflags .. defines .. includes .. forceincludes
	end

	local function getcxxflags(toolset, cfg, filecfg)
		local buildopt = tostring(filecfg.buildoptions)
		local cppflags = tostring(toolset.getcppflags(filecfg))
		local cxxflags = tostring(toolset.getcxxflags(filecfg))
		local defines = tostring(table.join(toolset.getdefines(filecfg.defines), toolset.getundefines(filecfg.undefines)))
		local includes = tostring(toolset.getincludedirs(cfg, filecfg.includedirs, filecfg.externalincludedirs))
		local forceincludes = tostring(toolset.getforceincludes(cfg))
		return buildopt .. cppflags .. cxxflags .. defines .. includes .. forceincludes
	end

	local function shouldcompileasc(cfg, node)
		if node.compileas and node.compileas ~= "Default" then
			return p.languages.isc(node.compileas)
		end
		if cfg.compileas and cfg.compileas ~= "Default" then
			return p.languages.isc(filecfg.compileas)
		end
		local filecfg = p.fileconfig.getconfig(node, cfg)
		if filecfg.compileas and filecfg.compileas ~= "Default" then
			return p.languages.isc(filecfg.compileas)
		end
		return path.iscfile(node.abspath)
	end

	local function shouldcompileascpp(cfg, node)
		if node.compileas and node.compileas ~= "Default" then
			return p.languages.iscpp(node.compileas)
		end
		if cfg.compileas and cfg.compileas ~= "Default" then
			return p.languages.iscpp(filecfg.compileas)
		end
		local filecfg = p.fileconfig.getconfig(node, cfg)
		if filecfg.compileas and filecfg.compileas ~= "Default" then
			return p.languages.iscpp(filecfg.compileas)
		end
		return path.iscppfile(node.abspath)
	end

	local function getfirstcfg(prj)
		for cfg in project.eachconfig(prj) do
			return cfg
		end
	end


	local function warnIfNotConsistentConfigs(prj, node)
		local function checkFilecfgs(filecfg1, filecfg2)
			if filecfg1.buildmessage ~= filecfg2.buildmessage then
				return false, "buildmessage"
			end
			if not table.equals(filecfg1.buildcommands or {}, filecfg2.buildcommands or {}) then
				return false, "buildcommands"
			end
			if #filecfg1.buildcommands == 0 and not filecfg1.buildmessage then return true, nil end
			if not table.equals(filecfg1.buildoutputs or {}, filecfg2.buildoutputs or {}) then return false, "buildoutputs" end
			if filecfg1.compilebuildoutputs ~= filecfg2.compilebuildoutputs then return false, "compilebuildoutputs" end
			return false, nil
		end
		local function checkCfgs(cfg1, cfg2)
			if cfg1 == cfg2 then return nil end

			local toolset1 = p.tools[_OPTIONS.cc or cfg1.toolset or p.GCC]
			local toolset2 = p.tools[_OPTIONS.cc or cfg2.toolset or p.GCC]
			if toolset1 ~= toolset2 then return "toolset" end

			local hasFileSettings1 = p.fileconfig.hasFileSettings(p.fileconfig.getconfig(node, cfg1))
			local hasFileSettings2 = p.fileconfig.hasFileSettings(p.fileconfig.getconfig(node, cfg2))
			if hasFileSettings1 ~= hasFileSettings2 then return "filtering" end
			if not hasFileSettings1 then return nil end

			local filecfg1 = p.fileconfig.getconfig(node, cfg1)
			local filecfg2 = p.fileconfig.getconfig(node, cfg2)

			if shouldcompileasc(cfg1, node) then
				if getcflags(toolset1, cfg1, filecfg1) ~= getcflags(toolset2, cfg2, filecfg2) then return "cflags" end
			elseif shouldcompileascpp(cfg1, node) then
				if getcxxflags(toolset1, cfg1, filecfg1) ~= getcxxflags(toolset2, cfg2, filecfg2) then return "cxxflags" end
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
				local rulecfg1 = p.context.extent(rule, environ1)
				local rulecfg2 = p.context.extent(rule, environ2)

				local _, rule_err = checkFilecfgs(filecfg1, filecfg2)
				if rule_err then return "rule " .. rule_err end
			end
			return nil
		end

		local first_cfg = getfirstcfg(prj) -- take first one as default

		for cfg in project.eachconfig(prj) do
			local err_field = checkCfgs(first_cfg, cfg)
			if err_field then
				p.warnOnce("codeblocks_check_configs", "Code::Blocks doesn't support custom build different by configuration. You might try using Token (i.e '%%%%{cfg.buildcfg}') to bypass that issue.")
				p.warn("Not consistent config (" .. err_field .. ") for file " .. node.name .. ". Keeping config " .. first_cfg.name)
				return
			end
		end
	end

--
-- Write out a list of the source code files in the project.
--

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
				warnIfNotConsistentConfigs(prj, node)
				local cfg = getfirstcfg(prj) -- take first one as default
				local filecfg = p.fileconfig.getconfig(node, cfg)
				local hasFileSettings = p.fileconfig.hasFileSettings(p.fileconfig.getconfig(node, cfg))
				if path.isresourcefile(node.name) then
					_p(3,'<Option compilerVar="WINDRES" />')
				elseif (node.compileas and node.compileas ~= "Default") or hasFileSettings then
					local toolset = p.tools[_OPTIONS.cc or cfg.toolset or p.GCC]
					local default_compiler = m.getcompilername(cfg)

					if shouldcompileasc(cfg, node) then
						_p(3,'<Option compilerVar="CC" />')
						_p(3,'<Option compile="1" />')
						_p(3,'<Option link="1" />')
						_p(3,'<Option compiler="%s" use="1" buildCommand="$compiler $options $includes%s -c -x c $file -o $object" />', default_compiler, getcflags(toolset, cfg, filecfg))
					elseif shouldcompileascpp(cfg, node) then
						_p(3,'<Option compilerVar="CPP" />')
						_p(3,'<Option compile="1" />')
						_p(3,'<Option link="1" />')
						_p(3,'<Option compiler="%s" use="1" buildCommand="$compiler $options $includes%s -c -x c++ $file -o $object" />', default_compiler, getcxxflags(toolset, cfg, filecfg))
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
					_p(3, '<Option compiler="%s" use="1" buildCommand="%s" />', m.getcompilername(cfg), p.esc(os.translateCommandsAndPaths(buildmessage .. commands .. compile, cfg.project.basedir, cfg.project.location):gsub('\n', '\\n')))
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
				for k,fsub in pairs(node.configs) do
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
				if m.getcompilername(cfg) == "gcc" then
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
