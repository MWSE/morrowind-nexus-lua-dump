-- Press-to-Continue overlay for OpenMW 0.49
-- Pauses after a save finishes loading, shows "Press E to Continue", resumes on E.
-- Ensures it draws above ALL other UI by creating a topmost custom layer.

local ui    = require('openmw.ui')
local util  = require('openmw.util')
local input = require('openmw.input')
local core  = require('openmw.core')
local vfs   = require('openmw.vfs')

-- === Config ===
local PROMPT_TEXT = 'Press E to Continue'
local PAUSE_TAG   = 'PressToContinue'               -- tag passed to Pause/Unpause events
local BLACK_PATH  = 'textures/ptc_black.png'        -- 1x1 black PNG you provide
local TEXT_SIZE   = 28
local BASE_LAYER_NAME = 'PTCOverlay'                -- we'll append suffixes if we promote

-- Preload texture if available
local BLACK_TEX = nil
if vfs.fileExists(BLACK_PATH) then
  BLACK_TEX = ui.texture { path = BLACK_PATH }
else
  ui.printToConsole("[PressToContinue] Missing "..BLACK_PATH.." (background will be transparent).", util.color.rgb(1,1,0))
end

-- --- Layer management --------------------------------------------------------
-- We always render on our own custom layer that we insert AFTER the current topmost layer.
-- If another mod later inserts an even higher layer, we promote ourselves once to stay on top.

local overlayLayerName = BASE_LAYER_NAME

local function getTopmostLayerName()
  local lastName = 'HUD'              -- there is always at least HUD
  for i, layer in ipairs(ui.layers) do
    lastName = layer.name
  end
  return lastName
end

local function ensureOverlayLayerExists()
  if ui.layers.indexOf(overlayLayerName) ~= nil then return end
  local afterName = getTopmostLayerName()
  ui.layers.insertAfter(afterName, overlayLayerName, { interactive = true })
  ui.printToConsole(("[PressToContinue] Created top layer '%s' after '%s'."):format(overlayLayerName, afterName), util.color.rgb(1,1,0))
end

local function promoteOverlayLayerIfNeeded()
  -- If our layer isn’t the last one anymore, insert a new higher layer and switch to it.
  local myIndex = ui.layers.indexOf(overlayLayerName)
  local topName = getTopmostLayerName()
  local topIndex = ui.layers.indexOf(topName)
  if myIndex ~= nil and topIndex ~= nil and myIndex < topIndex then
    overlayLayerName = overlayLayerName .. "_top"
    ui.layers.insertAfter(topName, overlayLayerName, { interactive = true })
    ui.printToConsole("[PressToContinue] Promoted overlay to very top.", util.color.rgb(1,1,0))
    return true -- caller should rebuild UI on the new layer
  end
  return false
end

-- --- UI elements -------------------------------------------------------------

local bgElement = nil      -- root Image element
local textElement = nil    -- root Text element
local overlayActive = false
local waitForKeyRelease = false -- avoid immediate dismiss if E was held

local function createBackground()
  if not BLACK_TEX then return nil end
  return ui.create {
    layer = overlayLayerName,
    type  = ui.TYPE.Image,
    props = {
      autoSize = false,
      size = ui.screenSize(),     -- fill window
      resource = BLACK_TEX,
    },
    name = 'ptc_bg',
  }
end

local function createCenteredText()
  -- Root Text element centered at screen center via relativePosition + anchor.
  return ui.create {
    layer = overlayLayerName,
    type  = ui.TYPE.Text,
    props = {
      relativePosition = util.vector2(0.5, 0.5),
      anchor           = util.vector2(0.5, 0.5),
      text      = PROMPT_TEXT,
      textSize  = TEXT_SIZE,
      textColor = util.color.rgb(1, 1, 1),
      textShadow = true,
    },
    name = 'ptc_label',
  }
end

local function destroyOverlay()
  if textElement then textElement:destroy() textElement = nil end
  if bgElement   then bgElement:destroy()   bgElement   = nil end
end

local function buildOverlay()
  destroyOverlay()
  ensureOverlayLayerExists()
  bgElement   = createBackground()
  textElement = createCenteredText()
end

local function showOverlay()
  if overlayActive then return end
  -- Pause BEFORE creating UI so no world progression sneaks in.
  core.sendGlobalEvent('Pause', PAUSE_TAG)
  buildOverlay()
  overlayActive = true
  waitForKeyRelease = input.isKeyPressed(input.KEY.E) -- debounce if E was already down
end

local function hideOverlay()
  if not overlayActive then return end
  destroyOverlay()
  core.sendGlobalEvent('Unpause', PAUSE_TAG)
  overlayActive = false
  waitForKeyRelease = false
end

-- Create overlay ASAP at module load (earlier than onInit/onActive) to avoid any world-frame flicker.
showOverlay()

return {
  engineHandlers = {
    onActive = function()
      -- Keep this in case of odd activation order; ensures overlay exists on save load.
      showOverlay()
    end,

    -- Runs every frame even when paused for player-attached scripts.
    onFrame = function(dt)
      if not overlayActive then return end

      -- If another mod inserted a higher layer after us, promote and rebuild once.
      if promoteOverlayLayerIfNeeded() then
        buildOverlay()
      end

      local eDown = input.isKeyPressed(input.KEY.E)
      if waitForKeyRelease then
        if not eDown then
          waitForKeyRelease = false
        end
        return
      end
      if eDown then
        hideOverlay()
      end
    end,

    onInactive = function()
      hideOverlay()
    end,
  },
}
