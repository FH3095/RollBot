local L = LibStub("AceLocale-3.0"):NewLocale("RollBot", "enUS", true, false)
if not L then
	return
end

-- %s rolls %d (%d-%d)
L['ROLL_REGEX'] = '^([^%s]+.*) rolls (%d+) %((%d+)%-(%d+)%)$'
L['MASTER_LOOTER_FRAME_START_ROLL'] = 'RollBot start roll'
