local self  = require('openmw.self')
local types = require('openmw.types')
local anim  = require('openmw.animation')
local vfs   = require('openmw.vfs')

local Actor = types.Actor

local VFX_ID   = 'visibleEarrings'
local VFX_BONE = 'head'

local EARRINGS_RECORD_IDS = {
    ['_earrings_01']  = true,
    ['_earrings_02']  = true,
    ['_earrings_03']  = true,
    ['_earrings_03a'] = true,
    ['_kd_femgdia']   = true,
    ['_kd_femgem']    = true,
    ['_kd_femgru']    = true,
    ['_kd_femgsa']    = true,
    ['_kd_femsdia']   = true,
    ['_kd_femsem']    = true,
    ['_kd_femsru']    = true,
    ['_kd_femssa']    = true,
    ['_kd_g01']       = true,
    ['_kd_g01r']      = true,
    ['_kd_g02']       = true,
    ['_kd_g02r']      = true,
    ['_kd_g03']       = true,
    ['_kd_g03r']      = true,
    ['_kd_g04']       = true,
    ['_kd_g04r']      = true,
    ['_kd_g05']       = true,
    ['_kd_g05r']      = true,
    ['_kd_g06']       = true,
    ['_kd_g06r']      = true,
    ['_kd_s01']       = true,
    ['_kd_s01r']      = true,
    ['_kd_s02']       = true,
    ['_kd_s02r']      = true,
    ['_kd_s03']       = true,
    ['_kd_s03r']      = true,
    ['_kd_s04']       = true,
    ['_kd_s04r']      = true,
    ['_kd_s05']       = true,
    ['_kd_s05r']      = true,
    ['_kd_s06']       = true,
    ['_kd_s06r']      = true,
}

local vfxEarrings = { loop = true, useAmbientLight = false, vfxId = VFX_ID }

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

local function findEarringsItem()
    for _, item in ipairs(Actor.inventory(self):getAll()) do
        local recId = getRecordId(item)
        if recId and EARRINGS_RECORD_IDS[recId] then
            return item
        end
    end
    return nil
end

local lastSkins = false

local function scanInv(force)
    local item  = findEarringsItem()
    local skins = item and getSkinsPath(item) or nil

    if not force and skins == lastSkins then return end
    lastSkins = skins

    anim.removeVfx(self, VFX_ID)
    if not skins then return end

    vfxEarrings.boneName = VFX_BONE
    anim.addVfx(self, skins, vfxEarrings)
end


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
