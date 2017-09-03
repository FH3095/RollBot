
local RB = RollBot
local log = FH3095Debug.log

local DEFAULT_POS = {
	LEFT = {
		relativePoint = "LEFT",
		xOfs = 200,
		yOfs = 0,
	},
	WndHeight = 300,
	WndWidth = 400,
}

local function createWindowText(rolls, label)
	local text = ""
	for _,roll in ipairs(rolls) do
		text = text .. roll["name"] .. " : " .. roll["roll"] .. " ("
		if roll["rollType"] ~= nil then
			text = text .. roll["rollType"] .. " = "
		end
		text = text .. roll["rollMin"] .. "-" .. roll["rollMax"] .. ")\n"
	end
	-- If label is not initalized, no text update is needed
	if label ~= nil then
		label:SetText(text)
	end
end

function RB:openResultWindow()
	log("OpenResultWindow")
	if self.vars.resultWindowVars["guiFrame"] ~= nil then
		self.vars.resultWindowVars["guiFrame"]:Show()
		return
	end
	-- Create a container frame
	local f = self.gui:Create("Window")
	f:SetCallback("OnClose",function(widget)
		RB.db.char.windowPositions.resultWindow = RB:getWindowPos(widget, true)
		widget:Hide()
	end)
	f:SetTitle(self.l["RESULT_WINDOW_NAME"])
	f:SetLayout("Fill")
	f:EnableResize(true)
	self:restoreWindowPos(f, self.db.char.windowPositions.resultWindow, DEFAULT_POS)

	-- Create Multiline-Edit-Box for text
	local text = self.gui:Create("MultiLineEditBox")
	text:SetText("")
	text:SetLabel("")
	text:DisableButton(true)
	text:SetDisabled(true)
	-- hack to set textcolor back to 1. I want a readonly box
	text.editBox:SetTextColor(1, 1, 1)
	f:AddChild(text)
	self.vars.resultWindowVars["guiLabel"] = text
	self.vars.resultWindowVars["guiFrame"] = f
	createWindowText(self.vars.resultWindowVars["rolls"], text)
end

function RB:resultAddRoll(name, roll, rollMin, rollMax, rollType)
	log("ResultAddRoll", name, roll, rollMin, rollMax, rollType)
	local vars = self.vars.resultWindowVars
	local function sortFunc(r1,r2)
		if(r1["rollMax"]==r2["rollMax"]) then
			return r1["roll"] > r2["roll"]
		else
			return r1["rollMax"] > r2["rollMax"]
		end
	end

	tinsert(vars["rolls"], {name=name, roll=roll, rollMin=rollMin, rollMax=rollMax, rollType = rollType})
	sort(vars["rolls"], sortFunc)
	createWindowText(vars["rolls"], vars["guiLabel"])
end

function RB:resultClearRolls()
	self.vars.resultWindowVars["rolls"] = {}
	createWindowText(self.vars.resultWindowVars["rolls"], self.vars.resultWindowVars["guiLabel"])
end
