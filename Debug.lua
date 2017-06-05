
local IS_DEBUG = true
RollBotDebug = {}

local function objToString(obj)
	if type(obj) == "table" then
		local s = "{ "
		for k,v in pairs(obj) do
			if type(k) == "table" then
				k = '"TableAsKey"'
			elseif type(k) ~= "number" then
				k = '"'..k..'"'
			end
			s = s .. "["..k.."] = " .. objToString(v) .. ','
		end
		return s .. "} "
	else
		return tostring(obj)
	end
end

function RollBotDebug.log(str, ...)
	if not IS_DEBUG then
		return
	end
	str = str .. ": "
	for i=1,select('#', ...) do
		local val = select(i ,...)
		str = str .. objToString(val) .. " ; "
	end
	print(str)
end
