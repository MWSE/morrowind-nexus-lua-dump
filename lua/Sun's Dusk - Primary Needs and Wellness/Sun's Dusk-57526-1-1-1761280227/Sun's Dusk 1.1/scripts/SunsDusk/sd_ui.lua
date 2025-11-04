--[[
   ╭──────────────────────────────────────────────────────────────────────╮
   │ Sun's Dusk · UI Runtime 		                                      │
   │ build the HUD, handle drag/scale, react to UI mode + buffs           │
   ╰──────────────────────────────────────────────────────────────────────╯
]]

require('scripts.SunsDusk.sd_ui_settings')


-- ╭─────────────────────────────────────────────────────────────────────╮
-- │ Locals                                                              │
-- ╰─────────────────────────────────────────────────────────────────────╯
local hudVisible = I.UI.isHudVisible()
local settingsSection = storage.playerSection('Settings' .. MODNAME .. "UI")
local lastUpdate = core.getRealTime() - 1

local buffShiftPX = 0
local refreshVisibility
local refreshedUiMode
SDVignetteAlpha = 0
-- ╭──────────────────────────────────────────────────────────────────────╮
-- │ Buff shift calculator                                                │
-- │ count the little boons, nudge the frame left                         │
-- ╰──────────────────────────────────────────────────────────────────────╯
-- Calculate the left shift based on active buff icons
local function calculateLeftShift()
    local activeSpells = types.Actor.activeSpells(self)
    local iconMap = {}

    for _, spellInstance in pairs(activeSpells) do
        for _, effectInstance in pairs(spellInstance.effects) do
            if effectInstance.id then
                iconMap[effectInstance.id] = true
            end
        end
    end

    local total = 0
    for _ in pairs(iconMap) do total = total + 1 end
	if buffShiftPX ~= total * HUD_LEFT_SHIFT_PER_BUFF then
		log(5, "buff icons shift:", tostring(total), "x", HUD_LEFT_SHIFT_PER_BUFF)
	end
    return total * HUD_LEFT_SHIFT_PER_BUFF
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Apply HUD position + anchor                                        │
-- ╰────────────────────────────────────────────────────────────────────╯
local function applyDisplayPos()
    if not SDHUD then return end
    local baseX = HUD_X_POS
    local baseY = HUD_Y_POS
    local display = v2(baseX - buffShiftPX, baseY)

    SDHUD.layout.props.position = display

    local layerId = ui.layers.indexOf("HUD")
    local hudLayerSize = ui.layers[layerId].size
    SDHUD.layout.props.anchor = v2(display.x / hudLayerSize.x, 0)
    SDHUD:update()
end

-- ───────────────────────────────────────────────────────────────── create UI ────────────────────────────────────────────────────────────

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Visibility rules                                                   │
-- ╰────────────────────────────────────────────────────────────────────╯
local function refreshUiVisibility()
	local newVisibility = nil
	if HUD_DISPLAY == "Always" then
		newVisibility = I.UI.isHudVisible()
	elseif HUD_DISPLAY == "Never" then
		newVisibility = false
	elseif HUD_DISPLAY == "Interface Only" then
		newVisibility = currentUiMode == "Interface" and I.UI.isHudVisible()
	elseif HUD_DISPLAY == "Hide on Interface" then
		newVisibility = currentUiMode == nil and I.UI.isHudVisible()
	elseif HUD_DISPLAY == "Hide on Dialogue Only" then
		newVisibility = currentUiMode ~= "Dialogue" and currentUiMode ~= "Barter" and I.UI.isHudVisible()
	end
	if newVisibility ~= nil and newVisibility ~= SDHUD.layout.props.visible then
		if mouseTooltip then
			mouseTooltip:destroy()
			mouseTooltip = nil
		end
		SDHUD.layout.props.visible = newVisibility
		log(3, "hud visibility = " .. tostring(newVisibility))
	end
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Build or refresh the HUD                                           │
-- ╰────────────────────────────────────────────────────────────────────╯



function updateSDVignette(dt)
	if not SDVignette then
		local layerId = ui.layers.indexOf("HUD")
        local hudLayerSize = ui.layers[layerId].size
        local horizontalAnchor = HUD_X_POS/hudLayerSize.x

		-- Main container for the entire HUD
		SDVignette = ui.create({
			type = ui.TYPE.Image,
			layer = 'Scene', 
			name = "SDVignette",
			props = {
				relativeSize = v2(1,1),
				resource = getTexture("textures/SunsDusk/vignette.png"),
				tileH = false,
				tileV = false,
				alpha = 0,
				color = util.color.hex("4E0E04"),
			},
		})
	end
	if dt and dt > 0 and SDVignetteAlpha > 0 then
		SDVignetteAlpha = math.max(0, SDVignetteAlpha-0.8*dt)
		SDVignette.layout.props.alpha = SDVignetteAlpha
		SDVignette:update()
	end
end
table.insert(onFrameJobs, updateSDVignette)

