-- scripts/speechcraft_bribe/ui.lua
-- OpenMW 0.49 – Bribery Minigame UI (proper title bar drag)
-- Title bar is full-width with a faint background; drag logic lives on the
-- ROOT container but only activates if the click is inside the title bar band.

local ui     = require('openmw.ui')
local util   = require('openmw.util')
local async  = require('openmw.async')
local input  = require('openmw.input')
local I      = require('openmw.interfaces')
local uiConstants = require('scripts.omw.mwui.constants')

local v2 = util.vector2

local M = {}

local window = nil
local currentOffer = ""

-- Configurable dimensions
local TOP_PAD  = 4     -- px spacer inside the frame above the bar
local TITLE_H  = 28    -- px draggable bar height
local WINDOW_W = 560   -- px keep bar and body aligned

-- Session position + drag state
local windowPos = nil
local dragState = { active = false, dragStart = nil, winStart = nil }

M.onSubmit = nil

local COLOR_HEADER = uiConstants.headerColor or util.color.rgb(1, 1, 1)
local COLOR_NORMAL = uiConstants.normalColor or util.color.rgb(1, 1, 1)

-- Helpers --------------------------------------------------------------

local function screenSize()
  return ui.screenSize()
end

local function clampToScreen(p)
  local size = screenSize()
  local margin = 16
  local x = math.max(0, math.min(p.x, math.max(0, size.x - margin)))
  local y = math.max(0, math.min(p.y, math.max(0, size.y - margin)))
  return v2(x, y)
end

local function destroy()
  if window then
    window:destroy()
    window = nil
  end
  currentOffer = "0"
  dragState.active = false
end

local function spacer(w, h)
  return { type = ui.TYPE.Widget, props = { size = v2(w or 0, h or 8) } }
end

local function text(label, size)
  return {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      text = label or "",
      autoSize = true,
      textSize = size or 16,
      textColor = COLOR_NORMAL,
      textShadow = true,
    },
  }
end

local function button(labelText, onClick)
  return {
    template = I.MWUI.templates.textNormal,
    type = ui.TYPE.Text,
    props = {
      text = labelText,
      autoSize = true,
      textSize = 18,
      textColor = COLOR_NORMAL,
      textShadow = true,
    },
    events = {
      mouseClick = async:callback(function()
        if onClick then onClick() end
      end),
    },
  }
end

local function row(children)
  return {
    type = ui.TYPE.Flex,
    props = {
      horizontal = true,
      autoSize = true,
      align = ui.ALIGNMENT.Start,
      arrange = ui.ALIGNMENT.Center,
    },
    content = ui.content(children),
  }
end

local function col(children)
  return {
    type = ui.TYPE.Flex,
    props = {
      horizontal = false,
      autoSize = true,
      align = ui.ALIGNMENT.Start,
      arrange = ui.ALIGNMENT.Start,
    },
    content = ui.content(children),
  }
end

local function parseOffer(s)
  local digits = tostring(s or ""):gsub("%D", "")
  if digits == "" then digits = "" end
  return tonumber(digits) or 0
end

-- Layout ---------------------------------------------------------------
-- Map an inflation percent (>= 0) to an obscured label.
-- Tiers (defaults):
--   0%                  -> None
--   1% .. 19%           -> Low
--   20% .. 49%          -> Medium
--   50% .. 99%          -> High
--   100% .. 199%        -> Very High
--   200%+               -> Extreme

local function inflationLabel(pct)
  local p = tonumber(pct) or 0
  if p < 1 then
   return "None"
  elseif p < 20 then
    return "Low"
  elseif p < 50 then
    return "Medium"
  elseif p < 100 then
    return "High"
  elseif p < 200 then
    return "Very High"
  else
    return "Extreme"
  end
end

local function buildContent(triesLeft, inflationPct, playerGold, statusText)
  return ui.content({
    row({
      text("Tries left:", 16),
      spacer(10, 1),
      text(tostring(triesLeft or 0), 16),
    }),

    spacer(0, 4),

    row({
      text("Inflation:", 16),
      spacer(10, 1),
      text(inflationLabel(inflationPct), 16),
    }),

    spacer(0, 10),

    row({
      text("Offer (gold):", 16),
      spacer(10, 1),
      {
        name = "OfferInput",
        type = ui.TYPE.TextEdit,
        props = {
          text = currentOffer,
          size = v2(240, 32),
          textSize = 18,
          textColor = COLOR_NORMAL,
        },
        events = {
          textChanged = async:callback(function(newText, layout)
            local digits = tostring(newText or ""):gsub("%D", "")
            currentOffer = digits
            if layout and layout.props then layout.props.text = digits end
            if window then window:update() end
          end),
          keyPress = async:callback(function(ev)
            if ev.code == input.KEY.Enter then
              if M.onSubmit then M.onSubmit(parseOffer(currentOffer)) end
              return true
            end
          end),
        },
      },
      spacer(16, 1),
      text(string.format("Your gold: %d", tonumber(playerGold) or 0), 16),
    }),

    spacer(0, 10),

    text(statusText or "", 16),

    spacer(0, 12),

    row({
      button("[ Submit ]", function()
        if M.onSubmit then M.onSubmit(parseOffer(currentOffer)) end
      end),
      spacer(24, 1),
      button("[ Cancel ]", function() destroy() end),
    }),
  })
