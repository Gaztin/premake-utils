local semver = {}
local mt = {
	__eq = function(a, b)
		if #a.parts ~= #b.parts then
			return false
		end
		for i = 1, #a.parts do
			if a.parts[i] ~= b.parts[i] then
				return false
			end
		end
		return true
	end,

	__lt = function(a, b)
		for i = 1, math.min(#a.parts, #b.parts) do
			if a.parts[i] < b.parts[i] then
				return true
			elseif a.parts[i] > b.parts[i] then
				return false
			end
		end
		return #a.parts < #b.parts
	end,

	__le = function(a, b)
		return a < b or a == b
	end,

	__tostring = function(self)
		return table.concat(self.parts, ".")
	end,

	__concat = function(a, b)
		return tostring(a)..tostring(b)
	end
}

function semver.new(...)
	local parts = {...}
	for i = 1, #parts do
		parts[i] = tostring(parts[i])
	end
	local v = {parts = parts}
	setmetatable(v, mt)
	return v
end

function semver.parse(versionString)
	local parts = {}
	for _, part in ("."..versionString):gmatch("(%.)([^%.]+)") do
		table.insert(parts, part)
	end
	local v = {parts = parts}
	setmetatable(v, mt)
	return v
end

return semver
