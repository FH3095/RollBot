
local RB = RollBot
local libST = LibStub("ScrollingTable")
local log = FH3095Debug.log
local wnd = {
	vars = {
		rolls = {},
	},
}


local DEFAULT_POS = {
	LEFT = {
		relativePoint = "LEFT",
		xOfs = 200,
		yOfs = 0,
	},
	WndHeight = 300,
	WndWidth = 400,
}

function wnd:showWindow()
	log("ResultWindow:showWindow")
	local settings = RB.db.profile.resultWindowSettings
	local window = self.vars.window
	local table = self.vars.table

	local cols = {
		{
			name = RB.l["RESULT_COLUMN_NAME"],
			width = settings.nameColumnSize,
		},
		{
			name = RB.l["RESULT_COLUMN_ROLL"],
			width = settings.rollColumnSize,
			align = "RIGHT",
		},
		{
			name = RB.l["RESULT_COLUMN_ROLLTYPE"],
			width = settings.rollTypeColumnSize,
		},
		{
			name = RB.l["RESULT_COLUMN_ITEM1"],
			width = settings.item1ColumnSize,
		},
		{
			name = RB.l["RESULT_COLUMN_ITEM2"],
			width = settings.item2ColumnSize,
		}
	}
	window:SetWidth(settings.nameColumnSize + settings.rollColumnSize +
		settings.rollTypeColumnSize + settings.item1ColumnSize + settings.item2ColumnSize + 60)
	window:SetHeight(settings.rowHeight * settings.numRows + 120)

	table:SetDisplayCols(cols)
	table:SetDisplayRows(settings.numRows, settings.rowHeight)
	table:EnableSelection(false)

	self:fillTableData()
	window:Show()
end

function wnd:createWindow()
	log("ResultWindow:createWindow")
	if self.vars.window ~= nil then
		self:showWindow()
		return
	end

	log("ResultWindow: Create new window")
	local window = RB.gui:Create("Window")
	window:SetCallback("OnClose",function(widget)
		RB.db.char.windowPositions.resultWindow = RB:getWindowPos(widget, true)
		widget:Hide()
	end)
	window:SetTitle(RB.l["RESULT_WINDOW_NAME"])
	window:SetLayout("Fill")
	window:EnableResize(false)
	RB:restoreWindowPos(window, RB.db.char.windowPositions.resultWindow, DEFAULT_POS)


	local settings = RB.db.profile.resultWindowSettings

	local table = libST:CreateST({}, settings.numRows, settings.rowHeight, nil, window.frame)
	table.frame:SetPoint("CENTER", window.frame, "CENTER")
	table.CompareSort = function(self, rowa, rowb, sortBy)
		local r1 = self:GetRow(rowa)
		local r2 = self:GetRow(rowb)
		log("CompareFunc", r1.rb_sort, r2.rb_sort)
		return r1.rb_sort < r2.rb_sort
	end

	local onLeaveHideToolTip = function()
		GameTooltip:Hide()
		return false
	end
	local onEnterShowToolTip = function(rowFrame, cellFrame, data, cols, row, realrow, column, scrollingTable, ...)
		if realrow == nil or column == nil or data == nil or cellFrame == nil then
			return false
		end

		local celldata = data[realrow].cols[column]
		if celldata.rb_item == nil then
			return false
		end

		GameTooltip:SetOwner(cellFrame, "ANCHOR_LEFT")
		GameTooltip:SetHyperlink(celldata.rb_item)
		GameTooltip:Show()
		return false
	end
	table:RegisterEvents({OnEnter = onEnterShowToolTip, OnLeave = onLeaveHideToolTip})


	self.vars.window = window
	self.vars.table = table

	self:showWindow()
end

function wnd:getItemText(itemLink)
	local settings = RB.db.profile.resultWindowSettings
	if itemLink == nil or not settings.showRollersCurrentItems then
		return ""
	end
	local _,_,itemRarity,itemLevel = GetItemInfo(itemLink)
	if itemRarity == nil or itemLevel == nil then
		return "[" .. RB.l["GS"] .. ": ? ]"
	end
	local _,_,_,itemCcolor = GetItemQualityColor(itemRarity)
	return "|c" .. itemCcolor .. "[" .. RB.l["GS"] .. ":" .. itemLevel .. "]|r"
end

function wnd:fillTableData()
	local rolls = self.vars.rolls
	local data = {}

	local sortValue = 1
	for _,roll in ipairs(rolls) do
		local rollType = "("
		if roll.rollType ~= nil then
			rollType = rollType .. roll.rollType .. " | "
		end
		rollType = rollType .. roll.rollMin .. "-" .. roll.rollMax .. ")"

		local item1Text = self:getItemText(roll.item1)
		local item2Text = self:getItemText(roll.item2)


		local row = {
			rb_sort = sortValue,
			cols = {
				{value = roll.name},
				{value = roll.roll},
				{value = rollType},
				{value = item1Text, rb_item = roll.item1,},
				{value = item2Text, rb_item = roll.item2,}
			},
		}
		tinsert(data, row)
		sortValue = sortValue + 1
	end
	if self.vars.table ~= nil then
		self.vars.table:SetData(data, false)
	end
end

function wnd:addRoll(name, roll, rollMin, rollMax, rollType, forItem)
	log("ResultWindow:addRoll", name, roll, rollMin, rollMax, rollType, forItem)
	local vars = self.vars
	local function sortFunc(r1,r2)
		if(r1.rollMax~=r2.rollMax) then
			return r1.rollMax > r2.rollMax
		else
			return r1.roll > r2.roll
		end
	end

	local _,_,_,itemEquipLoc = GetItemInfoInstant(forItem)
	local items = RB:inspectGetItemForSlot(name, itemEquipLoc)
	tinsert(vars.rolls, {name=name, roll=roll, rollMin=rollMin, rollMax=rollMax, rollType = rollType,
		item1 = items[1], item2 = items[2],})
	sort(vars.rolls, sortFunc)
	self:fillTableData()
end

function wnd:clearRolls()
	self.vars.rolls = {}
	self:fillTableData()
end

function RB:openResultWindow()
	wnd:createWindow()
end

function RB:resultAddRoll(name, roll, rollMin, rollMax, rollType)
	wnd:addRoll(name, roll, rollMin, rollMax, rollType, self.vars.lastRollItem)
end

function RB:resultClearRolls()
	wnd:clearRolls()
end