end

-- Title bar: darker strip + thin separator (drag detected by the root via a Y-band)
local function buildTopBar(npcName)
  -- darker background strip
  local bg = {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture { path = 'white' },
      color = util.color.rgb(0, 0, 0),
      alpha = 0.35,
      relativeSize = v2(1, 1),
    },
  }

  -- bottom separator line
  local sep = {
    type = ui.TYPE.Image,
    props = {
      resource = ui.texture { path = 'white' },
      color = util.color.rgb(1, 1, 1),
      alpha = 0.40,
      size = v2(WINDOW_W, 2),
      position = v2(0, TITLE_H - 2),
    },
  }

  local titleRow = {
    type = ui.TYPE.Flex,
    props = { horizontal = true, autoSize = true, arrange = ui.ALIGNMENT.Center, align = ui.ALIGNMENT.Center },
    content = ui.content({
      spacer(8, 0),
      {
        type = ui.TYPE.Text,
        props = {
          text = "Bribe: " .. (npcName or ""),
          textSize = 20,
          textColor = COLOR_NORMAL,
          textShadow = true,
          autoSize = true,
        },
      },
      spacer(8, 0),
    }),
  }

  return {
    type = ui.TYPE.Container,
    name = 'BribeTopBar',
    props = { size = v2(WINDOW_W, TITLE_H) },
    -- Container overlays children; order matters (later = on top)
    content = ui.content({ bg, sep, titleRow }),
  }
end

local function buildLayout(npcName, triesLeft, inflationPct, playerGold, statusText)
  if not windowPos then
    local size = screenSize()
    windowPos = clampToScreen(v2(size.x * 0.35, size.y * 0.25))
  end

  local inner  = col(buildContent(triesLeft, inflationPct, playerGold, statusText))
  local topBar = buildTopBar(npcName)

  local bodyContainer = {
    type = ui.TYPE.Container,
    props = { size = v2(WINDOW_W, 0) },
    content = ui.content({ inner }),
  }

  -- Template is a Container; type must match.
  local boxed = {
    template = I.MWUI.templates.boxTransparentThick,
    type = ui.TYPE.Container,
    content = ui.content({
      {
        type = ui.TYPE.Flex,
        props = { horizontal = false, autoSize = true, align = ui.ALIGNMENT.Start, arrange = ui.ALIGNMENT.Start },
        content = ui.content({
          spacer(0, TOP_PAD),
          topBar,
          spacer(0, 6),
          bodyContainer,
          spacer(0, 6),
        }),
      },
    }),
  }

  return {
    layer = "Windows",
    type = ui.TYPE.Container,
    name = "BribeWindow",
    props = {
      position = windowPos,
      autoSize = true,
    },
    events = {
      keyPress = async:callback(function(ev)
        if ev.code == input.KEY.Escape then
          destroy(); return true
        elseif ev.code == input.KEY.Enter then
          if M.onSubmit then M.onSubmit(parseOffer(currentOffer)) end
          return true
        end
      end),
      -- Drag on the ROOT, but only when the click is inside the title bar band.
      mousePress = async:callback(function(e)
        if e.button ~= 1 then return end
        local pos = windowPos or v2(0,0)
        local localY = e.position.y - pos.y
        if localY >= TOP_PAD and localY <= TOP_PAD + TITLE_H then
          dragState.active    = true
          dragState.dragStart = e.position
          dragState.winStart  = pos
        end
      end),
      mouseRelease = async:callback(function(_)
        dragState.active = false
      end),
      mouseMove = async:callback(function(e)
        if not dragState.active or not dragState.dragStart or not dragState.winStart then return end
        local dx = e.position.x - dragState.dragStart.x
        local dy = e.position.y - dragState.dragStart.y
        local newPos = clampToScreen(v2(dragState.winStart.x + dx, dragState.winStart.y + dy))
        if newPos.x ~= windowPos.x or newPos.y ~= windowPos.y then
          windowPos = newPos
          if window then
            window.layout.props.position = newPos
            window:update()
          end
        end
      end),
    },
    content = ui.content({ boxed }),
  }
end

-- Public ---------------------------------------------------------------

function M.open(npcName, triesLeft, inflationPct, playerGold, statusText)
  local layout = buildLayout(npcName, triesLeft, inflationPct, playerGold, statusText)
  if window == nil then
    window = ui.create(layout)
  else
    window.layout = layout
    window:update()
  end
end

function M.update(npcName, triesLeft, inflationPct, playerGold, statusText)
  if not window then return end
  window.layout = buildLayout(npcName, triesLeft, inflationPct, playerGold, statusText)
  window:update()
end

function M.close()
  destroy()
end

return M
