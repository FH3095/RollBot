
local ADDON_NAME = "RollBot"
local VERSION = "1.0.0"
local ADDON_MSGS = {
	lootOptionsReq = ADDON_NAME .. "1",
	lootOptionsResp = ADDON_NAME .. "2",
	startRoll =  ADDON_NAME .. "3",
	getVersionReq = ADDON_NAME .. "4",
	getVersionResp = ADDON_NAME .. "5",
}
local log = RollBotDebug.log
local RB = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME)
RollBot = RB

RB.consts = {}
RB.consts.ADDON_MSGS = ADDON_MSGS
RB.consts.ADDON_NAME = ADDON_NAME
RB.consts.VERSION = VERSION
RB.consts.ADDON_NAME_COLORED = "|cFF00FFFF" .. RB.consts.ADDON_NAME .. "|r"

function RB:OnInitialize()
	self.vars = {
		masterLooter = nil,
		rolls = {},
		versions = {},
	}
	self.l = LibStub("AceLocale-3.0"):GetLocale("RollBot", false)
	self.timers = LibStub("AceTimer-3.0")
	self.serializer = LibStub("AceSerializer-3.0")
	self.gui = LibStub("AceGUI-3.0")

	self.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", self:GenerateDefaultOptions(), true)
	LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, self:GenerateOptions(), {"RollBotSettings", "RBS"})
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME)

	self.com = LibStub("AceComm-3.0")
	local addonCommandFunc = function(prefix, message, distribution, sender)
		RB:comAddonMsg(prefix, message, distribution, sender)
	end
	for k,v in pairs(ADDON_MSGS) do
		self.com:RegisterComm(v, addonCommandFunc)
	end

	self.events = LibStub("AceEvent-3.0")
	self.events:RegisterEvent("GROUP_ROSTER_UPDATE", function() RB:eventGroupRosterUpdate() end)
	self.events:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg) RB:eventChatMsgSystem(msg) end)

	self.console = LibStub("AceConsole-3.0")
	local consoleCommandFunc = function(msg, editbox)
		RB:consoleParseCommand(msg, editbox)
	end
	self.console:RegisterChatCommand("RB", consoleCommandFunc, true)
	self.console:RegisterChatCommand("RollBot", consoleCommandFunc, true)
end

function RB:comAddonMsg(prefix, message, distribution, sender)
	if distribution ~= "RAID" then
		return
	end
	log("ComAddonMsg", message, distribution, sender)
	if prefix == ADDON_MSGS.lootOptionsReq and self:isMyselfMasterLooter() then
		self:sendMasterLooterSettings()
	elseif prefix == ADDON_MSGS.lootOptionsResp and self:isUserMasterLooter(sender) then
		local success, data = self.serializer:Deserialize(message)
		if not success then
			self:consolePrintError("Cant deserialize roll data: %s", data)
			return
		end
		self.vars.rolls = data
	elseif prefix == ADDON_MSGS.startRoll and self:isUserMasterLooter(sender) then
		self:openRollWindow(message)
	elseif prefix == ADDON_MSGS.getVersionReq then
		self.com:SendCommMessage(ADDON_MSGS.getVersionResp, VERSION, "RAID")
	elseif prefix == ADDON_MSGS.getVersionResp then
		self.vars.versions[sender] = message
	else
		self:consolePrintError("Invalid addon message: %s", prefix)
	end
end

function RB:checkMasterLooterChanged()
	log("CheckMasterLooterChanged")
	if self.vars.masterLooter == self:getMasterLooter() then
		return
	end
	self.com:SendCommMessage(ADDON_MSGS.lootOptionsReq, "", "RAID")
end

function RB:eventGroupRosterUpdate()
	log("GroupRosterUpdate")
	if self:isMyselfMasterLooter() then
		self.vars.rolls = self.db.profile.rolls
		log("Rolls are now", self.vars.rolls)
		self:sendMasterLooterSettings()
	else
		self:scheduleTimer(self.checkMasterLooterChanged, 2)
	end
end

function RB:eventChatMsgSystem(msg)
	local rollUser, roll, rollMin, rollMax = msg:match(self.l['ROLL_REGEX'])
	if (nil == rollUser) then
		return
	end
	log("EventChatMsgSystem, roll found", msg)
	RB:resultAddRoll(rollUser, roll, rollMin, rollMax)
end
