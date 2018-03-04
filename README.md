# Premake-CodeBlocks Module
Generate workspace and projects for [Code::Blocks](http://www.codeblocks.org/).

# Features
- Support for C/C++ language projects

# Usage (little reminder)
Put those files in a "codeblocks" subdirectory of [Premake search paths](https://github.com/premake/premake-core/wiki/Locating-Scripts).

### Adapt your premake5.lua script
```lua
require 'codeblocks'
```

### Launch
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
