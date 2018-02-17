
local RB = RollBot
local log = FH3095Debug.log

local DEFAULT_POS = {
	LEFT = {
		relativePoint = "TOP",
		xOfs = 0,
		yOfs = -100,
	},
	WndHeight = 100,
	WndWidth = 150,
}

local function cancelTimer()
	local vars = RB.vars.rollTimeWindowVars
	if vars.timerId ~= nil then
		log("RollTimeWindow: Cancel Timer")
		RB.timers:CancelTimer(vars.timerId)
		vars.timerId = nil
		vars.rollTimeText = nil
		vars.rollTimeWindow:ReleaseChildren()
		vars.rollTimeWindow:Hide()
		vars.rollTimeWindow = nil
	end
end

local function timerFunc()
	local vars = RB.vars.rollTimeWindowVars
	vars.timerCounter = vars.timerCounter - 1
	vars.timerLabel:SetText(tostring(vars.timerCounter))
	if vars.timerCounter <= 0 then
		if RB:isMyselfMasterLooter() then
			RB:sendChatMessage(RB.db.profile.rollFinishChatMsg)
		end
		cancelTimer()
	end
end

local function createCounterText(frame)
	local vars = RB.vars.rollTimeWindowVars

	local text = RB.gui:Create("Label")
	text:SetText(RB.vars.lastRoll.rollTime)
	text:SetFontObject(GameFontNormalLarge)
	frame:AddChild(text)

	vars.timerCounter = RB.vars.lastRoll.rollTime
	vars.timerLabel = text
	vars.rollTimeWindow = frame

	vars.timerId = RB.timers:ScheduleRepeatingTimer(timerFunc, 1)
end

function RB:openRollTimerWindowAndStart()
	if self.vars.lastRoll.rollTime <= 0 then
		return
	end
	log("StartRollTimer")
	cancelTimer()
	-- Create a container frame
	local f = self.vars.rollTimeWindowVars.guiFrame
	if f ~= nil then
		f:Show()
	else
		f = self.gui:Create("Window")
		f:SetCallback("OnClose",function(widget)
			RB.db.char.windowPositions.rollTimeWindow = RB:getWindowPos(widget, true)
			cancelTimer()
			widget:ReleaseChildren()
			widget:Hide()
		end)
		f:SetTitle(self.l["ROLL_TIME_WINDOW_NAME"])
		f:SetLayout("Fill")
		f:EnableResize(false)
		self:restoreWindowPos(f, self.db.char.windowPositions.rollTimeWindow, DEFAULT_POS)
		self.vars.rollTimeWindowVars.guiFrame = f
	end

	createCounterText(f)
end
