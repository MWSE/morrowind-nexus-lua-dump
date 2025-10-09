-- scripts/speechcraft_bribe/ui.lua
-- OpenMW 0.49 – Bribe UI (compact, no wrap, NO Max button, controller-safe, instant updates)

local ui     = require('openmw.ui')
local util   = require('openmw.util')
local async  = require('openmw.async')
local input  = require('openmw.input')
local I      = require('openmw.interfaces')
local uiConstants = require('scripts.omw.mwui.constants')

local v2    = util.vector2
local color = util.color

local M = {}

-- === Look & feel (compact) ===
local TOP_PAD   = 4
local TITLE_H   = 28
local MIN_W     = 340     -- smaller default window
local MAX_W     = 420     -- cap the width
local COLOR_HEADER = (uiConstants and uiConstants.headerColor) or color.rgb(1,1,1)
local COLOR_NORMAL = (uiConstants and uiConstants.normalColor) or color.rgb(1,1,1)
local TITLE_BG_ALPHA = 0.35
local SEP_ALPHA      = 0.40

-- === State ===
local window
local windowPos
local dragging = false
local dragStartMouse, dragStartPos

local triesLeft     = 0
local inflationPct  = 0
local playerGold    = 0
local npcName       = ""
local statusText    = ""

local currentOfferStr = ""

local prevGamepadCursor = nil
local boundKeys = {} -- input guards

-- Direct handle to the TextEdit so buttons can update it instantly
local offerInputLayout = nil

M.onSubmit = nil
function M.isOpen() return window ~= nil end

-- === Helpers ===
local function spacer(w, h) return { type = ui.TYPE.Widget, props = { size = v2(w or 0, h or 8) } } end
local function screenSize() return ui.screenSize() end

local function windowWidth()
  local sx = screenSize().x
  local w = math.floor(math.max(MIN_W, math.min(MAX_W, sx * 0.55)))
  return w
end

local function clamp(n, lo, hi) if n < lo then return lo elseif n > hi then return hi else return n end end
local function minOffer() return (playerGold > 0) and 1 or 0 end
local function parseOffer(s) local d=tostring(s or ""):gsub("%D",""); return tonumber(d) or 0 end

local function clampToScreen(p)
  local sz = screenSize()
  local x = math.max(0, math.min(p.x, math.max(0, sz.x - 10)))
  local y = math.max(0, math.min(p.y, math.max(0, sz.y - 10)))
  return v2(x, y)
end

local WHITE = ui.texture { path = 'white' }

-- Single-line text helper (no wrap)
local function text(label, size)
  return {
    template = I.MWUI and I.MWUI.templates and I.MWUI.templates.textNormal or nil,
    type = ui.TYPE.Text,
    props = {
      text = label or "",
      autoSize = true,
      textSize = size or 16,
      textColor = COLOR_NORMAL,
      textShadow = true,
      multiline = false,
      wordWrap  = false,
    },
  }
end

local function row(children)
  return {
    type = ui.TYPE.Flex,
    props = { horizontal = true, autoSize = true, align = ui.ALIGNMENT.Start, arrange = ui.ALIGNMENT.Center },
    content = ui.content(children),
  }
end

local function col(children)
  return {
    type = ui.TYPE.Flex,
    props = { horizontal = false, autoSize = true, align = ui.ALIGNMENT.Start, arrange = ui.ALIGNMENT.Start },
    content = ui.content(children),
  }
end

-- Re-arm gamepad cursor next frame after any click
local function reactivateCursorSoon()
  if I.GamepadControls and I.GamepadControls.setGamepadCursorActive then
    async:newUnsavableGameTimer(0.01, function()
      I.GamepadControls.setGamepadCursorActive(true)
    end)
  end
end

local function button(labelText, onClick)
  return {
    template = I.MWUI and I.MWUI.templates and I.MWUI.templates.textNormal or nil,
    type = ui.TYPE.Text,
    props = {
      text = labelText,
      autoSize = true,
      textSize = 18,
      textColor = COLOR_NORMAL,
      textShadow = true,
      multiline = false,
      wordWrap  = false,
    },
    events = {
      mouseClick = async:callback(function()
        if onClick then onClick() end
        reactivateCursorSoon()
        return true
      end),
    },
  }
end

