
local RB = RollBot
local log = RollBotDebug.log

local function createRollWindowChilds(frame, itemLink)
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

	local numButtons = 0
	for _,roll in ipairs(RB.vars.rolls) do
		local btn = RB.gui:Create("Button")
		btn:SetText(roll["name"])
		btn:SetCallback("OnClick", function()
			RB:doRoll(roll["roll"])
			frame:Hide()
		end)
		frame:AddChild(btn)
		numButtons = numButtons + 1
	end
	
	frame:SetHeight(28+64+10+numButtons*25+20)
end

function RB:openRollWindow(itemLink)
	-- TODO implement
	log("OpenRollWindow", itemLink)
	if itemLink == nil or nil == GetItemInfo(itemLink) then
		itemLink = self.vars.rollWindowVars["lastItem"]
	end
	self.vars.rollWindowVars["lastItem"] = itemLink

	local frame = self.vars.rollWindowVars["guiFrame"]
	if frame ~= nil then
		frame:Hide()
		frame:ReleaseChildren()
		createRollWindowChilds(frame, itemLink)
		frame:Show()
		return
	end
	-- Create a container frame
	frame = self.gui:Create("Window")
	frame:SetCallback("OnClose",function(widget) widget:ReleaseChildren() widget:Hide() end)
	frame:SetTitle(self.l["ROLL_WINDOW_NAME"])
	frame:SetLayout("List")
	frame:EnableResize(false)
	frame:SetPoint("TOP", "UIParent", "TOP", 0, -200)
	frame:SetWidth(220)
	frame:SetHeight(300)
	self.vars.rollWindowVars["guiFrame"] = frame

	createRollWindowChilds(frame, itemLink)
end
