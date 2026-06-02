ui = require('openmw.ui')
util = require('openmw.util')
core = require('openmw.core')
time = require('openmw_aux.time')
async = require('openmw.async')
v2 = util.vector2
I = require('openmw.interfaces')
storage = require('openmw.storage')
input = require('openmw.input')
types = require('openmw.types')
self = require("openmw.self")

MODNAME = "LocationHUD"

-- localization
L = require('scripts.locationhud.LH_locale')
borderTemplates = require('scripts.locationhud.LH_makeborder')

uiSection = storage.playerSection('Settings'..MODNAME.."General")
appearanceSection = storage.playerSection('Settings'..MODNAME.."Appearance")
require('scripts.locationhud.LH_settings')

locationHud = nil
locationText = nil

local lastCellName = nil
local fadeStartTime = nil

function updateLocationDisplay(force)
	if not locationText then return end
	
	local cell = self.cell
	local cellName = ""
	if cell then
		if cell.name and cell.name ~= "" then
			cellName = cell.name
		elseif cell.region and cell.region ~= "" then
			cellName = cell.region
		end
	end
	
	local cellChanged = cellName ~= lastCellName
	
	if force or cellChanged then
		locationText.props.text = cellName
		locationText.props.textColor = TEXT_COLOR
		
		lastCellName = cellName
		
		if cellChanged then
			fadeStartTime = core.getSimulationTime()
			locationHud.layout.props.alpha = 1
		elseif force then
			fadeStartTime = nil
			locationHud.layout.props.alpha = 1
		end
	end
	refreshUiVisibility()
end

function createLocationHud()
	-- clean up existing hud if it exists
	if locationHud then
		locationHud:destroy()
		locationHud = nil
		locationText = nil
	end
	
	locationHudBackground = {
		type = ui.TYPE.Image,
		name = "locationHudBackground",
		props = {
			resource = ui.texture { path = 'black' },
			relativeSize = v2(1,1),
			alpha = BACKGROUND_ALPHA
		}
	}
	
	local pad = v2(HUD_PADDING, HUD_PADDING)
	local template
	local paddingTemplate
	if HUD_BORDER then
		local borderFile = (HUD_BORDER_STYLE == "thick" or HUD_BORDER_STYLE == "verythick") and "thick" or "thin"
		local borderOffset = HUD_BORDER_STYLE == "verythick" and 4 or HUD_BORDER_STYLE == "thick" and 3 or HUD_BORDER_STYLE == "normal" and 2 or 1
		local borders = borderTemplates(borderFile, HUD_BORDER_COLOR, borderOffset, locationHudBackground, pad)
		template = borders.borders
		paddingTemplate = borders.padding
	else
		template = { content = ui.content{} }
		template.content:add(locationHudBackground)
		if HUD_PADDING > 0 then
			paddingTemplate = {
				type = ui.TYPE.Container,
				content = ui.content {
					{ props = { size = pad } },
					{ external = { slot = true }, props = { position = pad, relativeSize = v2(1, 1) } },
					{ props = { position = pad, relativePosition = v2(1, 1), size = pad } },
				},
			}
		end
	end
	
	local anchorPoint = v2(0, 0)
	if TEXT_ALIGNMENT == "Center" then
		anchorPoint = v2(0.5, 0)
	elseif TEXT_ALIGNMENT == "Right" then
		anchorPoint = v2(1, 0)
	end
	
	locationHud = ui.create({
		type = ui.TYPE.Container,
		layer = HUD_LOCK and 'Scene' or 'Modal',
		name = "locationHud",
		template = template,
		props = {
			position = v2(HUD_X_POS, HUD_Y_POS),
			anchor = anchorPoint,
		},
		content = ui.content {},
		userData = {
			windowStartPosition = v2(HUD_X_POS, HUD_Y_POS),
		}
	})
	
	locationHud.layout.events = {
		mousePress = async:callback(function(data, elem)
			if data.button == 1 then  -- left mouse button
				if not elem.userData then
					elem.userData = {}
				end
				elem.userData.isDragging = true
				elem.userData.lastMousePos = data.position
			end
			locationHud:update()
		end),
		
		mouseRelease = async:callback(function(data, elem)
			if elem.userData then
				elem.userData.isDragging = false
			end
			locationHud:update()
		end),
		
		mouseMove = async:callback(function(data, elem)
			if elem.userData and elem.userData.isDragging then
				local delta = data.position - elem.userData.lastMousePos
				elem.userData.lastMousePos = data.position
				local newPosition = (locationHud.layout.props.position or v2(0, 0)) + delta
				uiSection:set("HUD_X_POS", math.floor(newPosition.x))
				uiSection:set("HUD_Y_POS", math.floor(newPosition.y))
				locationHud.layout.props.position = newPosition
				locationHud:update()
			end
		end),
	}
	locationFlex = {
		type = ui.TYPE.Flex,
		name = "locationFlex",
		props = {
			horizontal = false,
			autoSize = true,
			size = v2(1,1),
			arrange = ui.ALIGNMENT.Start
		},
		content = ui.content{}
	}
	if paddingTemplate then
		locationHud.layout.content:add {
			template = paddingTemplate,
			content = ui.content { locationFlex },
		}
	else
		locationHud.layout.content:add(locationFlex)
	end
	
	locationText = {
		type = ui.TYPE.Text,
		name = "locationText",
		props = {
			text = "",
			textColor = TEXT_COLOR,
			textShadow = true,
			textShadowColor = util.color.rgba(0,0,0,0.9),
			textAlignV = ui.ALIGNMENT.Start,
			textAlignH = ui.ALIGNMENT.Start,
			textSize = FONT_SIZE,
		},
	}
	
	locationFlex.content:add(locationText)
	
	updateLocationDisplay(true)
