local self = require("openmw.self")
local types = require("openmw.types")
local input = require("openmw.input")
local async = require("openmw.async")
local core = require("openmw.core")
local camera = require("openmw.camera")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")
local l10n = core.l10n("AnimatedPickup")

local MD = camera.MODE
local sneaking = false
local animPickup, camMode = false, nil


I.Settings.registerPage {
   key = "animPickup",
   l10n = "AnimatedPickup",
   name = "settings_modName",
   description = "settings_modDesc"
}

I.Settings.registerGroup({
   key = "Settings_animPickup_player",
   page = "animPickup",
   l10n = "AnimatedPickup",
   name = "settings_modCategory1_name",
   permanentStorage = true,
   settings = {
	{key = "animatespd",
	default = 750,
	renderer = "number",
	name = "settings_modCategory1_setting01_name",
	argument = { min = 1, max = 2000 },
	},
	{key = "animatespdtk",
	default = 100,
	renderer = "number",
	name = "settings_modCategory1_setting02_name",
	argument = { min = 1, max = 2000 },
	},
	{key = "animate1st",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory1_setting03_name",
	},
	{key = "animate3rd",
	default = true,
	renderer = "checkbox",
	name = "settings_modCategory1_setting04_name",
	},
	{key = "nosteal",
	default = false,
	renderer = "checkbox",
	name = "settings_modCategory1_setting05_name",
	},
   },
})

local settings = storage.playerSection("Settings_animPickup_player")


local function updateSettings()
	camMode = camera.getMode()
	local anim = false
	if settings:get("animate1st") and camMode == MD.FirstPerson then anim = true end
	if settings:get("animate3rd") and ( camMode == MD.ThirdPerson or camMode == MD.Preview )
		then anim = true end
	core.sendGlobalEvent("playerState", {player=self, nosteal=settings:get("nosteal"),
		anim=anim, spd=settings:get("animatespd"), spdtk=settings:get("animatespdtk")})
end

settings:subscribe(async:callback(updateSettings))
updateSettings()


input.registerActionHandler("Sneak", async:callback(function(v)
	if self.controls.sneak ~= sneaking then
		sneaking = self.controls.sneak
		core.sendGlobalEvent("playerState", {player=self, sneak=sneaking, nosteal=settings:get("nosteal")})
	end
end))


local function onUpdate()
	if camera.getMode() ~= camMode then updateSettings() end
end


return {
	engineHandlers = { onUpdate = onUpdate },
	eventHandlers = { showUIMessage = function(data) ui.showMessage(l10n(data)) end }
}
