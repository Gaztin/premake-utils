This repository is a collection of useful Premake scripts and smaller extensions that don't merit repositories of their own. It's intended to be used as a submodule in other Premake-based projects.

### Contents

📦 **conan.lua**

A script that simplifies integration of [Conan](https://conan.io/) packages in Premake-based C++ projects.

Once included, it automatically downloads a Conan standalone and provides the user with the helper function `conan.require(...)` which installs a package and links it to the current project.
<details>

```lua
local conan = require "premake-utils/conan"

workspace "MyWorkspace"
  configurations { "Debug", "Release" }
  ...

project "MyConsoleApp"
  kind "ConsoleApp"
  language "C++"
  ...
  conan.require("zlib", "1.3")
```
*<summary>Show usage example</summary>*
</details>

---

🛌 **embed.lua**

This script is used for embedding files into a C++ project. It provides functions to generate header and source files that contain the embedded file data.
<details>

```lua
local embed = require "premake-utils/embed"

embed.start("src/generated/")
embed.addFile("res/icon.png")
embed.addFile("fonts/OpenSans-Regular.ttf")
embed.finish()

workspace "MyWorkspace"
  configurations { "Debug", "Release" }
  ...

project "MyConsoleApp"
  kind "ConsoleApp"
  language "C++"
  files {
    "src/generated/*",
    ...
  }
  ...
```
```cpp
#include "generated/Embeds.h"

int main(int argc, char* argv[])
{
    size_t iconFileSize = sizeof(Embeds::icon_png);
    uint8_t* iconFileData = Embeds::icon_png;
    ...
}
```
*<summary>Show usage example</summary>*
</details>

<details>

`setNamespace(x)`<br>
Changes the name of the generated namespace in which the constants are stored. Defaults to "Embeds".

`setIndentString(x)`<br>
Changes the indentation method used during generation. Defaults to "\t", or one tab character.

`setFileName(x)`<br>
Changes the base name of the generated .h and .cpp files. Defaults to "Embeds" (i.e. Embeds.h, Embeds.cpp).
*<summary>Customizations</summary>*
</details>
