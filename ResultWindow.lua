
local RB = RollBot
local log = RollBotDebug.log

local function createWindowText(rolls, label)
	local text = ""
	for _,roll in ipairs(rolls) do
		text = text .. roll["name"] .. " : " .. roll["roll"] .. " (" .. roll["rollMin"] .. "-" .. roll["rollMax"] .. ")\n"
	end
	label:SetText(text)
end

function RB:openResultWindow()
	log("OpenResultWindow")
	if self.vars.resultWindowVars["guiFrame"] ~= nil then
		self.vars.resultWindowVars["guiFrame"]:Show()
		return
	end
	-- Create a container frame
	local f = self.gui:Create("Window")
	f:SetCallback("OnClose",function(widget) RB.vars.resultWindowVars["guiFrame"]:Hide() end)
	f:SetTitle(self.l["RESULT_WINDOW_NAME"])
	f:SetLayout("Fill")
	f:EnableResize(true)
	f:SetWidth(200)
	f:SetHeight(300)
	f:SetPoint("LEFT", "UIParent", "LEFT", 200, 0)

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

function RB:resultAddRoll(name, roll, rollMin, rollMax)
	log("ResultAddRoll", name, roll, rollMin, rollMax)
	local vars = self.vars.resultWindowVars
	local function sortFunc(r1,r2)
		if(r1["rollMax"]==r2["rollMax"]) then
			return r1["roll"] > r2["roll"]
		else
			return r1["rollMax"] > r2["rollMax"]
		end
	end

	tinsert(vars["rolls"], {name=name, roll=roll, rollMin=rollMin, rollMax=rollMax})
	sort(vars["rolls"], sortFunc)
	createWindowText(vars["rolls"], vars["guiLabel"])
end

function RB:resultClearRolls()
	self.vars.resultWindowVars["rolls"] = {}
	createWindowText(self.vars.resultWindowVars["rolls"], self.vars.resultWindowVars["guiLabel"])
end
