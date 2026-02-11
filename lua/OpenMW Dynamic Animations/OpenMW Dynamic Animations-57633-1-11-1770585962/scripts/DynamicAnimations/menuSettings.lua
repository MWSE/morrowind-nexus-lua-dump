local I = require("openmw.interfaces")
--	local aux_util = require("openmw_aux.util")

I.Settings.registerPage {
   key = "ODAR_main",
   l10n = "DynamicAnimations",
   name = "settings_modName",
   description = "settings_modDesc",
}

local animGroups = require("scripts.DynamicAnimations.animations.config")

local function getGroups(baseAnims)
	local list = { "opt_default" }
	local names = {}
	for _, kf in ipairs(baseAnims) do
		for k, v in pairs(animGroups[kf]) do
			if v.playable and v.name and not names[v.name] then
				list[#list + 1] = v.name
				names[v.name] = true
			end
		end
	end
	return list
end

--[[
print(aux_util.deepToString(getGroups{"xbase_anim"}))
print(aux_util.deepToString(getGroups{"xbase_anim", "xbase_anim_female",
	"xbase_animkna", "xargonian_swimkna"}))
--]]

I.Settings.registerGroup {
   key = "Settings_ODAR_cat01",
   page = "ODAR_main",
   l10n = "DynamicAnimations",
   name = "settings_player_name",
   permanentStorage = true,
   settings = {
      {
         key = "p_odarEnabled",
         name = "settings_player_01_name",
         default = true,
         renderer = "checkbox",
      },
      {
          key = "walkMale",
          name = "settings_player_02_name",
          default = "opt_default",
          renderer = "select",
          argument = {
             disabled = false,
             l10n = "DynamicAnimations", 
             items = getGroups {"xbase_anim", "xbase_anim_female", "xbase_animkna", "xargonian_swimkna"},
          },
      },
      {
         key = "p_odarEnabled_1st",
         name = "settings_player_03_name",
         default = true,
         renderer = "checkbox",
      },
      {
         key = "p_useLowerSneak",
         name = "settings_player_04_name",
         default = true,
         renderer = "checkbox",
      },
      {
         key = "p_maxWalkSpeed",
         name = "settings_player_05_name",
         description = "settings_player_05_desc",
         default = 170,
         renderer = "number",
         argument = { min = 1, max = 10000 },
      },
   },
}


return