end

if input.triggers["MenuMouseWheelUp"] then
	input.registerTriggerHandler("MenuMouseWheelUp", async:callback(function()
		local vertical = 1
		if locationHud.layout.userData.isDragging then
			if input.isShiftPressed() then
				appearanceSection:set("BACKGROUND_ALPHA", math.min(1, math.max(0, BACKGROUND_ALPHA + vertical/10)))
			else
				appearanceSection:set("FONT_SIZE", math.max(5, FONT_SIZE + vertical)) -- minimum 5 to keep readable
			end
		end
	end))
end
if input.triggers["MenuMouseWheelDown"] then
	input.registerTriggerHandler("MenuMouseWheelDown", async:callback(function()
		local vertical = -1
		if locationHud.layout.userData.isDragging then
			if input.isShiftPressed() then
				appearanceSection:set("BACKGROUND_ALPHA", math.min(1, math.max(0, BACKGROUND_ALPHA + vertical/10)))
			else
				appearanceSection:set("FONT_SIZE", math.max(5, FONT_SIZE + vertical)) -- minimum 5 to keep readable
			end
		end
	end))
end

function onLoad(data)
	saveData = data or {}
	
	local layerId = ui.layers.indexOf("HUD")
	local hudLayerSize = ui.layers[layerId].size
	
	local minX = -FONT_SIZE*1.8
	local maxX = hudLayerSize.x - FONT_SIZE*2
	
	if TEXT_ALIGNMENT=="Right" then
		minX = FONT_SIZE*2
		maxX = hudLayerSize.x + FONT_SIZE*1.8
	elseif TEXT_ALIGNMENT=="Center" then
		minX = 0
		maxX = hudLayerSize.x
	end
	uiSection:set("HUD_X_POS", math.floor(math.max(minX, math.min(HUD_X_POS, maxX))))
	uiSection:set("HUD_Y_POS", math.floor(math.max(-FONT_SIZE*0.4, math.min(HUD_Y_POS, hudLayerSize.y - FONT_SIZE))))
	
	createLocationHud()
	
	-- poll cell name for change detection
	stopTimerFn = time.runRepeatedly(updateLocationDisplay, 0.5 * time.second, {
		type = time.SimulationTime,
		initialDelay = 0
	})
end

input.registerTriggerHandler("ToggleHUD", async:callback(function()
	locationHud.layout.props.visible = I.UI.isHudVisible()
	locationHud:update()
end))

function onSave()
	return saveData
end

function refreshUiVisibility()
	-- latch chargen completion once any signal fires
	if not saveData.chargenFinished
		and (types.Player.getBirthSign(self) ~= ""
			or types.Player.isCharGenFinished(self)
			or types.Actor.inventory(self):find("chargen statssheet")) then
		saveData.chargenFinished = true
	end
	
	-- exterior gate when HUD_EXTERIOR is enabled
	if saveData.chargenFinished and I.UI.isHudVisible() and ( not HUD_EXTERIOR or (self.cell:hasTag("QuasiExterior") or self.cell.isExterior)) then
		if HUD_DISPLAY == "Always" then
			locationHud.layout.props.visible = true
			locationHud:update()
		elseif HUD_DISPLAY == "Never" then
			locationHud.layout.props.visible = false
			locationHud:update()
		elseif HUD_DISPLAY == "Interface Only" then
			locationHud.layout.props.visible = currentUiMode == "Interface"
			locationHud:update()
		elseif HUD_DISPLAY == "Hide on Interface" then
			locationHud.layout.props.visible = currentUiMode == nil
			locationHud:update()
		else--if HUD_DISPLAY == "Hide on Dialogue Only" then
			locationHud.layout.props.visible = currentUiMode ~= "Dialogue" and currentUiMode ~= "Barter"
			locationHud:update()
		end
	else
		locationHud.layout.props.visible = false
		locationHud:update()
	end
end

function UiModeChanged(data)
	if not locationHud then return end
	currentUiMode = data.newMode
	refreshUiVisibility()
	shouldRefreshUiVisibility = 3
	
	-- for fast travel
	updateLocationDisplay()
end

local function onFrame()
	if shouldRefreshUiVisibility then
		shouldRefreshUiVisibility = shouldRefreshUiVisibility - 1
		if shouldRefreshUiVisibility == 0 then
			shouldRefreshUiVisibility = nil
			refreshUiVisibility()
		end
	end
	
	if fadeStartTime and locationHud then
		local elapsed = core.getSimulationTime() - fadeStartTime
		if elapsed < HOLD_DURATION then
		elseif elapsed < HOLD_DURATION + FADE_DURATION then
			locationHud.layout.props.alpha = 1 - (elapsed - HOLD_DURATION) / FADE_DURATION
			locationHud:update()
		else
			locationHud.layout.props.alpha = 0
			locationHud:update()
			fadeStartTime = nil
		end
	end
end

return {
	engineHandlers = {
		onInit = onLoad,
		onLoad = onLoad,
		onSave = onSave,
		onFrame = onFrame,
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
	}
}