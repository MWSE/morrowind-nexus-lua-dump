local I = require("openmw.interfaces")
local core = require("openmw.core")
local world = require('openmw.world')

local MOD_NAME = "comprehensive_rebalance"
local strings = core.l10n(MOD_NAME)

local function AddonInstalled(globalName)
	local globs = world.mwscript.getGlobalVariables()
	return globs and globs[globalName]
end

local function GetAddonInstallText(globalName)
	local installed = AddonInstalled(globalName)
	if installed then
		return strings("settings_addon_installed")
	else
		return strings("settings_addon_not_installed")
	end
end

local function doCheckbox(key, category, num, defaultValue)
	return
	{
		key = key,
		name = "settings_modCategory" .. category .. "_setting" .. num .. "_name",
		renderer = "checkbox",
		default = defaultValue,
		description = "settings_modCategory" .. category .. "_setting" .. num .. "_desc",
		
	}
end

local function doNumber(key, category, num, defaultValue)
	return
	{
		key = key,
		name = "settings_modCategory" .. category .. "_setting" .. num .. "_name",
		renderer = "number",
		default = defaultValue,
		description = "settings_modCategory" .. category .. "_setting" .. num .. "_desc",
		
	}
end

local function doComingSoon(key, category, num, defaultValue)
	return
	{
		key = key,
		name = "settings_modCategory" .. category .. "_setting" .. num .. "_name",
		renderer = "checkbox",
		default = defaultValue,
		description = "settings_modCategory" .. category .. "_setting" .. num .. "_desc",
		argument = {
                trueLabel = strings("settings_coming_soon"),
                falseLabel = strings("settings_coming_soon"),
            }
	}
end

local function doAddonText(key, category, num, addonName)
	return
	{
		key = key,
		name = "settings_modCategory" .. category .. "_setting" .. num .. "_name",
		renderer = "checkbox",
		description = "settings_modCategory" .. category .. "_setting" .. num .. "_desc",
		argument = {
			trueLabel = GetAddonInstallText(addonName),
			falseLabel = GetAddonInstallText(addonName),
		}
	}
end

I.Settings.registerGroup {
    key = "SettingsGlobal" .. MOD_NAME .. "misc",
	l10n = MOD_NAME,
    name = "settings_modCategory5_name",
    page = MOD_NAME,
    description = "settings_modCategory5_desc",
    permanentStorage = true,
    settings = {
		doAddonText("noEnchantAutoRecharge",5,1,"coreNoEnchantmentAddon"),
		doCheckbox("noBackwardsRunning",5,2,true),
    }
}

I.Settings.registerGroup {
    key = "SettingsGlobal" .. MOD_NAME .. "saving",
	l10n = MOD_NAME,
    name = "settings_modCategory6_name",
    page = MOD_NAME,
    description = "settings_modCategory6_desc",
    permanentStorage = true,
    settings = {
		doComingSoon("noSavingWilderness",6,1,true),
		doComingSoon("noSavingInTown",6,2,true),
		doComingSoon("freeSaveInterval",6,3,true),
    }
}

I.Settings.registerGroup {
    key = "SettingsGlobal" .. MOD_NAME .. "rest",
	l10n = MOD_NAME,
    name = "settings_modCategory1_name",
    page = MOD_NAME,
    --description = "settings_modCategory1_desc",
    permanentStorage = true,
    settings = {
		doCheckbox("noTresspassSleep",4,1,true),
		--doCheckbox("factionBedCosts",4,2,true),
		doCheckbox("noRepeatedSleeping",4,3,true),
		doNumber("noRepeatedSleepingTimer",4,4,20),
		doCheckbox("disableRest",1,1,true),
		doCheckbox("disableWait",1,2,false),
		doCheckbox("showTimeRest",1,3,false),
		doCheckbox("showTimeWait",1,4,true),
    }
}

I.Settings.registerGroup {
    key = "SettingsGlobal" .. MOD_NAME .. "menus",
	l10n = MOD_NAME,
    name = "settings_modCategory2_name",
    page = MOD_NAME,
    description = "settings_modCategory2_desc",
    permanentStorage = true,
    settings = {
		doCheckbox("realtimeInterface",2,1,true),
		doCheckbox("realtimeDialogue",2,2,true),
		doCheckbox("realtimeContainer",2,3,true),
		doCheckbox("realtimeReading",2,4,true),
		doCheckbox("realtimeJournal",2,5,true),
		doCheckbox("realtimeInteractions",2,6,true),
		doCheckbox("realtimeQuickKeysMenu",2,7,false),
		doCheckbox("realtimeMisc",2,8,false),
    }
}

I.Settings.registerGroup {
    key = "SettingsGlobal" .. MOD_NAME .. "char",
	l10n = MOD_NAME,
    name = "settings_modCategory3_name",
    page = MOD_NAME,
    description = "settings_modCategory3_desc",
    permanentStorage = true,
    settings = {
		doComingSoon("newHealthFormula",3,1,true),
		--doNumber("newHealthFormulaScale",3,2,3),
		doComingSoon("skillDegredation",3,3,true),
		doAddonText("trainersOnly",3,4,"coreNoSkillLevellingAddon"),
		doComingSoon("standardisedAttributes",3,5,true),
		--doNumber("standardisedAttributesValue",3,6,2),
	}
}