-- Press-to-Continue overlay for OpenMW 0.49
-- In-game overlay that reads settings from PLAYER permanent storage (registered by [menu]).
-- Pauses while visible, advances on ANY key/mouse/controller button,
-- shows slides in RANDOM order (deduped, no immediate repeat after reshuffle),
-- and keeps a stable schedule using a "next deadline" timer.
-- Overlay is created in onInit/onLoad (earliest hooks) to avoid a world flash.

local ui      = require('openmw.ui')
local util    = require('openmw.util')
local input   = require('openmw.input')
local core    = require('openmw.core')
local vfs     = require('openmw.vfs')
local storage = require('openmw.storage')
local async   = require('openmw.async')

local GROUP_KEY = 'SettingsGlobalPressToContinue' -- settings group (player storage)
local PAUSE_TAG = 'PTC_Overlay'                   -- pause tag

local DEFAULT_SWITCH_SECONDS = 5
local DEFAULT_ASPECT_KEY     = '16:9'
local DEFAULT_SCALE_MODE     = 'contain'

local ASPECT_MAP = { ['16:9']=16/9, ['4:3']=4/3, ['1:1']=1, ['21:9']=21/9 }

local SWITCH_SECONDS = DEFAULT_SWITCH_SECONDS
local SLIDE_ASPECT   = ASPECT_MAP[DEFAULT_ASPECT_KEY]
local SCALE_MODE     = DEFAULT_SCALE_MODE

local MODE = 'slides'

local overlayLayerName = 'PTCOverlay'
local renderLayerName  = nil
local overlayActive    = false
local waitForKeyRelease= false
local pausedByMe       = false

local blackBgElement, slideElement = nil, nil

-- Discovered slides: { {path=string, tex=ui.texture}, ... }
local slides = {}

-- Shuffle order state: order[] holds indices into slides
local order = {}
local orderPos = 1

-- Track the last shown slide PATH (string) to prevent immediate repeat after reshuffle
local lastShownPath = nil

-- Stable timing: schedule next switch at an absolute deadline (real time)
local nextSwitchReal = 0

local lastScreen = nil
local subscribed = false

local BLACK_PATH = 'textures/ptc_black.png'
local BLACK_TEX  = nil
do
  if vfs.fileExists(BLACK_PATH) then
    local ok, tex = pcall(ui.texture, { path = BLACK_PATH })
    if ok then BLACK_TEX = tex end
  end
end

local function log(fmt, ...) print(('[PTC] ' .. fmt):format(...)) end
local function clamp(v,lo,hi) if v < lo then return lo elseif v > hi then return hi else return v end end

local function parseAspect(key)
  local val = ASPECT_MAP[key]
  if val then return val end
  local w,h = tostring(key):match('^(%d+)%s*:%s*(%d+)$')
  if w and h and h ~= '0' then
    local r = tonumber(w)/tonumber(h)
    if r and r>0 then return r end
  end
  return SLIDE_ASPECT
end

-- SETTINGS (PLAYER): READ & SUBSCRIBE
local function P() return storage.playerSection(GROUP_KEY) end

local function readSettingsFromPlayer()
  local p = P()
  local ss = p:get('SwitchSeconds'); if type(ss)=='number' then SWITCH_SECONDS = clamp(ss, 0.1, 600) end
  local ak = p:get('SlideAspect');   if ak ~= nil then SLIDE_ASPECT = parseAspect(ak) end
  local sm = p:get('ScaleMode');     if sm=='contain' or sm=='cover' then SCALE_MODE = sm end
  -- Reset schedule on settings change so the new cadence starts cleanly
  nextSwitchReal = core.getRealTime() + SWITCH_SECONDS
  log('Settings (player): SwitchSeconds=%.2f, SlideAspect=%.3f, ScaleMode=%s', SWITCH_SECONDS, SLIDE_ASPECT, SCALE_MODE)
end

local function ensurePlayerSubscription()
  if subscribed then return end
  P():subscribe(async:callback(function(sectionName, changedKey)
    readSettingsFromPlayer()
    if slideElement then slideElement:update() end
    log('PLAYER storage changed (%s:%s) -> reapplied.', tostring(sectionName), tostring(changedKey))
  end))
  subscribed = true
  log('Subscribed to PLAYER storage section %s', GROUP_KEY)
end

-- LAYERS
local function pickExistingAnchorLayer()
  for _, name in ipairs({ 'MessageBox','Notification','Windows','HUD' }) do
    if ui.layers.indexOf(name) ~= nil then return name end
  end
  return nil
end

