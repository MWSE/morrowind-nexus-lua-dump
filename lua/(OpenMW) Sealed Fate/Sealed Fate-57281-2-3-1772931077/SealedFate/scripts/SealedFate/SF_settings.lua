local I = require('openmw.interfaces')

MODNAME = "SealedFate"

local settings = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = "Permadeath mod.\nTracks dangerous situations and optionally deletes your save on death or abandonment.\nAlso prevents cheating the Roguelite death counter.",
    permanentStorage = true,
    settings = {
        {
            key = "ENABLE_DELETION",
            name = "Permadeath",
            description = "Delete your save on death or if you quit while in danger.\nCannot be disabled while in danger.\nStored per save file.",
            renderer = "checkbox",
            default = false,
        },
		{
			key = "SKULL_STYLE",
			name = "Skull Style",
			description = "the skull shows when your saves are in danger",
			default = "1", 
			renderer = "select",
			argument = {
				disabled = false,
				l10n = "none", 
				items = {"1", "2", "3"},
			},
		},
		{
			key = "SKULL_SIZE",
			name = "Skull Size",
			description = "",
			default = 64, 
			renderer = "number",
			argument = {
				disabled = false,
				min = 0,
			},
		},
    }
}

I.Settings.registerGroup(settings)

I.Settings.registerPage {
    key = MODNAME,
    l10n = "none",
    name = MODNAME,
    description = "Configuration for the SealedFate permadeath system"
}

local updateSettings = function (_,setting)
	if hudSkull then
		skullGraphic.props.resource = ui.texture { path = "textures/sealedFate/"..settingsSection:get("SKULL_STYLE")..".png" }
		skullGraphic.props.size = v2(settingsSection:get("SKULL_SIZE"),settingsSection:get("SKULL_SIZE"))
		hudSkull:update()
	end
	if lastDangerousState then
		if PERMADEATH_ENABLED and not settingsSection:get("ENABLE_DELETION") then
			onFrameFunctions["enforcePermadeath"] = function()
				ui.showMessage("Did you really think you could cheat death this easily?")
				settingsSection:set("ENABLE_DELETION", true)
				onFrameFunctions["enforcePermadeath"] = nil
			end
		else
			PERMADEATH_ENABLED = settingsSection:get("ENABLE_DELETION")
			if saveData and saveData.uniqueId then
				permadeathSection:set(saveData.uniqueId, PERMADEATH_ENABLED)
				if PERMADEATH_ENABLED then
					playerSection:set(saveData.uniqueId, 1000)
					self.type.sendMenuEvent(self, 'SealedFate_storeSaveDir')
					ui.showMessage("Permadeath enabled.")
				end
			end
		end
	else
		PERMADEATH_ENABLED = settingsSection:get("ENABLE_DELETION")
		if saveData and saveData.uniqueId then
			permadeathSection:set(saveData.uniqueId, PERMADEATH_ENABLED)
		end
		if PERMADEATH_ENABLED then
			ui.showMessage("Permadeath enabled.")
		end
	end
	
	
	--if PERMADEATH_ENABLED ~= (PERMADEATH_ENABLED or settingsSection:get("ENABLE_DELETION")) then
	--	self.type.sendMenuEvent(self, 'SealedFate_setPermadeath', (PERMADEATH_ENABLED or settingsSection:get("ENABLE_DELETION")))
	--end
	
end

settingsSection:subscribe(async:callback(updateSettings))