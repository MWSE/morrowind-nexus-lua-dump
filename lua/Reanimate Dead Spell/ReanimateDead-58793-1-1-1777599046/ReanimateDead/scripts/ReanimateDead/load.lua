local content = require('openmw.content')
local storage = require('openmw.storage')
local C = require('scripts.ReanimateDead.common')

-- LOAD context's storage binding exposes only `playerSection`
-- (read-only) — `globalSection` is not bound despite what the Lua
-- docstring claims (verified in components/lua/storage.cpp
-- `initLoadPackage`). The Spell group is therefore registered from
-- player.lua. On first launch the section is empty and we fall back
-- to the hardcoded defaults below.
local spellSettings = storage.playerSection(C.SETTINGS.SECTION_SPELL)
local DEFAULT_DURATION = 30
local DEFAULT_MAGNITUDE = 5
local DEFAULT_BASE_COST = 20
local duration = spellSettings:get('duration') or DEFAULT_DURATION
local magnitude = spellSettings:get('magnitude') or DEFAULT_MAGNITUDE
local baseCost = spellSettings:get('baseCost') or DEFAULT_BASE_COST

-- baseCost feeds the engine's magicka-cost autocalc
-- (mwmechanics/spellutil.cpp).
--
-- Lua's `template` field copies the source MagicEffect's mIcon;
-- explicitly assigning `icon` afterward overrides it
-- (magictypebindings.cpp:499-500 `if rec["icon"] != nil then
-- effect.mIcon = rec["icon"]`). Reading off the live ESM record
-- avoids hardcoding a vanilla file path that could drift.
local turnUndeadRec = content.magicEffects.records['turnundead']
local turnUndeadIcon = turnUndeadRec and turnUndeadRec.icon

content.magicEffects.records[C.EFFECT_ID] = {
    template = content.magicEffects.records['summonscamp'],
    name = 'Reanimate Dead',
    icon = turnUndeadIcon,
    school = 'conjuration',
    baseCost = baseCost,
    harmful = false,
    hasDuration = true,
    hasMagnitude = true,
    onSelf = true,
    onTouch = false,
    onTarget = false,
    allowsSpellmaking = true,
    allowsEnchanting = true,
}

content.spells.records[C.SPELL_ID] = {
    name = 'Reanimate Dead',
    type = content.spells.TYPE.Spell,
    isAutocalc = true,
    -- No `area`: corpse selection is done in Lua at a script-driven
    -- radius. Including area inflates the engine's autocalc cost
    -- (cost += 0.05 * area * baseCost).
    effects = {
        {
            id = C.EFFECT_ID,
            range = content.RANGE.Self,
            duration = duration,
            magnitudeMin = magnitude,
            magnitudeMax = magnitude,
        },
    },
}

-- Defined in Lua because OpenCS can't reference our Lua-registered
-- magic effect — CS validates the enchantment's effect field as
-- unresolved at save time, but the engine fills it from this record
-- at runtime. ConstantEffect ignores duration/charge/cost.
content.enchantments.records.rd_reanimate_dead_en = {
    type = content.enchantments.TYPE.ConstantEffect,
    autocalcFlag = false,
    charge = 0,
    cost = 0,
    effects = {
        {
            id = C.EFFECT_ID,
            range = content.RANGE.Self,
            magnitudeMin = 10,
            magnitudeMax = 10,
        },
    },
}
