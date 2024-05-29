require("diject.just_an_incarnate.libs.types")
local log = include("diject.just_an_incarnate.utils.log")

local this = {}

---@param from tes3reference
---@param to tes3reference
function this.transferStats(from, to)
    tes3.setStatistic{reference = to, name = "health", current = from.mobile.health.base, base = from.mobile.health.base}
    tes3.setStatistic{reference = to, name = "fatigue", current = from.mobile.fatigue.base, base = from.mobile.fatigue.base}
    tes3.setStatistic{reference = to, name = "magicka", current = from.mobile.magicka.base, base = from.mobile.magicka.base}

    local spellsToRemove = {}
    for _, spell in pairs(to.object.spells) do
        if spell.castType == tes3.spellType.spell then
            table.insert(spellsToRemove, spell)
        end
    end
    for _, spell in pairs(spellsToRemove) do
        tes3.removeSpell{reference = to, spell = spell, updateGUI = true}
    end
    for _, spell in pairs(from.object.spells) do
        if spell.castType == tes3.spellType.spell then
            tes3.addSpell{reference = to, spell = spell, updateGUI = true}
        end
    end
    for i, attr in pairs(from.mobile.attributes) do
        to.mobile.attributes[i].base = attr.base
        to.mobile.attributes[i].current = attr.current
    end
    if to.baseObject.objectType == tes3.objectType.npc then
        for i, skill in pairs(from.mobile.skills) do
            to.mobile.skills[i].base = skill.base
            to.mobile.skills[i].current = skill.current
        end
    end
end

return this