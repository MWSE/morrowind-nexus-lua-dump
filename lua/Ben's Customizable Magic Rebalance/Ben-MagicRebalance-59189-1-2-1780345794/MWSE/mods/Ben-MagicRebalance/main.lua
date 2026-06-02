local magicEffect = require("Ben-MagicRebalance.magicEffect")
local limit = require("Ben-MagicRebalance.limit")
local spell = require("Ben-MagicRebalance.spell")
local alchemy = require("Ben-MagicRebalance.alchemy")
local npc = require("Ben-MagicRebalance.npc")
local mcm = require("Ben-MagicRebalance.mcm")
local config = require("Ben-MagicRebalance.config")
local common = require("Ben-MagicRebalance.common")
local util = require("Ben-MagicRebalance.util")
local gameConfig = config.getGameConfig()

local function onLoaded(e)

    -- guarantee execution order
    common.cacheMagicEffects()
    config.onLoaded(e)
    mcm.onLoaded(e)
    magicEffect.onLoaded(e)
    spell.onLoaded(e)
    limit.onLoaded(e)
    alchemy.onLoaded(e)
    npc.onLoaded(e)

end

local function onInitialized(e)

    if not gameConfig.shared.modEnabled then return false end

    event.register(tes3.event.load, npc.onLoad)
    event.register(tes3.event.cellActivated, npc.onCellActivated)
    event.register(tes3.event.loaded, onLoaded, { priority = -10 })
    event.register(tes3.event.uiActivated, limit.onUiActivated, { filter = "MenuSetValues", priority = -10 })
    event.register(tes3.event.uiEvent, limit.onUiEvent, { filter = tes3ui.registerID("MenuSetValues_MagLowSlider"), priority = -10 })
    event.register(tes3.event.uiEvent, limit.onUiEvent, { filter = tes3ui.registerID("MenuSetValues_MagHighSlider"), priority = -10 })
    event.register(tes3.event.uiEvent, limit.onUiEvent, { filter = tes3ui.registerID("MenuSetValues_DurationSlider"), priority = -10 })
    event.register(tes3.event.calcEnchantingSpellPointCost, spell.onCalcEnchantingSpellPointCost, { priority = -10 })
    event.register(tes3.event.spellCreated, spell.onSpellCreated, { priority = -10 })

    -- https://mwse.github.io/MWSE/apis/tes3/#tes3addmagiceffect
    -- https://mwse.github.io/MWSE/events/magicEffectsResolved/

    -- tes3.event.magicEffectsResolved = mods add new magicEffects
    -- tes3.event.loaded = mods add new spells and items

    -- EVENT ORDER:
    -- magicEffectsResolved
    -- modConfigReady
    -- initialized
    -- load
    -- cellActivated (cells around player)
    -- loaded
    -- cellActivated (new cells)

end

local function onModConfigReady(e)

    -- guarantee execution order
    common.cacheMagicEffects()
    config.onModConfigReady(e)
    mcm.onModConfigReady(e)

end

event.register(tes3.event.modConfigReady, onModConfigReady)
event.register(tes3.event.initialized, onInitialized)
