
local log = FH3095Debug.log
local RB = RollBot


function RB:GenerateDefaultOptions()
	local ret = {
		profile = {
			numRollOptions = 2,
			rollText = "ROLL %1$s, %2$d seconds",
			openResultWindowOnStartRollByOtherPM = false,
			showRollersCurrentItems = false,
			rollChatMsgType = "RAID_WARNING",
			rollTime = 30,
			rollFinishChatMsg = "Roll finished!",
			closeRollWindowAfterRollTime = true,
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
	if self.db.profile.showRollersCurrentItems == nil then
		self.db.profile.showRollersCurrentItems = false
	end
	if self.db.profile.resultWindowSettings == nil then
		self.db.profile.resultWindowSettings = {
			nameColumnSize = 100,
			rollColumnSize = 35,
			rollTypeColumnSize = 100,
			item1ColumnSize = 60,
			item2ColumnSize = 60,
			rowHeight = 15,
			numRows = 10,
			showRollersCurrentItems = true,
		}
	end
end

function RB:RefreshOptions()
	local config = LibStub("AceConfig-3.0")
	config:RegisterOptionsTable(RB.consts.ADDON_NAME, self:GenerateOptions(), {"RollBotSettings", "RBS"})
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

	local resultWindowOptions = {
		type 	= "group",
		name	= "Result Window",
		set		= "SetResultWindowOption",
		get		= "GetResultWindowOption",
		args = {
			nameColumnSize = {
				type	= "range",
				name	= "Name Column Size",
				min		= 1,
				max		= 10000,
				softMax	= 2000,
				step	= 1,
			},
			rollColumnSize = {
				type	= "range",
				name	= "Roll Result Column Size",
				min		= 1,
				max		= 10000,
				softMax	= 2000,
				step	= 1,
			},
			rollTypeColumnSize = {
				type	= "range",
				name	= "Roll Type Column Size",
				min		= 1,
				max		= 10000,
				softMax	= 2000,
				step	= 1,
			},
			item1ColumnSize = {
				type	= "range",
				name	= "Item 1 Column Size",
				min		= 1,
				max		= 10000,
				softMax	= 2000,
				step	= 1,
			},
			item2ColumnSize = {
				type	= "range",
				name	= "Item 2 Column Size",
				min		= 1,
				max		= 10000,
				softMax	= 2000,
				step	= 1,
			},
			rowHeight = {
				type	= "range",
				name	= "Row Height",
				min		= 1,
				max		= 10000,
				softMax	= 30,
				step	= 1,
			},
			numRows = {
				type	= "range",
				name	= "Number of Rows",
				min		= 3,
				max		= 1000,
				softMax	= 40,
				step	= 1,
			},
			showRollersCurrentItems = {
				name = "Show the items, the rollers are currently wearing",
				type = "toggle",
				tristate = false,
			},
		},
	}

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
					},
					closeRollWindowAfterRollTime = {
						name = "Automatically close roll window after roll time is expired",
						type="toggle",
						tristate = false,
					},
				}
			},
			rolls = rolls,
			rollTime = {
				name = "Roll time",
				type = "group",
				set = "SetBasicOption",
				get = "GetBasicOption",
				args = {
					rollTime = {
						type	= "range",
						name	= "Time to roll (seconds)",
						desc	= "Timer displayed until roll is finished, 0 to disable",
						min		= 0,
						max		= 3600,
						softMax	= 180,
						step	= 1,
					},
					rollFinishChatMsg = {
						type	= "input",
						name	= "Text to post when roll is finished",
						multiline = false,
					},
				}
			},
			resultWindowSettings = resultWindowOptions,
		},
	}
	ret.handler = self
	ret.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
	return ret
end

function RB:SetBasicOption(info, value)
	log("Set option", info[#info], value)
	self.db.profile[info[#info]] = value
	if info[#info] == "numRollOptions" then
		self:RefreshOptions()
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

function RB:SetResultWindowOption(info, value)
	log("Set result window option", info[#info], value)
	self.db.profile.resultWindowSettings[info[#info]] = value
end

function RB:GetResultWindowOption(info)
	return self.db.profile.resultWindowSettings[info[#info]]
end
