# Premake-CodeBlocks Module
Generate workspace and projects for [Code::Blocks](http://www.codeblocks.org/).

# Features
- Support for C/C++ language projects

# Usage (little reminder)
1. Put these files in a "codeblocks" subdirectory of [Premake search paths](https://github.com/premake/premake-core/wiki/Locating-Scripts).

2. Adapt your premake5.lua script, or better: create/adapt your [premake-system.lua](https://github.com/premake/premake-core/wiki/System-Scripts)
```lua
require "codeblocks"
```

3. Generate
```sh
premake5 codeblocks
```

# Tested on
<table>
<tr>
	<th>Platform</th>	<th>OS</th>	<th>Code::Blocks Version</th>	<th>Compiler</th>
</tr>
<tr>
	<td>i386</td>	<td>Debian Buster</td>	<td>16.01</td>	<td>Clang++ 4.0</td>
</tr>
</table>
