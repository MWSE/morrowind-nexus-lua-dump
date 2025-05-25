-- Take that! A fun combat mod by Storm Atronach

-- Pending: add block weapon shield bonus logic

-- Common

local common = require("StormAtronach.TT.common")
local config = common.config
local log = common.log


-- Variables

local counter = 1


-- New Mechanics

local mechanics = {}
mechanics.block = require("StormAtronach.TT.block")
mechanics.parry = require("StormAtronach.TT.parry")
mechanics.dodge = require("StormAtronach.TT.dodge")
mechanics.spellbatting = require("StormAtronach.TT.spellbatting")


-- Functions

local function deactivate()
    for _, mechanic in pairs(mechanics) do
        mechanic.active = false
    end
    log:debug("Active flags reset")
end

local function resetCooldownsAndTables()
        for _, mechanic in pairs(mechanics) do
        mechanic.cooldown = false
    end
    log:debug("Cooldowns reset")

    -- We also use this stream to clean the slowed actors and the attacks counter tables
    common.slowedActors = {}
    common.attacksCounter = {}
            
end

local function activate(e)
    deactivate()
    local mechanic = e.data.mechanic
    mechanic.active = true
    if mechanic.window then
        timer.start({duration = mechanic.window, callback = deactivate, type = timer.simulate})
        log:debug("Window started for %s. Duration: %s seconds", mechanic.name, mechanic.window)
    end
end

-- Event callbacks

local function onKeyDown(e)
    if not tes3.isKeyEqual({expected = config.hotkey, actual = e}) then return end
    if tes3.menuMode() then return end
    if mechanics.block.cooldown then return end
    -- Start the blocking sequence
    activate({ data = { mechanic = mechanics.block } })
    mechanics.block.onKeyDown()

end

-- On the simulate event, we check for actors to be slowed
local function onSimulate_slow(e)

    -- Slow stream
    -- If the table is empty, exit
    if next(common.slowedActors) == nil then return end
    -- We initalize a table to store the actors that we will keep in the next simulation
    local slowedActorsAux = {}

    for actor_ref, actor in pairs(common.slowedActors) do
        local startTime = actor.startTime
        local duration  = actor.duration
        local type      = actor.typeSlow

        -- Error check. If the values are not right, the reference should not be logged in the aux, and will not be evaluated in the next simulate
        if not (startTime and duration and type) then log:error("Values error. Actor ref = %s, Start time = %s, duration =%s, type = %s",actor_ref,startTime,duration,type) goto continue end

        -- We do the skip frame according to the type of slowdown
        if type >= counter then
        tes3.skipAnimationFrame({reference = actor_ref})
        end

        if os.clock() - startTime < duration then
            slowedActorsAux[actor_ref] = actor
        end
        -- Skipping the logic if we get errors.         
        ::continue::
    end

    -- And now we update the list
    common.slowedActors = slowedActorsAux

    -- Counter control
    if counter < 5 then counter = counter+1 else counter = 1 end

end

-- On the simulate event, we check the attacks counter
local function onSimulate_attacksCounter(e)

    if next(common.attacksCounter) == nil then return end
    -- We initalize a table to store the attacks that we will keep in the next simulation
    local attacksCounterAux = {}

     for timestamp, _ in pairs(common.attacksCounter) do
        -- Error check. If the values are not right, the reference should not be logged in the aux, and will not be evaluated in the next simulate
        if not timestamp then log:error("Values error. Timestamp = %s",timestamp) goto theend end
        if os.clock() - timestamp < common.config.parry_red_duration then
            attacksCounterAux[timestamp] = common.attacksCounter[timestamp]
        end
    ::theend::
    end
    -- And now we update the list
    common.attacksCounter = attacksCounterAux

end

