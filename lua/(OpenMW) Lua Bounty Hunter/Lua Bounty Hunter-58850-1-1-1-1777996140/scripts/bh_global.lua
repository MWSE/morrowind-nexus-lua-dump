local world  = require("openmw.world")
local types  = require("openmw.types")
local core   = require("openmw.core")
local util   = require("openmw.util")
local async  = require("openmw.async")

local shared   = require("scripts.bh_shared")
local FORTS    = shared.FORTS
local DEFAULTS = shared.DEFAULTS

local BH_SCRIPT  = "scripts/bh_npc.lua"
local BH_REWARD_SCRIPT = "scripts/bh_npc_reward.lua"
local GKO_SCRIPT = "scripts/gko_npc.lua"

local occupiedSlots = {}
for _, fort in ipairs(FORTS) do
    occupiedSlots[fort.id] = {}
end

local FORT_REWARD_LOWER = {}
for _, fort in ipairs(FORTS) do
    FORT_REWARD_LOWER[fort.id] = fort.rewardNpc:lower()
end

local currentPrisonerId = nil

-- set of actor ids whose bh_npc should be force-escaped on next activation
local pendingEscapeFlags = {}

local logEnabled = false
local function log(...)
    if logEnabled then print("[BH G]", ...) end
end

local cachedSettings = {}
for k, v in pairs(DEFAULTS) do cachedSettings[k] = v end

local function findFreeSlot(fort)
    local occ = occupiedSlots[fort.id]
    for i, slot in ipairs(fort.prisonSlots) do
        if not occ[i] then
            return i, util.vector3(slot.x, slot.y, slot.z)
        end
    end
    return nil
end

local function countFreeSlots(fort)
    local occ  = occupiedSlots[fort.id]
    local free = 0
    for i = 1, #fort.prisonSlots do
        if not occ[i] then free = free + 1 end
    end
    return free
end

local function getRewardNpcName(fort)
    local rewardNpcLower = FORT_REWARD_LOWER[fort.id] or fort.rewardNpc:lower()
    for _, actor in ipairs(world.activeActors) do
        if types.NPC.objectIsInstance(actor)
           and actor.recordId:lower() == rewardNpcLower
        then
            local rec = types.NPC.record(actor)
            return (rec and rec.name) or fort.rewardNpc
        end
    end
    return fort.rewardNpc
end

local function broadcastBhSettings()
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(BH_SCRIPT) then
            actor:sendEvent("BH_SettingsUpdated", cachedSettings)
        end
    end
end

-- push the BH min-level threshold to every gko_npc currently attached
local function broadcastMinLevelToGko()
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(GKO_SCRIPT) then
            actor:sendEvent("BH_MinLevelUpdated", {
                MIN_PRISONER_LEVEL = cachedSettings.MIN_PRISONER_LEVEL,
            })
            actor:sendEvent("BH_PlayerEscortState", { prisonerId = currentPrisonerId })
        end
    end
end

-- engine handlers

local function onActorActive(actor)
    if not types.NPC.objectIsInstance(actor) then return end
    if types.Player.objectIsInstance(actor) then return end

    -- watchdog-declared escape
    if pendingEscapeFlags[actor.id] then
        pendingEscapeFlags[actor.id] = nil
        if actor:hasScript(BH_SCRIPT) then
            actor:sendEvent("BH_ForceEscape", {})
        else
            -- bh_npc was somehow already removed
            core.sendGlobalEvent("GKD_ClearDisableKnockdown", { npcId = actor.id })
        end
    end

    -- push current min-level setting to a freshly-attached gko_npc.
    if actor:hasScript(GKO_SCRIPT) then
        actor:sendEvent("BH_MinLevelUpdated", {
            MIN_PRISONER_LEVEL = cachedSettings.MIN_PRISONER_LEVEL,
        })
        async:newUnsavableSimulationTimer(0, function()
            if actor:isValid() and actor:hasScript(GKO_SCRIPT) then
                actor:sendEvent("BH_PlayerEscortState", { prisonerId = currentPrisonerId })
            end
        end)
    end
end

