local modName = "FailureXPBonus"
local failureMultiplier = 1.25
local successMultiplier = 1.0  -- baseline, unmodified

-- Track whether the last relevant action was a failure
local lastActionFailed = false

-- Hook into attack resolution to detect misses
local function onAttack(e)
    -- e.attackerReference is the actor, e.targetReference is the target
    -- A miss occurs when the attack fires but deals 0 damage due to a failed roll
    -- We flag this so the subsequent skill gain gets the bonus
    if e.attackerReference == tes3.player then
        -- Check if the attack missed (no damage, target still alive, attack animation played)
        -- MWSE doesn't give a direct "miss" bool here; we use damage == 0 heuristic
        if e.damage ~= nil and e.damage == 0 then
            lastActionFailed = true
        else
            lastActionFailed = false
        end
    end
end

-- Hook into skill gain and apply multiplier
local function onSkillGain(e)
    if e.reference ~= tes3.player then return end

    if lastActionFailed then
        -- Override the progress amount
        e.progress = e.progress * failureMultiplier
        lastActionFailed = false  -- reset flag
    end
end

-- Register events
local function initialized()
    event.register("calcSkillProgress", onSkillGain)  -- fires before XP is committed
    event.register("damage", onAttack)
end

event.register("initialized", initialized)