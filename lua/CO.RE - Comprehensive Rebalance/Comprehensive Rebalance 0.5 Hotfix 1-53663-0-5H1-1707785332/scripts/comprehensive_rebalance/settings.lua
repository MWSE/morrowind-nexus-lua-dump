local I = require("openmw.interfaces")
local settings = require("scripts.comprehensive_rebalance.lib.settings")

I.Settings.registerGroup {
    key = "SettingsGlobal" .. settings.MOD_NAME .. "misc",
	l10n = settings.MOD_NAME,
    name = "settings_modCategory5_name",
    page = settings.MOD_NAME,
    description = "settings_modCategory5_desc",
    permanentStorage = true,
    settings = {
		settings.doAddonText("noEnchantAutoRecharge",5,1,"enchant_no_recharge"),
		settings.doCheckbox("noBackwardsRunning",5,2,true),
    }
}

I.Settings.registerGroup {
    key = "SettingsGlobal" .. settings.MOD_NAME .. "saving",
	l10n = settings.MOD_NAME,
    name = "settings_modCategory6_name",
    page = settings.MOD_NAME,
    description = "settings_modCategory6_desc",
    permanentStorage = true,
    settings = {
		settings.doComingSoon("noSavingWilderness",6,1,true),
		settings.doComingSoon("noSavingInTown",6,2,true),
		settings.doComingSoon("freeSaveInterval",6,3,true),
    }
}

I.Settings.registerGroup {
    key = "SettingsGlobal" .. settings.MOD_NAME .. "rest",
	l10n = settings.MOD_NAME,
    name = "settings_modCategory1_name",
    page = settings.MOD_NAME,
    --description = "settings_modCategory1_desc",
    permanentStorage = true,
    settings = {
		settings.doCheckbox("noTresspassSleep",4,1,true),
		--settings.doCheckbox("factionBedCosts",4,2,true),
		settings.doCheckbox("noRepeatedSleeping",4,3,true),
		settings.doNumber("noRepeatedSleepingTimer",4,4,20,1,nil),
		settings.doSelection("disableRestMode",1,1,{ "disabled", "enabled", "show_time" },"enabled"),
		settings.doSelection("disableWaitMode",1,2,{ "disabled", "enabled", "show_time" },"disabled"),
    }
}

I.Settings.registerGroup {
    key = "SettingsGlobal" .. settings.MOD_NAME .. "menus",
	l10n = settings.MOD_NAME,
    name = "settings_modCategory2_name",
    page = settings.MOD_NAME,
    description = "settings_modCategory2_desc",
    permanentStorage = true,
    settings = {
		settings.doCheckbox("realtimeInterface",2,1,true),
		settings.doCheckbox("realtimeDialogue",2,2,true),
		settings.doCheckbox("realtimeContainer",2,3,true),
		settings.doCheckbox("realtimeReading",2,4,true),
		settings.doCheckbox("realtimeJournal",2,5,true),
		settings.doCheckbox("realtimeInteractions",2,6,true),
		settings.doCheckbox("realtimeQuickKeysMenu",2,7,false),
		settings.doCheckbox("realtimeMisc",2,8,false),
    }
}

I.Settings.registerGroup {
    key = "SettingsGlobal" .. settings.MOD_NAME .. "char",
	l10n = settings.MOD_NAME,
    name = "settings_modCategory3_name",
    page = settings.MOD_NAME,
    description = "settings_modCategory3_desc",
    permanentStorage = true,
    settings = {
		settings.doCheckbox("newHealthFormula",3,1,true),
		settings.doNumber("newHealthFormulaScale",3,2,3),
		settings.doComingSoon("skillDegredation",3,3,true),
		settings.doAddonText("trainersOnly",3,4,"no_skill_levelling"),
		--settings.doCheckbox("noTrainers",3,7,false),
		settings.doComingSoon("standardisedAttributes",3,5,true),
		--settings.doNumber("standardisedAttributesValue",3,6,2),
		settings.doAddonText("fatigueChanges",3,8,"fatigue_changes"),
		settings.doSelection("convenientFatigueSetting",3,9,{"disabled", "slow", "fast"}, "slow"),
		settings.doNumber("convenientFatigueDelay",3,10,4,0,nil),
	}
}

I.Settings.registerGroup {
    key = "SettingsGlobal" .. settings.MOD_NAME .. "armour",
	l10n = settings.MOD_NAME,
    name = "settings_modCategory7_name",
    page = settings.MOD_NAME,
    description = "settings_modCategory7_desc",
    permanentStorage = true,
    settings = {
		--settings.doCheckbox("mediumArmorBuff",7,6,true),
		settings.doAddonText("mediumArmorBuff",7,6,"med_armour_buff"),
		settings.doAddonText("mediumArmorBuffLeFemme",7,7,"med_armour_lefemme"),
		settings.doAddonText("mediumArmorBuffEBQ",7,8,"med_armour_EBQ"),
		settings.doSelection("bulkyShieldsMode",7,1,{"disabled","penalty","bonus","both"},"penalty"),
		settings.doCheckbox("bulkyArmour",7,2,true),
		settings.doNumber("bulkyArmourMult",7,3,3,1,5),
		settings.doCheckbox("implacableArmour",7,4,false),
	}
}

I.Settings.registerGroup {
    key = "SettingsGlobal" .. settings.MOD_NAME .. "economy",
	l10n = settings.MOD_NAME,
    name = "settings_modCategory8_name",
    page = settings.MOD_NAME,
    description = "settings_modCategory8_desc",
    permanentStorage = true,
    settings = {
		settings.doAddonText("higherTravelPrices",8,1,"higher_travel_prices"),
		--settings.doAddonText("crimeDoesntPay",8,2,"crime_doesnt_pay"),
		--settings.doAddonText("moreExpensiveEconomy",8,3,"more_expensive_economy"),
		settings.doAddonText("creatureNPCBalance",8,4,"creeper_mudcrab_balance"),
		settings.doAddonText("merchantsGoldLimit",8,5,"merchants_gold_limit"),
	}
}
