local common = require("mer.darkShard.common")
local logger = common.createLogger("LunarDecay")
local SpellMaker = require("mer.darkShard.components.SpellMaker")
local ShardCell = require("mer.darkShard.components.ShardCell")


---@class DarkShard.LunarDecay
local LunarDecay = {
    spell = {
        id = "afq_lunar_decay",
        name = "Lunar Decay",
        castType = tes3.spellType.curse,
        effects = {
            {
                id = tes3.effect.drainAttribute,
                attribute = tes3.attribute.agility,
                rangeType = tes3.effectRange.self,
                min = 20,
                max = 20
            },
            {
                id = tes3.effect.drainAttribute,
                attribute = tes3.attribute.endurance,
                rangeType = tes3.effectRange.self,
                min = 20,
                max = 20
            },
        }
    },
    antidoteId = "afq_void_essence",
}


function LunarDecay.getSpell()
    return SpellMaker.createSpell(LunarDecay.spell)
end

function LunarDecay.hasAntidote()
    return tes3.isAffectedBy{
        reference = tes3.player,
        object = LunarDecay.antidoteId
    }
end

function LunarDecay.isAntidote(obj)
    return obj.id:lower() == LunarDecay.antidoteId
end

function LunarDecay.getAntidode()
    return tes3.getObject(LunarDecay.antidoteId)
end

function LunarDecay.isActive()
    return ShardCell.isOnShard() and not LunarDecay.hasAntidote()
end


function LunarDecay.update()
    local decaySpell = LunarDecay.getSpell()
    local decayActive = LunarDecay.isActive()
    local hasAntidote = tes3.isAffectedBy{ reference = tes3.player, object = LunarDecay.getAntidode()}
    if decayActive and not hasAntidote then
        logger:debug("Adding spell %s", decaySpell.id)
        tes3.addSpell{ reference = tes3.player, spell = LunarDecay.getSpell() }
    end
    if hasAntidote and not decayActive then
        logger:debug("Removing spell %s", decaySpell.id)
        tes3.removeSpell{ reference = tes3.player, spell = decaySpell }
    end
end


return LunarDecay