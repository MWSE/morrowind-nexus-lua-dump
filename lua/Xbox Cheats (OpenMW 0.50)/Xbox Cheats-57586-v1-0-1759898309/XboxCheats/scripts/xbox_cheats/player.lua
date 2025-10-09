-- Xbox-style cheat sequences as a *player* script (OpenMW 0.49/0.50 API).
-- Strict arming on Stats screen. Optional OG-Xbox “latch on exit” bug replication.

local core     = require('openmw.core')
local input    = require('openmw.input')
local async    = require('openmw.async')
local I        = require('openmw.interfaces')
local ui       = require('openmw.ui')
local self     = require('openmw.self')
local types    = require('openmw.types')
local storage  = require('openmw.storage')

-- Settings (permanent)
local S = storage.globalSection('SettingsXboxCheats')

-- ===== Custom triggers + A action =====
input.registerTrigger { key='XboxCheats.Black', l10n='XboxCheats', name='trigger_black_name', description='trigger_black_desc' }
input.registerTrigger { key='XboxCheats.White', l10n='XboxCheats', name='trigger_white_name', description='trigger_white_desc' }
input.registerAction  { key='XboxCheats.HoldA', type=input.ACTION_TYPE.Boolean, l10n='XboxCheats', name='action_holdA_name', description='action_holdA_desc', defaultValue=false }

-- Sequences (B/W)
local SEQS = {
  health  = { 'B','W','B','B','B' },
  magicka = { 'B','W','W','B','W' },
  fatigue = { 'B','B','W','W','B' },
}
local SEQ_LIST = { SEQS.health, SEQS.magicka, SEQS.fatigue }

-- Helpers / diagnostics
local function dbg(msg) if S:get('debugToasts') then ui.showMessage(msg) end end
local function msg(msg) ui.showMessage(msg) end

-- Stats gating (string IDs to avoid enum lookup errors across builds)
local function statsVisible()
  if not I.UI or not I.UI.getMode then return false end
  local MODE = (I.UI.MODE and I.UI.MODE.Interface) or 'Interface'
  if I.UI.getMode() ~= MODE then return false end
  return I.UI.isWindowVisible('Stats') or I.UI.isWindowVisible('StatsMenu')
end

-- Robust input buffer: prefix filter, timeout, cancel
local buffer, lastPressTime = {}, 0
local pressGapTimeout = 1.5

local function clearBuffer(reason)
  if #buffer > 0 then
    buffer, lastPressTime = {}, 0
    if reason then dbg('Sequence cleared: '..reason) end
  end
end

local function isPrefixOfAny(seqPrefix)
  for _, seq in ipairs(SEQ_LIST) do
    local ok = true
    for i = 1, #seqPrefix do
      if seq[i] ~= seqPrefix[i] then ok = false break end
    end
    if ok then return true end
  end
  return false
end

local function matches(seq)
  if #buffer ~= #seq then return false end
  for i = 1, #seq do
    if buffer[i] ~= seq[i] then return false end
  end
  return true
end

