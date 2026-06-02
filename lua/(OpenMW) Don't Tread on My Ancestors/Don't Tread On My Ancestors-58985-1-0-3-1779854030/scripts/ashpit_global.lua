local world = require('openmw.world')
local types = require('openmw.types')
local core  = require('openmw.core')
local async = require('openmw.async')

local shared = require('scripts.ashpit_shared')

local PLAYER_SCRIPT = 'scripts/ashpit_player.lua'
local UNDEAD_SCRIPT = 'scripts/ashpit_undead.lua'

local ASHPIT_IDS = shared.ASHPIT_IDS

local Static_isInstance = types.Static.objectIsInstance

local function isAshpitType(obj)
    return Static_isInstance(obj)
end

local function isAshpitRecord(idLower)
    return ASHPIT_IDS[idLower] == true
end

local function cellMatches(fcell, desc)
    if not fcell or not desc then return false end
    if (fcell.isExterior and true or false) ~= desc.isExterior then return false end
    if desc.isExterior then
        return (fcell.gridX or 0) == desc.gridX
           and (fcell.gridY or 0) == desc.gridY
    end
    return (fcell.name or '') == desc.name
end

local function isCellBlacklisted(desc)
    if not desc or desc.isExterior then return false end
    
    local cellName = (desc.name or ""):lower()
    for _, keyword in ipairs(shared.BLACKLISTED_CELLS) do
        if cellName:match(keyword) then
            return true
        end
    end
    return false
end

local activeAshpits = {}

-- while any hostile undead from this mod is alive, no further spawns of any kind are permitted
local activeHostile = {}

local S = {}
for k, v in pairs(shared.DEFAULTS) do S[k] = v end

local function log(msg)
    if S.PRINT_LOG then
        print('[AshpitUndead G] ' .. msg)
    end
end

local function applySettings(data)
    if not data then return end
    for k in pairs(S) do
        if data[k] ~= nil then S[k] = data[k] end
    end
end

local function hostileCount()
    local n = 0
    for _ in pairs(activeHostile) do n = n + 1 end
    return n
end

local function ensurePlayerScript(player)
    if not player:hasScript(PLAYER_SCRIPT) then
        player:addScript(PLAYER_SCRIPT)
    end
end

local function getPlayer()
    local p = world.players[1]
    if p and p:isValid() then return p end
    return nil
end

local function onObjectActive(obj)
    if not isAshpitType(obj) then return end

    local id = obj.recordId
    if not id then return end
    if not isAshpitRecord(id:lower()) then return end

    activeAshpits[obj.id] = obj

    local player = getPlayer()
    if player then
        ensurePlayerScript(player)
        player:sendEvent('AddAshpit', obj)
    end
end

local function onRequestAshpitScan(data)
    local player = getPlayer()
    if not player then return end
    ensurePlayerScript(player)

    local desc = data and data.cell

    if isCellBlacklisted(desc) then
        player:sendEvent('UpdateAshpitList', {})
        return
    end

    local list, n = {}, 0

    for pid, pobj in pairs(activeAshpits) do
        local keep = false
        if pobj:isValid() and pobj.count > 0 then
            if cellMatches(pobj.cell, desc) then
                keep = true
            end
        end
        if keep then
            n = n + 1
            list[n] = pobj
        else
            activeAshpits[pid] = nil
        end
    end

    player:sendEvent('UpdateAshpitList', list)
end

local function onAshpitSummon(data)
    if not data then return end
    local actor = data.actor
    if not actor or not actor:isValid() then return end

    -- no spawns of any kind while hostile undead are alive
    if hostileCount() > 0 then return end

    local mode        = data.mode or "hostile"
    local positions   = data.positions or {}
    local count       = data.spawnCount or 1
    local playerLevel = data.playerLevel or 1
    local followerDuration = data.followerDuration or 300

    if count < 1 then return end

    local spawned = {}
    local creatureName = nil

    for i = 1, count do
        local id = shared.pickWeightedUndead(playerLevel)
        if id then
            local pos = positions[i]
            if not pos then break end

            local undead = world.createObject(id)
            if undead then
                undead:teleport(actor.cell, pos, { onGround = true })
                log(('spawned "%s" mode=%s at z=%.1f'):format(tostring(id), mode, pos.z))

                undead:addScript(UNDEAD_SCRIPT)
                undead:sendEvent("Ashpit_PlayVFX_Self", {})

                -- defer sound by one frame so the freshly-created actor
                local soundTarget = undead
                async:newUnsavableSimulationTimer(0.05, function()
                    if soundTarget and soundTarget:isValid() then
                        core.sound.playSoundFile3d('Sound\\spawn_sound_by_PeterBitt.wav', soundTarget)
                    end
                end)

                if mode == "follower" then
                    undead:sendEvent("Ashpit_BeginFollower", {
                        target   = actor,
                        duration = followerDuration,
                    })
                else
                    activeHostile[undead.id] = true
                    undead:sendEvent("Ashpit_BeginHostile", {
                        target = actor,
                    })
                end

                -- ask the player script to track this undead for its watchdog
                actor:sendEvent("Ashpit_TrackUndead", {
                    undead = undead,
                    mode   = mode,
                })

                creatureName = shared.CREATURE_NAMES[id] or id
                spawned[#spawned + 1] = undead
            end
        end
    end

    if #spawned > 0 and creatureName then
        local msgList = (mode == "follower") and shared.MESSAGES_FOLLOWER or shared.MESSAGES_HOSTILE
        local msg = msgList[math.random(#msgList)]
        actor:sendEvent("Ashpit_ShowMessage", { message = msg })
    end
end

-- sent by the undead's local script on death or follower expiry
local function onAshpitUndeadInactive(data)
    if not data or not data.undead then return end
    local u = data.undead
    if activeHostile[u.id] then
        activeHostile[u.id] = nil
    end
    -- untrack from player watchdog
    local player = getPlayer()
    if player then
        player:sendEvent("Ashpit_UntrackUndead", { undead = u })
    end
    if u and u:isValid() and u.count > 0 then
        core.sound.playSoundFile3d('Sound\\despawn_sound_by_PeterBitt.wav', u)
        u:remove()
    end
end

-- sent by the player watchdog when an undead is no longer in the player's cell
local function onAshpitDespawnLost(data)
    if not data or not data.undead then return end
    local u = data.undead
    if activeHostile[u.id] then
        activeHostile[u.id] = nil
    end
    if u and u:isValid() and u.count > 0 then
        u:remove()
    end
end

local function onAshpitRegisterHostile(data)
    if data and data.undead and data.undead:isValid() then
        activeHostile[data.undead.id] = true
    end
end

local function onAshpitSettingsUpdated(data)
    applySettings(data)
end

local function onSave()
    return {}
end

local function onLoad(_)
    activeAshpits = {}
    activeHostile = {}
end

return {
    engineHandlers = {
        onObjectActive = onObjectActive,
        onSave         = onSave,
        onLoad         = onLoad,
    },
    eventHandlers = {
        RequestAshpitScan      = onRequestAshpitScan,
        Ashpit_Summon          = onAshpitSummon,
        Ashpit_UndeadInactive  = onAshpitUndeadInactive,
        Ashpit_DespawnLost     = onAshpitDespawnLost,
        Ashpit_RegisterHostile = onAshpitRegisterHostile,
        Ashpit_SettingsUpdated = onAshpitSettingsUpdated,
    },
}