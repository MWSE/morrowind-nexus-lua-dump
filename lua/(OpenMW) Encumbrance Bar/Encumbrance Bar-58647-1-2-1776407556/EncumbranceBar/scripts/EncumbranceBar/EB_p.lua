core    = require('openmw.core')
types   = require('openmw.types')
self    = require('openmw.self')
I       = require('openmw.interfaces')
ui      = require('openmw.ui')
util    = require('openmw.util')
v2      = util.vector2
async   = require('openmw.async')
input   = require('openmw.input')
storage = require('openmw.storage')

------------------------- CONSTANTS -------------------------
MODNAME = "EncumbranceBar"

------------------------- GLOBALS -------------------------
S = {}
G = {
	rootElement = nil,
	flashTimer  = 0,
	lastVisible = true,
	chargenDone = false,
	lastWeight  = nil,
	lastMax = nil,
}
F = {
	rebuildBar  = nil,
	clampOffset = nil,
}
lib = {
	getTexture = nil,
}

local G, F, lib = G, F, lib

------------------------- SETTINGS -------------------------
require('scripts.EncumbranceBar.EB_settings')
local generalSection = storage.playerSection('SettingsPlayer'..MODNAME..'General')

-- BetterBars settings (for snap positioning)
local bbSizeSection = storage.playerSection('SettingsBetterBarsSize')
local bbGeneralSection = storage.playerSection('SettingsBetterBarsGeneral')
local bbAppearanceSection = storage.playerSection('SettingsBetterBarsAppearance')
local bbSharedSection = storage.playerSection('BetterBars_Shared')

------------------------- LIBRARIES -------------------------
lib.makeBorder = require("scripts.EncumbranceBar.ui_makeBorder")
local borderCache = {}
local function getBorderTemplate(thickness)
	if not borderCache[thickness] then
		local style = thickness >= 3 and "thick" or "thin"
		borderCache[thickness] = lib.makeBorder(style, util.color.rgb(0.5, 0.5, 0.5), thickness, {
			type = ui.TYPE.Image,
			props = { relativeSize = v2(1, 1), alpha = 0.6 },
		}).borders
	end
	return borderCache[thickness]
end

local textureCache = {}
function lib.getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

function lib.lerpColor(a, b, t)
	t = math.max(0, math.min(1, t))
	return util.color.rgba(
		a.r + (b.r - a.r) * t,
		a.g + (b.g - a.g) * t,
		a.b + (b.b - a.b) * t,
		a.a + (b.a - a.a) * t
	)
end

------------------------- HELPERS -------------------------
-- float accumulators used by mousewheel resize; reset on mouse release
local scrollLength, scrollThickness
function F.clampOffset(x, y)
	local hudSize = ui.layers[ui.layers.indexOf("HUD")].size
	local halfX = math.floor(hudSize.x / 2)
	return math.max(-halfX, math.min(halfX, x)), math.min(math.max(-hudSize.y + 8, y), 8)
end

local function getFillColor(ratio)
	local threshold = S.BAR_THRESHOLD / 100
	local c
	if ratio <= threshold then
		c = lib.lerpColor(S.BAR_COLOR_LOW, S.BAR_COLOR_MID, ratio / threshold)
	else
		local transitionRange = (1 - threshold) * 0.1
		local t = math.min(1, (ratio - threshold) / transitionRange)
		c = lib.lerpColor(S.BAR_COLOR_MID, S.BAR_COLOR_HIGH, t)
	end

	if S.BAR_FLASH_DURATION > 0 and G.flashTimer > 0 then
		local t = G.flashTimer / S.BAR_FLASH_DURATION
		local fc = S.BAR_FLASH_COLOR
		c = lib.lerpColor(c, util.color.rgba(fc.r, fc.g, fc.b, c.a), t * 0.8)
	end
	return c
end

local function getEncumbrance()
	local cur = types.Actor.getEncumbrance(self)
	local max = types.Actor.getCapacity(self)
	local ratio = max > 0 and math.min(1, cur / max) or 0
	return cur, max, ratio
end

