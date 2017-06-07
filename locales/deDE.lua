local L = LibStub("AceLocale-3.0"):NewLocale("RollBot", "deDE")
if not L then
	return
end

-- %1$s würfelt. Ergebnis: %2$d (%3$d-%4$d)
L['ROLL_REGEX'] = '^([^%s]+.*) würfelt. Ergebnis: (%d+) %((%d+)%-(%d+)%)$'
L['MASTER_LOOTER_FRAME_START_ROLL'] = 'RollBot würfeln starten'
