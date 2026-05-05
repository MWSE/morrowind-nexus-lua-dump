local self    = require("openmw.self")
local types   = require("openmw.types")
local anim    = require("openmw.animation")
local vfs     = require("openmw.vfs")
local storage = require("openmw.storage")

local cloakEnabled = true

local function refreshCloakSetting()
    local ok, settings = pcall(storage.globalSection, "Settings_tt_visiblecloaks")
    if ok and settings then
        local v = settings:get("CLOAKNPC")
        if v ~= nil then
            cloakEnabled = (v ~= false)
        end
    end
end

refreshCloakSetting()

local Actor = types.Actor

local itemModels = {}

local function getModel(o)
   local id = o.recordId
   if itemModels[id] ~= nil then return itemModels[id] end
   local model = o.type.records[id].model:lower()
   model = model:gsub("_gnd%.nif$", ".nif")
   model = model:gsub("%.nif$",     "_skins.nif")
   if not vfs.fileExists(model) then model = "" end
   itemModels[id] = model
   return model
end

local VFX_ID  = "visibleItemsCuirass"
local vfxItem = { loop=true, useAmbientLight=false, vfxId=VFX_ID }

local devMode = false
local function debug(m)
   if devMode then print(m) end
end

local lastPos    = nil
local frameSpeed = 0

local function updateFrameSpeed()
   local pos = self.position
   if not lastPos then
       lastPos    = pos
       frameSpeed = 0
       return
   end
   local dx = pos.x - lastPos.x
   local dy = pos.y - lastPos.y
   lastPos    = pos
   frameSpeed = math.sqrt(dx * dx + dy * dy)
end

local function getMotionSuffix()
   local walkSpeed = Actor.getWalkSpeed(self)
   local runSpeed  = Actor.getRunSpeed(self)

   if walkSpeed <= 0 or runSpeed <= 0 then
       if frameSpeed < 1 then return '_skins.nif'
       elseif frameSpeed < 3 then return '_skins1.nif'
       else return '_skins3.nif' end
   end

   local walkThresh = walkSpeed / 60
   local runThresh  = runSpeed  / 60

   if frameSpeed < walkThresh * 0.4 then
       return '_skins.nif'
   elseif frameSpeed < runThresh * 0.6 then
       return '_skins1.nif'
   else
       return '_skins3.nif'
   end
end

local function getAvailableSuffix(basePath, preferredSuffix)
   if vfs.fileExists(basePath .. preferredSuffix) then
       return preferredSuffix
   end
   if vfs.fileExists(basePath .. '_skins.nif') then
       return '_skins.nif'
   end
   return nil
end

local function getBasePath(skinsPath)
   return skinsPath:gsub('_skins%.nif$', '')
end

local function applyMotionVfx(skinsPath, suffix)
   local basePath        = getBasePath(skinsPath)
   local availableSuffix = getAvailableSuffix(basePath, suffix)
   if not availableSuffix then
       debug('No vfx file found for: ' .. basePath)
       return false
   end
   local targetPath = basePath .. availableSuffix
   debug('cuirass motion vfx: ' .. targetPath)
   anim.removeVfx(self, VFX_ID)
   vfxItem.boneName = 'MEH'
   anim.addVfx(self, targetPath, vfxItem)
   return true
end

local SLOT             = Actor.EQUIPMENT_SLOT
local lastEquipped     = nil
local lastMotionSuffix = nil
local needScan         = true

local function scanInv(reset)
   if not cloakEnabled then
       anim.removeVfx(self, VFX_ID)
       lastEquipped     = nil
       lastMotionSuffix = nil
       return
   end

   local eq      = Actor.equipment(self)
   local cuirass = eq[SLOT.Cuirass]

   local currentSuffix = getMotionSuffix()
   local equipChanged  = reset or (cuirass ~= lastEquipped)
   local motionChanged = cuirass and (currentSuffix ~= lastMotionSuffix)

   if not equipChanged and not motionChanged then return end

   if equipChanged then
       debug('cuirass: remove vfx (equip change)')
       anim.removeVfx(self, VFX_ID)
       lastMotionSuffix = nil
   end

   if cuirass then
       local m = getModel(cuirass)
       if m ~= "" then
           local applied = applyMotionVfx(m, currentSuffix)
           if applied then
               lastEquipped     = cuirass
               lastMotionSuffix = currentSuffix
           end
       else
           lastEquipped = cuirass
       end
   else
       lastEquipped     = nil
       lastMotionSuffix = nil
       if equipChanged then
           anim.removeVfx(self, VFX_ID)
       end
   end
end

local FRAME_SKIP = 20
local counter    = math.random(3, FRAME_SKIP)

local function onActive()
    refreshCloakSetting()
    needScan = true
    counter  = 1
end

local function onUpdate(dt)
   if dt == 0 then return end

   updateFrameSpeed()

   if needScan then scanInv(true); needScan = false; counter = FRAME_SKIP; return end
   counter = counter - 1
   if counter <= 0 then counter = FRAME_SKIP; scanInv(false) end
end

return {
 engineHandlers = {
    onUpdate = onUpdate,
    onActive = onActive,
	onLoad   = function() refreshCloakSetting(); needScan = true end,
 },
 eventHandlers = {
    vfxRemoveAll    = function() counter = 1; needScan = true end,
    equipped        = function() needScan = true end,
    unequipped      = function() needScan = true end,
    cloakNpcToggled = function(data)
        cloakEnabled = data.enabled
        needScan     = true
        counter      = 1
    end,
 },
}