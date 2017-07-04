local L = LibStub("AceLocale-3.0"):NewLocale("RollBot", "deDE")
if not L then
	return
end

-- %1$s würfelt. Ergebnis: %2$d (%3$d-%4$d)
L['ROLL_REGEX'] = '^([^%s]+.*) würfelt. Ergebnis: (%d+) %((%d+)%-(%d+)%)$'
L['MASTER_LOOTER_FRAME_START_ROLL'] = 'RollBot würfeln starten'
L['RESULT_WINDOW_NAME'] = 'Ergebnisse'
L['ROLL_WINDOW_NAME'] = 'Würfel'
L['EXPORT_WINDOW_NAME'] = 'Export'
L['IMPORT_WINDOW_NAME'] = 'Import'
