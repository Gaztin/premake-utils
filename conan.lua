local conan = {}
conan.version = "2.2.3"

local function getDownloadUrlFromHost(host)
  if host == "windows" then
    return "https://github.com/conan-io/conan/releases/download/"..conan.version.."/conan-"..conan.version.."-windows-x86_64.zip"
  elseif host == "macosx" then
    local machine = os.outputof("uname -m")
    if machine == "arm64" then
      return "https://github.com/conan-io/conan/releases/download/"..conan.version.."/conan-"..conan.version.."-macos-arm64.tgz"
    else
      return "https://github.com/conan-io/conan/releases/download/"..conan.version.."/conan-"..conan.version.."-macos-x86_64.tgz"
    end
  elseif host == "linux" then
    local machine = os.outputof("uname -m")
    if machine ~= "x86_64" then
      error("Unsupported machine: " .. machine)
    end
    return "https://github.com/conan-io/conan/releases/download/"..conan.version.."/conan-"..conan.version.."-linux-x86_64.tgz"
  else
    error("Unsupported host: " .. host)
  end
end

local maxBars = 30
function downloadProgressFunction(total, current)
  local ratio = current / total;
  ratio = math.min(math.max(ratio, 0), 1);
  local percent = math.floor(ratio * 100);
  local bars = math.floor(ratio * maxBars)
  io.write("Downloading Conan: [" .. string.rep("=", bars) .. string.rep(" ", maxBars - bars) .. "] " .. percent .. "%\r")
end

local host        = os.host()
local downloadUrl = getDownloadUrlFromHost(host)
local zipFilePath = path.join(_MAIN_SCRIPT_DIR, "conan", path.getname(downloadUrl))
local didDownload = false

if not os.isfile(zipFilePath) then
  local downloadOptions = {
    progress = downloadProgressFunction,
  }
  os.mkdir(path.getdirectory(zipFilePath))
  io.write("Downloading Conan...\r")
  local resultString, responseCode = http.download(downloadUrl, zipFilePath, downloadOptions)
  io.write(string.rep(" ", maxBars + 30) .. "\r")
  if responseCode ~= 200 then
    error("Failed to download Conan: " .. resultString)
  end
  
  io.write("Extracting Conan...\r")
  local unzipResult = zip.extract(zipFilePath, path.getdirectory(zipFilePath))
  if unzipResult ~= 0 then
    os.remove(zipFilePath)
    error("Failed to extract Conan: " .. unzipResult)
  end
  io.write(string.rep(" ", 30) .. "\r")

  didDownload = true
end

conan.path = path.join(path.getdirectory(zipFilePath), "conan")

if didDownload then
  if host ~= "windows" then
    os.execute("chmod +x " .. conan.path)
  end
  io.write("Detecting default Conan profile...\r")
  os.outputof(conan.path .. " profile detect -vquiet")
  io.write(string.rep(" ", 40) .. "\r")
end

conan.require = function(packageName, packageVersion)
  local packageRef = packageName .. "/" .. packageVersion
  local prj = premake.api.scope.project
  -- Calling 'eachconfig' will result in a premature baking of the workspace, which is required to obtain the configurations
  -- Therefore, we need to deep copy the workspace and call 'eachconfig' on the copy
  local wks = table.deepcopy(premake.api.scope.workspace)
  for cfg in premake.workspace.eachconfig(wks) do
    local arch = cfg.architecture
    local buildType = cfg.buildcfg
    local outputFolder = path.getrelative(os.getcwd(), path.join(_MAIN_SCRIPT_DIR, "conan", "build"))
    local command = conan.path .. " install --require " .. packageRef .. " --output-folder " .. outputFolder .. " --settings build_type=" .. buildType .. " --settings arch=" .. arch .. " --build missing --generator PremakeDeps"

    io.write("Installing Conan dependencies (" .. cfg.name .. ")...\r")
    local output, exitCode = os.outputof(command)
    io.write(string.rep(" ", 50) .. "\r")
    if exitCode ~= 0 then
      error("Failed to install Conan dependencies")
    end

    local conf = buildType:lower() .. "_" .. arch:lower()
    local varsFileName = "conan_" .. packageName .. "_vars_" .. conf .. ".premake5.lua"
    local needsLinking = table.contains({"WindowedApp", "ConsoleApp", "SharedLib"}, prj.kind)

    filter {"configurations:" .. cfg.buildcfg, "platforms:" .. cfg.platform}
    dofile(path.join(outputFolder, varsFileName))

    externalincludedirs(conandeps[conf][packageName]["includedirs"])
    bindirs(conandeps[conf][packageName]["bindirs"])
    defines(conandeps[conf][packageName]["defines"])

    if needsLinking then
      libdirs(conandeps[conf][packageName]["libdirs"])
      links(conandeps[conf][packageName]["libs"])
      links(conandeps[conf][packageName]["system_libs"])
      links(conandeps[conf][packageName]["frameworks"])
    end

    filter {}
  end
end

return conan
