
local ADDON_NAME = "RollBot"
local VERSION = "@project-version@"
local ADDON_MSGS = {
	-- Removed request and response to raid
	startRoll =  ADDON_NAME .. "3",
	getVersionReq = ADDON_NAME .. "4",
	getVersionResp = ADDON_NAME .. "5",
}
local log = FH3095Debug.log
local RB = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME)
_G.RollBot = RB

RB.consts = {}
RB.consts.ADDON_MSGS = ADDON_MSGS
RB.consts.ADDON_NAME = ADDON_NAME
RB.consts.VERSION = VERSION
RB.consts.WINDOW_HEIGHT = "WndHeight"
RB.consts.WINDOW_WIDTH = "WndWidth"
RB.consts.COLORS = {
	HIGHLIGHT = "|cFF00FFFF",
}
RB.consts.ADDON_NAME_COLORED = RB.consts.COLORS.HIGHLIGHT .. RB.consts.ADDON_NAME .. "|r"
RB.consts.UNKNOWN_ITEM_FALLBACK = "|cffffffff|Hitem:6948::::::::110:257::::::|h[Ruhestein]|h|r"
RB.consts.UNKNOWN_ROLLS_FALLBACK = {[1] = {name = "Unknown", roll = 100}}
RB.consts.TOKENS = {
	-- -- Antorus -- --
	-- Cloak
	[152515] = { classes = {1,3,7,10}, slot = "INVTYPE_CLOAK"}, -- Warrior, Hunter, Shaman, Monk
	[152516] = { classes = {2,5,9,12}, slot = "INVTYPE_CLOAK"}, -- Paladin, Priest, Warlock, Demon Hunter
	[152517] = { classes = {4,6,8,11}, slot = "INVTYPE_CLOAK"}, -- Rogue, Deathknight, Mage, Druid
	-- Chest
	[152520] = { classes = {1,3,7,10}, slot = "INVTYPE_ROBE"}, -- Warrior, Hunter, Shaman, Monk
	[152519] = { classes = {2,5,9,12}, slot = "INVTYPE_ROBE"}, -- Paladin, Priest, Warlock, Demon Hunter
	[152518] = { classes = {4,6,8,11}, slot = "INVTYPE_ROBE"}, -- Rogue, Deathknight, Mage, Druid
	-- Gauntlets
	[152523] = { classes = {1,3,7,10}, slot = "INVTYPE_HAND"}, -- Warrior, Hunter, Shaman, Monk
	[152522] = { classes = {2,5,9,12}, slot = "INVTYPE_HAND"}, -- Paladin, Priest, Warlock, Demon Hunter
	[152521] = { classes = {4,6,8,11}, slot = "INVTYPE_HAND"}, -- Rogue, Deathknight, Mage, Druid
	-- Helm
	[152526] = { classes = {1,3,7,10}, slot = "INVTYPE_HEAD"}, -- Warrior, Hunter, Shaman, Monk
	[152525] = { classes = {2,5,9,12}, slot = "INVTYPE_HEAD"}, -- Paladin, Priest, Warlock, Demon Hunter
	[152524] = { classes = {4,6,8,11}, slot = "INVTYPE_HEAD"}, -- Rogue, Deathknight, Mage, Druid
	-- Leggings
	[152529] = { classes = {1,3,7,10}, slot = "INVTYPE_LEGS"}, -- Warrior, Hunter, Shaman, Monk
	[152528] = { classes = {2,5,9,12}, slot = "INVTYPE_LEGS"}, -- Paladin, Priest, Warlock, Demon Hunter
	[152527] = { classes = {4,6,8,11}, slot = "INVTYPE_LEGS"}, -- Rogue, Deathknight, Mage, Druid
	-- Shoulders
	[152532] = { classes = {1,3,7,10}, slot = "INVTYPE_SHOULDER"}, -- Warrior, Hunter, Shaman, Monk
	[152531] = { classes = {2,5,9,12}, slot = "INVTYPE_SHOULDER"}, -- Paladin, Priest, Warlock, Demon Hunter
	[152530] = { classes = {4,6,8,11}, slot = "INVTYPE_SHOULDER"}, -- Rogue, Deathknight, Mage, Druid
}
RB.consts.ITEM_TYPE_ARMOR = 4
RB.consts.ITEM_SUBTYPES = {
	CLOTH = 1,
	LEATHER = 2,
	MAIL = 3,
	PLATE = 4,
}
RB.consts.ITEM_SUBTYPES_TO_CLASS = {
	[1] = {5,8,9},
	[2] = {4,10,11,12},
	[3] = {3,7},
	[4] = {1,2,6},
}


function RB:OnInitialize()
	self.vars = {
		lastRoll = {
			item = self.consts.UNKNOWN_ITEM_FALLBACK,
			rolls = self.consts.UNKNOWN_ROLLS_FALLBACK,
			rollTime = 30,
		},
		versions = {},
		rollWindowVars = {
			guiFrame = nil,
		},
		rollTimeWindowVars = {
		}
	}
	self.l = LibStub("AceLocale-3.0"):GetLocale("RollBot", false)
	self.timers = LibStub("AceTimer-3.0")
	self.serializer = LibStub("AceSerializer-3.0")
	self.gui = LibStub("AceGUI-3.0")

	self.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", self:GenerateDefaultOptions(), true)
	self:MigrateOptions()
	self.db.RegisterCallback(self, "OnProfileChanged", function() RB:MigrateOptions(); RB:RefreshOptions() end)
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

	self:inspectStart()
end

function RB:OnEnable()
	FH3095Debug.onEnable()
end

function RB:comAddonMsg(prefix, message, distribution, sender)
	if distribution ~= "RAID" then
		return
	end
	log("ComAddonMsg", prefix, sender)
	if prefix == ADDON_MSGS.startRoll then
		if not self:isUserMasterLooter(sender) then
			log("Received StartRoll but user is not masterlooter", sender)
			return
		end

		local success, data = self.serializer:Deserialize(message)
		if not success then
			self:consolePrintError("Cant deserialize roll data: %s", data)
			return
		end

		log("ComAddonMsg start roll", sender, data)
		self:openRollWindow(data.item, data.rolls, data.rollTime, true)
		-- Clear results (also if player opened window via cmd)
		self:resultClearRolls()
		if self.db.profile.openResultWindowOnStartRollByOtherPM and not self:isMyselfMasterLooter() then
			self:openResultWindow()
			self:openRollTimerWindowAndStart()
		end
	elseif prefix == ADDON_MSGS.getVersionReq then
		self.com:SendCommMessage(ADDON_MSGS.getVersionResp, VERSION, "RAID")
	elseif prefix == ADDON_MSGS.getVersionResp then
		self.vars.versions[sender] = message
	else
		self:consolePrintError("Invalid addon message: %s", prefix)
	end
end

function RB:eventChatMsgSystem(msg)
	local rollUser, roll, rollMin, rollMax = msg:match(self.l['ROLL_REGEX'])
	if (nil == rollUser) then
		return
	end
	if tonumber(rollMin) ~= 1 then
		log("EventChatMsgSystem: Invalid roll, not starting at 1", rollUser, roll, rollMin, rollMax)
		return
	end
	log("EventChatMsgSystem, roll found", msg)
	local rollType = nil
	for _,roll in ipairs(self.vars.lastRoll.rolls) do
		if tonumber(rollMax) == roll["roll"] then
			rollType = roll["name"]
			break
		end
	end
	RB:resultAddRoll(rollUser, tonumber(roll), tonumber(rollMin), tonumber(rollMax), rollType)
end
