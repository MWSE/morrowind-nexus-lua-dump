-- Take that! A fun combat mod by Storm Atronach

-- Pending: add block weapon shield bonus logic

-- Common

local common = require("StormAtronach.TT.common")
local config = require("StormAtronach.TT.config")

-- Logging stuff
local log = mwse.Logger.new({
	name = config.name,
	level = config.log_level,
})

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
    common.parryingActors = {}
    log:debug("Tables reset")

    -- And the animation reset just in case
   local animReference = tes3.mobilePlayer.is3rdPerson and tes3.player or tes3.player1stPerson
   tes3.playAnimation({
       reference = animReference,
       group = 0,
   })
   log:debug("Animation reset")

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
    if (not tes3.isKeyEqual({expected = config.hotkey, actual = e})) then return end
    if tes3.menuMode() then return end
    -- Check for cooldown
    if mechanics.block.cooldown then return end
    -- Check if the player is attacking or casting
    if tes3.mobilePlayer.isAttackingOrCasting then return end
    -- Start the blocking sequence
    activate({ data = { mechanic = mechanics.block } })
    mechanics.block.onKeyDown()

end

-- On the simulate event, we check for actors to be slowed
local function onSimulate_slow(e)

    -- Slow stream
    -- If the table is empty, exit
    if next(common.slowedActors) == nil then return end
    -- We initialize a table to store the actors that we will keep in the next simulation
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
    -- We initialize a table to store the attacks that we will keep in the next simulation
    local attacksCounterAux = {}

     for timestamp, _ in pairs(common.attacksCounter) do
        -- Error check. If the values are not right, the reference should not be logged in the aux, and will not be evaluated in the next simulate
        if not timestamp then log:error("Values error. Timestamp = %s",timestamp) goto theend_ac end
        if os.clock() - timestamp < config.parry_red_duration then
            attacksCounterAux[timestamp] = common.attacksCounter[timestamp]
        end
    ::theend_ac::
    end
    -- And now we update the list
    common.attacksCounter = attacksCounterAux

end

-- Check the parrying actors
local function onSimulate_parryingActorTracker(e)

    if next(common.parryingActors) == nil then return end
    -- We initialize a table to store the attacks that we will keep in the next simulation
    local parryingActorsAux = {}

     for actor_ref, values in pairs(common.parryingActors) do
        -- Error check. If the values are not right, the reference should not be logged in the aux, and will not be evaluated in the next simulate
        if not actor_ref then log:error("Reference error: Actor ref = %s",actor_ref) goto theend_PAT end
        if not values.startTime then log:error("Values error. Actor ref = %s, Start time = %s",actor_ref,values.startTime) goto theend_PAT end
        if not values.duration then log:error("Values error. Actor ref = %s, Start time = %s, Duration = %s",actor_ref,values.startTime,values.duration) goto theend_PAT end
        if os.clock() - values.startTime < values.duration then
           parryingActorsAux[actor_ref] = values
        end
    ::theend_PAT::
    end
    -- And now we update the list
    common.parryingActors = parryingActorsAux

end

-- Exploratory code
--- @param e attackHitEventData
local function attackHitCallback(e)
    local TS = tes3.getSimulationTimestamp()
    local ID = e.reference.id
    log:trace("Attack hit event, ID: %s, TS: %s",ID,TS)

        -- Is the target the player
        local lookOutPlayer = e.targetReference == tes3.player

        -- Dodge stream
        if lookOutPlayer and mechanics.dodge.active then
            -- Hit chance is already set to 0 by the sanctuary effect
            -- Therefore, only needs to apply the slowdown to the attacker
            common.slowedActors[e.reference] = {startTime = os.clock(), duration = 2, typeSlow = 2 }

            -- Play sound
            tes3.playSound{ sound = "enchant fail" }
            -- Grant experience
            tes3.mobilePlayer:exerciseSkill(tes3.skill.acrobatics, config.dodge_skill_gain)
            -- Exit this stream
            return
        end

        -- Parry stream
        if lookOutPlayer and mechanics.parry.active then
            mechanics.parry.attackHitCallback(e)
        end

        -- Parry stream for NPCs
        if config.enemy_parry_active and common.parryingActors[e.targetReference] then
            mechanics.parry.attackHitCallback(e)
        end

end

-- Parry mechanic - with hit chance manipulation
--- @param e calcHitChanceEventData
local function onCalcHitChance(e)
    local TS = tes3.getSimulationTimestamp()
    local ID = e.attacker.id
    log:trace("Calc hit chance event, ID: %s, TS: %s", ID,TS)