-- === Title strip (faint band + separator) ===
local function buildTopBar(W)
  local bg = { type = ui.TYPE.Image, props = { resource = WHITE, color = color.rgb(0,0,0), alpha = TITLE_BG_ALPHA, size = v2(W, TITLE_H) } }
  local sep = { type = ui.TYPE.Image, props = { resource = WHITE, color = color.rgb(1,1,1), alpha = SEP_ALPHA, size = v2(W, 2), position = v2(0, TITLE_H - 2) } }
  local titleRow = row({
    spacer(8, 0),
    { template = I.MWUI and I.MWUI.templates and I.MWUI.templates.textNormal or nil,
      type = ui.TYPE.Text,
      props = {
        text = "Bribe: " .. (npcName or ""),
        textSize = 20,
        textColor = COLOR_HEADER,
        textShadow = true,
        autoSize = true,
        multiline = false,
        wordWrap  = false,
      } },
    spacer(8, 0),
  })
  return { type = ui.TYPE.Container, name = 'BribeTopBar', props = { size = v2(W, TITLE_H) }, content = ui.content({ bg, sep, titleRow }) }
end

-- === Body (single-line rows; compact) ===
local function inflationLabel(p)
  local n = tonumber(p) or 0
  if n < 1 then return "None"
  elseif n < 20 then return "Low"
  elseif n < 50 then return "Medium"
  elseif n < 100 then return "High"
  elseif n < 200 then return "Very High"
  else return "Extreme" end
end

local function buildBody(W)
  local inputW = (W < 360) and 110 or 130

  -- fresh handle each rebuild
  offerInputLayout = {
    name = "OfferInput",
    type = ui.TYPE.TextEdit,
    props = { text = currentOfferStr, size = v2(inputW, 30), textSize = 18, textColor = COLOR_NORMAL },
    events = {
      textChanged = async:callback(function(newText, layout)
        local digits = tostring(newText or ""):gsub("%D","")
        currentOfferStr = digits
        if layout and layout.props then layout.props.text = digits end
        if window then window:update() end
      end),
    },
  }

  return {
    type = ui.TYPE.Flex,
    props = { horizontal = false, autoSize = true, align = ui.ALIGNMENT.Start, arrange = ui.ALIGNMENT.Start },
    content = ui.content({
      row({
        text("Tries:", 16), spacer(6,1), text(tostring(triesLeft or 0), 16),
        spacer(10,1), text("Inflation:",16), spacer(6,1), text(inflationLabel(inflationPct),16),
        spacer(10,1), text("Gold:",16), spacer(6,1), text(tostring(playerGold or 0),16),
      }),
      spacer(0, 8),

      -- Offer row: keep on a single line
      row({
        text("Offer:", 16), spacer(6,1),
        offerInputLayout,
      }),
      spacer(0, 8),

      -- Step buttons: -25 -5 +5 +25 (single line; tight spacing)
      row({
        button(" -25 ", function()
          local v = clamp(parseOffer(currentOfferStr) - 25, minOffer(), math.max(1, playerGold))
          currentOfferStr = tostring(v)
          if offerInputLayout and offerInputLayout.props then offerInputLayout.props.text = currentOfferStr end
          if window then window:update() end
        end),
        spacer(6,0),
        button(" -5 ", function()
          local v = clamp(parseOffer(currentOfferStr) - 5, minOffer(), math.max(1, playerGold))
          currentOfferStr = tostring(v)
          if offerInputLayout and offerInputLayout.props then offerInputLayout.props.text = currentOfferStr end
          if window then window:update() end
        end),
        spacer(10,0),
        button(" +5 ", function()
          local v = clamp(parseOffer(currentOfferStr) + 5, minOffer(), math.max(1, playerGold))
          currentOfferStr = tostring(v)
          if offerInputLayout and offerInputLayout.props then offerInputLayout.props.text = currentOfferStr end
          if window then window:update() end
        end),
        spacer(6,0),
        button(" +25 ", function()
          local v = clamp(parseOffer(currentOfferStr) + 25, minOffer(), math.max(1, playerGold))
          currentOfferStr = tostring(v)
          if offerInputLayout and offerInputLayout.props then offerInputLayout.props.text = currentOfferStr end
          if window then window:update() end
        end),
      }),

      spacer(0, 10),
      text(statusText or "", 16),

      spacer(0, 10),
      row({
        button("[ Offer ]", function()
          local v = clamp(parseOffer(currentOfferStr), minOffer(), math.max(1, playerGold))
          if M.onSubmit then M.onSubmit(v) end
        end),
        spacer(16, 1),
        button("[ Cancel ]", function() M.close() end),
      }),
    }),
  }
