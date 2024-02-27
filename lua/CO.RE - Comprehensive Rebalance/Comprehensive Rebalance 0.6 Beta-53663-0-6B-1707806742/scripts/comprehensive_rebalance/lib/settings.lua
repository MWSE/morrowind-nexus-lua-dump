local core = require("openmw.core")
local storage = require('openmw.storage')

local settings = {}

settings.MOD_NAME = "comprehensive_rebalance"
settings.MOD_NAME_ADDON = settings.MOD_NAME .. ".omwaddon"
settings.strings = core.l10n(settings.MOD_NAME)

function settings.GetSection(name)
    return storage.globalSection("SettingsGlobal" .. settings.MOD_NAME .. name)
end

function settings.GetAddonInstallText(addon)
	local installed = core.contentFiles.has(addon..".omwaddon")
	if installed then
		return settings.strings("settings_addon_installed")
	else
		return settings.strings("settings_addon_not_installed")
	end
end

function settings.doCheckbox(key, category, num, defaultValue)
	return
	{
		key = key,
		name = "settings_modCategory" .. category .. "_setting" .. num .. "_name",
		renderer = "checkbox",
		default = defaultValue,
		description = "settings_modCategory" .. category .. "_setting" .. num .. "_desc",
		
	}
end

function settings.doNumber(key, category, num, defaultValue, vMin, vMax)
	return
	{
		key = key,
		name = "settings_modCategory" .. category .. "_setting" .. num .. "_name",
		renderer = "number",
		default = defaultValue,
		description = "settings_modCategory" .. category .. "_setting" .. num .. "_desc",
        argument = {
            min = vMin,
            max = vMax,
            integer = true,
        },
	}
end

function settings.doSelection(key, category, num, values, defaultValue)
    return
    {
		key = key,
        l10n = settings.MOD_NAME,
		name = "settings_modCategory" .. category .. "_setting" .. num .. "_name",
		renderer = "select",
		description = "settings_modCategory" .. category .. "_setting" .. num .. "_desc",
        default = defaultValue,
        argument = {
            items = values,
            l10n = settings.MOD_NAME,
        },
    }
end

function settings.doComingSoon(key, category, num, defaultValue)
	return
	{
		key = key,
		name = "settings_modCategory" .. category .. "_setting" .. num .. "_name",
		renderer = "checkbox",
		default = defaultValue,
		description = "settings_modCategory" .. category .. "_setting" .. num .. "_desc",
		argument = {
                trueLabel = settings.strings("settings_coming_soon"),
                falseLabel = settings.strings("settings_coming_soon"),
            }
	}
end

function settings.doAddonText(key, category, num, addonName)
	return
	{
		key = key,
		name = "settings_modCategory" .. category .. "_setting" .. num .. "_name",
		renderer = "checkbox",
		description = "settings_modCategory" .. category .. "_setting" .. num .. "_desc",
		argument = {
			trueLabel = settings.GetAddonInstallText(addonName),
			falseLabel = settings.GetAddonInstallText(addonName),
		}
	}
end

return settings
