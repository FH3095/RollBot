
local ADDON_NAME = "RollBot"
local IS_DEBUG = true
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
	self.com = LibStub("AceComm-3.0")
	self.l = LibStub("AceLocale-3.0"):GetLocale("RollBot", false)
	self.db = LibStub("AceDB-3.0"):New(ADDON_NAME .. "DB", self:GenerateDefaultOptions(), true)
	LibStub("AceConfig-3.0"):RegisterOptionsTable(ADDON_NAME, self:GenerateOptions(), {"RollBot", "RB"})
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions(ADDON_NAME)
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
	log("Options table", ret)
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
