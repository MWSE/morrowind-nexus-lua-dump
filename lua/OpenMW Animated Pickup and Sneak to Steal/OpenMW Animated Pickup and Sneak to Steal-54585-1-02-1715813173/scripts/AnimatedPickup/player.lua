local self = require("openmw.self")
local types = require("openmw.types")
local input = require("openmw.input")
local async = require("openmw.async")
local core = require("openmw.core")
local camera = require("openmw.camera")
local ui = require("openmw.ui")
local I = require("openmw.interfaces")
local storage = require("openmw.storage")

local MD = camera.MODE
local sneaking = false
local animPickup, camMode = false, nil


I.Settings.registerPage {
   key = "animPickup",
   l10n = "animPickup",
   name = "Animated Pickup + Sneak to Steal",
   description = "by Taitechnic\t\tv 1.02\n\n\z
Based on the MWSE mod Animated Pickup by C3pa, combined with my other mod Sneak to Steal.\n\n\z
Animates item pickup with a telekinesis style effect.\n\n\z
Block owned items from being picked up (stolen) unless you have sneak enabled."
}

I.Settings.registerGroup({
   key = "Settings_animPickup_player",
   page = "animPickup",
   l10n = "animPickup",
   name = "Player Settings",
   permanentStorage = true,
   settings = {
	{key = "animatespd",
	default = 750,
	renderer = "number",
	name = "Pickup animation speed.",
	argument = { min = 1, max = 2000 },
	},
	{key = "animate1st",
	default = true,
	renderer = "checkbox",
	name = "Animate item pickup when in 1st person.",
	},
	{key = "animate3rd",
	default = true,
	renderer = "checkbox",
	name = "Animate item pickup when in 3rd person.",
	},
	{key = "nosteal",
	default = false,
	renderer = "checkbox",
	name = "Need Sneak enabled to take any owned item using Activate key.",
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
	core.sendGlobalEvent("playerState", {player=self, nosteal=settings:get("nosteal"), anim=anim, spd=settings:get("animatespd")})
end

settings:subscribe(async:callback(updateSettings))
updateSettings()


input.registerActionHandler("Sneak", async:callback(function(v)
	if self.controls.sneak ~= sneaking then
		sneaking = not sneaking
		core.sendGlobalEvent("playerState", {player=self, sneak=sneaking, nosteal=settings:get("nosteal")})
	end
end))


local function onUpdate()
	if camera.getMode() ~= camMode then updateSettings() end
end


return {
	engineHandlers = { onUpdate = onUpdate },
	eventHandlers = { showUIMessage = function(data) ui.showMessage(data) end }
}