local function push(sym)
  if not statsVisible() then return end
  buffer[#buffer+1] = sym
  if #buffer > 5 then table.remove(buffer, 1) end
  lastPressTime = core.getSimulationTime()
  if not isPrefixOfAny(buffer) then
    clearBuffer('wrong input')
  else
    dbg('Pressed: '..sym)
  end
end

-- Armed / filling state
local armed = nil         -- { kind='health'|'magicka'|'fatigue', untilTime=number }
local acc = 0
local filling = false
local didHello = false

-- Bug replica: latch fill if leaving Stats while A is held
local bugMode = false     -- read from settings each update
local latched = false     -- when true, we ignore A release & timeout and keep filling anywhere
local lastStats = false   -- last frame: was Stats visible?
local lastAHeld = false   -- last frame: was A held?

local function arm(kind)
  local timeout = S:get('timeoutSec') or 5
  armed = { kind = kind, untilTime = core.getSimulationTime() + timeout }
  acc, filling, latched = 0, false, false
  msg('ARMED: '..kind..' (hold A)')
end
local function disarm(reason)
  if armed then dbg('Disarmed: '..(reason or '')) end
  armed, acc, filling, latched = nil, 0, false, false
end

-- Dynamic stat accessor (0.49 pattern)
local function getDyn(kind)
  if     kind == 'health'  then return types.Actor.stats.dynamic.health(self)
  elseif kind == 'magicka' then return types.Actor.stats.dynamic.magicka(self)
  elseif kind == 'fatigue' then return types.Actor.stats.dynamic.fatigue(self)
  end
end

-- Check & arm when buffer completes
local function checkMatchesAndArm()
  if #buffer == 5 then
    if matches(SEQS.health)  then clearBuffer(); return arm('health')  end
    if matches(SEQS.magicka) then clearBuffer(); return arm('magicka') end
    if matches(SEQS.fatigue) then clearBuffer(); return arm('fatigue') end
    clearBuffer('no match')
  end
end

-- Trigger handlers
input.registerTriggerHandler('XboxCheats.Black', async:callback(function() push('B'); checkMatchesAndArm() end))
input.registerTriggerHandler('XboxCheats.White', async:callback(function() push('W'); checkMatchesAndArm() end))

-- Fallbacks so it works out of the box (Q/E for B/W; Esc/Backspace/B cancels)
local function onKeyPress(key)
  if key.code == input.KEY.Q then
    input.activateTrigger('XboxCheats.Black')
  elseif key.code == input.KEY.E then
    input.activateTrigger('XboxCheats.White')
  elseif key.code == input.KEY.Escape or key.code == input.KEY.Backspace then
    clearBuffer('cancel'); disarm('cancel')
  end
end
local function onControllerButtonPress(id)
  if id == input.CONTROLLER_BUTTON.LeftShoulder then
    input.activateTrigger('XboxCheats.Black')
  elseif id == input.CONTROLLER_BUTTON.RightShoulder then
    input.activateTrigger('XboxCheats.White')
  elseif id == input.CONTROLLER_BUTTON.B then
    clearBuffer('cancel'); disarm('cancel')
  end
end

-- Per-frame
local function onUpdate(dt)
  if not didHello then didHello = true; dbg('XboxCheats loaded. Enter codes on the Stats page.') end

  bugMode = S:get('bugHoldAExit') and true or false
  local visible = statsVisible()

  -- Inter-press timeout (while on Stats)
  if visible and #buffer > 0 then
    local now = core.getSimulationTime()
    if now - lastPressTime > pressGapTimeout then clearBuffer('timeout') end
  end

  -- **Bug latch**: detect leaving Stats while A is held and armed -> latch
  local aHeldNow = input.getBooleanActionValue('XboxCheats.HoldA')
                or input.isControllerButtonPressed(input.CONTROLLER_BUTTON.A)
  if bugMode and armed and lastStats and not visible and lastAHeld then
    latched = true
    dbg('Bug latch engaged (filling persists outside menus)')
  end

  -- If you leave Stats and NOT latched, disarm and clear buffer
  if not visible and (not bugMode or not latched) then
    if armed then disarm('left stats') end
    clearBuffer()
  end

  -- Do the fill
  if armed then
    -- Timeout only matters if not latched
    if not latched and core.getSimulationTime() >= armed.untilTime then return disarm('timeout') end

    local effectiveHeld = latched or aHeldNow
    if not effectiveHeld then
      filling = false
    else
      local stat = getDyn(armed.kind)
      if not stat then return disarm('no stat') end

      local cap = (stat.base or 0) + (stat.modifier or 0)
      if stat.current >= cap then return disarm('reached cap') end

      if not filling then filling = true; dbg('Filling '..armed.kind..'…') end

      local rate = S:get('fillRate') or 60
      acc = acc + dt * rate
      while acc >= 1 and stat.current < cap do
        stat.current = math.min(cap, stat.current + 1)
        acc = acc - 1
      end

      if stat.current >= cap then disarm('reached cap') end
    end
  end

  -- Remember last frame’s state for latch detection
  lastStats, lastAHeld = visible, aHeldNow
end

return {
  engineHandlers = {
    onUpdate = onUpdate,
    onKeyPress = onKeyPress,
    onControllerButtonPress = onControllerButtonPress,
    onSave = function() return {
      armed=armed, acc=acc, buffer=buffer, filling=filling, didHello=didHello,
      lastPressTime=lastPressTime, bugMode=bugMode, latched=latched, lastStats=lastStats, lastAHeld=lastAHeld
    } end,
    onLoad = function(data)
      armed         = data and data.armed or nil
      acc           = data and data.acc or 0
      buffer        = data and data.buffer or {}
      filling       = data and data.filling or false
      didHello      = data and data.didHello or false
      lastPressTime = data and data.lastPressTime or 0
      bugMode       = data and data.bugMode or false
      latched       = data and data.latched or false
      lastStats     = data and data.lastStats or false
      lastAHeld     = data and data.lastAHeld or false
    end,
  },
}