-- effective bar length = base length + per-capacity bonus
local function effectiveLength(baseLength)
	local mult = S.BAR_LENGTH_PER_CAPACITY or 0
	if mult <= 0 then return baseLength end
	local max = types.Actor.getCapacity(self)
	return math.floor(baseLength + max * mult + 0.5)
end

local function getSnapLayout()
	if S.BAR_SNAP_BB == "Off" then return nil end
	local bbThick = bbSizeSection:get("THICKNESS") or 12
	local bbSpacing = bbSizeSection:get("SPACING") or 3
	local bbPos = bbGeneralSection:get("POSITION") or "Bottom Left"
	local vo = bbThick + bbSpacing
	local ebIconSize = S.BAR_SHOW_ICON and bbThick or 0
	local above = S.BAR_SNAP_BB == "Above"

	-- Use actual BB position if available (handles drag + resize)
	local layout = bbSharedSection:get("layout")
	if layout then
		local bbX, bbY = layout.posX, layout.posY
		local x = bbX - ebIconSize
		if bbPos == "Bottom Left" then
			return {
				thickness = bbThick,
				position = v2(x, above and (bbY - 3 * vo) or (bbY + vo)),
				anchor = v2(0, 1),
				relativePosition = v2(0, 1),
			}
		else
			return {
				thickness = bbThick,
				position = v2(x, above and (bbY - vo) or (bbY + 3 * vo)),
				anchor = v2(0, 0),
				relativePosition = v2(0, 0),
			}
		end
	end

	-- Fallback: compute from defaults (BetterBars not loaded yet)
	local bbIcons = bbAppearanceSection:get("SHOW_ICONS") or false
	local bbIconShift = bbIcons and (bbThick + 2) or 0
	if bbPos == "Bottom Left" then
		local so = math.max(3, 57 - vo * 3)
		return {
			thickness = bbThick,
			position = v2(94 + bbIconShift - ebIconSize, above and (-so - 3 * vo) or (-so + vo)),
			anchor = v2(0, 1),
			relativePosition = v2(0, 1),
		}
	else
		local so = math.floor(vo / 2)
		return {
			thickness = bbThick,
			position = v2(so + bbIconShift - ebIconSize, above and (so - vo) or (so + 3 * vo)),
			anchor = v2(0, 0),
			relativePosition = v2(0, 0),
		}
	end
end

------------------------- BUILD UI -------------------------
-- external alpha (settable via EncumbranceBar_setAlpha event)
local containerAlpha = 1

-- mirrors BetterBars: hide bar during character generation and when HUD is toggled off
local function chargenFinished()
	if G.chargenDone then return true end
	if types.Player.getBirthSign(self) ~= "" then
		G.chargenDone = true
		return true
	end
	if types.Player.isCharGenFinished(self) then
		G.chargenDone = true
		return true
	end
	if types.Actor.inventory(self):find("chargen statssheet") then
		G.chargenDone = true
		return true
	end
	return false
end

