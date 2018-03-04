--
-- Name:	codeblocks/codeblocks.lua
-- Purpose:	Load Code::Blocks module
-- Author:	
-- Modified by:	
-- Created:	2018/03/03
-- Copyright:	(c) 2018 Jason Perkins and the Premake project
--

	local p = premake

	p.modules.codeblocks = {}

	local codeblocks = p.modules.codeblocks

	codeblocks._VERSION = "1.0.0-dev"

	codeblocks.workspace = {}
	codeblocks.project = {}

	include("codeblocks_action.lua")
	include("codeblocks_main.lua")
	include("codeblocks_cbp.lua")
	include("codeblocks_workspace.lua")

	print("Code::Blocks module loaded.")

	return codeblocks
