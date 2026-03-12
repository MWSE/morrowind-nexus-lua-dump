local I = require('openmw.interfaces')
local self = require('openmw.self')
local types = require('openmw.types')

local Actor = types.Actor

local MOD_TAG = '[IntCapAlchemy_100] '
local DEBUG = true

local baseUI = nil

local function hasAlchemyToken(value)
  return type(value) == 'string' and value:lower():find('alchemy', 1, true) ~= nil
end

local function optionsContainAlchemy(options)
  if type(options) ~= 'table' then
    return false
  end
  local windows = options.windows
  if type(windows) == 'table' then
    for i = 1, #windows do
      if hasAlchemyToken(windows[i]) then
        return true
      end
    end
  end
  return false
end

local clamp = {
  active = false,
  kind = nil, -- 'damage' | 'modifier'
  baseline = nil,
  lastNeeded = 0,
  storedMagickaCurrent = nil,
  pendingFrames = 0,
}

local function getIntelligenceStat()
  return Actor.stats.attributes.intelligence(self)
end

local function getMagickaStat()
  return Actor.stats.dynamic.magicka(self)
end

local function chooseClampKind(intStat)
  if type(intStat.damage) == 'number' then
    clamp.kind = 'damage'
    clamp.baseline = intStat.damage
    return true
  end
  if type(intStat.modifier) == 'number' then
    clamp.kind = 'modifier'
    clamp.baseline = intStat.modifier
    return true
  end
  return false
end

local function beginClamp()
  local intStat = getIntelligenceStat()
  if not intStat or type(intStat.modified) ~= 'number' then
    return false
  end

  if not clamp.active then
    clamp.active = true
    clamp.pendingFrames = 0
    clamp.kind = nil
    clamp.baseline = nil
    clamp.lastNeeded = 0
    clamp.storedMagickaCurrent = nil
  end

  if clamp.kind == nil or clamp.baseline == nil then
    if not chooseClampKind(intStat) then
      return false
    end
  end

  if clamp.storedMagickaCurrent == nil then
    local magicka = getMagickaStat()
    if magicka and type(magicka.current) == 'number' then
      clamp.storedMagickaCurrent = magicka.current
    end
  end

  return true
end

local function ensureClamped()
  local intStat = getIntelligenceStat()
  if not intStat or type(intStat.modified) ~= 'number' then
    return
  end

  if not beginClamp() then
    return
  end

  if clamp.kind == 'damage' then
    local baseline = clamp.baseline
    local current = intStat.damage
    if type(baseline) ~= 'number' or type(current) ~= 'number' then
      return
    end
    local extra = current - baseline
    local unclamped = intStat.modified + extra
    local needed = math.max(0, unclamped - 100)
    if needed ~= clamp.lastNeeded then
      intStat.damage = baseline + needed
      clamp.lastNeeded = needed
    end
  else
    local baseline = clamp.baseline
    local current = intStat.modifier
    if type(baseline) ~= 'number' or type(current) ~= 'number' then
      return
    end
    local extra = baseline - current
    local unclamped = intStat.modified + extra
    local needed = math.max(0, unclamped - 100)
    if needed ~= clamp.lastNeeded then
      intStat.modifier = baseline - needed
      clamp.lastNeeded = needed
    end
  end
end

local function restore()
  if not clamp.active then
    return
  end

  local intStat = getIntelligenceStat()
  if intStat and clamp.kind == 'damage' and type(clamp.baseline) == 'number' and type(intStat.damage) == 'number' then
    intStat.damage = clamp.baseline
  elseif intStat and clamp.kind == 'modifier' and type(clamp.baseline) == 'number' and type(intStat.modifier) == 'number' then
    intStat.modifier = clamp.baseline
  end

  if clamp.storedMagickaCurrent ~= nil then
    local magicka = getMagickaStat()
    if magicka and type(magicka.current) == 'number' then
      local maxMagicka = (magicka.base or 0) + (magicka.modifier or 0)
      magicka.current = math.min(clamp.storedMagickaCurrent, maxMagicka)
    end
  end

  clamp.active = false
  clamp.kind = nil
  clamp.baseline = nil
  clamp.lastNeeded = 0
  clamp.storedMagickaCurrent = nil
  clamp.pendingFrames = 0
end

local function isAlchemyVisible()
  local ui = baseUI or (I and I.UI)
  if not ui then
    return false
  end
  if type(ui.isWindowVisible) == 'function' then
    local ok, visible = pcall(ui.isWindowVisible, 'Alchemy')
    if ok and visible then
      return true
    end
  end
  if type(ui.getMode) == 'function' then
    local ok, mode = pcall(ui.getMode)
    if ok and hasAlchemyToken(mode) then
      return true
    end
  end
  local modes = ui.modes
  if type(modes) == 'table' then
    local top = modes[#modes]
    if top and (hasAlchemyToken(top.mode) or hasAlchemyToken(top.name)) then
      return true
    end
    local windows = top and top.windows
    if type(windows) == 'table' then
      for i = 1, #windows do
        if hasAlchemyToken(windows[i]) then
          return true
        end
      end
    end
  end
  return false
end

local function tick()
  if isAlchemyVisible() then
    ensureClamped()
    clamp.pendingFrames = 0
    return
  end

  if clamp.active and clamp.pendingFrames < 3 then
    clamp.pendingFrames = clamp.pendingFrames + 1
    ensureClamped()
    return
  end

  restore()
end

local UIWrapper = {}
setmetatable(UIWrapper, {
  __index = function(_, k)
    if baseUI then
      return baseUI[k]
    end
    local ui = I and I.UI
    return ui and ui[k] or nil
  end
})

UIWrapper.setMode = function(mode, options)
  if hasAlchemyToken(mode) or optionsContainAlchemy(options) then
    ensureClamped()
    if DEBUG then
      local intStat = getIntelligenceStat()
      print(MOD_TAG .. 'Pre-clamp via UI.setMode (INT=' .. tostring(intStat and intStat.modified) .. ')')
    end
  end
  local ui = baseUI
  if ui and type(ui.setMode) == 'function' then
    return ui.setMode(mode, options)
  end
end

UIWrapper.addMode = function(mode, options)
  if hasAlchemyToken(mode) or optionsContainAlchemy(options) then
    ensureClamped()
    if DEBUG then
      local intStat = getIntelligenceStat()
      print(MOD_TAG .. 'Pre-clamp via UI.addMode (INT=' .. tostring(intStat and intStat.modified) .. ')')
    end
  end
  local ui = baseUI
  if ui and type(ui.addMode) == 'function' then
    return ui.addMode(mode, options)
  end
end

return {
  interfaceName = 'UI',
  interface = UIWrapper,
  engineHandlers = {
    onInterfaceOverride = function(base)
      baseUI = base
    end,
    onInit = function()
      local ui = baseUI or (I and I.UI)
      print(MOD_TAG .. 'Loaded. UI=' .. tostring(ui and ui.version))
    end,
    onFrame = tick,
    onSave = function()
      restore()
      return {}
    end,
  },
}