end
--- @param e attackEventData
local function onAttack(e)
    local TS = tes3.getSimulationTimestamp()
    local ID = e.reference.id
    log:trace("Attack event,ID: %s, TS: %s",ID,TS)
    -- Check if it is the player. Would love to add that to NPCs but they'll need an AI upgrade to be able to do this
    local playerIsThatYou   = e.reference == tes3.player
    -- Check if the attack is fully drawn
    local areYouReady       = tes3.mobilePlayer.actionData.attackSwing == 1

    -- Power attacking!
    if playerIsThatYou and areYouReady then
        mechanics.parry.onAttack()
        activate({ data = { mechanic = mechanics.parry } })
        log:trace("Parry mechanic started")
    end

    -- Spell batting
    if playerIsThatYou and areYouReady then
        mechanics.spellbatting.activateBatting()
    end

    -- Enemy parry
    if not playerIsThatYou and config.enemy_parry_active then
        log:trace("NPC Parry mechanic started")
        local enemySwing = e.reference.mobile.actionData.attackSwing
        if enemySwing >= config.enemy_min_attackSwing then
            common.parryingActors[e.reference] = {startTime = os.clock(), duration = config.enemy_parry_window, reference = e.reference}
        end
    end

end

--- @param e damageEventData
local function onDamage(e)
    local TS = tes3.getSimulationTimestamp()
    local ID = e.reference.id
    log:trace("Damage event, ID: %s, TS: %s",ID,TS)
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
---@param e calcBlockChanceEventData
local function calcBlockChanceCallback(e)
    local TS = tes3.getSimulationTimestamp()
    local ID = e.target.id
    log:trace("Calc block chance event, ID: %s, TS: %s",ID,TS)

    if e.target ~= tes3.player then return end
    local playerAttacking = tes3.mobilePlayer.actionData.attackSwing == 1
    local allowVanillaBlock = config.allow_vanilla_block
    if e.blockChance > config.vanilla_blocking_cap and not (playerAttacking and allowVanillaBlock) then
        e.blockChance = config.vanilla_blocking_cap
    end
end


-- Initializing the mod. Setting priority lower than Poleplay (it is -10 there)
local function initialized()
    -- Register the button event
    event.register(tes3.event.keyDown, onKeyDown, {priority = -100})
    event.register(tes3.event.mouseButtonDown, onKeyDown, {priority = -100})

    -- Register the hitchance event
    event.register(tes3.event.calcHitChance, onCalcHitChance, { priority = -100 })

    -- Register the simulate event for "slow" effect
    event.register(tes3.event.simulate, onSimulate_slow)

    -- Register the simulate event for "attacks counter"
    event.register(tes3.event.simulate, onSimulate_attacksCounter)

    -- Register the simulate event for the parrying actors tracker
    event.register(tes3.event.simulate, onSimulate_parryingActorTracker)

    -- Register the event for jump for the dodge mechanic
    event.register(tes3.event.jump, onJump)

    -- Register the damage event
    event.register(tes3.event.damage, onDamage, {priority = -100})

    -- Register the attack event
    event.register(tes3.event.attack, onAttack, {priority = -100})

    -- Register the event for the block chance cap
    event.register(tes3.event.calcBlockChance, calcBlockChanceCallback, {priority = -100})

    -- Register the event for onAttackHit
    event.register(tes3.event.attackHit, attackHitCallback)

    -- Create the vfx for sparks
    local sparks = tes3.createObject{objectType = tes3.objectType.static, id = "AXE_sa_VFX_WSparks", mesh = "e\\spark.nif"}

    -- Print a "Ready!" statement to the MWSE.log file.
    print("[Take that!] Mod has been initialized")
    if sparks then
        print("Sparks VFX created")
    else
        print("Sparks VFX could not be created")
    end
end


local function modActivation()
    -- Unregister everything
    event.unregister(tes3.event.keyDown, onKeyDown)
    event.unregister(tes3.event.mouseButtonDown, onKeyDown)
    event.unregister(tes3.event.calcHitChance, onCalcHitChance)
    event.unregister(tes3.event.simulate, onSimulate_slow)
    event.unregister(tes3.event.simulate, onSimulate_attacksCounter)
    event.unregister(tes3.event.simulate, onSimulate_parryingActorTracker)
    event.unregister(tes3.event.jump, onJump)
    event.unregister(tes3.event.damage, onDamage)
    event.unregister(tes3.event.attack, onAttack)
    resetCooldownsAndTables()
    if config.enabled then
    initialized()
    end

end

event.register(tes3.event.loaded, deactivate)
event.register(tes3.event.loaded, resetCooldownsAndTables)
event.register(tes3.event.initialized, initialized)
event.register("stormatronach:modActivation", modActivation)
require("StormAtronach.TT.mcm")