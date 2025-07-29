local I = require("openmw.interfaces")

local mDef = require("scripts.fresh-loot.config.definition")
local mCfg = require("scripts.fresh-loot.config.configuration")
local mTypes = require("scripts.fresh-loot.config.types")
local mStore = require("scripts.fresh-loot.settings.store")

local settingGroups = {
    {
        section = mStore.section.global,
        settings = {
            {
                key = mStore.cfg.itemLists.key,
                renderer = mDef.renderers.multilines,
                default = "",
            },
            {
                key = mStore.cfg.enabled.key,
                renderer = "checkbox",
                default = true,
            },
            {
                key = mStore.cfg.doUnlevelledItems.key,
                renderer = "checkbox",
                default = true,
            },
            {
                key = mStore.cfg.doEquippedItems.key,
                renderer = "checkbox",
                default = true,
            },
            {
                key = mStore.cfg.doArmors.key,
                renderer = "checkbox",
                default = true,
            },
            {
                key = mStore.cfg.doClothing.key,
                renderer = "checkbox",
                default = true,
            },
            {
                key = mStore.cfg.doWeapons.key,
                renderer = "checkbox",
                default = true,
            },
            {
                key = mStore.cfg.endGameLootLevel.key,
                renderer = mDef.renderers.number,
                default = mCfg.lootLevel.endGameLootLevel,
            },
            {
                key = mStore.cfg.itemsWindowKey.key,
                renderer = mDef.renderers.hotkey,
                default = nil,
            },
            {
                key = mStore.cfg.logMode.key,
                renderer = "select",
                default = mStore.cfg.logMode.keys[mTypes.logLevels.None],
            },
        },
    },
    {
        section = mStore.section.chance,
        settings = {
            {
                key = mStore.cfg.firstModifierChance.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.first,
            },
            {
                key = mStore.cfg.secondModifierChance.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.second,
            },
            {
                key = mStore.cfg.propsModifiersChance.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.props,
            },
            {
                key = mStore.cfg.enableCrowdChanceBoost.key,
                renderer = "checkbox",
                default = true,
            },
            {
                key = mStore.cfg.equippedWeaponSecondChance.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.equippedWeaponSecondChance,
            },
            {
                key = mStore.cfg.equippedWeaponSecondChanceLootLevelRatio.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.equippedWeaponSecondChanceLootLevelRatio,
            },
            {
                key = mStore.cfg.maxLootLevelChanceBoost.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.maxLootLevelChanceBoost,
            },
            {
                key = mStore.cfg.maxLockChanceBoost.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.maxLockBoost,
            },
            {
                key = mStore.cfg.maxTrapChanceBoost.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.maxTrapBoost,
            },
            {
                key = mStore.cfg.maxWaterDepthChanceBoost.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.maxWaterDepthBoost,
            },
            {
                key = mStore.cfg.secondModifierChanceBoostReduction.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.secondModifierChanceBoostReduction,
            },
        },
    },
    {
        section = mStore.section.level,
        settings = {
            {
                key = mStore.cfg.passiveActorsLevelRatio.key,
                renderer = mDef.renderers.number,
                default = mCfg.lootLevel.passiveActorsLevelRatio,
            },
            {
                key = mStore.cfg.playerLevelScaling.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierLevel.playerLevelScaling,
            },
            {
                key = mStore.cfg.maxLockLevelBoost.key,
                renderer = mDef.renderers.number,
                default = mCfg.lootLevel.maxLockBoost,
            },
            {
                key = mStore.cfg.maxTrapLevelBoost.key,
                renderer = mDef.renderers.number,
                default = mCfg.lootLevel.maxTrapBoost,
            },
            {
                key = mStore.cfg.maxWaterDepthLevelBoost.key,
                renderer = mDef.renderers.number,
                default = mCfg.lootLevel.maxWaterDepthBoost,
            },
        },
    },
    {
        section = mStore.section.misc,
        settings = {
            {
                key = mStore.cfg.maxModsValueOverNpcWealth.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.maxModsValueOverNpcWealth,
            },
            {
                key = mStore.cfg.maxModsValueOverCreatureWealth.key,
                renderer = mDef.renderers.number,
                default = mCfg.modifierChance.maxModsValueOverCreatureWealth,
            },
            {
                key = mStore.cfg.projectileStackReduction.key,
                renderer = mDef.renderers.number,
                default = mCfg.itemConversion.projectileStackReduction,
            },
            {
                key = mStore.cfg.maxItemWindowRowsPerPage.key,
                renderer = mDef.renderers.number,
                default = mCfg.itemWindow.maxRowsPerPage,
            },
        },
    },
}

for order, group in ipairs(settingGroups) do
    group.key = group.section.key
    group.page = mDef.MOD_NAME
    group.l10n = mDef.MOD_NAME
    group.name = group.section.name .. "SectionTitle"
    group.description = mDef.getMessageKeyIfOpenMWTooOld(group.section.name .. "SectionDesc")
    group.permanentStorage = false
    group.order = order - 1
    for _, setting in ipairs(group.settings) do
        setting.name = setting.key .. "_name"
        setting.description = setting.key .. "_desc"
        setting.argument = mStore.cfg[setting.key].argument
    end
    I.Settings.registerGroup(group)
end