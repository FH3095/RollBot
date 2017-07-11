
FH3095Debug = {
	logFrame = nil,
}

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

function FH3095Debug.log(str, ...)
	if FH3095Debug.logFrame == nil then
		return
	end
	str = str .. ": "
	for i=1,select('#', ...) do
		local val = select(i ,...)
		str = str .. objToString(val) .. " ; "
	end

	FH3095Debug.logFrame:AddMessage(str)
end

function FH3095Debug.onInit()
	for i=1,NUM_CHAT_WINDOWS do
		local frameName = GetChatWindowInfo(i)
		if frameName == "Debug" then
			FH3095Debug.logFrame = _G["ChatFrame" .. i]
			return
		end
	end
end
