local download = {}

local maxBars = 30
local function downloadProgressFunction(total, current)
  local ratio = current / total;
  ratio = math.min(math.max(ratio, 0), 1);
  local percent = math.floor(ratio * 100);
  local bars = math.floor(ratio * maxBars)
  io.write("Downloading: ["..string.rep("=", bars)..string.rep(" ", maxBars - bars).."] "..percent.."%\r")
end

local function downloadFile(url, destinationFilePath)
  local downloadOptions = {
    progress = downloadProgressFunction,
  }
  os.mkdir(path.getdirectory(destinationFilePath))
  io.write("Downloading...\r")
  local resultString, responseCode = http.download(url, destinationFilePath, downloadOptions)
  io.write(string.rep(" ", maxBars + 20).."\r")
  if responseCode ~= 200 then
    error("Failed to download "..url..": "..resultString)
  end
end

local function unpackZipFile(zipFilePath, unpackDir)
  os.mkdir(unpackDir)
  io.write("Unpacking...\r")
  local result = zip.extract(zipFilePath, unpackDir)
  if result ~= 0 then
    error("Failed to unpack "..zipFilePath..": "..result)
    return false
  end
  io.write(string.rep(" ", 20).."\r")
  return true
end

local function unpackTarball(tarballPath, unpackDir)
  os.mkdir(unpackDir)
  io.write("Unpacking...\r")
  local output, exitCode = os.outputof("tar -xf "..tarballPath.." -C "..unpackDir)
  if exitCode ~= 0 then
    error("Failed to unpack "..tarballPath..": "..exitCode)
    return false
  end
  io.write(string.rep(" ", 20).."\r")
  return true
end



function download.zipFileAndUnpack(url, optionalUnpackDirName)
  local downloadsDir = path.join(_MAIN_SCRIPT_DIR, ".downloads")
  local destinationZipFilePath = path.join(downloadsDir, path.getname(url))
  local unpackDirName = optionalUnpackDirName or path.getbasename(url)
  local unpackDir = path.join(downloadsDir, unpackDirName)
  local didDownload = false
  
  if not os.isfile(destinationZipFilePath) then
    downloadFile(url, destinationZipFilePath)
    local didUnpack = unpackZipFile(destinationZipFilePath, unpackDir)
    if not didUnpack then
      os.remove(destinationZipFilePath)
    end
  
    didDownload = true
  end
  return unpackDir, didDownload
end

function download.tarballAndUnpack(url, optionalUnpackDirName)
  local downloadsDir = path.join(_MAIN_SCRIPT_DIR, ".downloads")
  local destinationTarballPath = path.join(downloadsDir, path.getname(url))
  local unpackDirName = optionalUnpackDirName or path.getbasename(url)
  local unpackDir = path.join(downloadsDir, unpackDirName)
  local didDownload = false
  
  if not os.isfile(destinationTarballPath) then
    downloadFile(url, destinationTarballPath)
    local didUnpack = unpackTarball(destinationTarballPath, unpackDir)
    if not didUnpack then
      os.remove(destinationTarballPath)
    end
  
    didDownload = true
  end
  return unpackDir, didDownload
end

return download
