-- shared game libraries for all mod files:
core = require('openmw.core')
types = require('openmw.types')
self = require('openmw.self')
I = require('openmw.interfaces')
ui = require('openmw.ui')
util = require('openmw.util')
v2 = util.vector2
async = require('openmw.async')
input = require('openmw.input')
storage = require('openmw.storage')

------------------------- CONSTANTS -------------------------
MODNAME = "LevelUpIndicator"
local iLevelUpTotal = core.getGMST("iLevelUpTotal") or 10

------------------------- GLOBALS -------------------------
S = {} -- settings
G = { -- runtime state
	arrowElement = nil,
	arrowTimer   = nil,
}
F = { -- mod functions + helpers
	showArrow   = nil,
	clampOffset = nil,
}
lib = { -- portable, generic helpers
	getTexture = nil,
--	lib.makeBorder = nil,
}
--saveData = nil -- currently unused

-- performance opt:
local G, F, lib = G, F, lib

------------------------- SETTINGS -------------------------
require('scripts.LevelUpIndicator.LUI_settings')
local generalSection = storage.playerSection('SettingsPlayer'..MODNAME..'General') -- for saving offsets and size

------------------------- LIBRARIES -------------------------
local textureCache = {}
function lib.getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

-- border element template (thick (when 3-4px) or thin, borderColor, thickness in pixels, background)
--lib.makeBorder = require("scripts.LevelUpIndicator.ui_makeBorder")

--local borderTemplate = makeBorder("thin", util.color.rgb(0.5, 0.5, 0.5), 1, {
--    type = ui.TYPE.Image,
--    props = { relativeSize = v2(1, 1), alpha = 0.6 },
--}).borders

------------------------- HELPERS -------------------------
-- clamp x,y offset to hud bounds
function F.clampOffset(x, y)
	local layerId = ui.layers.indexOf("HUD")
	local hudSize = ui.layers[layerId].size -- layer id and hud size might change in case the player resizes the window. very rare
	return
		math.max(-math.floor(hudSize.x / 2), math.min(math.floor(hudSize.x / 2), x)),
		math.min(math.max(-hudSize.y + 8, y), 8)
end

------------------------- MAIN -------------------------
local function getAlpha()
	if not S.ARROW_LOCK then return 1 end -- unlocked = always fully visible for dragging
	if not G.arrowTimer then return 0 end
	-- fade in
	if G.arrowTimer <= S.ARROW_FADE_IN then
		return G.arrowTimer / math.max(0.001, S.ARROW_FADE_IN)
	end
	-- hold and optionally pulsing
	local holdEnd = S.ARROW_FADE_IN + S.ARROW_HOLD
	if G.arrowTimer <= holdEnd then
		if S.ARROW_PULSES and S.ARROW_PULSES > 0 and S.ARROW_HOLD > 0 then
			local t = (G.arrowTimer - S.ARROW_FADE_IN) / S.ARROW_HOLD
			local a = math.acos(1/6)  -- plateau edge of 0.9 + 0.6*cos
			local x = -a + (2 * math.pi * (S.ARROW_PULSES) + 2 * a) * t
			return math.min(1, 0.9 + 0.6 * math.cos(x))
		end
		return 1
	end
	-- fade out
	local totalDuration = holdEnd + S.ARROW_FADE_OUT
	if G.arrowTimer <= totalDuration then
		return 1 - (G.arrowTimer - holdEnd) / math.max(0.001, S.ARROW_FADE_OUT)
	end
	return 0
end

local function destroyArrow()
	if G.arrowElement then
		G.arrowElement:destroy()
		G.arrowElement = nil
	end
	G.arrowTimer = nil
end

