
local RB = RollBot
local libI = LibStub("LibInspect")
local log = FH3095Debug.log
local isDebugEnabled = FH3095Debug.isEnabled
local module = {
	vars = {
		cache = {},
		counter = 1,
		inspectTimerId = nil,
		cleanupTimerId = nil,
	},
	consts = {
		RAID_MIN = 1,
		RAID_MAX = 40,
		CLEANUP_INTERVAL = 30 * 60,
		TOKENS = {
			-- -- Antorus -- --
			-- Cloak
			[152515] = { classes = {1,3,7,10}, slot = 15}, -- Warrior, Hunter, Shaman, Monk
			[152516] = { classes = {2,5,9,12}, slot = 15}, -- Paladin, Priest, Warlock, Demon Hunter
			[152517] = { classes = {4,6,8,11}, slot = 15}, -- Rogue, Deathknight, Mage, Druid
			-- Chest
			[152520] = { classes = {1,3,7,10}, slot = 5}, -- Warrior, Hunter, Shaman, Monk
			[152519] = { classes = {2,5,9,12}, slot = 5}, -- Paladin, Priest, Warlock, Demon Hunter
			[152518] = { classes = {4,6,8,11}, slot = 5}, -- Rogue, Deathknight, Mage, Druid
			-- Gauntlets
			[152523] = { classes = {1,3,7,10}, slot = 10}, -- Warrior, Hunter, Shaman, Monk
			[152522] = { classes = {2,5,9,12}, slot = 10}, -- Paladin, Priest, Warlock, Demon Hunter
			[152521] = { classes = {4,6,8,11}, slot = 10}, -- Rogue, Deathknight, Mage, Druid
			-- Helm
			[152526] = { classes = {1,3,7,10}, slot = 1}, -- Warrior, Hunter, Shaman, Monk
			[152525] = { classes = {2,5,9,12}, slot = 1}, -- Paladin, Priest, Warlock, Demon Hunter
			[152524] = { classes = {4,6,8,11}, slot = 1}, -- Rogue, Deathknight, Mage, Druid
			-- Leggings
			[152529] = { classes = {1,3,7,10}, slot = 7}, -- Warrior, Hunter, Shaman, Monk
			[152528] = { classes = {2,5,9,12}, slot = 7}, -- Paladin, Priest, Warlock, Demon Hunter
			[152527] = { classes = {4,6,8,11}, slot = 7}, -- Rogue, Deathknight, Mage, Druid
			-- Shoulders
			[152532] = { classes = {1,3,7,10}, slot = 3}, -- Warrior, Hunter, Shaman, Monk
			[152531] = { classes = {2,5,9,12}, slot = 3}, -- Paladin, Priest, Warlock, Demon Hunter
			[152530] = { classes = {4,6,8,11}, slot = 3}, -- Rogue, Deathknight, Mage, Druid

		}
	},
}

local function guidToName(guid)
	local _, _, _, _, _, name, realm = GetPlayerInfoByGUID(guid)
	local ret = name
	if realm and tostring(realm) ~= "" then
		ret = name .. "-" .. realm
	end
	return ret
end

function module:inspectPlayer(unitId)
	if not (UnitIsConnected(unitId) and CanInspect(unitId) and not InCombatLockdown()) then
		return false
	end

	local canInspect, unitFound = libI:RequestData("items", unitId, false)
	log("InspectPlayer DataRequested", canInspect, unitFound)
	if not canInspect or not unitFound then
		return false
	end
	return true
end

function module:cleanupCache()
	log("InspectCleanupCache")
	local existingGUIDs = {}
	for i=self.consts.RAID_MIN,self.consts.RAID_MAX do
		local guid = UnitGUID("raid" .. i)
		if guid ~= nil then
			existingGUIDs[guid] = true
		end
	end
	for guid,_ in pairs(self.vars.cache) do
		if existingGUIDs[guid] == nil then
			if isDebugEnabled() then
				log("InspectCleanupCache Player removed", guid, guidToName(guid))
			end
			self.vars.cache[guid] = nil
		end
	end
end

function module:runCheck()
	if not IsInRaid() or InCombatLockdown() then
		return
	end

	local i = self.vars.counter
	local curTime = time()
	while i <= self.consts.RAID_MAX do
		local unitId = "raid" .. i
		local unitGuid = UnitGUID(unitId)
		if (self.vars.cache[unitGuid] == nil or self.vars.cache[unitGuid].maxAge <= curTime) and self:inspectPlayer(unitId) then
			break
		end
		i = i + 1
	end

	i = i + 1
	if i > self.consts.RAID_MAX then
		i = self.consts.RAID_MIN
	end
	self.vars.counter = i
end

function module:inspectReady(guid, data, age)
	self.vars.cache[guid] = {}
	self.vars.cache[guid].maxAge = time() + (self.vars.settings.refreshInterval * 60)
	self.vars.cache[guid].items = data.items
	if isDebugEnabled then
		log("InspectReady done", guid, guidToName(guid), age, self.vars.cache[guid] ~= nil)
	end
end

function RB:inspectGetWearingItemForPlayer(player, newItem)
	local newItemId,_,_,newItemLoc = GetItemInfoInstant(newItem)
	local guid = UnitGUID(player)
	local result = {}
	if module.vars.cache[guid] == nil or module.vars.cache[guid].items == nil then
		return result
	end

	if module.consts.TOKENS[newItemId] ~= nil then
		newItemLoc = module.consts.TOKENS[newItemId].slot
	end

	for i=INVSLOT_FIRST_EQUIPPED,INVSLOT_LAST_EQUIPPED do
		local itemLink = module.vars.cache[guid].items[i]
		if itemLink ~= nil then
			local _,_,_,curItemLoc = GetItemInfoInstant(itemLink)
			if curItemLoc == newItemLoc then
				tinsert(result, itemLink)
			end
		end
	end
	log("InspectGetItem player, guid, newItem, newItemLoc, result", player, guid, newItem, newItemLoc, result)
	return result
end

function RB:inspectStart()
	local settings = self.db.profile.inspectSettings
	module.vars.settings = settings
	log("InspectStart", settings.doInspect, settings.inspectInterval, settings.refreshInterval)
	if not settings.doInspect then
		return
	end

	libI:SetMaxAge((settings.refreshInterval * 60) - 1)
	libI:AddHook(self.consts.ADDON_NAME, "items", function(guid, data, age) module:inspectReady(guid, data, age) end)
	if module.vars.timerId == nil then
		module.vars.inspectTimerId = self.timers:ScheduleRepeatingTimer(module.runCheck, settings.inspectInterval, module)
	end
	if module.vars.cleanupTimerId == nil then
		module.vars.cleanupTimerId = self.timers:ScheduleRepeatingTimer(module.cleanupCache, module.consts.CLEANUP_INTERVAL, module)
	end
end
