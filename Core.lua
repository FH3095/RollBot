
local ADDON_NAME = "RollBot"
local VERSION = "1.0.0"
local IS_DEBUG = true
local ADDON_MSGS = {
	lootOptionsReq = ADDON_NAME .. "1",
	lootOptionsResp = ADDON_NAME .. "2",
	startRoll =  ADDON_NAME .. "3",
	getVersionReq = ADDON_NAME .. "4",
	getVersionResp = ADDON_NAME .. "5",
}
local RB = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME)
RollBot = RB

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

local function log(str, ...)
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

function RB:OnInitialize()
	self.vars = {
		masterLooter = nil,
	}
	self.l = LibStub("AceLocale-3.0"):GetLocale("RollBot", false)
	self.timer = LibStub("AceTimer-3.0")
	self.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", self:GenerateDefaultOptions(), true)
	LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, self:GenerateOptions(), {"RollBot", "RB"})
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME)

	self.com = LibStub("AceComm-3.0")
	local addonCommandFunc = function(prefix, message, distribution, sender)
		RB:comAddonMsg(prefix, message, distribution, sender)
	end
	for k,v in pairs(ADDON_MSGS) do
		self.com:RegisterComm(v, addonCommandFunc)
	end

	self.events = LibStub("AceEvent-3.0")
	self.events:RegisterEvent("GROUP_ROSTER_UPDATE", function() RB:GROUP_ROSTER_UPDATE() end)
end

function RB:comAddonMsg(prefix, message, distribution, sender)
	log("ComAddonMsg", message, distribution, sender)
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

function RB:GROUP_ROSTER_UPDATE()
	log("GroupRosterUpdate")
end

function RB:GenerateDefaultOptions()
	local ret = {
		profile = {
			numRollOptions = 3,
			rolls ={
				roll1 = {
					roll = 100,
					name = "Need",
				},
				roll2 = {
					roll = 95,
					name = "Greed",
				},
				roll3 = {
					roll = 90,
					name = "Disenchant",
				},
			}
		}
	}
	return ret
end

function RB:GenerateOptions()
	local rolls = {
		type	= "group",
		name	= "Rolls",
		set		= "SetRollOption",
		get		= "GetRollOption",
		childGroups = "select",
		args	= {},
	};
	for i=1,self.db.profile.numRollOptions do
		local rollName = "Roll %3d"
		rollName = rollName:format(i)
		local roll = {
			type = "group",
			name = rollName,
			args = {
				name = {
					type	= "input",
					name	= "Name",
					multiline = false,
				},
				roll = {
					type	= "range",
					name	= "Roll",
					min		= 1,
					max		= 1000000,
					softMax	= 100,
					step	= 1,
				}
			}
		}
		rolls.args["roll" .. i] = roll
	end

	local ret = {
		name = ADDON_NAME,
		type = "group",
		args = {
			basic = {
				name = "Basic",
				type = "group",
				set = "SetBasicOption",
				get = "GetBasicOption",
				args = {
					numRollOptions = {
						type	= "range",
						name	= "Roll Options",
						desc	= "Number of roll options",
						min		= 1,
						max		= 100,
						softMax	= 10,
						step	= 1,
					},
				}
			},
			rolls = rolls,
		},
	}
	--log("Options table", ret)
	ret.handler = self
	ret.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	return ret
end

function RB:SetBasicOption(info, value)
	log("Set option", info[#info], value)
	self.db.profile[info[#info]] = value
	if info[#info] == "numRollOptions" then
		local config = LibStub("AceConfig-3.0")
		config:RegisterOptionsTable(ADDON_NAME, self:GenerateOptions(), {"RollBot", "RB"})
	end
end

function RB:GetBasicOption(info)
	return self.db.profile[info[#info]]
end

function RB:SetRollOption(info, value)
	local rollName = info[#info-1]
	local rollOption = info[#info]
	log("Set roll option", rollName, rollOption, value)
	if self.db.profile.rolls[rollName] == nil then
		self.db.profile.rolls[rollName] = {}
	end
	self.db.profile.rolls[rollName][rollOption] = value
end

function RB:GetRollOption(info)
	local rollName = info[#info-1]
	local rollOption = info[#info]
	if self.db.profile.rolls[rollName] == nil then
		return nil
	end
	return self.db.profile.rolls[rollName][rollOption]
end
