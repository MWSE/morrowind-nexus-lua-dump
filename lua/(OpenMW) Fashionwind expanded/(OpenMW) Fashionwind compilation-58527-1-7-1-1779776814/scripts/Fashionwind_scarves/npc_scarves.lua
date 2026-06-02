-- npc_scarves.lua
-- NPC local script: shows cosmetic scarves as visible 3D items on NPCs.
--
-- Scans the NPC's inventory for any known scarf item and attaches
-- the corresponding _skins.nif to the 'ScarfNeck' bone via addVfx.
-- Only the first matching item found is shown.
--
-- OMWSCRIPTS ENTRY:
--   NPC: scripts/yourmod/npc_scarves.lua

local self  = require('openmw.self')
local types = require('openmw.types')
local anim  = require('openmw.animation')
local vfs   = require('openmw.vfs')

local Actor = types.Actor

local VFX_ID   = 'visibleScarves'
local VFX_BONE = 'ScarfNeck'

local SCARVES_RECORD_IDS = {
    ['_rv_scarf01'] = true,
    ['_rv_scarf02'] = true,
    ['_rv_scarf03'] = true,
    ['_rv_scarf04'] = true,
    ['_rv_scarf05'] = true,
    ['_rv_scarf06'] = true,
    ['_rv_scarf07'] = true,
    ['_rv_scarf08'] = true,
    ['_rv_scarf09'] = true,
    ['_rv_scarf10'] = true,
    ['_rv_scarf11'] = true,
    ['_rv_scarf12'] = true,
    ['_rv_scarf13'] = true,
    ['_rv_scarf14'] = true,
    ['_rv_scarf15'] = true,
    ['_rv_scarf16'] = true,
}

local vfxScarves = { loop = true, useAmbientLight = false, vfxId = VFX_ID }

local modelCache = {}

local function getRecordId(item)
    local ok, rec = pcall(types.Clothing.record, item)
    if ok and rec and rec.id then return rec.id:lower() end
    ok, rec = pcall(types.Armor.record, item)
    if ok and rec and rec.id then return rec.id:lower() end
    return nil
end

local function getSkinsPath(item)
    local id = item.recordId
    if modelCache[id] ~= nil then return modelCache[id] end
    local ok, rec = pcall(function() return item.type.records[id] end)
    if not ok or not rec or not rec.model then
        modelCache[id] = nil
        return nil
    end
    local path = rec.model:lower()
    path = path:gsub('_gnd%.nif$', ''):gsub('%.nif$', '')
    local folder = path:match('^(.*[/\\])') or ''
    local fname  = path:match('([^/\\]+)$') or path
    local skins  = folder .. fname .. '_skins.nif'
    if not vfs.fileExists(skins) then skins = nil end
    modelCache[id] = skins
    return skins
end

local function findScarfItem()
    for _, item in ipairs(Actor.inventory(self):getAll()) do
        local recId = getRecordId(item)
        if recId and SCARVES_RECORD_IDS[recId] then
            return item
        end
    end
    return nil
end

local lastSkins = false  -- false = uninitialized, nil = none found, string = path

local function scanInv(force)
    local item  = findScarfItem()
    local skins = item and getSkinsPath(item) or nil

    if not force and skins == lastSkins then return end
    lastSkins = skins

    anim.removeVfx(self, VFX_ID)
    if not skins then return end

    vfxScarves.boneName = VFX_BONE
    anim.addVfx(self, skins, vfxScarves)
end

-- ---------------------------------------------------------------------------
-- Engine handlers
-- ---------------------------------------------------------------------------

local FRAME_SKIP = 20
local counter    = math.random(3, FRAME_SKIP)
local needScan   = true

local function onActive()
    needScan  = true
    lastSkins = false
    counter   = 1
end

local function onUpdate(dt)
    if dt == 0 then return end
    if needScan then needScan = false; scanInv(true); counter = FRAME_SKIP; return end
    counter = counter - 1
    if counter <= 0 then counter = FRAME_SKIP; scanInv(false) end
end

return {
    engineHandlers = {
        onUpdate = onUpdate,
        onActive = onActive,
    },
    eventHandlers = {
        vfxRemoveAll = function()
            lastSkins = false
            counter   = math.random(11, 16)
            needScan  = true
        end,
        equipped   = function() needScan = true end,
        unequipped = function() needScan = true end,
    },
}
