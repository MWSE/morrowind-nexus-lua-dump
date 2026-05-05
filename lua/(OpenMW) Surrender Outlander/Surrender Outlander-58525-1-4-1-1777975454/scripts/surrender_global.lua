local core    = require("openmw.core")
local types   = require("openmw.types")
local world   = require("openmw.world")
local util    = require("openmw.util")
local async   = require("openmw.async")

local shared            = require("scripts.surrender_shared")
local KHAJIIT_RACE     = shared.KHAJIIT_RACE
local BRIBE_MESSAGES   = shared.BRIBE_MESSAGES
local KHAJIIT_MESSAGES = shared.KHAJIIT_MESSAGES
local BRIBEABLE_CLASSES = shared.BRIBEABLE_CLASSES
local EXEMPT_NPCS      = shared.EXEMPT_NPCS
local DEFAULTS         = shared.DEFAULTS

local LOCAL_SCRIPT = "scripts/surrender_npc.lua"

local logEnabled = DEFAULTS.LOG

local function log(...)
    if logEnabled then
        print("[Surrender][global]", ...)
    end
end

local function Surrender_SetLog(value)
    logEnabled = value and true or false
end

local function pickMessage(npc)
    local record = types.NPC.record(npc)
    local race   = record and record.race and record.race:lower() or ""
    if KHAJIIT_RACE[race] then
        return KHAJIIT_MESSAGES[math.random(#KHAJIIT_MESSAGES)]
    end
    return BRIBE_MESSAGES[math.random(#BRIBE_MESSAGES)]
end

local function ensureLocalScript(npc)
    if not npc:hasScript(LOCAL_SCRIPT) then
        npc:addScript(LOCAL_SCRIPT)
    end
end

local function Surrender_Bribe(data)
    log("Surrender_Bribe received")
    local goldItem = data.goldItem
    local npcs     = data.npcs
    local player   = data.player

    if not goldItem or not goldItem:isValid() then
        log("Surrender_Bribe: invalid goldItem, aborting")
        return
    end
    if not player or not player:isValid() then
        log("Surrender_Bribe: invalid player, aborting")
        return
    end
    if not npcs or #npcs == 0 then
        log("Surrender_Bribe: empty npcs list, aborting")
        return
    end

    -- find closest bribeable NPC to receive the gold
    local closest     = nil
    local closestDist = math.huge
    for _, npc in ipairs(npcs) do
        if npc:isValid() and not types.Actor.isDead(npc) then
            local dist = (npc.position - goldItem.position):length()
            if dist < closestDist then
                closestDist = dist
                closest     = npc
            end
        end
    end

    if not closest then
        log("Surrender_Bribe: no valid closest NPC, aborting")
        return
    end

    log("Surrender_Bribe: closest receiver =", closest.recordId)

    -- tell the closest NPC to walk over and animate picking up the gold
    ensureLocalScript(closest)
    closest:sendEvent("Surrender_PickupGold", {
        goldItem = goldItem,
        player   = player,
        message  = pickMessage(closest),
    })

    -- build ceasefire target list
    local ceasefireTargets
    if data.classCeasefire then
        ceasefireTargets = {}
        for _, actor in ipairs(world.activeActors) do
            if types.NPC.objectIsInstance(actor)
               and not types.Actor.isDead(actor)
               and not EXEMPT_NPCS[actor.recordId:lower()] then
                local record = types.NPC.record(actor)
                if record and record.class and BRIBEABLE_CLASSES[record.class:lower()] then
                    table.insert(ceasefireTargets, actor)
                end
            end
        end
    else
        ceasefireTargets = npcs
    end

    log("Surrender_Bribe: ceasefire targets =", #ceasefireTargets)

    -- tell targets to cease fire
    for _, npc in ipairs(ceasefireTargets) do
        if npc:isValid() and not types.Actor.isDead(npc) then
            ensureLocalScript(npc)
            npc:sendEvent("Surrender_Ceasefire", {
                ceasefire = data.ceasefire,
                player    = player,
            })
        end
    end
end

local function Surrender_FinalizeGoldPickup(data)
    log("Surrender_FinalizeGoldPickup received")
    local npc      = data.npc
    local goldItem = data.goldItem
    local player   = data.player
    local message  = data.message

    if not npc or not npc:isValid() or types.Actor.isDead(npc) then
        log("Surrender_FinalizeGoldPickup: bad NPC, aborting")
        return
    end
    if not goldItem or not goldItem:isValid() then
        log("Surrender_FinalizeGoldPickup: bad goldItem, aborting")
        return
    end
    if not player or not player:isValid() then
        log("Surrender_FinalizeGoldPickup: bad player, aborting")
        return
    end

    goldItem:moveInto(types.Actor.inventory(npc))
    core.sound.playSound3d("Item Gold Up", npc)

    local npcName = types.NPC.record(npc).name or "Someone"
    player:sendEvent("SurrenderMessage", {
        message = npcName .. ": \"" .. (message or "") .. "\""
    })
end

local function Surrender_PlayerAttacked()
    log("Surrender_PlayerAttacked: breaking ceasefires")
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(LOCAL_SCRIPT) then
            actor:sendEvent("Surrender_BreakCeasefire", {})
        end
    end
end

local function Surrender_ThrowGold(data)
    log("Surrender_ThrowGold received")
    local player = data.player
    if not player or not player:isValid() then
        log("Surrender_ThrowGold: invalid player, aborting")
        return
    end

    local amount = data.amount
    local yaw    = data.yaw
    local usePhysics = data.usePhysics

    local inv  = types.Actor.inventory(player)
    local gold = nil
    for _, item in ipairs(inv:getAll()) do
        if item.recordId:lower() == "gold_001" then
            gold = item
            break
        end
    end
    if not gold or not gold:isValid() then
        log("Surrender_ThrowGold: no gold_001 stack found, aborting")
        return
    end
    if gold.count < amount then
        log("Surrender_ThrowGold: gold stack < amount, aborting")
        return
    end

    local pos = player.position
    local dropped = gold:split(amount)
    log("Surrender_ThrowGold: dropped", amount, "gold, usePhysics =", tostring(usePhysics))

    -- Lua Physics Engine
    if usePhysics then
        local D = require('scripts/MaxYari/LuaPhysics/scripts/physics_defs')

        local forward = player.rotation * util.vector3(0, 1, 0)

        local spawnPos = pos + (forward * 40) + util.vector3(0, 0, 99)

        dropped:teleport(player.cell, spawnPos)

        dropped:sendEvent(D.e.WhatIsMyPhysicsData, { object = dropped })

        dropped:sendEvent(D.e.SetPhysicsProperties, {
            drag = 0.10,
            bounce = 0.4,
            isSleeping = false,
            culprit = player,
            mass = 0.1,
            buoyancy = 0.3,
            lockRotation = false,
            angularDrag = 0.5,
            resetOnLoad = false,
            ignoreWorldCollisions = false,
            collisionMode = "sphere",
            realignWhenRested = false
        })

        local impulse = (forward * 3.5) + util.vector3(0, 0, 1.2)

        dropped:sendEvent(D.e.ApplyImpulse, {
            impulse = impulse,
            culprit = player
        })
    else
        local dropPos = util.vector3(
            pos.x + math.sin(yaw) * 50,
            pos.y + math.cos(yaw) * 50,
            pos.z + 10
        )
        dropped:teleport(player.cell, dropPos)
    end

    core.sound.playSound3d("Item Gold Down", player)

    player:sendEvent('Surrender_TryBribeFromThrow', {
        amount = amount,
    })
    player:sendEvent('GNPCs_NotifyGoldDrop', {
        amount = amount,
    })
end

local function Surrender_OpenGuardDialogue(data)
    log("Surrender_OpenGuardDialogue received")
    local player = data.player
    local guard  = data.guard
    if not player or not player:isValid() then
        log("Surrender_OpenGuardDialogue: invalid player, aborting")
        return
    end
    if not guard or not guard:isValid() then
        log("Surrender_OpenGuardDialogue: invalid guard, aborting")
        return
    end
    if types.Actor.isDead(guard) then
        log("Surrender_OpenGuardDialogue: guard is dead, aborting")
        return
    end
    log("Surrender_OpenGuardDialogue: opening dialogue with", guard.recordId)
    player:sendEvent("AddUiMode", { mode = "Dialogue", target = guard })
end

local function Surrender_RequestRemoval(actor)
    if not actor or not actor:isValid() then return end
    async:newUnsavableSimulationTimer(2.0, function()
        if actor:isValid() and actor:hasScript(LOCAL_SCRIPT) then
            actor:removeScript(LOCAL_SCRIPT)
        end
    end)
end

return {
    eventHandlers = {
        Surrender_Bribe               = Surrender_Bribe,
        Surrender_FinalizeGoldPickup  = Surrender_FinalizeGoldPickup,
        Surrender_PlayerAttacked      = Surrender_PlayerAttacked,
        Surrender_ThrowGold           = Surrender_ThrowGold,
        Surrender_OpenGuardDialogue   = Surrender_OpenGuardDialogue,
        Surrender_RequestRemoval      = Surrender_RequestRemoval,
        Surrender_SetLog              = Surrender_SetLog,
    },
}