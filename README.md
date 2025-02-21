# Premake-CodeBlocks Module
"Premake" module that generates *workspace and projects* for [Code::Blocks](http://www.codeblocks.org/).<br>
**Based on source code from** [Premake4](https://github.com/premake/premake-4.x/tree/master/src/actions/codeblocks).

## Features
- Support for C/C++ language projects

## Usage (little reminder)
1. Put these files in a "Code::Blocks" subdirectory of [Premake search paths](https://premake.github.io/docs/Locating-Scripts/).<br>

2. Adapt your premake5.lua script, or better: create/adapt your [premake-system.lua](https://premake.github.io/docs/System-Scripts/)

```lua
require "codeblocks"
```

3. Generate Code::Blocks files

The module checks if configurations are compatible with Code::Blocks, but it slows down the process. It can be disabled with option `--codeblocks-check=false`

```sh
premake5 codeblocks
# Or
premake5 codeblocks --codeblocks=false
```

# Note
If you are interested in a Code::Blocks plugin doing the reverse job, you may try [*Premake5 exporter*](https://gitlab.com/arnholm/premake5cb).

## Working on plugin
If your IDE understands [EmmyLua annotations](https://emmylua.github.io/annotation.html), you may take a look at [lua-d-premake5](https://github.com/chris-be/lua-d-premake5).

## Tested on
<table>
<tr>
	<th>OS (Platform) - Date</th>	<th>Premake</th>	<th>Code::Blocks Version</th>	<th>Target compiler</th>
</tr>
<tr>
	<td>Void Linux (x64) - April 2024</td>	<td>5.0.0-alpha15</td>	<td>20.03</td>	<td>clang, gcc</td>
</tr>
</table>