-- Parry mechanic - with hit chance manipulation
local function onCalcHitChance(e)
        -- Is the target the player
        local lookOutPlayer = e.target == tes3.player

        -- Dodge stream
        if lookOutPlayer and mechanics.dodge.active then
            -- Hit chance is already set to 0 by the sanctuary effect
            -- Therefore, only needs to apply the slowdown to the attacker
            common.slowedActors[e.attacker] = {startTime = os.clock(), duration = 2, typeSlow = 2 }

            -- Play sound
            tes3.playSound{ sound = "enchant fail" }
            -- Grant experience
            tes3.mobilePlayer:exerciseSkill(tes3.skill.acrobatics, config.dodge_skill_gain)
            -- Exit this stream
            return
        end

        -- Parry stream
        if lookOutPlayer and mechanics.parry.active then
            mechanics.parry.onCalcHitChance(e)
        end
end

local function onAttack(e)
    log:trace("AttackCallBack function initiated")
    -- Check if it is the player. Would love to add that to NPCs but they'll need an AI upgrade to be able to do this
    local playerIsThatYou   = e.reference == tes3.player
    -- Check if the attack is fully drawn
    local areYouReady       = tes3.mobilePlayer.actionData.attackSwing == 1
    
    -- Power attacking!
    -- Removed the condition for power attack for parrying. It is now a normal attack.
    if playerIsThatYou then
        mechanics.parry.onAttack()
        activate({ data = { mechanic = mechanics.parry } })
        log:trace("Parry mechanic started")
    
    -- Spell batting
    end
    
    if playerIsThatYou and areYouReady then
        mechanics.spellbatting.activateBatting()
    end
        

end

local function onDamage(e)
    mechanics.block.onDamage(e)
end

local function onJump(e)
    if e.reference ~= tes3.player then return end

    -- Lets get funky
    if not mechanics.dodge.cooldown then
        local dodgeDuration = mechanics.dodge.onJump()
        activate({ data = { mechanic = mechanics.dodge } })
        timer.start({duration = dodgeDuration, callback = deactivate, type = timer.simulate})
    end
end

-- Capping the vanilla block chance
local function calcBlockChanceCallback(e)
    if e.target ~= tes3.player then return end
    if e.blockChance > config.vanilla_blocking_cap then
        e.blockChance = config.vanilla_blocking_cap
    end

end


-- Initializing the mod. Setting priority lower than Poleplay (it is -10 there)
local function initialized()
    -- Register the button event
    event.register(tes3.event.keyDown, onKeyDown, {priority = -100})

    -- Register the hitchance event
    event.register(tes3.event.calcHitChance, onCalcHitChance, { priority = -100 })

    -- Register the simulate event for "slow" effect
    event.register(tes3.event.simulate, onSimulate_slow)

    -- Register the simulate event for "attacks counter" effect
    event.register(tes3.event.simulate, onSimulate_attacksCounter)

    -- Register the event for jump for the dodge mechanic
    event.register(tes3.event.jump, onJump)

    -- Register the damage event
    event.register(tes3.event.damage, onDamage, {priority = -100})

    -- Register the attack event
    event.register(tes3.event.attack, onAttack, {priority = -100})

    -- Register the event for the block chance cap
    event.register(tes3.event.calcBlockChance, calcBlockChanceCallback)

    -- Print a "Ready!" statement to the MWSE.log file.
    log:info("Mod has been initialized")
    print("[Take that!] Mod has been initialized")
end


local function modActivation()
    -- Unregister everything
    event.unregister(tes3.event.keyDown, onKeyDown)
    event.unregister(tes3.event.calcHitChance, onCalcHitChance)
    event.unregister(tes3.event.simulate, onSimulate_slow)
    event.unregister(tes3.event.simulate, onSimulate_attacksCounter)
    event.unregister(tes3.event.jump, onJump)
    event.unregister(tes3.event.damage, onDamage)
    event.unregister(tes3.event.attack, onAttack)

    if config.enabled then
    initialized()
    end

end

event.register(tes3.event.loaded, deactivate)
event.register(tes3.event.loaded, resetCooldownsAndTables)
event.register(tes3.event.initialized, initialized)
event.register("stormatronach:modActivation", modActivation)
require("StormAtronach.TT.mcm")