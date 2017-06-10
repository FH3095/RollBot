
local ADDON_NAME = "RollBot"
local VERSION = "@project-version@"
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
RB.consts.COLORS = {
	HIGHLIGHT = "|cFF00FFFF",
}
RB.consts.ADDON_NAME_COLORED = RB.consts.COLORS.HIGHLIGHT .. RB.consts.ADDON_NAME .. "|r"

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
	self.events:RegisterEvent("CHAT_MSG_SYSTEM", function(_, msg) RB:eventChatMsgSystem(msg) end)

	self.buckets = LibStub("AceBucket-3.0")
	self.buckets:RegisterBucketEvent("GROUP_ROSTER_UPDATE", 0.5, function() RB:eventGroupRosterUpdate() end)

	self.console = LibStub("AceConsole-3.0")
	local consoleCommandFunc = function(msg, editbox)
		RB:consoleParseCommand(msg, editbox)
	end
	self.console:RegisterChatCommand("RB", consoleCommandFunc, true)
	self.console:RegisterChatCommand("RollBot", consoleCommandFunc, true)

	local toggleDropDownMenuHookFunc = function(_, _, frame)
		if frame ~= GroupLootDropDown then
			return
		end
		local info = UIDropDownMenu_CreateInfo();
		info.notCheckable = 1;
		info.text = RB.l['MASTER_LOOTER_FRAME_START_ROLL'];
		info.func = function()
			local itemLink = GetLootSlotLink(LootFrame.selectedSlot)
			log("MasterLooterDropDown_StartRoll", LootFrame.selectedSlot, itemLink)
			RB:startRoll(itemLink)
		end
		UIDropDownMenu_AddButton(info);
	end
	hooksecurefunc("ToggleDropDownMenu", toggleDropDownMenuHookFunc)
end

function RB:comAddonMsg(prefix, message, distribution, sender)
	if distribution ~= "RAID" then
		return
	end
	log("ComAddonMsg", prefix, sender)
	if prefix == ADDON_MSGS.lootOptionsReq then
		if not self:isMyselfMasterLooter() then
			return
		end
		self:sendMasterLooterSettings()
	elseif prefix == ADDON_MSGS.lootOptionsResp then
		local success, data = self.serializer:Deserialize(message)
		if not success then
			self:consolePrintError("Cant deserialize roll data: %s", data)
			return
		end
		if not self:isUserMasterLooter(sender) then
			log("Received LootOptions but user is not masterlooter", sender, data)
			return
		end

		log("ComAddonMsg: New MasterLooter options", data, self.vars.masterLooter, self:getMasterLooter())
		self.vars.masterLooter = self:getMasterLooter()
		self.vars.rolls = data
	elseif prefix == ADDON_MSGS.startRoll then
		if not self:isUserMasterLooter(sender) then
			log("Received StartRoll but user is not masterlooter", sender, message)
			return
		end
		log("ComAddonMsg start roll", sender, message)
		self:openRollWindow(message)
		if self.db.profile.openResultWindowOnStartRollByOtherPM and not self:isMyselfMasterLooter() then
			self:openResultWindow()
			self:resultClearRolls()
		end
	elseif prefix == ADDON_MSGS.getVersionReq then
		self.com:SendCommMessage(ADDON_MSGS.getVersionResp, VERSION, "RAID")
	elseif prefix == ADDON_MSGS.getVersionResp then
		self.vars.versions[sender] = message
	else
		self:consolePrintError("Invalid addon message: %s", prefix)
	end
end

function RB:checkMasterLooterChanged()
	if self.vars.masterLooter == self:getMasterLooter() then
		return
	end
	log("CheckMasterLooterChanged: Master looter changed, request loot options")
	self.com:SendCommMessage(ADDON_MSGS.lootOptionsReq, "", "RAID")
end

function RB:eventGroupRosterUpdate()
	if self:isMyselfMasterLooter() then
		self.vars.rolls = self.db.profile.rolls
		log("GroupRosterUpdate: Im now the master looter")
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