function updateSDHUD()
	if not SDHUD then
		local layerId = ui.layers.indexOf("HUD")
        local hudLayerSize = ui.layers[layerId].size
        local horizontalAnchor = HUD_X_POS/hudLayerSize.x

		-- Main container for the entire HUD
		SDHUD = ui.create({
			type = ui.TYPE.Container,
			layer = HUD_LOCK and 'Scene' or 'Modal',  -- Appears above game UI
			name = "SDHUD",
			props = {
				position = v2(HUD_X_POS, HUD_Y_POS),
				autoSize = true,
				anchor = v2(horizontalAnchor,0),
			},
			content = ui.content {},
			userData = {
				windowStartPosition = v2(HUD_X_POS, HUD_Y_POS),
			}
		})
		log(5, "hud container spawned")
		
		-- Drag handlers
		SDHUD_mousePress = function(data, elem)
			if data.button == 1 then  -- Left mouse button
				if not SDHUD.layout.userData then SDHUD.layout.userData = {} end
				SDHUD.layout.userData.isDragging = true
				SDHUD.layout.userData.dragStartPosition = data.position
				SDHUD.layout.userData.windowStartPositionBase = v2(settingsSection:get("HUD_X_POS") or HUD_X_POS, settingsSection:get("HUD_Y_POS") or HUD_Y_POS)
			end
			SDHUD:update()
		end
		
		SDHUD_mouseRelease = function(data, elem)
			if SDHUD.layout.userData then SDHUD.layout.userData.isDragging = false end
			SDHUD:update()
		end
			
		SDHUD_mouseMove = function(data, elem)
			if SDHUD.layout.userData and SDHUD.layout.userData.isDragging then
				local deltaX = data.position.x - SDHUD.layout.userData.dragStartPosition.x
				local deltaY = data.position.y - SDHUD.layout.userData.dragStartPosition.y
				local newBase = v2(
					SDHUD.layout.userData.windowStartPositionBase.x + deltaX,
					SDHUD.layout.userData.windowStartPositionBase.y + deltaY
				)
				settingsSection:set("HUD_X_POS", math.floor(newBase.x))
				settingsSection:set("HUD_Y_POS", math.floor(newBase.y))
				applyDisplayPos()
			end
		end
		
		-- Drag and drop handling
		SDHUD.layout.events = {
			mousePress = async:callback(SDHUD_mousePress),
			mouseRelease = async:callback(SDHUD_mouseRelease),
			mouseMove = async:callback(SDHUD_mouseMove),
		}
		-- Flex row or column of widgets
		sunsduskFlex = {
			type = ui.TYPE.Flex,
			name = "sunsduskFlex",
			props = {
				horizontal = HUD_ORIENTATION == "Horizontal",
				autoSize = true,
				size = v2(1,1),
				arrange = ui.ALIGNMENT.End
			},
			content = ui.content{}
		}
		SDHUD.layout.content:add(sunsduskFlex)
	else
		-- Reset and repack content
		sunsduskFlex.content = ui.content {}
	end
	
	refreshUiVisibility()
	
	-- Add module widgets
	for module_index, module_widgets in pairs(uiWidgets) do
		for widget_index, widget in pairs(module_widgets) do
			sunsduskFlex.content:add(widget)
		end
	end
	-- Stable order, tidy look
	table.sort(sunsduskFlex.content, function(a,b) return a.order < b.order end)

	-- Nudge left if vanilla buffs crowd us
	buffShiftPX = calculateLeftShift()
	applyDisplayPos()
end

table.insert(refreshWidgetJobs, updateSDHUD)

-- ───────────────────────────────────────────────────────────── HUD toggle ─────────────────────────────────────────────────────────────────

input.registerTriggerHandler("ToggleHUD", async:callback(function()
	SDHUD.layout.props.visible = I.UI.isHudVisible()
	SDHUD:update()
	log(3, "hud toggled -> " .. tostring(SDHUD.layout.props.visible))
end))

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ UI mode reactions                                                  │
-- ╰────────────────────────────────────────────────────────────────────╯
local function UiModeChanged(data)
	if not SDHUD then return end
	refreshUiVisibility()
	refreshVisibility = 3
	currentUiMode = data.newMode
	
end

table.insert(UiModeChangedJobs, UiModeChanged)

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Mouse wheel = scale while dragging                                 │
-- ╰────────────────────────────────────────────────────────────────────╯
local function onMouseWheel(vertical)
	if SDHUD.layout.userData.isDragging then
		settingsSection:set("HUD_ICON_SIZE", math.max(5, HUD_ICON_SIZE + vertical))
		log(5, "icon size -> " .. tostring(settingsSection:get("HUD_ICON_SIZE")))
	end
end

table.insert(mousewheelJobs, onMouseWheel)

-- ──────────────────────────────────────────────────────── configure initial position ────────────────────────────────────────────────────────

local function onLoad(originalData)
	local layerId = ui.layers.indexOf("HUD")
	local hudLayerSize = ui.layers[layerId].size

	settingsSection:set("HUD_X_POS", math.floor(math.max(0, math.min(HUD_X_POS, hudLayerSize.x))))
	settingsSection:set("HUD_Y_POS", math.floor(math.max(0, math.min(HUD_Y_POS, hudLayerSize.y - HUD_ICON_SIZE))))
	updateSDVignette()
	updateSDHUD()
end

table.insert(onLoadJobs, onLoad)

-- ────────────────────────────────────────────────────────────  update ───────────────────────────────────────────────────────────────

function refreshUI()
	updateSDHUD()
end

local function onFrame(dt)
	local now = core.getRealTime()
	if now > lastUpdate + 1 then
		lastUpdate = now
		refreshUI()
	elseif refreshVisibility then
		refreshVisibility = refreshVisibility - 1
		if refreshVisibility == 0 then
			refreshUiVisibility()
			SDHUD:update()
			refreshVisibility = nil
		end
	elseif HUD_LEFT_SHIFT_PER_BUFF > 0 then
		local newLeftShift = calculateLeftShift()
		if newLeftShift ~= buffShiftPX then
			buffShiftPX = newLeftShift
			refreshUI()
			lastUpdate = now
		end
	end
end

table.insert(onFrameJobsSluggish, onFrame)