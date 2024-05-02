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
