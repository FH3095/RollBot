
local RB = RollBot
local log = FH3095Debug.log

function RB:openImportExportWindow(doExport)
	log("OpenImportExportWindow", doExport)

	local frame = self.gui:Create("Window")
	frame:SetCallback("OnClose",function(widget) RB.gui:Release(widget)	end)
	frame:SetLayout("Fill")
	frame:EnableResize(true)

	local text = self.gui:Create("MultiLineEditBox")
	text:SetLabel("")
	text:SetText("")
	frame:AddChild(text)

	if doExport then
		frame:SetTitle(self.l["EXPORT_WINDOW_NAME"])
		text:SetText(self.serializer:Serialize(self.db.profile))
		text:DisableButton(true)
	else
		frame:SetTitle(self.l["IMPORT_WINDOW_NAME"])
		text:SetCallback("OnEnterPressed", function(widget, event, text)
			local success, data = self.serializer:Deserialize(text)
			if not success then
				log("Import failed, invalid data", text)
				self:consolePrintError("Cant deserialize data")
				frame:Release()
				return
			end

			self.db:ResetProfile(false, false)
			for key,value in pairs(data) do
				self.db.profile[key] = value
			end
			frame:Release()
			ReloadUI()
		end)
	end
end
