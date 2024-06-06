local embed = {}
embed.indentString = "\t"
embed.indentLevel = 0
embed.currentFile = nil

local function readFileContent(inputPath)
  local inputFile = io.open(inputPath, "rb")
  local content = inputFile:read("*a")
  inputFile:close()
  return content
end

local function write(text)
  embed.currentFile:write(text)
end

local function writeIndent()
  write(embed.indentString:rep(embed.indentLevel))
end

local function newLine(count)
  count = count or 1
  write(("\n"):rep(count))
end

local function writeLine(text)
  writeIndent()
  write(text)
  newLine()
end

local function push(text)
  writeLine(text)
  embed.indentLevel = embed.indentLevel + 1
end

local function pop(text)
  embed.indentLevel = embed.indentLevel - 1
  writeLine(text)
end

local function writeCArray(identifier, content)
  push("const uint8_t " .. identifier .. "[] {")
  for j = 1, #content do
    if j % 16 == 1 then
      writeIndent()
    else
      write(" ")
    end
    write(string.format("0x%02X,", string.byte(content, j)))
    if j % 16 == 0 then
      newLine()
    end
  end
  newLine()
  pop("};")
end

local function createHeaderFile(headerPath, inputPaths)
  embed.currentFile = io.open(headerPath, "w")
  writeLine("// This file is generated by a script. Do not modify it manually.")
  writeLine("#pragma once")
  writeLine("#include <cstdint>")
  newLine()
  writeLine("namespace Embeds {")
  for i, inputPath in ipairs(inputPaths) do
    local inputName = path.getname(inputPath)
    local identifier = inputName:gsub("[^%w]", "_")
    local content = readFileContent(inputPath)
    newLine()
    writeCArray(identifier, content)
  end
  newLine()
  writeLine("}")
  embed.currentFile:close()
end

function embed.file(outputDir, inputPath)
  local inputName = path.getname(inputPath)
  local headerPath = path.join(outputDir, inputName .. ".h")
  createHeaderFile(headerPath, {inputPath})
  print("Embedded file: " .. inputPath .. " -> " .. headerPath)
end

function embed.files(outputDir, inputPaths)
  local headerPath = path.join(outputDir, "Embeds.h")
  createHeaderFile(headerPath, inputPaths)
  print("Embedded files: [" .. table.concat(inputPaths, ", ") .. "] -> " .. headerPath)
end

return embed