local function ensureOverlayLayerOrFallback()
  if ui.layers.indexOf(overlayLayerName) ~= nil then renderLayerName = overlayLayerName; return end
  local afterName = pickExistingAnchorLayer()
  if afterName then
    local ok = pcall(function() ui.layers.insertAfter(afterName, overlayLayerName, { interactive = true }) end)
    if ok and ui.layers.indexOf(overlayLayerName) ~= nil then renderLayerName = overlayLayerName; return end
  end
  renderLayerName = afterName or 'HUD'
end

-- SLIDES: discovery, de-dup, shuffle
local function addUniqueSlide(path, seen)
  local key = path:lower()
  if not seen[key] then
    local ok, tex = pcall(ui.texture, { path = path })
    if ok and tex then
      slides[#slides+1] = { path=path, tex=tex }
      seen[key] = true
    end
  end
end

local function fisherYatesShuffle(t)
  -- RNG is engine-seeded; math.randomseed is not available to scripts.
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

local function rebuildOrder(avoidPath)
  order = {}
  for i = 1, #slides do order[i] = i end
  if #order > 1 then fisherYatesShuffle(order) end

  -- Guard: don't start the new deck with the same slide we just showed
  if avoidPath and #order > 1 and slides[order[1]].path == avoidPath then
    local j = 2
    if slides[order[j]].path == avoidPath then
      for k = 3, #order do
        if slides[order[k]].path ~= avoidPath then j = k; break end
      end
    end
    order[1], order[j] = order[j], order[1]
  end

  orderPos = 1
  if #order > 0 then
    log('Shuffled %d unique slide(s). First: %s', #order, slides[order[1]].path)
  end
end

local function collectSlides(avoidPath)
  slides = {}
  local seen = {}
  local dupes = 0
  local prefixes = {
    'Splash','Splash/','Textures/Splash','Textures/Splash/','textures/splash','textures/splash/',
  }
  local function scan(prefix)
    local ok, iter = pcall(vfs.pathsWithPrefix, prefix)
    if ok and iter then
      while true do
        local p = iter(); if not p then break end
        local ext = (p:match("%.([%w]+)$") or ''):lower()
        if ext=='dds' or ext=='tga' or ext=='png' or ext=='jpg' or ext=='jpeg' or ext=='bmp' then
          local lower = p:lower()
          if not seen[lower] then
            addUniqueSlide(p, seen)
          else
            dupes = dupes + 1
          end
        end
      end
    end
  end
  for _, pre in ipairs(prefixes) do scan(pre) end
  if #slides == 0 then
    log('No slides found in VFS; falling back to black.')
  else
    if dupes > 0 then log('Slides found: %d unique (skipped %d duplicates).', #slides, dupes)
    else log('Slides found: %d unique.', #slides) end
  end
  rebuildOrder(avoidPath)

  -- start the cadence from the first slide we show
  nextSwitchReal = core.getRealTime() + SWITCH_SECONDS
end

local function stepToNextInOrder()
  if #order == 0 then return end
  orderPos = orderPos + 1
  if orderPos > #order then
    -- exhausted: reshuffle, avoiding the one we just showed
    rebuildOrder(lastShownPath)
  end
end

-- SIZING
local function slideRelativeSize(screen, targetAspect, mode)
  local sAspect = screen.x / screen.y
  if mode=='cover' then
    if sAspect < targetAspect then return util.vector2(1, targetAspect/sAspect) else return util.vector2(sAspect/targetAspect, 1) end
  else
    if sAspect > targetAspect then return util.vector2(targetAspect/sAspect, 1) else return util.vector2(1, sAspect/targetAspect) end
  end
end

local function updateSlideSizing()
  if not slideElement then return end
  local rel = slideRelativeSize(ui.screenSize(), SLIDE_ASPECT, SCALE_MODE)
  slideElement.layout.props.relativeSize     = rel
  slideElement.layout.props.relativePosition = util.vector2(0.5, 0.5)
  slideElement.layout.props.anchor           = util.vector2(0.5, 0.5)
  slideElement:update()
end

-- PAUSE / UNPAUSE via built-in world events (works across 0.48/0.49)
local function pauseWorld()
  if not pausedByMe then
    core.sendGlobalEvent('Pause', PAUSE_TAG)
    pausedByMe = true
    log('World paused (tag=%s).', PAUSE_TAG)
  end
end

local function unpauseWorld()
  if pausedByMe then
    core.sendGlobalEvent('Unpause', PAUSE_TAG)
    pausedByMe = false
    log('World unpaused (tag=%s).', PAUSE_TAG)
  end
end

-- Helpers to read current slide
local function currentSlideTex()
  if #order == 0 then return nil end
  return slides[order[orderPos]].tex
end
local function currentSlidePath()
  if #order == 0 then return '(none)' end
  return slides[order[orderPos]].path
end

-- UI CREATE / DESTROY
local function destroyOverlay()
  if slideElement   then slideElement:destroy();   slideElement   = nil end
  if blackBgElement then blackBgElement:destroy(); blackBgElement = nil end
  overlayActive = false
  unpauseWorld()
end

local function createBlackBackground()
  if not BLACK_TEX then return nil end
  return ui.create {
    layer = renderLayerName, type = ui.TYPE.Image,
    props = { autoSize=false, relativeSize=util.vector2(1,1), resource=BLACK_TEX },
    name  = 'ptc_bg',
  }
end

local function createSlideImage()
  if #order == 0 then return nil end
  local rel = slideRelativeSize(ui.screenSize(), SLIDE_ASPECT, SCALE_MODE)
  local elem = ui.create {
    layer = renderLayerName, type = ui.TYPE.Image,
    props = {
      autoSize=false,
      relativeSize=rel,
      relativePosition=util.vector2(0.5,0.5),
      anchor=util.vector2(0.5,0.5),
      resource=currentSlideTex(),
    },
    name  = 'ptc_slide',
  }
  lastShownPath = currentSlidePath() -- record the first one shown
  return elem
end

local function showOverlay()
  ensureOverlayLayerOrFallback()
  destroyOverlay()

  ensurePlayerSubscription()
  readSettingsFromPlayer()

  if MODE=='slides' then collectSlides(lastShownPath) end

  if MODE=='slides' and #order>0 then
    if BLACK_TEX then blackBgElement = createBlackBackground() end
    slideElement = createSlideImage()
    log('Starting shuffled slideshow at: %s', currentSlidePath())
  else
    if BLACK_TEX then blackBgElement = createBlackBackground() end
  end

  overlayActive = (blackBgElement ~= nil) or (slideElement ~= nil)
  waitForKeyRelease = true
  lastScreen = ui.screenSize()
  pauseWorld()
end

local function hideOverlay() destroyOverlay() end

-- ANY KEY / MOUSE / CONTROLLER
local function anyInputPressed()
  for _, code in pairs(input.KEY) do
    if input.isKeyPressed(code) then return true end
  end
  for b = 1, 5 do
    if input.isMouseButtonPressed(b) then return true end
  end
  for _, btn in pairs(input.CONTROLLER_BUTTON) do
    if input.isControllerButtonPressed(btn) then return true end
  end
  return false
end

local function detectResizeAndRelayout()
  local nowScreen = ui.screenSize()
  if not lastScreen or nowScreen.x~=lastScreen.x or nowScreen.y~=lastScreen.y then
    if blackBgElement then blackBgElement:update() end
    updateSlideSizing()
    lastScreen = nowScreen
  end
end

return {
  engineHandlers = {
    -- EARLY hooks: create overlay here to avoid a one-frame world flash
    onInit = function()
      core.sendGlobalEvent('Unpause', PAUSE_TAG) -- safety for reloadlua mid-overlay
      pausedByMe = false

      ensurePlayerSubscription()
      readSettingsFromPlayer()
      showOverlay() -- create immediately on script creation
    end,

    onLoad = function(savedData, initData)
      -- When loading from a save, this is called while the object is inactive (per docs).
      core.sendGlobalEvent('Unpause', PAUSE_TAG)
      pausedByMe = false

      ensurePlayerSubscription()
      readSettingsFromPlayer()
      showOverlay() -- create immediately on script load
    end,

    -- intentionally NO onInactive handler anymore (it was destroying the overlay during load)

    onFrame = function(dt)
      if not overlayActive then return end
      detectResizeAndRelayout()

      if #order>0 and SWITCH_SECONDS>0 then
        local now = core.getRealTime() -- real wall-clock seconds
        if now >= nextSwitchReal then
          nextSwitchReal = nextSwitchReal + SWITCH_SECONDS
          stepToNextInOrder()
          if slideElement then
            slideElement.layout.props.resource = currentSlideTex()
            slideElement:update()
            lastShownPath = currentSlidePath()
            log('Next (shuffled) slide %d/%d: %s', orderPos, #order, lastShownPath)
            updateSlideSizing()
          end
        end
      end

      if waitForKeyRelease then
        if not anyInputPressed() then waitForKeyRelease = false end
        return
      end
      if anyInputPressed() then hideOverlay() end
    end,
  },

  eventHandlers = {
    PTC_RescanSlides = function()
      collectSlides(lastShownPath)
      if slideElement and #order > 0 then
        slideElement.layout.props.resource = currentSlideTex()
        slideElement:update()
        lastShownPath = currentSlidePath()
        updateSlideSizing()
        nextSwitchReal = core.getRealTime() + SWITCH_SECONDS
        log('Rescanned & reshuffled. Now have %d unique slide(s). First: %s', #order, lastShownPath)
      end
    end,
  },
}
