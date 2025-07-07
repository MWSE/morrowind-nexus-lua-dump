local I = require("openmw.interfaces")
local vfs = require('openmw.vfs')


local sounds = {}
sounds.files = require("scripts.SSQN.configSound")


local function build(m)
	local f = sounds.files		local list = {}
	for _, v in ipairs(m) do
		if f[v] then list[#list + 1] = v	end
	end
	return list
end

sounds.start = build {
	"snd_ui_obj_new_01", "snd_ui_skill_increase", "snd_ui_quest_new",
	"snd_mw_quest_1", "snd_mw_quest_2", "snd_mw_objective",
	"snd_sky_quest", "snd_ob_quest", "snd_sixth", "snd_levelup", "snd_mystic",
	"snd_racer", "snd_none",
	"snd_custom", "snd_custom_2", "snd_custom_3",
}

sounds.finish = build {
	"snd_ui_obj_new_01", "snd_ui_skill_increase", "snd_ui_quest_new",
	"snd_mw_quest_1", "snd_mw_quest_2", "snd_mw_objective",
	"snd_sky_quest", "snd_ob_quest", "snd_sixth", "snd_levelup", "snd_mystic",
	"snd_racer", "snd_none", "snd_same",
	"snd_custom", "snd_custom_2", "snd_custom_3"
}

sounds.update = build {
	"snd_ui_obj_new_01", "snd_ui_skill_increase",
	"snd_mw_objective",
	"snd_mw_quest_1",
	"snd_journal",
	"snd_book1", "snd_book2", "snd_none",
	"snd_custom", "snd_custom_2", "snd_custom_3"
}

sounds.objective = build {
	"snd_ui_obj_new_01",
	"snd_ob_quest",
	"snd_mw_objective",
	"snd_mw_quest_1",
	"snd_sixth",
	"snd_mystic",
	"snd_ui_skill_increase",
	"snd_none",
	"snd_custom", "snd_custom_2", "snd_custom_3"
}


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
         key = "showDiscover",
         default = true,
         renderer = "checkbox",
         name = "settings_modCategory1_setting01b_name",
      },
      {
         key = "discoverUpper",
         default = true,
         renderer = "checkbox",
         name = "settings_modCategory1_setting01c_name",
      },
        {
            key = "textSizeTitle",
            name = "settings_modCategory1_setting01d_name",
            default = "24",
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "SSQN",
                items = { "16", "20", "24" },
            },
	},
        {
            key = "textSize",
            name = "settings_modCategory1_setting01e_name",
            default = "16",
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "SSQN",
                items = { "16", "18" },
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
         key = "bannertransp",
         default = false,
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
            key = "anim_style",
            name = "settings_modCategory1_setting04a_name",
            default = "opt_anim_scroll", 
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "SSQN", 
                items = { "opt_anim_scroll", "opt_fadeout" },
            },
	},
        {
            key = "soundfile",
            name = "settings_modCategory1_setting06_name",
            description = "settings_modCategory1_setting06_desc",
            default = "snd_ui_quest_new",
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "SSQN", 
                items = sounds.start,
            },
	},
        {
            key = "soundfilefin",
            name = "settings_modCategory1_setting08_name",
            description = "settings_modCategory1_setting08_desc",
            default = "snd_same", 
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "SSQN", 
                items = sounds.finish,
            },
        },
        {
            key = "sound_objective",
            name = "settings_modCategory1_setting09a_name",
            description = "settings_modCategory1_setting09a_desc",
            default = "snd_ui_obj_new_01",
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "SSQN",
                items = sounds.objective,
            },
        },
        {
            key = "soundfileupdate",
            name = "settings_modCategory1_setting10_name",
            description = "settings_modCategory1_setting10_desc",
            default = "snd_journal",
            renderer = "select",
            argument = {
                disabled = false,
                l10n = "SSQN",
                items = sounds.update,
            }
        },
        {
         key = "soundcustom",
         default = "SSQN\\ob_quest.wav",
         renderer = "textLine",
         name = "settings_modCategory1_setting07_name",
         description = "settings_modCategory1_setting07_desc",
        },
        {
         key = "soundcustomfin",
         default = "SSQN\\ob_quest.wav",
         renderer = "textLine",
         name = "settings_modCategory1_setting09_name",
        },
        {
         key = "soundcustomupdate",
         default = "SSQN\\ob_quest.wav",
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
