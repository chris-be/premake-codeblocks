--
-- Name:		codeblocks/codeblocks_workspace.lua
-- Purpose:		Generate a Code::Blocks workspace.
-- Copyright:	See attached license file
--

	-- Premake libraries
	---@module 'premake5'
	local p = premake
	local project = p.project
	local workspace = p.workspace
	-- local tree = p.tree

	-- CodeBlocks "workspace" code
	local codeblocks = p.modules.codeblocks
	local m = codeblocks.workspace

	-- Generate a CodeBlocks workspace
	function m.generate(wks)
		p.utf8()

		_p('<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>')
		_p('<CodeBlocks_workspace_file>')
		_p(1,'<Workspace title="%s">', wks.name)

		for prj in workspace.eachproject(wks) do
			local fname = path.join(path.getrelative(wks.location, prj.location), prj.filename)
			local active = iif(prj.name == (wks.startproject or wks.projects[1].name), ' active="1"', '')

			_p(2,'<Project filename="%s.cbp"%s>', fname, active)
			for _,dep in ipairs(project.getdependencies(prj)) do
				_p(3,'<Depends filename="%s.cbp" />', path.join(path.getrelative(wks.location, dep.location), dep.filename))
			end

			_p(2,'</Project>')
		end

		_p(1,'</Workspace>')
		_p('</CodeBlocks_workspace_file>')
	end
