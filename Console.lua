
local RB = RollBot
local log = RollBotDebug.log

function RB:consoleParseCommand(msg, editbox)
	log("ParseChatCommand", msg)
	local cmd, nextpos = self.console:GetArgs(msg)
	if cmd == "help" or cmd == nil then
		self:consolePrintHelp()
	elseif cmd == "startroll" then
		local itemLink = self.console:GetArgs(msg, 1, nextpos)
		self:consoleStartRoll(itemLink)
	elseif cmd == "versions" then
		self:scheduleTimer(self.consolePrintVersions, 7)
		self.com:SendCommMessage(self.consts.ADDON_MSGS.getVersionReq, "", "RAID")
	else
		self.console:Printf("Invalid command \"%s\". Use \"help\" for available commands.", cmd)
	end
end

function RB:consolePrintHelp()
	self.console:Printf("%s: Available commands:", self.consts.ADDON_NAME)
	self.console:Printf("versions")
	self.console:Printf("    Requests version from everyone in the raid, waits 7 seconds for response and then prints the versions")
	self.console:Printf("startroll ItemLink")
	self.console:Printf("    Posts a raidwarning or raidmessage and let the raiders with the client choose their roll")
end

function RB:consoleStartRoll(itemLink)
	local itemName = GetItemInfo(itemLink)
	if nil == itemName then
		self:consolePrintError("Invalid item link: %s", itemLink)
		return
	end

	local ownRaidId = UnitInRaid("player")
	if ownRaidId == nil then
		self:consolePrintError("Cant start roll while not in a raid")
		return
	end
	local _, ownRank = GetRaidRosterInfo(ownRaidId)
	local chatMsgType = "RAID"
	if ownRank > 0 then
		chatMsgType = "RAID_WARNING"
	end
	self.com:SendCommMessage(self.consts.ADDON_MSGS.startRoll, itemLink, "RAID")
	SendChatMessage(self.db.profile.rollText:format(itemLink), chatType)
end

function RB:consolePrintVersions()
	-- TODO: Change GetUnitName to get info from raid roster
	self.vars.versions[GetUnitName("player",true)] = self.consts.VERSION
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
	self.console:Printf("%s: Versions in raid:", self.consts.ADDON_NAME)
	for k,v in pairs(versions) do
		self.console:Printf("%s: %s", k, v)
	end
end

function RB:consolePrintError(str, ...)
	str = "RollBot: Error: " .. str
	print(str:format(...))
end
