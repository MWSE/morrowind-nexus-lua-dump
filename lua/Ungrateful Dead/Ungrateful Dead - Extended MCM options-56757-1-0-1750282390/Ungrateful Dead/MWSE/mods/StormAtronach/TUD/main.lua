-- Requirements and logging
local config = require("StormAtronach.TUD.config")
---@type Wisdom[]
local wisdoms = require("StormAtronach.TUD.wisdom")
local log = mwse.Logger.new({
	name = config.name,
	level = config.logLevel,
})


---Utility functions
local function getRandomWisdom()
    if not wisdoms or #wisdoms == 0 then log:error("No wisdoms available.") return nil end
    return wisdoms[math.random(1, #wisdoms)]
end


-- Apply effects
---@param effects WisdomEffect[]
local function applyEffects(effects)
    if not effects or #effects == 0 then log:warn("No effects to apply.") return end

-- Set the duration of the effects
    for _, effect in pairs(effects) do
        effect.duration = config.duration or 600 -- Default to 600 seconds (10 minutes)
        log:debug("Applying effect: id=%s min=%s max=%s duration=%s", tostring(effect.id), tostring(effect.min), tostring(effect.max), tostring(effect.duration))
    end

    tes3.applyMagicSource{
        reference = tes3.player,
        bypassResistances = true,
        name = "Ancestral Wisdom",
        effects = effects
    }
    log:info("Applied %d effects to player.", #effects)
end

---@param e spellCastedEventData
local function ancestralWisdom(e)
    if not config.enabled then log:info("Mod is disabled; skipping ancestralWisdom.") return end
    -- Check if it the caster is the player
    if e.caster ~= tes3.player then log:debug("Caster is not player; skipping.") return end
    -- Check if it is a power
    if not e.source.isPower then log:debug("Source is not a power; skipping.") return end
    -- Check if summonAncestralGhost is an effect of the spell
    local hasAncestralGhost = false
    for _, effect in pairs(e.source.effects) do
        if effect.id == tes3.effect.summonAncestralGhost then
            hasAncestralGhost = true
            break
        end
    end

    -- If the spell does not have the summonAncestralGhost effect, do nothing
    if not hasAncestralGhost then log:debug("Spell does not have summonAncestralGhost effect; skipping.")  return end

    -- And now for the fun part:
    ---@type Wisdom
    local wisdom = getRandomWisdom()
    if not wisdom then log:error("No wisdom selected.") return end
    local blessingsChance = 0
    local blessingActivate = false
    if config.blessingsEnabled then
        blessingsChance = config.blessingsChance or 100
        blessingActivate = math.random(1, 100) <= blessingsChance
         log:debug("Blessings enabled. Chance: %d, Rolled: %s", blessingsChance, tostring(blessingActivate))
    end
    local magnitudeVar = 1
    if config.magnitudeVarEnabled then
        magnitudeVar = math.random(100-config.magnitudeVar,100) / 100
        log:debug("Magnitude variation enabled. magnitudeVar: %.2f", magnitudeVar)
    end
    if wisdom and hasAncestralGhost then
        tes3.messageBox({message = wisdom.saying})  log:info("Displayed wisdom: %s", wisdom.saying)
        -- Apply the blessing if it is activated
        if blessingActivate then
            ---@type WisdomEffect[]
            local effects = table.deepcopy(wisdom.effects)
            if effects then
                -- Apply the blessing effects
                for _, effect in pairs(effects) do
                    effect.min = math.round(effect.min * magnitudeVar,1)
                    effect.max = math.round(effect.max * magnitudeVar,1)
                end
                log:info("Applying blessing effects.")
                applyEffects(effects)
            else
                log:error("No effects found in wisdom: %s", wisdom.saying)
            end
        else
            log:info("Blessing not activated.")
        end
    else
        tes3.messageBox({message = "Your ancestor is unusually quiet."})
    end
end
-- Register the event handler
-- On spell cast
event.register(tes3.event.spellCasted, ancestralWisdom)
require("StormAtronach.TUD.mcm")

