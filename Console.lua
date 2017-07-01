
local RB = RollBot
local log = RollBotDebug.log

function RB:consoleParseCommand(msg, editbox)
	log("ParseChatCommand", msg)
	local cmd, nextpos = self.console:GetArgs(msg)
	if cmd == nil or cmd == "" then
		self:consolePrintHelp()
		return
	end

	cmd = cmd:lower()
	if cmd == "help" then
		self:consolePrintHelp()
	elseif cmd == "startroll" then
		local itemLink = self.console:GetArgs(msg, 1, nextpos)
		self:startRoll(itemLink)
	elseif cmd == "results" then
		self:openResultWindow()
	elseif cmd == "resultsclear" then
		self:resultClearRolls()
	elseif cmd == "rolls" then
		self:openRollWindow(nil)
	elseif cmd == "versions" then
		self:scheduleTimer(self.consolePrintVersions, 7)
		self.com:SendCommMessage(self.consts.ADDON_MSGS.getVersionReq, "", "RAID")
	else
		self:consolePrintError("Invalid command \"%s\". Use \"help\" for available commands.", cmd)
	end
end

function RB:consolePrintHelp()
	self.console:Printf("%s: Available commands:", self.consts.ADDON_NAME_COLORED)
	self.console:Printf(RB.consts.COLORS.HIGHLIGHT .. "/RB|r or " .. RB.consts.COLORS.HIGHLIGHT .. "/RollBot|r")
	self.console:Printf("    Main Command")
	self.console:Printf(RB.consts.COLORS.HIGHLIGHT .. "/RBS|r or " .. RB.consts.COLORS.HIGHLIGHT  .. "/RollBotSettings|r")
	self.console:Printf("    Command for settings editing")
	self.console:Printf("Possible " .. RB.consts.COLORS.HIGHLIGHT .. "/RollBot|r parameters:")
	self.console:Printf(RB.consts.COLORS.HIGHLIGHT .. "Versions|r")
	self.console:Printf("    Requests version from everyone in the raid, waits 7 seconds for response and then prints the versions")
	self.console:Printf(RB.consts.COLORS.HIGHLIGHT .. "StartRoll ItemLink|r")
	self.console:Printf("    Posts a raidwarning or raidmessage and let the raiders with the addon choose their roll")
	self.console:Printf(RB.consts.COLORS.HIGHLIGHT .. "Results|r")
	self.console:Printf("    Opens roll window that contains the rolls from the chat")
	self.console:Printf(RB.consts.COLORS.HIGHLIGHT .. "ResultsClear|r")
	self.console:Printf("    Clears the results")
	self.console:Printf(RB.consts.COLORS.HIGHLIGHT .. "Rolls|r")
	self.console:Printf("    Opens the window that contains the buttons to do rolls")
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