local function buildLayout()
	local cur, max, ratio = getEncumbrance()
	local isVertical = S.BAR_VERTICAL
	local snap = getSnapLayout()
	local thick = snap and snap.thickness or S.BAR_THICKNESS
	local effLen = effectiveLength(S.BAR_LENGTH)
	local w = isVertical and thick or effLen
	local h = isVertical and effLen or thick
	local iconSize = S.BAR_SHOW_ICON and thick or 0
	-- text format: Off / current only / compact / spaced
	local showText = S.BAR_TEXT_MODE ~= "Off"
	local textStr
	if S.BAR_TEXT_MODE == "123" then
		textStr = string.format("%d", math.floor(cur + 0.5))
	elseif S.BAR_TEXT_MODE == "123/234" then
		textStr = string.format("%d/%d", math.floor(cur + 0.5), math.floor(max + 0.5))
	else
		textStr = string.format("%d / %d", math.floor(cur + 0.5), math.floor(max + 0.5))
	end
	local textRight = showText and S.BAR_TEXT_POSITION == "Right outside" and not isVertical
	local textPos = S.BAR_TEXT_POSITION
	local textSize = textRight and (thick + math.floor(thick/6)) or math.max(8, thick * 0.85)
	local fillColor = getFillColor(ratio)

	-- icon (left in horizontal, below in vertical)
	local iconWidget = {
		name = "icon",
		type = ui.TYPE.Image,
		props = {
			resource = lib.getTexture("textures/EncumbranceBar/icon.png"),
			size = v2(iconSize, iconSize),
			color = fillColor,
			autoSize = false,
		},
	}

	local fillTexture = isVertical and "textures/EncumbranceBar/fill2.png" or "textures/EncumbranceBar/fill.png"
	-- vertical fill grows up from bottom, horizontal grows right from left
	local fillRelSize = isVertical and v2(1, ratio) or v2(ratio, 1)
	local fillRelPos = isVertical and v2(0, 1) or v2(0, 0)
	local fillAnchor = isVertical and v2(0, 1) or v2(0, 0)

	local bgWidget = {
		name = "bg",
		type = ui.TYPE.Image,
		props = {
			resource = lib.getTexture("white"),
			relativeSize = v2(1, 1),
			color = S.BAR_BG_COLOR,
			alpha = 0.8,
		},
	}

	local fillWidget = {
		name = "fill",
		type = ui.TYPE.Image,
		props = {
			resource = lib.getTexture(fillTexture),
			relativeSize = fillRelSize,
			color = fillColor,
			relativePosition = fillRelPos,
			anchor = fillAnchor,
		},
	}

	-- centered weight text
	local textWidget = {
		name = "text",
		type = ui.TYPE.Text,
		props = {
			text = textStr,
			textSize = textSize,
			textColor = S.BAR_TEXT_COLOR,
			textShadow = true,
			textShadowColor = util.color.rgba(0, 0, 0, 0.75),
			relativePosition = v2(0.5, 0.5),
			anchor = v2(0.5, 0.5),
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
		},
	}

	-- inside-bar alignment: Left / Center / Right
	if textPos == "Left" then
		textWidget.props.relativePosition = v2(0, 0.5)
		textWidget.props.anchor = v2(0, 0.5)
		textWidget.props.position = v2(4, 0)
		textWidget.props.textAlignH = ui.ALIGNMENT.Start
	elseif textPos == "Right" then
		textWidget.props.relativePosition = v2(1, 0.5)
		textWidget.props.anchor = v2(1, 0.5)
		textWidget.props.position = v2(-4, 0)
		textWidget.props.textAlignH = ui.ALIGNMENT.End
	end

	-- bar container holding bg, fill and text stacked
	local barChildren = { bgWidget, fillWidget }
	if showText and not textRight then
		
		table.insert(barChildren, textWidget)
	end
	local barContainer = {
		name = "bar",
		type = ui.TYPE.Widget,
		template = getBorderTemplate(S.BAR_BORDER_THICKNESS),
		props = { size = v2(w, h) },
		content = ui.content(barChildren),
	}

	-- flex row, icon goes below the bar when vertical
	local rowChildren = {}
	if isVertical then
		table.insert(rowChildren, barContainer)
		if S.BAR_SHOW_ICON then table.insert(rowChildren, iconWidget) end
	else
		if S.BAR_SHOW_ICON then table.insert(rowChildren, iconWidget) end
		table.insert(rowChildren, barContainer)
	end

	-- text to the right of the bar (horizontal mode only)
	local textRightW = 0
	if textRight then
		textRightW = math.max(40, math.floor(textSize * 7))
		textWidget.props.relativePosition = v2(0, 0.5)
		textWidget.props.anchor = v2(0, 0.5)
		textWidget.props.textAlignH = ui.ALIGNMENT.Start
		textWidget.props.position = v2(0, -1)
		table.insert(rowChildren, {props = {size=v2(1,1)*2}})
		table.insert(rowChildren, {
			name = "textRight",
			type = ui.TYPE.Widget,
			props = { size = v2(textRightW, h) },
			content = ui.content({ textWidget }),
		})
	end

	local totalW = isVertical and math.max(w, iconSize) or (w + iconSize + textRightW)
	local totalH = isVertical and (h + iconSize) or h
	-- root anchored bottom-center with offsets
	return {
		layer = (snap or S.BAR_LOCK) and "HUD" or "Modal",
		type = ui.TYPE.Flex,
		props = {
			horizontal = not isVertical,
			size = v2(totalW, totalH),
			relativePosition = snap and snap.relativePosition or v2(0.5, 1),
			anchor = snap and snap.anchor or v2(0, 1),
			position = snap and snap.position or v2(S.BAR_X_OFFSET, S.BAR_Y_OFFSET),
			visible = G.lastVisible,
		},
		content = ui.content(rowChildren),
		userData = { isDragging = false, lastMousePos = v2(0, 0) },
		events = {
			mousePress = async:callback(function(data, elem)
				if data.button == 1 and not S.BAR_LOCK and S.BAR_SNAP_BB == "Off" then
					elem.userData.isDragging = true
					elem.userData.lastMousePos = data.position
				end
			end),
			mouseRelease = async:callback(function(data, elem)
				if elem.userData.isDragging then
					elem.userData.isDragging = false
					scrollLength, scrollThickness = nil, nil
					generalSection:set("BAR_X_OFFSET", math.floor(S.BAR_X_OFFSET + 0.5))
					generalSection:set("BAR_Y_OFFSET", math.floor(S.BAR_Y_OFFSET + 0.5))
					generalSection:set("BAR_LENGTH", S.BAR_LENGTH)
					generalSection:set("BAR_THICKNESS", S.BAR_THICKNESS)
				end
			end),
			mouseMove = async:callback(function(data, elem)
				if not elem.userData.isDragging then return end
				local delta = data.position - elem.userData.lastMousePos
				elem.userData.lastMousePos = data.position
				S.BAR_X_OFFSET, S.BAR_Y_OFFSET = F.clampOffset(
					S.BAR_X_OFFSET + delta.x,
					S.BAR_Y_OFFSET + delta.y
				)
				if G.rootElement then
					G.rootElement.layout.props.position = v2(S.BAR_X_OFFSET, S.BAR_Y_OFFSET)
					G.rootElement:update()
				end
			end),
		},
	}
