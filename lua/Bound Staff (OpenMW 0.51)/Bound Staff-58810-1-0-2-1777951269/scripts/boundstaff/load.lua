local content = require('openmw.content')

local EFFECT_ID = 'bound_staff_effect'
local SPELL_ID  = 'bound_staff_spell'

-- Register the custom magic effect.
-- Template inherits visuals/sounds from an existing bound weapon effect.
-- hasDuration=true, hasMagnitude=false: it's a timed toggle, no magnitude needed.
content.magicEffects.records[EFFECT_ID] = {
    template     = content.magicEffects.records['boundspear'],
    name         = 'Bound Staff',
    description  = 'The spell effect conjures a lesser Daedra bound in the form of a magical, wondrously powerful Daedric staff. The staff appears automatically equipped on the caster, displacing any currently equipped weapon to inventory. When the effect ends, the staff disappears, and any previously equipped weapon is automatically re-equipped.',
    school       = 'conjuration',
    baseCost     = 11,
    onSelf       = true,
    onTouch      = false,
    onTarget     = false,
    harmful      = false,
    hasDuration  = true,
    hasMagnitude = false,
    isAppliedOnce = true,
}

-- Register the spell that uses the effect.
-- isAutocalc=false so we control the cost directly.
content.spells.records[SPELL_ID] = {
    name        = 'Bound Staff',
    type        = content.spells.TYPE.Spell,
    cost        = 13,
    isAutocalc  = false,
    effects     = {
        {
            id           = EFFECT_ID,
            range        = content.RANGE.Self,
            duration     = 60,
            magnitudeMin = 0,
            magnitudeMax = 0,
        },
    },
}
