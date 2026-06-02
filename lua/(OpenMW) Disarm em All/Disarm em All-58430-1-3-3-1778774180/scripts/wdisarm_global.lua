local types = require("openmw.types")
local core = require("openmw.core")
local world = require("openmw.world")
local async = require("openmw.async")
local util  = require("openmw.util")
local pickup = require("scripts.wdisarm_pickup")

local shared   = require("scripts.wdisarm_shared")
local data     = require("scripts.wdisarm_data")
local DEFAULTS = shared.DEFAULTS

local NPC_SCRIPT = "scripts/wdisarm_npc.lua"

local cachedSettings = {
    MOD_ENABLED          = DEFAULTS.MOD_ENABLED,
    DISARM_NPCS          = DEFAULTS.DISARM_NPCS,
    DISARM_CREATURES     = DEFAULTS.DISARM_CREATURES,
    BASE_CHANCE          = DEFAULTS.BASE_CHANCE,
    STR_AGI_FACTOR       = DEFAULTS.STR_AGI_FACTOR,
    MAX_CHANCE           = DEFAULTS.MAX_CHANCE,
    PLAYER_CHANCE_MULT   = DEFAULTS.PLAYER_CHANCE_MULT,
    CHARGE_THRESHOLD     = DEFAULTS.CHARGE_THRESHOLD,
    WEIGHT_CHECK_ENABLED = DEFAULTS.WEIGHT_CHECK_ENABLED,
    WEIGHT_THRESHOLD     = DEFAULTS.WEIGHT_THRESHOLD,
    SHIELD_PROTECTS      = DEFAULTS.SHIELD_PROTECTS,
    NPC_PICKUP_ENABLED   = DEFAULTS.NPC_PICKUP_ENABLED,
    NPC_PICKUP_CHANCE    = DEFAULTS.NPC_PICKUP_CHANCE,
    PICKUP_RADIUS        = DEFAULTS.PICKUP_RADIUS,
    PICKUP_DELAY         = DEFAULTS.PICKUP_DELAY,
    DAMAGE_THRESHOLD     = DEFAULTS.DAMAGE_THRESHOLD,
    SKILL_THRESHOLD      = DEFAULTS.SKILL_THRESHOLD,
    CREATURE_COMBAT_MULT = DEFAULTS.CREATURE_COMBAT_MULT,
    STRENGTH_AS_MULT     = DEFAULTS.STRENGTH_AS_MULT,
    USE_PHYSICS          = DEFAULTS.USE_PHYSICS,
}

local droppedWeapons = {}
local refusedNpcs = {}
local processing = {}

local function isEligibleForScript(actor)
    if not actor:isValid() then return false end
    if types.Actor.isDead(actor) then return false end
    if types.Player.objectIsInstance(actor) then return false end

    local isNPC = types.NPC.objectIsInstance(actor)
    local isCreature = types.Creature.objectIsInstance(actor)
    if not isNPC and not isCreature then return false end

    if isNPC and not cachedSettings.DISARM_NPCS then return false end
    if isCreature and not cachedSettings.DISARM_CREATURES then return false end

    if shared.EXCLUDED_NPCS[string.lower(actor.recordId)] then return false end
    return true
end

local function syncActiveScripts()
    -- attach/detach dynamic scripts on active actors according to current settings
    for _, actor in ipairs(world.activeActors) do
        local has = actor:hasScript(NPC_SCRIPT)
        local eligible = cachedSettings.MOD_ENABLED and isEligibleForScript(actor)

        if eligible and not has then
            actor:addScript(NPC_SCRIPT)
            actor:sendEvent("Disarm_SettingsUpdated", cachedSettings)
        elseif has and not eligible then
            actor:removeScript(NPC_SCRIPT)
            refusedNpcs[actor.id] = nil
        elseif has and eligible then
            actor:sendEvent("Disarm_SettingsUpdated", cachedSettings)
        end
    end
end

local function onActorActive(actor)
    if not cachedSettings.MOD_ENABLED then return end
    if isEligibleForScript(actor) and not actor:hasScript(NPC_SCRIPT) then
        actor:addScript(NPC_SCRIPT)
        actor:sendEvent("Disarm_SettingsUpdated", cachedSettings)
    end
end

local function onSettingsUpdated(d)
    cachedSettings = d
    syncActiveScripts()
end

local function onDynamicScriptCleanup(d)
    if not d.npc or not d.npc:isValid() then return end
    refusedNpcs[d.npc.id] = nil
    if d.npc:hasScript(NPC_SCRIPT) then
        d.npc:removeScript(NPC_SCRIPT)
        -- print(string.format("[Disarm] Cleaned up %s from '%s' (id=%s)",
        -- NPC_SCRIPT, tostring(d.npc.recordId), tostring(d.npc.id)))
    end
end

