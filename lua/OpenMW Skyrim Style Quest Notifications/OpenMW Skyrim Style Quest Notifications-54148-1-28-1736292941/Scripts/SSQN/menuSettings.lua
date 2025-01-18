local I = require("openmw.interfaces")
local vfs = require('openmw.vfs')


local sounds = {}
sounds.files = {
	["Skyrim Quest"] = "SSQN\\quest_update.wav",
	["6th House Chime"] = "Fx\\envrn\\bell2.wav",
	["Skill Raise"] = "Fx\\inter\\levelUP.wav",
	["Magic Effect"] = "Fx\\magic\\mystA.wav",
	["Oblivion Quest"] = "SSQN\\ob_quest.wav",
	["Cliff Racer"] = "Cr\\cliffr\\scrm.wav",
	["Book Page 1"] = "Fx\\BOOKPAG1.wav",
	["Book Page 2"] = "Fx\\BOOKPAG2.wav",
	["Journal Update"] = "SSQN\\journal_update.wav",
	["SkyUI New Quest"] = "Fx\\ui\\ui_quest_new.wav",
	["SkyUI Objective 1"] = "Fx\\ui\\ui_objective_new_01.wav",
	["SkyUI Skill Increase"] = "Fx\\ui\\ui_skill_increase.wav",
	["None"] = nil, ["Custom"] = "custom", ["Same as Start"] = "same"
	}

for k, v in pairs(sounds.files) do
	local path = "Sound\\" .. v
	if not vfs.fileExists(path) and v ~= "custom" and v ~= "same" then
		print("Not found " .. path)	sounds.files[k] = nil
	end
end

local function verify(m)
	local f = sounds.files		local list = {}
	for _, v in ipairs(m) do
		if f[v] then list[#list + 1] = v	end
	end
	return list
end

sounds.start = verify({ "Skyrim Quest", "SkyUI New Quest", "SkyUI Objective 1", "SkyUI Skill Increase", "6th House Chime", "Skill Raise",
	"Magic Effect", "Oblivion Quest", "Cliff Racer", "None", "Custom" })

sounds.finish = verify({ "Skyrim Quest", "SkyUI New Quest", "SkyUI Objective 1", "SkyUI Skill Increase", "6th House Chime", "Skill Raise",
	"Magic Effect",	"Oblivion Quest", "Cliff Racer", "None", "Custom", "Same as Start" })

sounds.update = verify({ "Journal Update", "SkyUI Objective 1", "SkyUI Skill Increase", "Book Page 1", "Book Page 2", "None", "Custom" })


I.Settings.registerPage {
   key = "openmw_SSQN",
   l10n = "SSQN",
   name = "settings_modName",
   description = "settings_modDesc"
}

I.Settings.registerGroup({
   key = "Settings_openmw_SSQN",
   page = "openmw_SSQN",
   l10n = "SSQN",
   name = "settings_modCategory1_name",
   permanentStorage = true,
   settings = {
      {
         key = "enabled",
         default = true,
         renderer = "checkbox",
         name = "settings_modCategory1_setting01_name",
      },
      {
         key = "showicon",
         default = true,
         renderer = "checkbox",
         name = "settings_modCategory1_setting01a_name",
      },
      {
         key = "bannertransp",
         default = true,
         renderer = "checkbox",
         name = "settings_modCategory1_setting02_name",
      },
	{
         key = "bannerposx",
         default = 0.5,
         renderer = "number",
         name = "settings_modCategory1_setting03_name",
	description = "settings_modCategory1_setting03_desc",
         argument = {
            min = 0.0, max = 1.0,
         },
	},
	{
         key = "bannerposy",
         default = 0.15,
         renderer = "number",
	name = "",
         description = "settings_modCategory1_setting04_desc",
         argument = {
            min = 0.0, max = 1.0,
         },
	},
	{
         key = "bannertime",
         default = 5,
         renderer = "number",
         name = "settings_modCategory1_setting05_name",
         argument = {
            min = 2.0,
         },
	},
        {
            key = "soundfile",
            name = "settings_modCategory1_setting06_name",
            description = "settings_modCategory1_setting06_desc",
            default = "Skyrim Quest", 
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "LocalizationContext", 
                items = sounds.start,
            },
	},
      {
         key = "soundcustom",
         default = "SSQN\\quest_update.wav",
         renderer = "textLine",
         name = "settings_modCategory1_setting07_name",
         description = "settings_modCategory1_setting07_desc",
      },
        {
            key = "soundfilefin",
            name = "settings_modCategory1_setting08_name",
            description = "settings_modCategory1_setting08_desc",
            default = "Same as Start", 
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "LocalizationContext", 
                items = sounds.finish,
            },
	},
      {
         key = "soundcustomfin",
         default = "SSQN\\quest_update.wav",
         renderer = "textLine",
         name = "settings_modCategory1_setting09_name",
      },
        {
            key = "soundfileupdate",
            name = "settings_modCategory1_setting10_name",
            description = "settings_modCategory1_setting10_desc",
            default = "Journal Update",
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "LocalizationContext", 
                items = sounds.update,
            },
	},
      {
         key = "soundcustomupdate",
         default = "SSQN\\quest_update.wav",
         renderer = "textLine",
         name = "settings_modCategory1_setting11_name",
      },
      {
         key = "bannerdemo",
         default = false,
         renderer = "checkbox",
         name = "settings_modCategory1_setting12_name",
      },
   },
})

return
