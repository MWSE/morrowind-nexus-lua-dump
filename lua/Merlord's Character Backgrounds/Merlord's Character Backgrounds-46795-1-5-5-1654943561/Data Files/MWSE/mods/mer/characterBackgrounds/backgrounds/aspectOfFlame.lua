local config = require('mer.characterBackgrounds.config')

local getData = function()
    local data = tes3.player.data.merBackgrounds
    return data
end

local fireEffects = {
    [tes3.effect.fireShield] = true,
    [tes3.effect.fireDamage] = true,
    [tes3.effect.weaknesstoFire] = true,
    [tes3.effect.resistFire] = true,
}
local frostEffects = {
    [tes3.effect.frostShield] = true,
    [tes3.effect.frostDamage] = true,
    [tes3.effect.weaknesstoFrost] = true,
    [tes3.effect.resistFrost] = true,
}

local function spellIsFire(spell)
    for i=1, #spell.effects do
        local effect = spell.effects[i]
        if not fireEffects[effect.id] then
            return false
        end
    end
    return true
end

local function spellIsFrost(spell)
    for i=1, #spell.effects do
        local effect = spell.effects[i]
        if not frostEffects[effect.id] then
            return false
        end
    end
    return true
end


return {
    id = "aspectOfFlame",
    name = "Aspect of Flame",
    description = (
        "You have a natural affinity for fire. Perhaps are descended from a Fire Elemental, " ..
        "but it's best not to think about how that might have happened. Regardless, as a result, not only " ..
        "are you immune to fire, but you are also able to cast fire spells much more easily. However, you are " ..
        "vulnerable to frost and have difficulty casting frost spells."
    ),
    doOnce = function()
        local immuneToFireSpell = tes3spell.create(
            "charBG_aspectOfFlame_immunity",
            "Aspect of Flame"
        )
        immuneToFireSpell.castType = tes3.spellType.ability
        immuneToFireSpell.effects[1] = {
            id = tes3.effect.resistFire,
            rangeType = tes3.effectRange.self,
            min = 100,
            max = 100,
        }
        mwscript.addSpell{ reference = tes3.player, spell = immuneToFireSpell }
    end,
    callback = function()
        local function spellCast(e)
            local data = getData()
            if data.currentBackground == "aspectOfFlame" then
                if e.caster == tes3.player then
                    if e.source and spellIsFire(e.source) then
                        local newCastChance = math.min(100, e.castChance * 2)
                        mwse.log("Aspect of Fire casting fire spell, changing cast chance from %s to %s",
                            e.castChance, newCastChance)
                        e.castChance = newCastChance
                    end
                end
            end
        end

        event.unregister("spellCast", spellCast)
        event.register("spellCast", spellCast)
    end
}