local vfs = require('openmw.vfs')

local sounds = {
	snd_sky_quest = "SSQN\\quest_update.wav",
	snd_sixth = "Fx\\envrn\\bell2.wav",
	snd_levelup = "Fx\\inter\\levelUP.wav",
	snd_mystic = "Fx\\magic\\mystA.wav",
	snd_ob_quest = "SSQN\\ob_quest.wav",
	snd_racer = "Cr\\cliffr\\scrm.wav",
	snd_book1 = "Fx\\BOOKPAG1.wav",
	snd_book2 = "Fx\\BOOKPAG2.wav",
	snd_journal = "SSQN\\journal_update.wav",
	snd_ui_quest_new = "Fx\\ui\\ui_quest_new.wav",
	snd_ui_obj_new_01 = "Fx\\ui\\ui_objective_new_01.wav",
	snd_ui_skill_increase = "Fx\\ui\\ui_skill_increase.wav",
	snd_ui_levelup = "Fx\\ui\\ui_levelup.wav",
	snd_none = "", snd_custom = "custom", snd_same = "same",

	["Skyrim Quest"] = "SSQN\\quest_update.wav",
	["6th House Chime"] = "Fx\\envrn\\bell2.wav",
	["Skill Raise"] = "Fx\\inter\\levelUP.wav",
	["Magic Effect"] = "Fx\\magic\\mystA.wav",
	["Oblivion Quest"] = "SSQN\\ob_quest.wav",
	["Cliff Racer"] = "Cr\\cliffr\\scrm.wav",
	["Journal Update"] = "SSQN\\journal_update.wav",
}

local default = {
	snd_ui_quest_new = "SSQN\\quest_update.wav",
	snd_ui_obj_new_01 = "SSQN\\ob_quest.wav",
	snd_ui_skill_increase = "Fx\\inter\\levelUP.wav",
	snd_ui_levelup = "Fx\\inter\\levelUP.wav",
}

for k, v in pairs(sounds) do
	if v ~= "" and v ~= "custom" and v ~= "same" then
		local path = "Sound\\" .. v
		if not vfs.fileExists(path) then
			if default[k] then
				print("Using default sound file for "..k)
				sounds[k] = default[k]
			else
				print("Missing sound " .. path)		sounds[k] = nil
			end
		end
	end
end

return sounds
