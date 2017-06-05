
local RB = RollBot
local log = RollBotDebug.log

function RB:openResultWindow()
	-- TODO implement
	log("OpenResultWindow")
	local AceGUI = LibStub("AceGUI-3.0")
	-- Create a container frame
	local f = AceGUI:Create("Frame")
	f:SetCallback("OnClose",function(widget) AceGUI:Release(widget) end)
	f:SetTitle("AceGUI-3.0 Example")
	f:SetStatusText("Status Bar")
	f:SetLayout("Flow")
	-- Create a button
	local btn = AceGUI:Create("Button")
	btn:SetWidth(170)
	btn:SetText("Button !")
	btn:SetCallback("OnClick", function() print("Click!") end)
	-- Add the button to the container
	f:AddChild(btn)
end

function RB:resultAddRoll(name, roll, rollMin, rollMax)
	-- TODO implement
	log("ResultAddRoll", name, roll, rollMin, rollMax)
end

function RB:resultClearRolls()
-- TODO implement
end
