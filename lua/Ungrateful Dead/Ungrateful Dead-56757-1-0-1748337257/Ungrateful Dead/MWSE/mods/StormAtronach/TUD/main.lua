
local config = require("StormAtronach.TUD.config").config
local wisdoms = require("StormAtronach.TUD.wisdom")
local previousWisdom = {}


local function getRandomWisdom()
    if not wisdoms or #wisdoms == 0 then return nil end
    return wisdoms[math.random(1, #wisdoms)]
end


-- Apply effects
local function applyEffects(effects)
    if not effects or #effects == 0 then return end
        tes3.applyMagicSource{
            reference = tes3.player,
            bypassResistances = true,
            name = "Ancestral Wisdom",
            effects = effects
        }
end


local function ancestralWisdom(e)
    if not config.enabled then return end
    -- Check if it the caster is the player
    if e.caster ~= tes3.player then return end
    -- Check if it is a power
    if not e.source.isPower then return end
    -- Check if summonAncestralGhost is an effect of the spell
    local hasAncestralGhost = false
    for _, effect in pairs(e.source.effects) do
        if effect.id == tes3.effect.summonAncestralGhost then
            hasAncestralGhost = true
            break
        end
    end

    -- If the spell does not have the summonAncestralGhost effect, do nothing
    if not hasAncestralGhost then return end
  
    -- And now for the fun part:
    local wisdom = getRandomWisdom()
    if wisdom and hasAncestralGhost then
        applyEffects(wisdom.effects)
        tes3.messageBox({message = wisdom.saying})
    else
        tes3.messageBox({message = "Your ancestor is unusually quiet."})
    end
end



-- On spell cast
event.register(tes3.event.spellCasted, ancestralWisdom)
require("StormAtronach.TUD.mcm")

