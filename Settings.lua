
local log = FH3095Debug.log
local RB = RollBot


function RB:GenerateDefaultOptions()
	local ret = {
		profile = {
			numRollOptions = 2,
			rollText = "ROLL %s",
			openResultWindowOnStartRollByOtherPM = false,
			rollChatMsgType = "RAID_WARNING",
			rolls ={
				[1] = {
					roll = 100,
					name = "Need",
				},
				[2] = {
					roll = 95,
					name = "Greed",
				},
			}
		}
	}
	return ret
end

function RB:MigrateOptions()
	if self.db.char.windowPositions == nil then
		self.db.char.windowPositions = {}
	end
	if self.db.profile.rollChatMsgType == nil then
		self.db.profile.rollChatMsgType = "RAID_WARNING"
	end
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
		rolls.args[tostring(i)] = roll
	end

	local ret = {
		name = RB.consts.ADDON_NAME,
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
						min		= 2,
						max		= 100,
						softMax	= 10,
						step	= 1,
					},
					rollText = {
						type	= "input",
						name	= "Roll Text",
						multiline = false,
					},
					openResultWindowOnStartRollByOtherPM = {
						name = "Also open result window when other pm starts roll",
						type = "toggle",
						tristate = false,
					},
					rollChatMsgType = {
						name = "Post roll text to",
						type = "select",
						values = {
							RAID_WARNING = CHAT_MSG_RAID_WARNING,
							RAID = CHAT_MSG_RAID,
							SAY = CHAT_MSG_SAY,
							YELL = CHAT_MSG_YELL,
						}
					}
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
		config:RegisterOptionsTable(RB.consts.ADDON_NAME, self:GenerateOptions(), {"RollBotSettings", "RBS"})
	end
end

function RB:GetBasicOption(info)
	return self.db.profile[info[#info]]
end

function RB:SetRollOption(info, value)
	local rollName = tonumber(info[#info-1])
	local rollOption = info[#info]
	log("Set roll option", rollName, rollOption, value)
	if self.db.profile.rolls[rollName] == nil then
		self.db.profile.rolls[rollName] = {}
	end
	self.db.profile.rolls[rollName][rollOption] = value
end

function RB:GetRollOption(info)
	local rollName = tonumber(info[#info-1])
	local rollOption = info[#info]
	if self.db.profile.rolls[rollName] == nil then
		return nil
	end
	return self.db.profile.rolls[rollName][rollOption]
end
