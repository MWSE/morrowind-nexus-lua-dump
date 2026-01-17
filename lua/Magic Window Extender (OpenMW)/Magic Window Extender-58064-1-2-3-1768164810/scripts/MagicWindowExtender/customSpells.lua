local core = require('openmw.core')

local configPlayer = require('scripts.MagicWindowExtender.config.player')
local API = require('openmw.interfaces').MagicWindow

local Spells = API.Spells
local C = API.Constants

local flatIcons = configPlayer.modIntegration.s_CustomSpellIconStyle == 'CustomSpellIconStyle_Flat'
local iconPrefix = flatIcons and 'flat_' or 'tex_'

-- Effect definitions are based on openmw.core.MagicEffect structure (relevant fields only)
-- These are:
-- id (string)
-- icon (string, path in vfs)
-- name (string, localized name)
-- school (string, skill ID)
-- hasDuration (bool)
-- hasMagnitude (bool)
-- isAppliedOnce (bool)
-- And MWE specific:
-- magnitudeType (API.Constants.Magic.MagnitudeDisplayType)
Spells.registerEffect{
    id = "TD_Passwall",
    icon = "icons/td/s/" .. (flatIcons and "td_s_passwall.dds" or "b_td_s_passwall.dds"),
    name = "Passwall", -- TODO: Localize
    school = "mysticism",
    hasDuration = false,
    hasMagnitude = false,
    isAppliedOnce = true,
    magnitudeType = C.Magic.MagnitudeDisplayType.FEET,
}

-- Now define effect overrides for the spell
Spells.registerSpell{
    id = "T_Com_Mys_UNI_Passwall",
    effects = {
        {
            -- Based on core.MagicEffectWithParams structure
            id = "TD_Passwall",
            effect = Spells.getCustomEffect("TD_Passwall"),
            magnitudeMin = 0,
            magnitudeMax = 0,
            area = 25,
            duration = 0,
            range = core.magic.RANGE.Touch,
        }
    },
}

local function weatherTemplate(id, name)
    Spells.registerEffect{
        id = id,
        icon = "icons/MagicWindowExtender/customSpells/" .. iconPrefix .. id .. ".dds",
        name = name,
        school = "alteration",
        hasDuration = false,
        hasMagnitude = false,
        isAppliedOnce = true,
        magnitudeType = C.Magic.MagnitudeDisplayType.NONE,
    }

    Spells.registerSpell{
        id = id .. "_spell",
        effects = {
            {
                id = id,
                effect = Spells.getCustomEffect(id),
                magnitudeMin = 0,
                magnitudeMax = 0,
                area = 0,
                duration = 0,
                range = core.magic.RANGE.Self,
            }
        },
    }
end
weatherTemplate("detd_ashstorm", "Call Ash Weather")
weatherTemplate("detd_blight", "Call Blight Weather")
weatherTemplate("detd_blizzard", "Call Blizzard Weather")
weatherTemplate("detd_clear", "Call Clear Weather")
weatherTemplate("detd_cloudy", "Call Cloudy Weather")
weatherTemplate("detd_foggy", "Call Foggy Weather")
weatherTemplate("detd_overcast", "Call Overcast Weather")
weatherTemplate("detd_rain", "Call Rainy Weather")
weatherTemplate("detd_snow", "Call Snowy Weather")
weatherTemplate("detd_thunder", "Call Storm Weather")

Spells.registerEffect{
    id = "zhac_portal",
    icon = "icons/MagicWindowExtender/customSpells/" .. iconPrefix .. "zhac_portal.dds",
    name = "Portal",
    school = "mysticism",
    hasDuration = false,
    hasMagnitude = false,
    isAppliedOnce = true,
    magnitudeType = C.Magic.MagnitudeDisplayType.NONE,
}

Spells.registerSpell{
    id = "zhac_portal_alpha",
    effects = {
        {
            id = "zhac_portal",
            effect = Spells.getCustomEffect("zhac_portal"),
            magnitudeMin = 0,
            magnitudeMax = 0,
            area = 0,
            duration = 0,
            range = core.magic.RANGE.Self,
        }
    },
}

local sleepSchool = core.magic.effects.records['commandhumanoid'].school
local sleepIcon = sleepSchool == 'illusion' and 'detd_sleep_ill.dds' or 'detd_sleep.dds'
Spells.registerEffect{
    id = "detd_sleep",
    icon = "icons/MagicWindowExtender/customSpells/" .. iconPrefix .. sleepIcon,
    name = "Sleep",
    school = sleepSchool,
    hasDuration = true,
    hasMagnitude = false,
    isAppliedOnce = false,
    magnitudeType = C.Magic.MagnitudeDisplayType.SECONDS,
}

Spells.registerSpell{
    id = "detd_sleep_spell",
    effects = {
        {
            id = "detd_sleep",
            effect = Spells.getCustomEffect("detd_sleep"),
            magnitudeMin = 0,
            magnitudeMax = 0,
            area = 2,
            duration = 60,
            range = core.magic.RANGE.Target,
        }
    },
}

Spells.registerSpell{
    id = "detd_sleepspellenchat",
    effects = {
        {
            id = "detd_sleep",
            effect = Spells.getCustomEffect("detd_sleep"),
            magnitudeMin = 0,
            magnitudeMax = 0,
            area = 2,
            duration = 60,
            range = core.magic.RANGE.Target,
        }
    },
}

Spells.registerEffect{
    id = "detd_shrink",
    icon = "icons/MagicWindowExtender/customSpells/" .. iconPrefix .. "detd_shrink.dds",
    name = "Shrink",
    school = "alteration",
    hasDuration = false,
    hasMagnitude = false,
    isAppliedOnce = true,
    magnitudeType = C.Magic.MagnitudeDisplayType.NONE,
}

Spells.registerSpell{
    id = "detd_shrink_spell_init",
    effects = {
        {
            id = "detd_shrink",
            effect = Spells.getCustomEffect("detd_shrink"),
            magnitudeMin = 0,
            magnitudeMax = 0,
            area = 0,
            duration = 0,
            range = core.magic.RANGE.Self,
        }
    },
}