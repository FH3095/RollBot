
local RB = RollBot
local log = RollBotDebug.log

function RB:openResultWindow()
	-- TODO implement
	log("OpenResultWindow")
	-- Create a container frame
	local f = self.gui:Create("Window")
	f:SetCallback("OnClose",function(widget) RB.gui:Release(widget) end)
	f:SetTitle("AceGUI-3.0 Example")
	f:SetLayout("Flow")
	f:EnableResize(false)
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

function RB:resultAddRoll(name, roll, rollMin, rollMax)
	-- TODO implement
	log("ResultAddRoll", name, roll, rollMin, rollMax)
end

function RB:resultClearRolls()
-- TODO implement
end
