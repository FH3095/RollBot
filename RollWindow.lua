
local RB = RollBot
local log = FH3095Debug.log

local DEFAULT_POS = {
	TOP = {
		relativePoint = "TOP",
		xOfs = 0,
		yOfs = -200,
	},
}

local function cancelRollWindowTimer()
	if RB.vars.rollWindowVars["timerId"] ~= nil then
		log("RollWindow: Cancel Timer")
		RB.timers:CancelTimer(RB.vars.rollWindowVars["timerId"])
		RB.vars.rollWindowVars["timerId"] = nil
		RB.vars.rollWindowVars["rollTimeText"] = nil
	end
end

local function createRollWindowChilds(frame, itemLink, rolls, rollTime, startTimer)
	local icon = RB.gui:Create("Icon")
	-- Usually dont use .frame, but I treat this as an exception
	icon:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(icon.frame, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetHyperlink(itemLink)
		GameTooltip:Show()
	end)
	icon:SetCallback("OnLeave", function() GameTooltip:Hide() end)
	icon:SetWidth(64)
	icon:SetHeight(64)
	icon:SetImage(GetItemIcon(itemLink))
	frame:AddChild(icon)

	local spacer = RB.gui:Create("Label")
	spacer:SetText(" ")
	frame:AddChild(spacer)

	local rollTimeGroup = RB.gui:Create("InlineGroup")
	rollTimeGroup:SetTitle(RB.l['ROLL_TIME_LEFT'])
	rollTimeGroup:SetRelativeWidth(1.0)
	local rollTimeText = RB.gui:Create("Label")
	if startTimer and rollTime > 0 then
		rollTimeText:SetText(tostring(rollTime))
		cancelRollWindowTimer()
		RB.vars.rollWindowVars["timerCounter"] = rollTime
		RB.vars.rollWindowVars["rollTimeText"] = rollTimeText
		local function timerFunc()
			RB.vars.rollWindowVars["timerCounter"] = RB.vars.rollWindowVars["timerCounter"] - 1
			RB.vars.rollWindowVars["rollTimeText"]:SetText(tostring(RB.vars.rollWindowVars["timerCounter"]))
			if RB.vars.rollWindowVars["timerCounter"] <= 0 then
				cancelRollWindowTimer()
				if RB.db.profile.closeRollWindowAfterRollTime then
					frame:Hide()
				end
			end
		end
		RB.vars.rollWindowVars["timerId"] = RB.timers:ScheduleRepeatingTimer(timerFunc, 1)
	else
		rollTimeText:SetText("-")
	end
	rollTimeGroup:AddChild(rollTimeText)
	frame:AddChild(rollTimeGroup)

	local numButtons = 0
	for _,roll in ipairs(rolls) do
		local btn = RB.gui:Create("Button")
		btn:SetText(roll["name"])
		btn:SetCallback("OnClick", function()
			RB:doRoll(roll["roll"])
			frame:Hide()
		end)
		frame:AddChild(btn)
		numButtons = numButtons + 1
	end

	frame:SetHeight(28+64+20+40+numButtons*25+20)
end

function RB:openRollWindow(itemLink, rolls, rollTime, justStarted)
	log("OpenRollWindow", itemLink, rolls, rollTime, justStarted)
	if itemLink == nil then
		itemLink = self.vars.lastRoll.item
	end
	self.vars.lastRoll.item = itemLink
	if rolls == nil then
		rolls = self.vars.lastRoll.rolls
	end
	self.vars.lastRoll.rolls = rolls
	if rollTime == nil then
		rollTime = self.vars.lastRoll.rollTime
	end
	self.vars.lastRoll.rollTime = rollTime


	local frame = self.vars.rollWindowVars["guiFrame"]
	if frame ~= nil then
		cancelRollWindowTimer()
		frame:Hide()
		frame:ReleaseChildren()
		createRollWindowChilds(frame, itemLink, rolls, rollTime, justStarted)
		frame:Show()
		return
	end
	-- Create a container frame
	frame = self.gui:Create("Window")
	frame:SetCallback("OnClose",function(widget)
		RB.db.char.windowPositions.rollWindow = RB:getWindowPos(widget, false)
		cancelRollWindowTimer()
		widget:ReleaseChildren()
		widget:Hide()
	end)
	frame:SetTitle(self.l["ROLL_WINDOW_NAME"])
	frame:SetLayout("List")
	frame:EnableResize(false)
	frame:SetWidth(220)
	frame:SetHeight(300)
	self:restoreWindowPos(frame, self.db.char.windowPositions.rollWindow, DEFAULT_POS)
	self.vars.rollWindowVars["guiFrame"] = frame

	createRollWindowChilds(frame, itemLink, rolls, rollTime, justStarted)
end
