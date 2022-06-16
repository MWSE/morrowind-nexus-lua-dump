local zero = require("sb_dwemercycle.zero")
local effects = {}

---@param reference tes3reference
local function playShieldVFX(reference)
    local zeroShield = tes3.createReference { object = "sb_bike_destroyed", position = reference.position, orientation = reference.orientation }
    local ZeroVFX = tes3.applyMagicSource {
        reference         = zeroShield,
        name              = "",
        castChance        = 100,
        bypassResistances = true,
        effects           = {}
    }
    if ZeroVFX then
        ZeroVFX:playVisualEffect {
            effectIndex = 0,
            position    = zeroShield.position,
            visual      = "VFX_ShieldCast",
            scale       = 10
        }
    end
    tes3.playSound { sound = "alteration cast", reference = zeroShield }
    timer.start { duration = 2, callback = function()
        zeroShield:delete()
    end }
end

--- @param e spellResistEventData
local function spellResistCallback(e)
    if (e.target == zero.getReference()) then
        if (e.effectIndex == tes3.effect.waterWalking or
                e.effectIndex == tes3.effect.shield or e.effectIndex == tes3.effect.fireShield or e.effectIndex == tes3.effect.lightningShield or e.effectIndex == tes3.effect.frostShield or
                e.effectIndex == tes3.effect.feather or e.effectIndex == tes3.effect.levitate or e.effectIndex == tes3.effect.slowFall or
                e.effectIndex == tes3.effect.invisibility or e.effectIndex == tes3.effect.chameleon or e.effectIndex == tes3.effect.light or
                e.effectIndex == tes3.effect.silence or e.effectIndex == tes3.effect.sound or e.effectIndex == tes3.effect.dispel or e.effectIndex == tes3.effect.spellAbsorption or e.effectIndex == tes3.effect.reflect or
                e.effectIndex == tes3.effect.restoreAttribute or e.effectIndex == tes3.effect.restoreMagicka or
                e.effectIndex == tes3.effect.fortifyAttribute or e.effectIndex == tes3.effect.fortifyMagicka or e.effectIndex == tes3.effect.fortifyMaximumMagicka or e.effectIndex == tes3.effect.fortifyAttack) then
            if (e.effect.attribute == nil or (e.effect.attribute and (e.effect.attribute == tes3.attribute.strength or e.effect.attribute == tes3.attribute.speed))) then
                e.resistedPercent = 0
            else
                return false
            end
        elseif (e.effectIndex == tes3.effect.fireDamage or e.effectIndex == tes3.effect.shockDamage or e.effectIndex == tes3.effect.frostDamage or
                e.effectIndex == tes3.effect.drainAttribute or e.effectIndex == tes3.effect.drainHealth or e.effectIndex == tes3.effect.drainMagicka or
                e.effectIndex == tes3.effect.damageAttribute or e.effectIndex == tes3.effect.damageHealth or e.effectIndex == tes3.effect.damageMagicka) then
            if (e.effect.attribute == nil or (e.effect.attribute and (e.effect.attribute == tes3.attribute.strength or e.effect.attribute == tes3.attribute.speed))) then
                e.resistedPercent = 100
                --playShieldVFX(e.target)
                tes3.playSound { sound = "alteration cast", reference = zeroShield }
                tes3.cast { reference = e.target, target = e.caster, spell = e.source, instant = true }
            else
                return false
            end
        else
            return false
        end
    end
end

function effects.init()
    event.register(tes3.event.spellResist, spellResistCallback)
end

return effects