local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')
local ui = require('openmw.ui')

local SPELL_ID = "aralorblessing"
local MSG = "Saint Aralor the Penitent has looked upon your suffering with mercy. As he once walked the pilgrimages in chains, so too have you paid your debt. His blessing is upon you, outlander. May it remind you that repentance is never beyond reach."

local function isEligible()
    if types.NPC.record(self).race ~= "dark elf" then return false end
    for _, factionId in pairs(types.NPC.getFactions(self)) do
        if factionId == "imperial cult" then return false end
    end
    return true
end

local function hasBlessing()
    for _, spell in ipairs(types.Actor.spells(self)) do
        if spell.id == SPELL_ID then return true end
    end
    return false
end

I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
    if source == 'jail' and isEligible() and not hasBlessing() then
        if math.random(100) == 1 then
            types.Actor.spells(self):add(SPELL_ID)
            ui.showMessage(MSG)
        end
    end
end)

return {}