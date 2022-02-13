# Premake-CodeBlocks Module
Generate workspace and projects for [Code::Blocks](http://www.codeblocks.org/).

# Features
- Support for C/C++ language projects

# Usage (little reminder)
1. Put these files in a "codeblocks" subdirectory of [Premake search paths](https://premake.github.io/docs/Locating-Scripts/).

2. Adapt your premake5.lua script, or better: create/adapt your [premake-system.lua](https://premake.github.io/docs/System-Scripts/)
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
	<th>OS (Platform) - Date</th>	<th>Premake</th>	<th>Code::Blocks Version</th>	<th>Compiler</th>
</tr>
<tr>
	<td>Debian Buster (i686) - March 2018</td>	<td>5.0.0-alpha-12</td>	<td>16.01</td>	<td>Clang++ 4.0</td>
</tr>
<tr>
	<td>Void Linux (i686) - February 2021</td>	<td>5.0.0-beta1</td>	<td>20.03</td>	<td>Clang++ 12.0</td>
</tr>
</table>
