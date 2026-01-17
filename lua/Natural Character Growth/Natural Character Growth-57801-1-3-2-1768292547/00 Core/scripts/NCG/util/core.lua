local core = require('openmw.core')
local T = require('openmw.types')

local module = {}

module.GMSTs = {
    fAutoPCSpellChance = core.getGMST("fAutoPCSpellChance"),
    fEffectCostMult = core.getGMST("fEffectCostMult"),
    iAutoSpellAttSkillMin = core.getGMST("iAutoSpellAttSkillMin"),
    iAutoPCSpellMax = core.getGMST("iAutoPCSpellMax"),
    fPCbaseMagickaMult = core.getGMST("fPCbaseMagickaMult"),
}

module.isStarwindMode = function()
    return core.contentFiles.has('Starwind.omwaddon') or core.contentFiles.has('StarwindRemasteredPatch.esm')
end

module.getAttrName = function(statId)
    return core.stats.Attribute.records[statId].name
end

module.getMaxHealthModifier = function(actor)
    local healthMod = 0
    for _, spell in pairs(T.Actor.activeSpells(actor)) do
        if spell.affectsBaseValues then
            for _, effect in pairs(spell.effects) do
                if effect.id == core.magic.EFFECT_TYPE.FortifyHealth then
                    healthMod = healthMod + effect.magnitudeThisFrame
                end
            end
        end
    end
    return healthMod
end

return module