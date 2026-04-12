local self    = require('openmw.self')
local types   = require('openmw.types')
local anim    = require('openmw.animation')
local ui      = require('openmw.ui')
local async   = require('openmw.async')
local camera  = require('openmw.camera')
local storage = require('openmw.storage')
local input   = require('openmw.input')
local I       = require('openmw.interfaces')

local Actor = types.Actor
local MD    = { first = camera.MODE.FirstPerson, third = camera.MODE.ThirdPerson }

local cam     = camera.getMode()
local devMode = false

local VFX_ID     = 'visibleGlasses'
local vfxGlasses = { loop = true, useAmbientLight = false, vfxId = VFX_ID }

local glassesListIndex = storage.playerSection('Settings_tt_fashionwind_glasses_cycle')
local headBoneOwner    = storage.playerSection('Settings_tt_gl')

local function getGlassesIndex()  return glassesListIndex:get('cycleIndex') or 1 end
local function setGlassesIndex(n) glassesListIndex:set('cycleIndex', n) end

local function getShowGlasses()   return glassesListIndex:get('showGlasses') == true end
local function setShowGlasses(v)  glassesListIndex:set('showGlasses', v) end

local function claimHeadBone() headBoneOwner:set('owner', 'glasses') end
local function headIsOurs()
   local owner = headBoneOwner:get('owner')
   return owner == nil or owner == 'glasses'
end

local glassesList = {
   'blindfold1', 'eyepatch1L', 'eyepatch1R',
   'glasses1s', 'glasses1', 'glasses2s', 'glasses2',
   'glasses3', 'glasses4s', 'glasses4',
   'goggles1', 'goggles2', 'goggles3', 'goggles4',
   'Lenses2', 'goggles5', 'goggles6', 'goggles7', 'goggles8', 'Lenses1',
}

local function buildStemMap()
   local stemMap = {}
   for _, item in ipairs(Actor.inventory(self):getAll()) do
       local ok, rec = pcall(function() return item.type.records[item.recordId] end)
       if ok and rec and rec.model then
           local path = rec.model:lower()
           path = path:gsub('_gnd%.nif$', ''):gsub('%.nif$', '')
           local folder = path:match('^(.*[/\\])') or ''
           local fname  = path:match('([^/\\]+)$') or path
           stemMap[fname] = folder .. fname .. '_skins.nif'
       end
   end
   return stemMap
end

local function getAvailableGlasses()
   local stemMap   = buildStemMap()
   local available = {}
   for _, stem in ipairs(glassesList) do
       local skinsPath = stemMap[stem:lower()]
       if skinsPath then available[#available + 1] = { stem = stem, skins = skinsPath } end
   end
   return available
end

local showGlasses        = getShowGlasses()
local GlassesKeyWasDown  = false
local GvariantKeyWasDown = false

local counter   = math.random(3, 20)
local refresh   = true
local newEquip  = false
local useHelper = false
local lastSkins = nil

local function debug(m)
   if devMode then print(m); ui.showMessage(m) end
end

local function scanInv(reset)
   newEquip = false
   refresh  = false

   local availGlasses = getAvailableGlasses()
   local gIdx         = getGlassesIndex()
   if gIdx > #availGlasses then gIdx = math.max(#availGlasses, 1) end
   local activeSkins  = availGlasses[gIdx] and availGlasses[gIdx].skins or nil

   local changed = (activeSkins ~= lastSkins) or reset
   if not changed then return end
   lastSkins = activeSkins

   debug('glasses: remove vfx')
   anim.removeVfx(self, VFX_ID)

   if showGlasses and activeSkins and cam ~= MD.first and headIsOurs() then
       debug('glasses vfx: ' .. activeSkins)
       vfxGlasses.boneName = 'head'
       anim.addVfx(self, activeSkins, vfxGlasses)
   end
end

local function onInit()
   if showGlasses then
       claimHeadBone()
       counter = 3
       refresh = true
   end
end

local function onFrame(dt)

   local keyDown = input.getBooleanActionValue('GLShow')
   if keyDown and not GlassesKeyWasDown then
       showGlasses = not showGlasses
       setShowGlasses(showGlasses)
       if showGlasses then claimHeadBone() end
       counter = 1
       refresh = true
       debug('Glasses VFX: ' .. (showGlasses and 'ON' or 'OFF'))
   end
   GlassesKeyWasDown = keyDown

   local gVarKeyDown = input.getBooleanActionValue('GLChange')
   if gVarKeyDown and not GvariantKeyWasDown then
       local availGlasses = getAvailableGlasses()
       if #availGlasses > 0 then
           showGlasses = true
           setShowGlasses(showGlasses)
           claimHeadBone()
           local cur = getGlassesIndex()
           if cur > #availGlasses then cur = #availGlasses end
           local nxt = cur % #availGlasses + 1
           setGlassesIndex(nxt)
           counter = 1
           refresh = true
           debug('Glasses: ' .. availGlasses[nxt].stem .. ' (' .. nxt .. '/' .. #availGlasses .. ')')
       else
           debug('Glasses: none available in inventory')
       end
   end
   GvariantKeyWasDown = gVarKeyDown

   if newEquip then scanInv(refresh) end
   counter = counter - 1
   if counter > 0 then return end
   counter = 20
   if refresh or not useHelper then scanInv(refresh) end
end

local function onUpdate(dt)
   if dt == 0 then return end
   if cam == camera.getMode() then return end
   local mode, fp = camera.getMode(), MD.first
   if mode == fp or cam == fp then
       cam = mode
       counter = 3
       refresh = true
   end
   cam = mode
end

return {
   engineHandlers = { onUpdate = onUpdate, onFrame = onFrame, onInit = onInit },
   eventHandlers  = {
       UiModeChanged = function(e)
           local uiModes = {
               [I.UI.MODE.Rest]     = true,
               [I.UI.MODE.Training] = true,
               [I.UI.MODE.Travel]   = true,
           }
           if uiModes[e.oldMode] then
               counter = 3
               refresh = true
           end
       end,
       olhInitialized = function()
           useHelper = true
           I.luaHelper.eventRegister('equipped',   function() newEquip = true end)
           I.luaHelper.eventRegister('unequipped', function() newEquip = true end)
       end,
       vfxRemoveAll = function()
           counter = math.random(11, 16)
           refresh = true
       end,
   },
}