local types  = require("openmw.types")
local world  = require("openmw.world")
local core = require("openmw.core")
local shared = require("scripts.Rilms_shared")

local BLESSING_ID  = shared.BLESSING_ID
local PAUPER_CLASS = shared.PAUPER_CLASS
local DEFAULTS     = shared.DEFAULTS
local MESSAGES     = shared.MESSAGES

local cachedSettings = {
    DONATE_CHANCE = DEFAULTS.DONATE_CHANCE,
    MAX_DONATIONS = DEFAULTS.MAX_DONATIONS,
}

local donationCounts = {}
local activeNpcId    = nil

local function globals()
    return world.mwscript.getGlobalVariables()
end

local function persistState(player)
    player:sendEvent("RilmsSaveState", {
        donationCounts = donationCounts,
    })
end

local function processDonation(player)
    if not activeNpcId then return end
    local npcId = activeNpcId
    local count = donationCounts[npcId] or 0


    donationCounts[npcId] = count + 1

    if donationCounts[npcId] >= cachedSettings.MAX_DONATIONS then
        globals().rilms_npc_full = 1
    end

    if math.random() < cachedSettings.DONATE_CHANCE then
        types.Actor.spells(player):add(BLESSING_ID)
        core.sound.playSound3d("skillraise", player)
        globals().rilms_blessed = 1
        donationCounts = {}
        globals().rilms_npc_full = 0
        persistState(player)
        player:sendEvent("RilmsMessage", { message = MESSAGES.success })
    else
        persistState(player)
        player:sendEvent("RilmsMessage", { message = MESSAGES.failure })
    end
end

return {
    engineHandlers = {
        onActorActive = function(actor)
            if not types.NPC.objectIsInstance(actor) then return end
            if types.Actor.isDead(actor) then return end
            local classId = types.NPC.record(actor).class
            if classId and classId:lower() == PAUPER_CLASS and globals().rilms_blessed == 0 then
                actor:addScript("scripts/rilms_local.lua")
            end
        end,
        onUpdate = function(dt)
            local g = globals()
            if not g.rilms_donate_flag or g.rilms_donate_flag == 0 then return end
            g.rilms_donate_flag = 0
            local player = nil
            for _, actor in ipairs(world.activeActors) do
                if types.Player.objectIsInstance(actor) then
                    player = actor
                    break
                end
            end
            if not player then return end
            processDonation(player)
        end,
    },
    eventHandlers = {
        Rilms_SettingsUpdated = function(data)
            cachedSettings = data
        end,
        RilmsSetActiveNpc = function(data)
            if data and data.npcId then
                activeNpcId = data.npcId
            end
        end,
        RilmsUpdateNpcFull = function(data)
            if not data or not data.npcId then return end
            local count = donationCounts[data.npcId] or 0
            globals().rilms_npc_full = (count >= cachedSettings.MAX_DONATIONS) and 1 or 0
        end,
        RilmsRestoreState = function(data)
            if data.donationCounts then donationCounts = data.donationCounts end
        end,
    },
}