end

function F.rebuildBar()
	if G.rootElement then G.rootElement:destroy() end
	if not S.BAR_ENABLED then G.rootElement = nil; return end
	G.rootElement = ui.create(buildLayout())
	G.rootElement.layout.props.alpha = containerAlpha
end

------------------------- UPDATE LOOP -------------------------
local function onUpdate(dt)
	if not S.BAR_ENABLED then
		if G.rootElement then G.rootElement:destroy(); G.rootElement = nil end
		return
	end
	if not G.rootElement then F.rebuildBar(); return end

	-- hide during chargen / when HUD is toggled off
	local shouldBeVisible = I.UI.isHudVisible() and chargenFinished()
	if shouldBeVisible ~= G.lastVisible then
		G.lastVisible = shouldBeVisible
		G.rootElement.layout.props.visible = shouldBeVisible
		G.rootElement:update()
	end
	if not shouldBeVisible then return end

	local cur, max, ratio = getEncumbrance()
	local weightChanged = G.lastWeight ~= cur or G.lastMax ~= max

	if G.lastMax ~= max and (S.BAR_LENGTH_PER_CAPACITY or 0) > 0 then
		G.lastWeight, G.lastMax = cur, max
		F.rebuildBar()
		return
	end
	
	if G.lastWeight ~= cur and G.lastWeight ~= nil and S.BAR_FLASH_DURATION > 0 then
		G.flashTimer = S.BAR_FLASH_DURATION
	end
	
	G.lastWeight = cur
	G.lastMax = max

	local wasFlashing = G.flashTimer > 0
	if wasFlashing then
		G.flashTimer = math.max(0, G.flashTimer - core.getRealFrameDuration())
	end

	if not weightChanged and not wasFlashing then return end

	local fillColor = getFillColor(ratio)
	local row = G.rootElement.layout
	local barContainer = row.content.bar
	local fillElem = barContainer.content.fill
	fillElem.props.relativeSize = S.BAR_VERTICAL and v2(1, ratio) or v2(ratio, 1)
	fillElem.props.color = fillColor
	if S.BAR_SHOW_ICON then
		row.content.icon.props.color = fillColor
	end
	local showText = S.BAR_TEXT_MODE ~= "Off"
	if showText and weightChanged then
		local txt
		if S.BAR_TEXT_MODE == "123" then
			txt = string.format("%d", math.floor(cur + 0.5))
		elseif S.BAR_TEXT_MODE == "123/234" then
			txt = string.format("%d/%d", math.floor(cur + 0.5), math.floor(max + 0.5))
		else
			txt = string.format("%d / %d", math.floor(cur + 0.5), math.floor(max + 0.5))
		end
		if S.BAR_TEXT_POSITION == "Right outside" and not S.BAR_VERTICAL then
			row.content.textRight.content.text.props.text = txt
		else
			barContainer.content.text.props.text = txt
		end
	end
	G.rootElement:update()
