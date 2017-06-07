
local RB = RollBot
local log = RollBotDebug.log

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
	local _, _, masterLooterRaidId = GetLootMethod()
	local ret = GetRaidRosterInfo(masterLooterRaidId)
	return ret
end

function RB:scheduleTimer(func, delay)
	local timerFunc = function()
		func(RB)
	end
	self.timers:ScheduleTimer(timerFunc, delay)
end

function RB:getOwnRaidInfo()
	local ownRaidId = UnitInRaid("player")
	if ownRaidId == nil then
		return nil
	end
	return GetRaidRosterInfo(ownRaidId)
end

-- TODO: Test method
function RB:isUserMasterLooter(user)
	local userRaidId = UnitInRaid(user)
	if userRaidId == nil then
		return false
	end
	local _,_,_,_,_,_,_,_,_,_, isMasterLooter = GetRaidRosterInfo(userRaidId)
	if isMasterLooter == true then
		return true
	end
	return false
end

function RB:sendMasterLooterSettings()
	log("SendMasterLooterSettings")
	local data = self.serializer:Serialize(self.vars.rolls)
	self.com:SendCommMessage(self.consts.ADDON_MSGS.lootOptionsResp, data, "RAID")
end

function RB:doRoll(max)
	RandomRoll(1, max)
end

function RB:startRoll(itemLink)
	local success, ownRank = self:getOwnRaidInfo()
	if success == nil then
		self:consolePrintError("Not in raid")
		return
	end
	if not self:isMyselfMasterLooter() then
		self:consolePrintError("You are not the master looter")
		return
	end
	local chatMsgType = "RAID"
	if ownRank > 0 then
		chatMsgType = "RAID_WARNING"
	end
	self.com:SendCommMessage(self.consts.ADDON_MSGS.startRoll, itemLink, "RAID")
	SendChatMessage(self.db.profile.rollText:format(itemLink), chatMsgType)
	self:openResultWindow()
	self:resultClearRolls()
end
