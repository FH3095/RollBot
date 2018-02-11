
local IS_DEBUG = false
--@alpha@
IS_DEBUG = true
--@end-alpha@

FH3095Debug = {
	logFrame = nil,
	enabled = false,
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
	if not FH3095Debug.isEnabled() then
		return
	end
	if (FH3095Debug.logFrame == nil and FH3095Debug.enabled) or (not IS_DEBUG and not FH3095Debug.enabled) then
		return
	end
	str = str .. ": "
	for i=1,select('#', ...) do
		local val = select(i ,...)
		str = str .. objToString(val) .. " ; "
	end

	if FH3095Debug.logFrame == nil then
		print(str)
	else
		FH3095Debug.logFrame:AddMessage(str)
	end
end

function FH3095Debug.isEnabled()
	if (FH3095Debug.enabled and FH3095Debug.logFrame == nil) or (not FH3095Debug.enabled and not IS_DEBUG) then
		return false
	end
	return true
end

function FH3095Debug.onEnable()
	for i=1,NUM_CHAT_WINDOWS do
		local frameName = GetChatWindowInfo(i)
		if frameName == "Debug" then
			FH3095Debug.logFrame = _G["ChatFrame" .. i]
			return
		end
	end
	FH3095Debug.enabled = true
end
