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

local VFX_ID = "visibleScarves"

local maskSettings = storage.playerSection('Settings_tt_fashionwind_scarves_ui')

local FROST_SPELL_ID = "fx_SCfrostshield"

local vfxScarves = { loop = true, useAmbientLight = false, vfxId = VFX_ID }
local BUFF_SPELLS = {
    FROST_SPELL_ID,
    }

local function applyScarfBuffs(actor)
    if not maskSettings:get('SKARFBUFFS') then return end
    for _, spellId in ipairs(BUFF_SPELLS) do
        Actor.spells(actor):add(spellId)
    end
end

local function removeScarfBuffs(actor)
    for _, spellId in ipairs(BUFF_SPELLS) do
        Actor.spells(actor):remove(spellId)
    end
end							

local scarvesListIndex = storage.playerSection("scarves_cycle")

local function getScarvesIndex()
  return scarvesListIndex:get("cycleIndex") or 1
end

local function setScarvesIndex(n)
  scarvesListIndex:set("cycleIndex", n)
end

local function getShowScarves()
  return scarvesListIndex:get("showScarves") or false
end

local function setShowScarves(val)
  scarvesListIndex:set("showScarves", val)
end

local scarvesList = {
  "scarf1", "scarf2", "scarf3", "scarf4", "scarf5", "scarf6", "scarf7", "scarf8", "scarf9", "scarf10", "scarf11", "scarf12", "scarf13", "scarf14", "scarf15", "scarf16", 
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

local function getAvailableScarves()
  local stemMap   = buildStemMap()
  local available = {}
  for _, stem in ipairs(scarvesList) do
      local skinsPath = stemMap[stem:lower()]
      if skinsPath then
          available[#available + 1] = { stem = stem, skins = skinsPath }
      end
  end
  return available
end

local showScarves       = getShowScarves()
local SCShowLastFrame   = false
local SCChangeLastFrame = false

local counter         = math.random(3, 20)
local refresh         = true
local newEquip        = false
local useHelper       = false
local lastSkins       = nil
local debounceCounter = 0

local settingsSC = storage.playerSection("Settings_tt_fashionwind_scarves_ui")

local function debug(m)
  if devMode then
      print(m)
      ui.showMessage(m)
  end
end

local function setShowScarvesWithSpell(val, availScarves)
    showScarves = val
    setShowScarves(val)
    local scarves = availScarves or getAvailableScarves()
    if val and #scarves > 0 then
        applyScarfBuffs(self)   
    else
        removeScarfBuffs(self)  
    end
end

local function scanInv(reset)
  newEquip = false
  refresh  = false

  local availScarves = getAvailableScarves()
  local sIdx         = getScarvesIndex()
  if sIdx > #availScarves then sIdx = math.max(#availScarves, 1) end
  local activeSkins  = availScarves[sIdx] and availScarves[sIdx].skins or nil

  local changed = (activeSkins ~= lastSkins) or reset
  if not changed then return end

  lastSkins = activeSkins

  debug("scarves: remove vfx")
  anim.removeVfx(self, VFX_ID)

  if showScarves and activeSkins and cam ~= MD.first then
      debug("scarves vfx: " .. activeSkins)
      vfxScarves.boneName = "ScarfNeck"
      anim.addVfx(self, activeSkins, vfxScarves)
  end
end

local function onFrame(dt)
  if debounceCounter > 0 then
      debounceCounter = debounceCounter - 1
      return
  end

--  local showKeyCode   = settingsSC:get('SCShow')
--  local changeKeyCode = settingsSC:get('SCChange')

--  local keyDownShow   = showKeyCode   and input.isKeyPressed(showKeyCode)   or false
--  local keyDownChange = changeKeyCode and input.isKeyPressed(changeKeyCode) or false

  local SCkeyDownShow = input.getBooleanActionValue('SCShow')
  if SCkeyDownShow and not SCShowLastFrame then
      setShowScarvesWithSpell(not showScarves)
      counter = 1
      refresh = true
      debug("Scarves VFX: " .. (showScarves and "ON" or "OFF"))
  end
  SCShowLastFrame = SCkeyDownShow

  local keyDownChange = input.getBooleanActionValue('SCChange')
  if keyDownChange and not SCChangeLastFrame then
      local availScarves = getAvailableScarves()
      if #availScarves > 0 then
          setShowScarvesWithSpell(true, availScarves)
          local cur = getScarvesIndex()
          if cur > #availScarves then cur = #availScarves end
          local nxt = cur % #availScarves + 1
          setScarvesIndex(nxt)
          counter = 1
          refresh = true
          debounceCounter = 15
          debug("Scarf: " .. availScarves[nxt].stem
              .. " (" .. nxt .. "/" .. #availScarves .. ")")
      else
          debug("Scarves: none available in inventory")
      end
  end
  SCChangeLastFrame = keyDownChange

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
    showScarves = getShowScarves()
    removeScarfBuffs(self)                             
    if showScarves then applyScarfBuffs(self) end       
    counter   = 3
    refresh   = true
    lastSkins = nil
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