local L = LibStub("AceLocale-3.0"):NewLocale("RollBot", "enUS", true, false)
if not L then
	return
end

-- %s rolls %d (%d-%d)
L['ROLL_REGEX'] = '^([^%s]+.*) rolls (%d+) %((%d+)%-(%d+)%)$'
L['MASTER_LOOTER_FRAME_START_ROLL'] = 'RollBot start roll'
L['RESULT_WINDOW_NAME'] = 'Results'
L['ROLL_WINDOW_NAME'] = 'Rolls'
L['EXPORT_WINDOW_NAME'] = 'Export'
L['IMPORT_WINDOW_NAME'] = 'Import'
L['ROLL_TIME_LEFT'] = "Remaining time"
L['ROLL_TIME_WINDOW_NAME'] = 'Roll-time'
