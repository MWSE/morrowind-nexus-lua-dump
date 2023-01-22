local common = require("mer.skoomaesthesia.common")
local logger = common.createLogger("SpellService")
local SpellService = {}
function SpellService.getSpellId(stateId)
    return string.format("mer_sk_%s", string.lower(stateId))
end

function SpellService.getSpellForState(state)
    if state.spellEffects then
        local spellId = SpellService.getSpellId(state.id)
        local spell = tes3.getObject(spellId) ---@type any
        ---@cast spell tes3spell
        if not spell then
            --spell = tes3spell.create(spellId, state.name)
            spell = tes3.createObject{
                objectType = tes3.objectType.spell,
                castType = tes3.spellType.ability,
            }
            ---@cast spell tes3spell
            spell.name = state.name
            spell.castType = tes3.spellType.ability
            for i=1, #state.spellEffects do
                local effect = spell.effects[i]
                local newEffect = state.spellEffects[i]
                effect.id = newEffect.id
                effect.attribute = newEffect.attribute
                effect.rangeType = tes3.effectRange.self
                effect.min = newEffect.min or 0
                effect.max = newEffect.max or 0
            end
        end
        logger:debug("Returning Spell: %s", spell.id)
        return spell
    else
        logger:debug("Unable to get spell")
        return nil
    end
end

return SpellService