local function onDoDisarm(d)
    if not d or not d.victim or not d.victim:isValid() then return end
    
    local victim = d.victim
    local isPlayer = d.isPlayer or false
    local eqTable = types.Actor.getEquipment(victim)
    
    if not eqTable then return end
    local weapon = eqTable[types.Actor.EQUIPMENT_SLOT.CarriedRight]
    
    if not weapon or not weapon:isValid() then return end
    if not types.Weapon.objectIsInstance(weapon) then return end
    if weapon.recordId:find("^bound_") then return end
    if weapon.count < 1 then return end

    local pos = victim.position
    local dropped = weapon:split(1)
    
    -- Lua Engine Physics
    if cachedSettings.USE_PHYSICS then
        local D = require('scripts/MaxYari/LuaPhysics/scripts/physics_defs')
        local bbox = dropped:getBoundingBox()
        local weaponHeight = bbox.halfSize.z
        local dropHeight = 50
        
        local finalPosition = util.vector3(pos.x, pos.y, pos.z + dropHeight + weaponHeight)
        dropped:teleport(victim.cell, finalPosition)

        dropped:sendEvent(D.e.WhatIsMyPhysicsData, { object = dropped })
        dropped:sendEvent(D.e.SetPhysicsProperties, {
            drag = 0.13,
            bounce = 0.75,
            isSleeping = false,
            culprit = victim,
            mass = 3,
            buoyancy = 0.3,
            lockRotation = false,
            angularDrag = 0.12,
            resetOnLoad = false,
            ignoreWorldCollisions = false,
            collisionMode = "sphere", 
            realignWhenRested = false
        })

        local forward = victim.rotation * util.vector3(0, 1, 0)
        local side = victim.rotation * util.vector3(1, 0, 0)
        local impulse = (forward * 12) + (side * (math.random() - 0.5) * 10) + util.vector3(0, 0, 5)
        
        dropped:sendEvent(D.e.ApplyImpulse, { impulse = impulse, culprit = victim })
    else
        dropped:teleport(victim.cell, util.vector3(pos.x, pos.y, pos.z + 10))
    end

    local rec = types.Weapon.record(weapon)
    local sound = rec and data.WEAPON_SOUND[rec.type]
    if sound then
        core.sound.playSound3d(sound:gsub(" Up$", " Down"), victim)
    end

    if isPlayer then
        droppedWeapons[dropped.id] = dropped
        return
    end

    async:newUnsavableSimulationTimer(cachedSettings.PICKUP_DELAY, function()
        if not dropped:isValid() or dropped.cell == nil then return end
        if not victim:isValid() or types.Actor.isDead(victim) then return end
        if (dropped.position - victim.position):length() > cachedSettings.PICKUP_RADIUS then return end
        
        droppedWeapons[dropped.id] = nil
        refusedNpcs = {} 
        
        local pickupRec = types.Weapon.record(dropped)
        local pickupSound = pickupRec and data.WEAPON_SOUND[pickupRec.type]
        if pickupSound then core.sound.playSound3d(pickupSound, victim) end
        
        dropped:moveInto(types.Actor.inventory(victim))
        victim:sendEvent("Disarm_Reequip", { weapon = dropped })
    end)
end

local function onCheckPickup(d)
    if not cachedSettings.NPC_PICKUP_ENABLED then return end
    if not d or not d.npc or not d.npc:isValid() then return end
    if not types.NPC.objectIsInstance(d.npc) then return end

    async:newUnsavableSimulationTimer(0.2, function()
        if not d.npc:isValid() then return end
        local npc = d.npc
        local npcId = npc.id

        local closest = nil
        local closestDist = math.huge
        
        for wId, dropped in pairs(droppedWeapons) do
            if dropped:isValid() and dropped.cell ~= nil then
                if not processing[wId] and not (refusedNpcs[npcId] and refusedNpcs[npcId][wId]) then
                    local dist = (dropped.position - npc.position):length()
                    if dist < cachedSettings.PICKUP_RADIUS and dist < closestDist then
                        closest = dropped
                        closestDist = dist
                    end
                end
            else
                droppedWeapons[wId] = nil
            end
        end

        if not closest then return end
        local closestId = closest.id

        if not pickup.shouldPickup(npc, closest, cachedSettings.NPC_PICKUP_CHANCE, cachedSettings.DAMAGE_THRESHOLD, cachedSettings.SKILL_THRESHOLD) then
            if not refusedNpcs[npcId] then refusedNpcs[npcId] = {} end
            refusedNpcs[npcId][closestId] = true
            return
        end

        processing[closestId] = true
        droppedWeapons[closestId] = nil
        
        async:newUnsavableSimulationTimer(cachedSettings.PICKUP_DELAY, function()
            processing[closestId] = nil
            if refusedNpcs[npcId] then refusedNpcs[npcId] = nil end
            
            if not closest:isValid() or closest.cell == nil then return end
            if not npc:isValid() or types.Actor.isDead(npc) then return end
            
            local rec = types.Weapon.record(closest)
            local sound = rec and data.WEAPON_SOUND[rec.type]
            if sound then core.sound.playSound3d(sound, npc) end
            
            closest:moveInto(types.Actor.inventory(npc))
            npc:sendEvent("Disarm_Reequip", { weapon = closest })
        end)
    end)
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
    },
    eventHandlers = {
        Disarm_SettingsUpdated = onSettingsUpdated,
        Disarm_DynamicScriptCleanup = onDynamicScriptCleanup,
        Disarm_DoDisarm = onDoDisarm,
        Disarm_CheckPickup = onCheckPickup,
    },
}