local function createArrow()
	if G.arrowElement then G.arrowElement:destroy() end
	local texturePath = "textures/LevelUpIndicator/arrow" .. S.ARROW_VARIATION
	if S.ARROW_GRAYSCALE then
		texturePath = texturePath .. "gray"
	end
	texturePath = texturePath .. ".png"
	
	-- root, level up arrow
	G.arrowElement = ui.create({
		type = ui.TYPE.Image,
		layer = S.ARROW_LOCK and "HUD" or "Modal",
		props = {
			resource = lib.getTexture(texturePath),
			color = S.ARROW_COLOR,
			size = v2(S.ARROW_SIZE, S.ARROW_SIZE),
			relativePosition = v2(0.5, 1),
			anchor = v2(0.5, 1),
			position = v2(S.ARROW_X_OFFSET, S.ARROW_Y_OFFSET),
			alpha = getAlpha(),
		},
		userData = {
			isDragging = false,
			lastMousePos = v2(0, 0),
		},
	})

	G.arrowElement.layout.events = {
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then
				elem.userData.isDragging = true
				elem.userData.lastMousePos = data.position
			end
			G.arrowElement:update()
		end),

		mouseRelease = async:callback(function(data, elem)
			if elem.userData.isDragging then
				elem.userData.isDragging = false
				generalSection:set("ARROW_X_OFFSET", math.floor(S.ARROW_X_OFFSET))
				generalSection:set("ARROW_Y_OFFSET", math.floor(S.ARROW_Y_OFFSET))
				generalSection:set("ARROW_SIZE", math.floor(S.ARROW_SIZE))
			end
			G.arrowElement:update()
		end),

		mouseMove = async:callback(function(data, elem)
			if not elem.userData.isDragging then return end
			local delta = data.position - elem.userData.lastMousePos
			elem.userData.lastMousePos = data.position
			local newPos = (G.arrowElement.layout.props.position or v2(0, 0)) + delta
			S.ARROW_X_OFFSET, S.ARROW_Y_OFFSET = F.clampOffset(newPos.x, newPos.y)
			G.arrowElement.layout.props.position = v2(S.ARROW_X_OFFSET, S.ARROW_Y_OFFSET)
			G.arrowElement:update()
		end),
	}
end

function F.showArrow()
	G.arrowTimer = math.min(G.arrowTimer or 0, S.ARROW_FADE_IN)
	createArrow()
end

local function canLevelUp()
	local lvl = types.Actor.stats.level(self)
	return lvl.progress >= iLevelUpTotal
end

I.SkillProgression.addSkillLevelUpHandler(function(skillid, source, options)
	if not S.ARROW_ENABLED then return end
	-- wait a frame so every mod has applied their changes
	async:newUnsavableSimulationTimer(0, function()
		if canLevelUp() then
			F.showArrow()
		end
	end)
end)

local function onUpdate(dt)
	if not G.arrowTimer or not S.ARROW_LOCK then return end

	local realDt = core.getRealFrameDuration()
	G.arrowTimer = G.arrowTimer + realDt

	local alpha = getAlpha()
	if alpha <= 0 and G.arrowTimer > 0 then
		destroyArrow()
		return
	end

	if G.arrowElement then
		G.arrowElement.layout.props.alpha = alpha
		G.arrowElement.layout.props.size = v2(S.ARROW_SIZE, S.ARROW_SIZE)
		G.arrowElement.layout.props.color = S.ARROW_COLOR
		G.arrowElement.layout.props.position = v2(S.ARROW_X_OFFSET, S.ARROW_Y_OFFSET)
		G.arrowElement:update()
	end
end

-- scroll while dragging to resize. saved on mouseRelease
local function onMouseWheel(vertical)
	if not G.arrowElement then return end
	if not G.arrowElement.layout.userData.isDragging then return end
	S.ARROW_SIZE = math.max(12, math.min(128, S.ARROW_SIZE + vertical * 2))
	G.arrowElement.layout.props.size = v2(S.ARROW_SIZE, S.ARROW_SIZE)
	G.arrowElement:update() --updating element in place, recreation would cause a focus loss
end

if input.triggers["MenuMouseWheelUp"] then
	input.registerTriggerHandler("MenuMouseWheelUp", async:callback(function()
		onMouseWheel(1)
	end))
end
if input.triggers["MenuMouseWheelDown"] then
	input.registerTriggerHandler("MenuMouseWheelDown", async:callback(function()
		onMouseWheel(-1)
	end))
end

if not S.ARROW_LOCK then
	F.showArrow()
end

--local function onLoad(data)
--	--global saveData
--	saveData = data or {}
--end

--local function onSave(data)
--	return saveData
--end

return {
	engineHandlers = {
		--onInit = onLoad,
		--onLoad = onLoad,
		--onSave = onSave,
		onUpdate = onUpdate,
	},
}