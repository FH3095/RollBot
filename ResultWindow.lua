
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

local function createWindowText(rolls, label, item)
	local inspectDb = nil
	local rollItemEquipLoc = nil
	if GExRT ~= nil and GExRT.A.Inspect ~= nil and GExRT.A.Inspect.db.inspectDB ~= nil then
		inspectDb = GExRT.A.Inspect.db.inspectDB
	end
	if item ~= nil then
		rollItemEquipLoc = select(9,GetItemInfo(item))
	end
	local text = ""
	for _,roll in ipairs(rolls) do
		text = text .. roll["name"] .. " : " .. roll["roll"] .. " ("
		if roll["rollType"] ~= nil then
			text = text .. roll["rollType"] .. " | "
		end
		text = text .. roll["rollMin"] .. "-" .. roll["rollMax"] .. ")"
		if RB.db.profile.showRollersCurrentItems and rollItemEquipLoc ~= nil and
			inspectDb ~= nil and inspectDb[roll["name"]] ~= nil and inspectDb[roll["name"]].items ~= nil then
			for _,curItem in pairs(inspectDb[roll["name"]].items) do
				local _,_,itemRarity,itemLevel,_,_,_,_,itemEquipLoc = GetItemInfo(curItem)
				if itemEquipLoc == rollItemEquipLoc then
					local _,_,_,itemCcolor = GetItemQualityColor(itemRarity)
					text = text .. " |c" .. itemCcolor .. "[GS:" .. itemLevel .. "]|r"
				end
			end
			-- TODO Implement show item. Befor that: Rewrite Result window so that I can display that item...
		end
		text = text .. "\n"
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
	createWindowText(self.vars.resultWindowVars["rolls"], text, self.vars.lastRollItem)
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
	createWindowText(vars["rolls"], vars["guiLabel"], self.vars.lastRollItem)
end

function RB:resultClearRolls()
	self.vars.resultWindowVars["rolls"] = {}
	createWindowText(self.vars.resultWindowVars["rolls"], self.vars.resultWindowVars["guiLabel"])
end