end

------------------------- MOUSEWHEEL RESIZE -------------------------
-- float accumulators so small multiplicative steps aren't lost to rounding
local function onMouseWheel(vertical)
	if not G.rootElement then return end
	if not G.rootElement.layout.userData.isDragging then return end
	scrollLength    = scrollLength    or S.BAR_LENGTH
	scrollThickness = scrollThickness or S.BAR_THICKNESS
	local factor = 1 + vertical * 0.03
	scrollLength    = math.max(40, math.min(400, scrollLength    * factor))
	scrollThickness = math.max(8,  math.min(80,  scrollThickness * factor))
	local isVertical = S.BAR_VERTICAL
	local length    = math.floor(scrollLength    + 0.5)
	local thickness = math.floor(scrollThickness + 0.5)
	S.BAR_LENGTH    = length
	S.BAR_THICKNESS = thickness
	local effLen = effectiveLength(length)
	local w = isVertical and thickness or effLen
	local h = isVertical and effLen or thickness
	local iconSize = S.BAR_SHOW_ICON and thickness or 0
	local row = G.rootElement.layout
	local bar = row.content.bar
	-- root flex
	row.props.size = v2(
		isVertical and math.max(w, iconSize) or (w + iconSize),
		isVertical and (h + iconSize) or h
	)
	-- container
	bar.props.size = v2(w, h)
	-- text size
	local showText = S.BAR_TEXT_MODE ~= "Off"
	local textRightActive = showText and S.BAR_TEXT_POSITION == "Right outside" and not isVertical
	local newTextSize = textRightActive and (thickness + math.floor(thickness/6)) or math.max(8, thickness * 0.85)
	if showText then
		if textRightActive then
			row.content.textRight.content.text.props.textSize = newTextSize
		else
			bar.content.text.props.textSize = newTextSize
		end
	end
	-- icon
	if S.BAR_SHOW_ICON then
		row.content.icon.props.size = v2(iconSize, iconSize)
	end
	-- text-right container + row width
	if textRightActive then
		local outerText = row.content.textRight
		local textRightW = math.max(40, math.floor(newTextSize * 7))
		outerText.props.size = v2(textRightW, h)
		row.props.size = v2(w + iconSize + textRightW, h)
	end
	G.rootElement:update()
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

-- initial build
F.rebuildBar()

-- Rebuild when BetterBars settings change (for snap positioning)
local function onBBSettingChange()
	if S.BAR_SNAP_BB ~= "Off" then F.rebuildBar() end
end
bbSizeSection:subscribe(async:callback(onBBSettingChange))
bbGeneralSection:subscribe(async:callback(onBBSettingChange))
bbAppearanceSection:subscribe(async:callback(onBBSettingChange))
bbSharedSection:subscribe(async:callback(function()
	if S.BAR_SNAP_BB == "Off" then return end
	if not G.rootElement then return end
	local snap = getSnapLayout()
	if snap then
		G.rootElement.layout.props.position = snap.position
		G.rootElement:update()
	end
end))

-- external alpha control (mirrors BetterBars_setAlpha)
local function setAlpha(alpha)
	containerAlpha = alpha
	if G.rootElement then
		G.rootElement.layout.props.alpha = containerAlpha
		G.rootElement:update()
	end
end

return {
	engineHandlers = {
		onUpdate = onUpdate,
	},
	eventHandlers = {
		EncumbranceBar_setAlpha = setAlpha,
	},
}