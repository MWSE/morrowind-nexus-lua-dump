local world = require('openmw.world')
local types = require('openmw.types')
local util = require('openmw.util')

local cfg = require('scripts.slyropes.config')

local v3 = util.vector3
local transform = util.transform

local helpersByPlayer = {}
local recordReady = false
local recordFailed = false
local generatedCollisionRecordId = nil
local createFailureLogged = false

local function log(msg)
    if cfg.DEBUG then
        print('[Sly Nerevarine] ' .. msg)
    end
end

local function ensureCollisionRecord()
    if recordReady and generatedCollisionRecordId then
        return true
    end
    if recordFailed then
        return false
    end

    -- OpenMW's current world.createRecord support does not include StaticRecord.
    -- It does include ActivatorRecord, and createRecord ignores the provided id and returns a generated id.
    -- The previous v0.4 attempted to create a StaticRecord and then createObject(cfg.COLLISION_RECORD_ID),
    -- which made createObject fail with "unknown ID" despite the misleading success log.
    local ok, recOrErr = pcall(function()
        local draft = types.Activator.createRecordDraft({
            id = cfg.COLLISION_RECORD_ID,
            model = cfg.COLLISION_MODEL,
        })
        return world.createRecord(draft)
    end)

    if ok and recOrErr and recOrErr.id then
        generatedCollisionRecordId = recOrErr.id
        recordReady = true
        log('created runtime activator collision record: requested=' .. cfg.COLLISION_RECORD_ID .. ', actual=' .. tostring(generatedCollisionRecordId))
        return true
    end

    recordFailed = true
    log('failed to create collision activator record: ' .. tostring(recOrErr))
    return false
end

local function playerKey(player)
    if player and player.isValid and player:isValid() then
        return player.id or 'player'
    end
    return 'player'
end

local function makeHelper()
    if not ensureCollisionRecord() then
        return nil
    end

    local ok, objOrErr = pcall(function()
        return world.createObject(generatedCollisionRecordId)
    end)
    if ok and objOrErr then
        return objOrErr
    end

    if not createFailureLogged then
        createFailureLogged = true
        log('failed to create collision helper object using record ' .. tostring(generatedCollisionRecordId) .. ': ' .. tostring(objOrErr))
    end
    return nil
end

local function ensureHelpers(player)
    local key = playerKey(player)
    local pair = helpersByPlayer[key]
    if not pair then
        pair = {}
        helpersByPlayer[key] = pair
    end

    if not pair.primary or not pair.primary:isValid() then
        pair.primary = makeHelper()
    end

    if cfg.USE_CROSS_HELPER and (not pair.cross or not pair.cross:isValid()) then
        pair.cross = makeHelper()
    end

    return pair
end

local function cleanupPair(pair)
    if not pair then
        return
    end
    if pair.primary and pair.primary:isValid() then
        pcall(function() pair.primary:remove() end)
    end
    if pair.cross and pair.cross:isValid() then
        pcall(function() pair.cross:remove() end)
    end
    pair.primary = nil
    pair.cross = nil
    pair.lockedRotation = nil
end

local function baseRotation(pair, player, rope)
    if cfg.ALIGNMENT_MODE == 'locked-player' then
        if not pair.lockedRotation and player and player:isValid() then
            pair.lockedRotation = player.rotation
        end
        return pair.lockedRotation or transform.identity
    end
    if cfg.ALIGNMENT_MODE == 'rope' and rope and rope:isValid() then
        return rope.rotation
    end
    if cfg.ALIGNMENT_MODE == 'world-x' then
        return transform.identity
    end
    if cfg.ALIGNMENT_MODE == 'world-y' then
        return transform.rotateZ(math.rad(90))
    end
    if player and player:isValid() then
        return player.rotation
    end
    return transform.identity
end

local function withYawOffset(rot, degrees)
    local deg = tonumber(degrees) or 0
    if deg == 0 then
        return rot
    end
    return rot * transform.rotateZ(math.rad(deg))
end

local function moveHelper(helper, cell, position, rotation)
    if not helper or not helper:isValid() or not cell then
        return false
    end

    local ok, err = pcall(function()
        helper:teleport(cell, position, { rotation = rotation, onGround = false })
    end)
    if ok then
        return true
    end

    -- Compatibility fallback for older Lua API variants.
    ok, err = pcall(function()
        helper:teleport(cell, position, rotation)
    end)
    if ok then
        return true
    end

    log('failed to move collision helper: ' .. tostring(err))
    return false
end

local function onMoveCollision(data)
    local player = data and data.player
    local supportPos = data and (data.supportPos or data.hitPos)
    if not player or not player:isValid() or not player.cell or not supportPos then
        return
    end

    local pair = ensureHelpers(player)
    if not pair or not pair.primary then
        return
    end

    -- supportPos is a local visual rope hit/patch, not the player's current position.
    local centerZ = supportPos.z + cfg.HELPER_TOP_OFFSET - cfg.HELPER_HALF_HEIGHT
    local pos = v3(supportPos.x, supportPos.y, centerZ)
    local rot = withYawOffset(baseRotation(pair, player, data.rope), cfg.ROPE_EXTRA_YAW_DEGREES)

    moveHelper(pair.primary, player.cell, pos, rot)

    if cfg.USE_CROSS_HELPER and pair.cross then
        moveHelper(pair.cross, player.cell, pos, rot * transform.rotateZ(math.rad(90)))
    end
end

local function onStopCollision(data)
    local player = data and data.player
    local key = playerKey(player)
    local pair = helpersByPlayer[key]
    cleanupPair(pair)
    helpersByPlayer[key] = nil
end

local function onSave()
    for key, pair in pairs(helpersByPlayer) do
        cleanupPair(pair)
        helpersByPlayer[key] = nil
    end
    return {}
end

return {
    engineHandlers = {
        onInit = function()
            ensureCollisionRecord()
            log('global collision helper loaded')
        end,
        onSave = onSave,
    },
    eventHandlers = {
        SlyRopes_MoveCollision = onMoveCollision,
        SlyRopes_StopCollision = onStopCollision,
    },
}