local function onSave()
    local saved = {}
    for fortId, slots in pairs(occupiedSlots) do
        local entry = {}
        for i, actorId in pairs(slots) do
            entry[tostring(i)] = actorId
        end
        saved[fortId] = entry
    end
    return {
        occupiedSlots      = saved,
        pendingEscapeFlags = pendingEscapeFlags,
    }
end

local function onLoad(data)
    for _, fort in ipairs(FORTS) do
        occupiedSlots[fort.id] = {}
    end
    pendingEscapeFlags = {}
    if not data then return end
    if data.occupiedSlots then
        for fortId, entry in pairs(data.occupiedSlots) do
            if occupiedSlots[fortId] then
                for iStr, actorId in pairs(entry) do
                    occupiedSlots[fortId][tonumber(iStr)] = actorId
                end
            end
        end
    end
    if data.pendingEscapeFlags then
        for k, v in pairs(data.pendingEscapeFlags) do
            pendingEscapeFlags[k] = v
        end
    end
    log("Slots restored from save")
end

-- event handlers

local function onSettingsUpdated(data)
    for k in pairs(cachedSettings) do
        if data[k] ~= nil then cachedSettings[k] = data[k] end
    end
    logEnabled = cachedSettings.ENABLE_LOGS
    broadcastBhSettings()
    broadcastMinLevelToGko()
    log("Settings applied: ESCAPE_CHANCE=", cachedSettings.ESCAPE_CHANCE,
        " REWARD_PER_LEVEL=", cachedSettings.REWARD_PER_LEVEL,
        " MIN_PRISONER_LEVEL=", cachedSettings.MIN_PRISONER_LEVEL)
end

local function onPrisonerKnockedOut(data)
    if not cachedSettings.MOD_ENABLED then return end
    local npc    = data.npc
    local player = data.player
    if not npc    or not npc:isValid()    then return end
    if not player or not player:isValid() then return end

    player:sendEvent("BH_CheckAlreadyEscorting", {
        npc      = npc,
        player   = player,
        npcName  = data.npcName,
    })
end

local function onStartEscort(data)
    local npc    = data.npc
    local player = data.player
    if not npc    or not npc:isValid()    then return end
    if not player or not player:isValid() then return end
    if npc:hasScript(BH_SCRIPT) then return end

    npc:addScript(BH_SCRIPT)
    npc:sendEvent("BH_SettingsUpdated", cachedSettings)
    npc:sendEvent("BH_Init", {
        player          = player,
        playerIsKhajiit = data.playerIsKhajiit or false,
    })
    log("Prisoner tagged:", npc.recordId)
end

local function onFinishOffNpc(data)
    local npc = data and data.npc
    if not npc or not npc:isValid() then return end
    if types.Actor.isDead(npc) then return end

    if not npc:hasScript(BH_SCRIPT) then
        npc:addScript(BH_SCRIPT)
    end
    npc:sendEvent("BH_KillSelf", {})
    log("FinishOff requested for", npc.recordId)
end

-- prisoner does not reappear (player teleported)
local function onPrisonerEscapedViaCellChange(data)
    local npcId = data and data.npcId
    if not npcId then return end
    pendingEscapeFlags[npcId] = true
    log("Pending force-escape queued for", npcId)
end

local function onRequestRemoval(npc)
    if not npc or not npc:isValid() then return end
    pendingEscapeFlags[npc.id] = nil
    core.sendGlobalEvent("GKD_ClearDisableKnockdown", { npcId = npc.id })
    if npc:hasScript(BH_SCRIPT) then
        npc:removeScript(BH_SCRIPT)
    end
end

local function onRequestRewardScriptRemoval(npc)
    if not npc or not npc:isValid() then return end
    if npc:hasScript(BH_REWARD_SCRIPT) then
        npc:removeScript(BH_REWARD_SCRIPT)
    end
end

local function onUpdateEscortState(data)
    currentPrisonerId = data.prisonerId
    for _, actor in ipairs(world.activeActors) do
        if actor:hasScript(GKO_SCRIPT) then
            actor:sendEvent("BH_PlayerEscortState", { prisonerId = currentPrisonerId })
        end
    end
end

