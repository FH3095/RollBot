
local RB = RollBot
local log = RollBotDebug.log

function RB:consoleParseCommand(msg, editbox)
	log("ParseChatCommand", msg)
	local cmd, nextpos = self.console:GetArgs(msg)
	cmd = cmd:lower()
	if cmd == "help" or cmd == nil then
		self:consolePrintHelp()
	elseif cmd == "startroll" then
		local itemLink = self.console:GetArgs(msg, 1, nextpos)
		self:consoleStartRoll(itemLink)
	elseif cmd == "resultwindow" then
		self:openResultWindow()
	elseif cmd == "rollwindow" then
		self:openRollWindow(nil)
	elseif cmd == "versions" then
		self:scheduleTimer(self.consolePrintVersions, 7)
		self.com:SendCommMessage(self.consts.ADDON_MSGS.getVersionReq, "", "RAID")
	else
		self.console:Printf("Invalid command \"%s\". Use \"help\" for available commands.", cmd)
	end
end

function RB:consolePrintHelp()
	self.console:Printf("%s: Available commands:", self.consts.ADDON_NAME_COLORED)
	self.console:Printf("versions")
	self.console:Printf("    Requests version from everyone in the raid, waits 7 seconds for response and then prints the versions")
	self.console:Printf("startroll ItemLink")
	self.console:Printf("    Posts a raidwarning or raidmessage and let the raiders with the client choose their roll")
	self.console:Printf("resultwindow")
	self.console:Printf("    Opens roll result window")
	self.console:Printf("rollwindow")
	self.console:Printf("    Opens roll window (again)")
end

function RB:consoleStartRoll(itemLink)
	local itemName = GetItemInfo(itemLink)
	if nil == itemName then
		self:consolePrintError("Invalid item link: %s", itemLink)
		return
	end
	self:startRoll(itemLink)
end

function RB:consolePrintVersions()
	local ownName = RB:getOwnRaidInfo()
	if ownName == nil then
		self:consolePrintError("Not in raid")
		return
	end
	self.vars.versions[ownName] = self.consts.VERSION
	local versions = {}
	for k,v in pairs(self.vars.versions) do
		if versions[v] == nil then
			versions[v] = ""
		else
			versions[v] = versions[v] .. ", "
		end
		versions[v] = versions[v] .. k
	end
	table.sort(versions)
	self.console:Printf("%s: Versions in raid:", self.consts.ADDON_NAME_COLORED)
	for k,v in pairs(versions) do
		self.console:Printf("%s: %s", k, v)
	end
end

function RB:consolePrintError(str, ...)
	str = self.consts.ADDON_NAME_COLORED .. " |cFFFF0000Error:|r " .. str
	print(str:format(...))
end
