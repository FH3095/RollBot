
local RB = RollBot
local log = RollBotDebug.log

local function _old(f)
	-- Create a button
	local btn = self.gui:Create("Button")
	btn:SetWidth(170)
	btn:SetText("Button !")
	btn:SetCallback("OnClick", function() print("Click!") end)
	-- Usually dont use .frame, but I treat this as an exception
	btn:SetCallback("OnEnter", function()
		GameTooltip:SetOwner(btn.frame, "ANCHOR_BOTTOMRIGHT")
		GameTooltip:SetHyperlink("item:16846:0:0:0:0:0:0:0")
		GameTooltip:Show()
	end)
	btn:SetCallback("OnLeave", function() GameTooltip:Hide() end)
	-- Add the button to the container
	f:AddChild(btn)
	for i=1,5 do
		btn = self.gui:Create("Button")
		btn:SetWidth(150)
		btn:SetText("Button " .. i)
		f:AddChild(btn)
	end
end

function RB:openRollWindow(itemLink)
	-- TODO implement
	log("OpenRollWindow", itemLink)
end
