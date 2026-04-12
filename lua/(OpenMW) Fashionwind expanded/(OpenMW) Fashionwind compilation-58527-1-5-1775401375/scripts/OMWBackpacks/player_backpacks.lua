local self    = require("openmw.self")
local types   = require("openmw.types")
local anim    = require("openmw.animation")
local ui      = require("openmw.ui")
local async   = require("openmw.async")
local camera  = require("openmw.camera")
local vfs     = require("openmw.vfs")
local storage = require("openmw.storage")
local input   = require("openmw.input")
local I       = require("openmw.interfaces")

local Actor = types.Actor
local MD    = { first = camera.MODE.FirstPerson, third = camera.MODE.ThirdPerson }

local cam     = camera.getMode()
local devMode = false

local VFX_ID = "visibleBackpacks"

local backSettings = storage.playerSection('Settings_tt_FashionBPC')

local BACK_SPELL_ID = "fx_Backpack"

local vfxBackpacks = { loop = true, useAmbientLight = false, vfxId = VFX_ID }
local BUFF_SPELLS = {
    BACK_SPELL_ID,
    }

local function applyBackpackBuffs(actor)
    for _, spellId in ipairs(BUFF_SPELLS) do
        Actor.spells(actor):add(spellId)
    end
end

local function removeBackpackBuffs(actor)
    for _, spellId in ipairs(BUFF_SPELLS) do
        Actor.spells(actor):remove(spellId)
    end
end							

local backpackListIndex = storage.playerSection("backpack_cycle")

local function getBackpackIndex()
   return backpackListIndex:get("cycleIndex") or 1
end

local function setBackpackIndex(n)
   backpackListIndex:set("cycleIndex", n)
end

local function getShowBackpack()
   return backpackListIndex:get("showBackpack") or false
end

local function setShowBackpack(val)
   backpackListIndex:set("showBackpack", val)
end

local backpackList = {
   "0_bag",
   "backpack",
}

local function buildStemMap()
   local stemMap = {}
   for _, item in ipairs(Actor.inventory(self):getAll()) do
       local ok, rec = pcall(function()
           return item.type.records[item.recordId]
       end)
       if ok and rec and rec.model then
           local path = rec.model:lower()
           path = path:gsub("_gnd%.nif$", ""):gsub("%.nif$", "")
           local folder = path:match("^(.*[/\\])") or ""
           local fname  = path:match("([^/\\]+)$") or path
           stemMap[fname] = folder .. fname .. "_skins.nif"
       end
   end
   return stemMap
end

local function getAvailableBackpacks()
   local stemMap   = buildStemMap()
   local available = {}
   for _, stem in ipairs(backpackList) do
       local skinsPath = stemMap[stem:lower()]
       if skinsPath then
           available[#available + 1] = { stem = stem, skins = skinsPath }
       end
   end
   return available
end

local showBackpack       = getShowBackpack()
local BPShowLastFrame    = false
local BPChangeLastFrame  = false

local counter         = math.random(3, 20)
local refresh         = true
local newEquip        = false
local useHelper       = false
local lastSkins       = nil
local debounceCounter = 0

local settingsBP = storage.playerSection("Settings_tt_FashionBPC")

local function debug(m)
   if devMode then
       print(m)
       ui.showMessage(m)
   end
end

local function setShowBackpackWithSpell(val, availBackpacks)
   showBackpack = val
   setShowBackpack(val)
   local backpacks = availBackpacks or getAvailableBackpacks()														 
   if val and #backpacks > 0 then
       applyBackpackBuffs(self)
   else
       removeBackpackBuffs(self)
   end
end

local function scanInv(reset)
   newEquip = false
   refresh  = false

   local availBackpacks = getAvailableBackpacks()
   local bIdx           = getBackpackIndex()
   if bIdx > #availBackpacks then bIdx = math.max(#availBackpacks, 1) end
   local activeSkins    = availBackpacks[bIdx] and availBackpacks[bIdx].skins or nil

   local changed = (activeSkins ~= lastSkins) or reset
   if not changed then return end

   lastSkins = activeSkins

   debug("backpacks: remove vfx")
   anim.removeVfx(self, VFX_ID)

   if showBackpack and activeSkins and cam ~= MD.first then
       debug("backpack vfx: " .. activeSkins)
       vfxBackpacks.boneName = "Backpack1"
       anim.addVfx(self, activeSkins, vfxBackpacks)
   end
end

local function onFrame(dt)
   if debounceCounter > 0 then
       debounceCounter = debounceCounter - 1
       return
   end

   local showKeyCode   = settingsBP:get('BPShow')
   local changeKeyCode = settingsBP:get('BPChange')

   local keyDownShow   = showKeyCode   and input.isKeyPressed(showKeyCode)   or false
   local keyDownChange = changeKeyCode and input.isKeyPressed(changeKeyCode) or false

   if keyDownShow and not BPShowLastFrame then
       setShowBackpackWithSpell(not showBackpack)
       counter = 1
       refresh = true
       debug("Backpack VFX: " .. (showBackpack and "ON" or "OFF"))
   end
   BPShowLastFrame = keyDownShow

   if keyDownChange and not BPChangeLastFrame then
       local availBackpacks = getAvailableBackpacks()
       if #availBackpacks > 0 then
           setShowBackpackWithSpell(true)
           local cur = getBackpackIndex()
           if cur > #availBackpacks then cur = #availBackpacks end
           local nxt = cur % #availBackpacks + 1
           setBackpackIndex(nxt)
           counter = 1
           refresh = true
           debounceCounter = 15
           debug("Backpack: " .. availBackpacks[nxt].stem
               .. " (" .. nxt .. "/" .. #availBackpacks .. ")")
       else
           debug("Backpacks: none available in inventory")
       end
   end
   BPChangeLastFrame = keyDownChange

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

local function onActive()
   showBackpack = getShowBackpack()
   counter      = 3
   refresh      = true
   lastSkins    = nil
end

return {
   engineHandlers = {
       onActive = onActive,
       onUpdate = onUpdate,
       onFrame  = onFrame,
   },
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
           I.luaHelper.eventRegister("equipped",   function() newEquip = true end)
           I.luaHelper.eventRegister("unequipped", function() newEquip = true end)
       end,
       vfxRemoveAll = function()
           counter = math.random(3, 8)
           refresh = true
       end,
   },
}