end

-- === Layout (frame + title + width wrapper) ===
local function buildLayout()
  local W = windowWidth()

  if not windowPos then
    local sz = screenSize()
    windowPos = clampToScreen(v2(math.floor(sz.x * 0.5 - W * 0.5), math.floor(sz.y * 0.25)))
  end

  local boxed = {
    template = I.MWUI and I.MWUI.templates and I.MWUI.templates.boxTransparentThick or nil,
    type = ui.TYPE.Container,
    content = ui.content({
      col({
        spacer(0, TOP_PAD),
        buildTopBar(W),
        spacer(0, 6),
        { type = ui.TYPE.Container, props = { size = v2(W, 0) }, content = ui.content({ buildBody(W) }) },
        spacer(0, 6),
      }),
    }),
  }

  return {
    layer = "Windows",
    type  = ui.TYPE.Container,
    name  = "BribeWindow",
    props = { position = windowPos, autoSize = true },
    events = {
      -- Drag only on title strip region
      mousePress = async:callback(function(e)
        reactivateCursorSoon()
        if e.button == 1 then
          local localY = e.position.y - (windowPos and windowPos.y or 0)
          if localY >= TOP_PAD and localY <= TOP_PAD + TITLE_H then
            dragging = true
            dragStartMouse = e.position
            dragStartPos   = windowPos
            return true
          end
        end
        return false
      end),
      mouseMove = async:callback(function(e)
        if not dragging then return false end
        local dx = e.position.x - dragStartMouse.x
        local dy = e.position.y - dragStartMouse.y
        windowPos = clampToScreen(v2(dragStartPos.x + dx, dragStartPos.y + dy))
        if window and window.layout and window.layout.props then
          window.layout.props.position = windowPos
          window:update()
        end
        return true
      end),
      mouseRelease = async:callback(function()
        reactivateCursorSoon()
        if dragging then dragging = false; return true end
        return false
      end),
      mouseClick = async:callback(function() reactivateCursorSoon() return true end),
    },
    content = ui.content({ boxed }),
  }
end

-- === Input guards: block BOTH 'Activate' and 'Use' while open ===
local function bindGuardFor(actionKey)
  if boundKeys[actionKey] then return end
  if not (input.actions and input.actions[actionKey]) then return end
  input.bindAction(actionKey, async:callback(function(dt, base)
    if window ~= nil then return false end
    return base
  end), {})
  boundKeys[actionKey] = true
end
local function ensureGuards() bindGuardFor('Activate'); bindGuardFor('Use'); end

-- === Refresh/create ===
local function refresh()
  if not window then
    window = ui.create(buildLayout())
  else
    window.layout = buildLayout()
    window:update()
  end
end

-- === Public API ===
function M.open(npc, tries, inflPct, gold, status)
  ensureGuards()

  npcName      = npc or ""
  triesLeft    = tries or 0
  inflationPct = inflPct or 0
  playerGold   = tonumber(gold or 0) or 0
  statusText   = status or ""

  local v = clamp(parseOffer(currentOfferStr), minOffer(), math.max(1, playerGold))
  if v < 1 and playerGold > 0 then v = 1 end
  currentOfferStr = tostring(v)

  if not windowPos then
    local W = windowWidth()
    local sz = screenSize()
    windowPos = clampToScreen(v2(math.floor(sz.x * 0.5 - W * 0.5), math.floor(sz.y * 0.25)))
  end

  if I.GamepadControls and I.GamepadControls.isGamepadCursorActive then
    prevGamepadCursor = I.GamepadControls.isGamepadCursorActive()
    if I.GamepadControls.setGamepadCursorActive then
      I.GamepadControls.setGamepadCursorActive(true)
    end
  end

  if window then window:destroy(); window = nil end
  refresh()
end

function M.update(npc, tries, inflPct, gold, status)
  if not window then return end
  npcName      = npc or npcName
  triesLeft    = tries or triesLeft
  inflationPct = inflPct or inflationPct
  playerGold   = tonumber(gold or playerGold) or 0
  statusText   = status or statusText
  refresh()
end

function M.close()
  if prevGamepadCursor ~= nil and I.GamepadControls and I.GamepadControls.setGamepadCursorActive then
    I.GamepadControls.setGamepadCursorActive(prevGamepadCursor)
    prevGamepadCursor = nil
  end
  if window then window:destroy(); window = nil end
end

return M