local function onClaimReward(data)
    local fort = nil
    for _, f in ipairs(FORTS) do
        if f.id == data.fortId then fort = f; break end
    end
    if not fort then return end

    local npc    = data.npc
    local player = data.player
    if not npc    or not npc:isValid()    then return end
    if not player or not player:isValid() then return end

    local slotIdx, slotPos = findFreeSlot(fort)
    if not slotIdx then
        player:sendEvent("BH_ShowMessage", { message = fort.fullMessage })
        return
    end

    occupiedSlots[fort.id][slotIdx] = npc.id
    local freeAfter = countFreeSlots(fort)
    log("Slot", slotIdx, "reserved in", fort.id, ", free after:", freeAfter)

    local rewardPerLevel = data.rewardPerLevel or cachedSettings.REWARD_PER_LEVEL or 50
    local reward         = (data.npcLevel or 1) * rewardPerLevel
    local npcDisplayName = getRewardNpcName(fort)
    local msg = string.format(shared.MESSAGES.reward, npcDisplayName, reward)
    if freeAfter == 0 then
        msg = msg .. shared.MESSAGES.reward_last_slot
    end

    local goldStack = world.createObject("gold_001", reward)
    goldStack:moveInto(types.Actor.inventory(player))
    core.sound.playSound3d("Item Gold Up", player)
    player:sendEvent("BH_ShowMessage", { message = msg })

    local rewardNpcLower = FORT_REWARD_LOWER[fort.id]
    for _, actor in ipairs(world.activeActors) do
        if types.NPC.objectIsInstance(actor)
           and actor.recordId:lower() == rewardNpcLower
        then
            if not actor:hasScript(BH_REWARD_SCRIPT) then
                actor:addScript(BH_REWARD_SCRIPT)
            end
            actor:sendEvent("BH_PlayRewardAnimation", {})
            break
        end
    end

    npc:sendEvent("BH_WaitForDeportation", {
        fortId = fort.id,
        cell   = fort.prisonCell,
        pos    = slotPos,
        player = player,
    })
end

local function onDeportPrisoner(data)
    local npc  = data.npc
    local cell = data.cell
    local pos  = data.pos
    if not npc or not npc:isValid() then return end

    pendingEscapeFlags[npc.id] = nil
    core.sendGlobalEvent("GKD_ClearDisableKnockdown", { npcId = npc.id })

    local teleportPos = util.vector3(pos.x, pos.y, pos.z)
    npc:teleport(cell, teleportPos)
    log("Deported to prison:", cell)

    if npc:hasScript(BH_SCRIPT) then
        npc:removeScript(BH_SCRIPT)
    end
end

local function onRequestFortStatus(data)
    local player = data.player
    if not player or not player:isValid() then return end

    local fortStatus = {}
    for _, fort in ipairs(FORTS) do
        local free  = countFreeSlots(fort)
        local total = #fort.prisonSlots
        table.insert(fortStatus, {
            id            = fort.id,
            name          = fort.name or fort.id,
            rewardNpcName = fort.rewardNpcName or fort.rewardNpc,
            free          = free,
            total         = total,
        })
    end

    -- Send the calculated list back to the player script
    player:sendEvent("BH_ReceiveFortStatus", { forts = fortStatus })
end

return {
    engineHandlers = {
        onActorActive = onActorActive,
        onSave        = onSave,
        onLoad        = onLoad,
    },

    eventHandlers = {
        BH_SettingsUpdated              = onSettingsUpdated,
        BH_PrisonerKnockedOut           = onPrisonerKnockedOut,
        BH_StartEscort                  = onStartEscort,
        BH_FinishOffNpc                 = onFinishOffNpc,
        BH_PrisonerEscapedViaCellChange = onPrisonerEscapedViaCellChange,
        BH_RequestRemoval               = onRequestRemoval,
        BH_RequestRewardScriptRemoval   = onRequestRewardScriptRemoval,
        BH_UpdateEscortState            = onUpdateEscortState,
        BH_ClaimReward                  = onClaimReward,
        BH_DeportPrisoner               = onDeportPrisoner,
        BH_RequestFortStatus            = onRequestFortStatus,
    },
}