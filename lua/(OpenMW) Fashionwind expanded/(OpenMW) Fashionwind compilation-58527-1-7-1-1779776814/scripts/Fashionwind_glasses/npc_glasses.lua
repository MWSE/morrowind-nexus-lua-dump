local self  = require('openmw.self')
local types = require('openmw.types')
local anim  = require('openmw.animation')
local vfs   = require('openmw.vfs')

local Actor = types.Actor

local VFX_ID   = 'visibleGlasses'
local VFX_BONE = 'head'

local GLASSES_RECORD_IDS = {
    ['_rv_blindfold1']  = true,
    ['_rv_eyepatch1l']  = true,
    ['_rv_eyepatch1r']  = true,
    ['_rv_glasses1']    = true,
    ['_rv_glasses1s']   = true,
    ['_rv_glasses2']    = true,
    ['_rv_glasses2s']   = true,
    ['_rv_glasses3']    = true,
    ['_rv_glasses4']    = true,
    ['_rv_glasses4s']   = true,
    ['_rv_goggles1']    = true,
    ['_rv_goggles2']    = true,
    ['_rv_goggles3']    = true,
    ['_rv_goggles4']    = true,
    ['_rv_goggles5']    = true,
    ['_rv_goggles6']    = true,
    ['_rv_goggles7']    = true,
    ['_rv_goggles8']    = true,
    ['_rv_lenses1']     = true,
    ['_rv_lenses2']     = true,
}

local vfxGlasses = { loop = true, useAmbientLight = false, vfxId = VFX_ID }

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

local function findGlassesItem()
    for _, item in ipairs(Actor.inventory(self):getAll()) do
        local recId = getRecordId(item)
        if recId and GLASSES_RECORD_IDS[recId] then
            return item
        end
    end
    return nil
end

local lastSkins = false  

local function scanInv(force)
    local item  = findGlassesItem()
    local skins = item and getSkinsPath(item) or nil

    if not force and skins == lastSkins then return end
    lastSkins = skins

    anim.removeVfx(self, VFX_ID)
    if not skins then return end

    vfxGlasses.boneName = VFX_BONE
    anim.addVfx(self, skins, vfxGlasses)
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
