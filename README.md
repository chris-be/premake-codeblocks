# Premake-CodeBlocks Module
"Premake" module that generates *workspace and projects* for [Code::Blocks](http://www.codeblocks.org/).<br>
**Based on source code from** [Premake4](https://github.com/premake/premake-4.x/tree/master/src/actions/codeblocks).

## Features
- Support for C/C++ language projects

## Usage (little reminder)
1. Put these files in a "Code::Blocks" subdirectory of [Premake search paths](https://premake.github.io/docs/Locating-Scripts/).

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

## Tested on
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
<tr>
	<td>Void Linux (x64) - April 2024</td>	<td>5.0.0-alpha15</td>	<td>20.03</td>	<td>Clang++ 17.0.6</td>
</tr>
</table>

