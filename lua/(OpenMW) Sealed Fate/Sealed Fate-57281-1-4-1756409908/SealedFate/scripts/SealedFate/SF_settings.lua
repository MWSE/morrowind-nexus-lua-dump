local I = require('openmw.interfaces')

MODNAME = "SealedFate"

local settings = {
    key = 'Settings'..MODNAME,
    page = MODNAME,
    l10n = MODNAME,
    name = MODNAME,
    description = "A permadeath mod that triggers when you quit during combat or while affected by harmful spells",
    permanentStorage = true,
    settings = {
        {
            key = "ENABLE_DELETION",
            name = "Permadeath",
            description = "Enable save file deletion on death and abandoning.\nCan not be disabled in combat",
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
				l10n = "LocalizationContext", 
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
    l10n = MODNAME,
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
		end
	else
		PERMADEATH_ENABLED = settingsSection:get("ENABLE_DELETION")
	end
	
	--if PERMADEATH_ENABLED ~= (PERMADEATH_ENABLED or settingsSection:get("ENABLE_DELETION")) then
	--	self.type.sendMenuEvent(self, 'SealedFate_setPermadeath', (PERMADEATH_ENABLED or settingsSection:get("ENABLE_DELETION")))
	--end
	
end

settingsSection:subscribe(async:callback(updateSettings))