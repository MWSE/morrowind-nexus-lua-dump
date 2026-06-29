
if not core.contentFiles.has("Devilish_Vampire_Overhaul.esp") and not core.contentFiles.has("Devilish_Vampire_Overhaul.omwscripts") then return end

G_eventHandlers.SunsDusk_Vampire_drankBlood = function(data)
	local stage = (data and data.stage) or 0

	if saveData.m_thirst then
		saveData.m_thirst.thirst = 0
	end
	if saveData.m_hunger then
		saveData.m_hunger.hunger = 0
		saveData.m_hunger.fastingMinutes = 0
	end

	G_refreshNeeds()
end
