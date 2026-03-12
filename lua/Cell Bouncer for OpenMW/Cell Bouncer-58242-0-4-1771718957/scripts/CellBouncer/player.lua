local ui      = require('openmw.ui')
local util    = require('openmw.util')
local core    = require('openmw.core')
local ambient = require('openmw.ambient')
local self    = require('openmw.self')
local vfs     = require('openmw.vfs')
local types   = require('openmw.types')

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

-- Seconds to wait before allowing another boundary message
-- Prevents repeat events from stacking
local MESSAGE_COOLDOWN = 2.09
local lastMessageTime = 0

-- Seconds to wait before playing the boundary message again
-- Prevents repeat events from stacking
local SNDFILE_COOLDOWN = 6.0
local lastSndFileTime = 0

-- Duration of the fade-in effect in seconds
local FADE_IN_DURATION = 1.25

-- =============================================================================
-- UI LAYER MANAGEMENT
-- =============================================================================

-- Init vars
local overlayLayerName = 'CBOverlay'

local function ensureOverlayLayerExists()
	if ui.layers.indexOf(overlayLayerName) ~= nil then return end
	ui.layers.insertBefore('Windows', overlayLayerName, { interactive = false })
end

-- =============================================================================
-- UI ELEMENTS
-- =============================================================================

-- Init vars
local BLACK_PATH	= 'textures/CellBouncer/cb_black.png'	-- 1x1 black PNG
local bgElement = nil																		-- root Image element
local overlayActive = false

-- Preload texture if available
local BLACK_TEX = nil
if vfs.fileExists(BLACK_PATH) then
	BLACK_TEX = ui.texture { path = BLACK_PATH }
else
	ui.printToConsole("[CellBouncer] Missing "..BLACK_PATH.." (background will be transparent).", util.color.rgb(1,1,0))
end

local function createBackground()
	if not BLACK_TEX then return nil end
	return ui.create {
		layer = overlayLayerName,
	type	= ui.TYPE.Image,
		props = {
			autoSize = false,
			size = ui.screenSize(),		 -- fill window
			resource = BLACK_TEX,
		alpha = 1.0,
		},
		name = 'cb_bg',
	}
end

local function destroyOverlay()
	if bgElement then bgElement:destroy()	 bgElement	 = nil end
end

local function buildOverlay()
	destroyOverlay()
	ensureOverlayLayerExists()
	bgElement	 = createBackground()
end

local function showOverlay()
	if overlayActive then return end
	buildOverlay()
	overlayActive = true
end

local function hideOverlay()
	if not overlayActive then return end
	destroyOverlay()
	overlayActive = false
end

-- =============================================================================
-- MAIN LOOP
-- =============================================================================

local isFadingIn = false
local fadeElapsed = 0

return {
	engineHandlers = {
		onFrame = function(dt)
			if not isFadingIn or not bgElement then return end
			
			fadeElapsed = fadeElapsed + dt
			
			local t = fadeElapsed / FADE_IN_DURATION
			if t >= 1.0 then
				-- Fade complete
				bgElement.layout.props.alpha = 0.0
				bgElement:update()

				hideOverlay()
				isFadingIn = false
				return
			end
			
			-- Linear fade from black to transparent
			bgElement.layout.props.alpha = 1.0 - t
			bgElement:update()
		end
	},
	eventHandlers = {
		DisplayBoundaryMessage = function(messageText)
			local currentTime = core.getRealTime()
			
			if (currentTime - lastMessageTime) >= MESSAGE_COOLDOWN then
				ui.showMessage(messageText)
				lastMessageTime = currentTime
			end
		end,
		PlaySoundFile = function(soundFile)
			local currentTime = core.getRealTime()
			
			if (currentTime - lastSndFileTime) >= SNDFILE_COOLDOWN then
				ambient.say(soundFile)
				lastSndFileTime = currentTime
			end
		end,
		FlipCamera = function()
			self.controls.yawChange = math.pi
		end,
		ScreenFadeOut = function()
			showOverlay()
			
			-- Start fully black
			bgElement.layout.props.alpha = 1.0
			bgElement:update()
			
			-- Arm fade-in
			isFadingIn = true
			fadeElapsed = 0
		end
	}
}