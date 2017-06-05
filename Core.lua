
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

function RB:OnInitialize()
	self.vars = {
		masterLooter = nil,
		rolls = {},
		versions = {},
	}
	self.l = LibStub("AceLocale-3.0"):GetLocale("RollBot", false)
	self.timers = LibStub("AceTimer-3.0")
	self.serializer = LibStub("AceSerializer-3.0")

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
	elseif prefix == ADDON_MSGS.getVersionReq then
		self.com:SendCommMessage(ADDON_MSGS.getVersionResp, VERSION, "RAID")
	elseif prefix == ADDON_MSGS.getVersionResp then
		self.vars.versions[sender] = message
	end
end

function RB:isMasterLooterActive()
	local lootMethod = GetLootMethod()
	if IsInRaid() and lootMethod == "master" then
		return true
	end
	return false
end

function RB:isMyselfMasterLooter()
	local lootMethod, masterLooterPartyId = GetLootMethod()
	if IsInRaid() and lootMethod == "master" and masterLooterPartyId == 0 then
		return true
	end
	return false
end

function RB:getMasterLooter()
	if not self:isMasterLooterActive() then
		return nil
	end
	if self:isMyselfMasterLooter() then
		return UnitName("player", true)
	end
	local _, _, masterLooterRaidId = GetLootMethod()
	local ret = GetRaidRosterInfo(masterLooterRaidId)
	return ret
end

function RB:checkMasterLooterChanged()
	log("CheckMasterLooterChanged")
	if self.vars.masterLooter == self:getMasterLooter() then
		return
	end
end

function RB:sendMasterLooterSettings()
	log("SendMasterLooterSettings")
	local data = self.serializer:Serialize(self.vars.rolls)
	self.com:SendCommMessage(ADDON_MSGS.lootOptionsResp, data, "RAID")
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

function RB:scheduleTimer(func, delay)
	local timerFunc = function()
		func(RB)
	end
	self.timers:ScheduleTimer(timerFunc, delay)
end
