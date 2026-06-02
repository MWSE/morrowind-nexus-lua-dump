-- ============================================================
-- Spells of Morrowind: Haggle-light and Travel Illumination — LOAD Script
-- 
-- UPDATES:
-- - Added Detach Light spell and effect definitions
-- ============================================================

local content = require('openmw.content')
local storage = require('openmw.storage')

local function debugLog(msg)
    local section = storage.playerSection('Settings_ArcaneIllumination_Debug')
    if section and section:get('debugMode') then
        print("[Haggle-Light] " .. tostring(msg))
    end
end

debugLog("LOAD script starting...")

-- ============================================================
-- MAGIC EFFECT DEFINITIONS
-- ============================================================

content.magicEffects.records.animate_lantern_mgef = {
    template     = content.magicEffects.records['open'],
    name         = 'Conjure Lantern',
    school       = 'conjuration',
    icon         = 'icons/s/conjurelantern.tga',
    description  = 'Conjures a floating travelling lantern for set time.',
    onSelf       = true,
    onTarget     = false,
    onTouch      = false,
    hasDuration  = true,
    hasMagnitude = false,
}

content.magicEffects.records.attach_lantern_mgef = {
    template     = content.magicEffects.records['open'],
    name         = 'Attach Light',
    school       = 'alteration',
    icon         = 'icons/s/attachlight.tga',
    description  = 'Attaches a light source from your inventory that travels besides you until it burns out. Duration is dynamically set based on the consumed item\'s condition.',
    onSelf       = true,
    onTarget     = false,
    onTouch      = false,
    hasDuration  = true,
    hasMagnitude = false,
}

content.magicEffects.records.light_wisp_mgef = {
    template     = content.magicEffects.records['open'],
    name         = 'Light Wisp',
    school       = 'illusion',
    icon         = 'icons/s/lightwisp.tga',
    description  = 'Summons a light emitting wisp that follows you for set time.',
    onSelf       = true,
    onTarget     = false,
    onTouch      = false,
    hasDuration  = true,
    hasMagnitude = false,
}

content.magicEffects.records.haggle_light_mgef = {
    template     = content.magicEffects.records['open'],
    name         = 'Haggle-light',
    school       = 'illusion',
    icon         = 'icons/s/hagglelight.tga',
    description  = 'Conjures an arcane haggler soul, can act as light source before haggling. Place items inside, then activate it again to sell them for up to your mercantile level equal to % of their value.',
    onSelf       = true,
    onTarget     = false,
    onTouch      = false,
    hasDuration  = true,
    hasMagnitude = true,
}

-- NEW: Detach Light effect
-- Instantly removes all active conjured lights
content.magicEffects.records.detach_light_mgef = {
    template     = content.magicEffects.records['open'],
    name         = 'Detach Light',
    school       = 'conjuration',
    icon         = 'icons/s/detachlight.tga',  -- You may need to create this icon
    description  = 'Instantly detaches and dismisses all conjured or attached lights.',
    onSelf       = true,
    onTarget     = false,
    onTouch      = false,
    hasDuration  = false,
    hasMagnitude = false,
}

-- ============================================================
-- LAUNCH EFFECTS (projectile VFX for spells)
-- ============================================================

content.magicEffects.records.ai_animate_launch = {
    template = content.magicEffects.records['open'],
    name     = 'Animate Lantern Launch',
    school   = 'conjuration',
    allowsSpellmaking = false,
    allowsEnchanting = false,
}

content.magicEffects.records.ai_attach_launch = {
    template = content.magicEffects.records['open'],
    name     = 'Attach Lantern Launch',
    school   = 'alteration',
    allowsSpellmaking = false,
    allowsEnchanting = false,
}

content.magicEffects.records.ai_wisp_launch = {
    template = content.magicEffects.records['charm'],
    name     = 'Light Wisp Launch',
    school   = 'illusion',
    bolt     = 'VFX_IllusionBolt',
    allowsSpellmaking = false,
    allowsEnchanting = false,
}

-- No launch effect needed for Detach Light (instant cast)

-- ============================================================
-- SPELL RECORDS
-- ============================================================

content.spells.records.animate_lantern_spell = {
    name       = 'Conjure Lantern',
    type       = content.spells.TYPE.Spell,
    cost       = 20,
    school     = 'conjuration',
    isAutocalc = false,
    hasMagnitude = false,
    effects    = {
        {
            id           = 'animate_lantern_mgef',
            range        = content.RANGE.Self,
            duration     = 300,
        },
    },
}

content.spells.records.attach_lantern_spell = {
    name       = 'Attach Light',
    type       = content.spells.TYPE.Spell,
    cost       = 10,
    school     = 'alteration',
    isAutocalc = false,
    hasMagnitude = false,
    effects    = {
        {
            id           = 'attach_lantern_mgef',
            range        = content.RANGE.Self,
            duration     = 300,
        },
    },
}

content.spells.records.light_wisp_spell = {
    name       = 'Light Wisp',
    type       = content.spells.TYPE.Spell,
    cost       = 20,
    school     = 'illusion',
    isAutocalc = false,
    hasMagnitude = false,
    effects    = {
        {
            id           = 'light_wisp_mgef',
            range        = content.RANGE.Self,
            duration     = 300,
        },
    },
}

content.spells.records.haggle_light_spell = {
    name       = 'Haggle-light',
    type       = content.spells.TYPE.Spell,
    cost       = 30,
    school     = 'illusion',
    isAutocalc = false,
    effects    = {
        {
            id           = 'haggle_light_mgef',
            range        = content.RANGE.Self,
            duration     = 120,
            magnitudeMin = 1,
            magnitudeMax = 100,
        },
    },
}

-- NEW: Detach Light spell
-- Free spell (0 cost) that instantly removes all conjured lights
content.spells.records.detach_light_spell = {
    name       = 'Detach Light',
    type       = content.spells.TYPE.Spell,
    cost       = 0,  -- Free to cast
    school     = 'conjuration',
    isAutocalc = false,
    hasMagnitude = false,
    effects    = {
        {
            id           = 'detach_light_mgef',
            range        = content.RANGE.Self,
            duration     = 0,
            magnitude    = 0,
        },
    },
}

debugLog("All spells and effects registered successfully")