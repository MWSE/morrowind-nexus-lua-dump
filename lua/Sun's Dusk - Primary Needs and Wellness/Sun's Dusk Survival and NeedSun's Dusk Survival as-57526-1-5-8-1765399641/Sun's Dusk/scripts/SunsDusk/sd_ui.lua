--[[
   ╭────────────────────────────────────────────────────────────────────╮
   │ Sun's Dusk · UI Runtime											│
   │ build the HUD, handle drag/scale, react to UI mode + buffs			│
   ╰────────────────────────────────────────────────────────────────────╯
]]

require('scripts.SunsDusk.sd_ui_settings')

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Locals																│
-- ╰────────────────────────────────────────────────────────────────────╯

local settingsSection = storage.playerSection('Settings' .. MODNAME .. "UI")
local lastUpdate = core.getRealTime() - 1

local buffShiftPX = 0
local refreshVisibility
local refreshedUiMode
local lastVignetteAlpha = 0
local lastVignetteColor = "default"
local vignetteColors = {
	default = util.color.hex("4E0E04"),
	hot = util.color.rgb(0.8235, 0.3725, 0.1098),
	cold = util.color.rgb(0.5294, 0.8314, 0.9490),
	scorching = util.color.rgb(215/255, 75/255, 35/255),
	risingHeat = util.color.rgb(240/255, 110/255, 70/255),
}

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Buff shift calculator												│
-- ╰────────────────────────────────────────────────────────────────────╯

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
-- │ Apply HUD position + anchor										│
-- ╰────────────────────────────────────────────────────────────────────╯

local function applyDisplayPos()
	if not SDHUD then return end
	local baseX = HUD_X_POS
	local baseY = HUD_Y_POS
	local display = v2(baseX - buffShiftPX, baseY)

	SDHUD.layout.props.position = display

	local layerId = ui.layers.indexOf("HUD")
	G_hudLayerSize = ui.layers[layerId].size
	SDHUD.layout.props.anchor = v2(display.x / G_hudLayerSize.x, 0)
	SDHUD:update()
end
table.insert(G_refreshWidgetJobs, applyDisplayPos)

-- ───────────────────────────────────────────────────────────────── create UI ────────────────────────────────────────────────────────────

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Visibility rules													│
-- ╰────────────────────────────────────────────────────────────────────╯

local function refreshUiVisibility()
	local newVisibility = nil
	if not chargenFinished() then
		newVisibility = false
	elseif HUD_DISPLAY == "Always" then
		newVisibility = I.UI.isHudVisible()
	elseif HUD_DISPLAY == "Never" then
		newVisibility = false
	elseif HUD_DISPLAY == "Interface Only" then
		newVisibility = currentUiMode == "Interface" and I.UI.isHudVisible()
	elseif HUD_DISPLAY == "Hide on Interface" then
		newVisibility = currentUiMode == nil and I.UI.isHudVisible()
	elseif HUD_DISPLAY == "Hide on Dialogue Only" then
		newVisibility = currentUiMode ~= "Dialogue" and currentUiMode ~= "Barter" and currentUiMode ~= "Companion" and I.UI.isHudVisible()
	end
	if newVisibility ~= nil and newVisibility ~= SDHUD.layout.props.visible then
		if mouseTooltip then
			mouseTooltip:destroy()
			mouseTooltip = nil
		end
		SDHUD.layout.props.visible = newVisibility
		SDHUD:update()
		log(3, "hud visibility = " .. tostring(newVisibility))
	end
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Build or refresh the HUD											│
-- ╰────────────────────────────────────────────────────────────────────╯

function updateSDVignette(dt)
	if not SDVignette then
		local horizontalAnchor = HUD_X_POS/G_hudLayerSize.x

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
				color = vignetteColors.default,
			},
		})
	end
	-- Decay flash vignette
	if G_flashVignette > 0 then
		G_flashVignette = math.max(0, G_flashVignette - 0.8 * core.getRealFrameDuration())
	end
	
	-- Calculate combined alpha multiplicatively
	local remaining = (1 - G_flashVignette)
	
	for moduleName, alpha in pairs(G_vignetteFlags) do
		if alpha > 0 then
			remaining = remaining * (1 - alpha)
		end
	end
	local color = "default"
	for _, colorName in pairs(G_vignetteColorFlags) do
		color = colorName
	end
	
	local combinedAlpha = 1 - remaining
	--print("combAlpha",combinedAlpha)
	-- Update widget only if alpha changed
	if combinedAlpha ~= lastVignetteAlpha or color ~= lastVignetteColor then
		SDVignette.layout.props.alpha = combinedAlpha
		SDVignette.layout.props.color = vignetteColors[color]
		SDVignette:update()
		lastVignetteAlpha = combinedAlpha
		lastVignetteColor = color
	end
end
table.insert(G_onFrameJobs, updateSDVignette)

function G_destroySDHUD()
	if SDHUD then
		SDHUD:destroy()
		SDHUD = nil
	end
	if SDHUD_columns then
		SDHUD_columns:destroy()
		SDHUD_columns = nil
	end
end
table.insert(G_destroyHudJobs, G_destroySDHUD)

local reupdate = false
function G_updateSDHUD()
	--print("updSDHUD U_columns:"..tostring(G_columnsNeedUpdate).." U_rows:"..tostring(G_rowsNeedUpdate))
	if not SDHUD then
		--print("init hud")
		local horizontalAnchor = HUD_X_POS/G_hudLayerSize.x

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
				
				G_rowsNeedUpdate = true
				applyDisplayPos()
				
			end
		end
		
		-- Drag and drop handling
		SDHUD.layout.events = {
			mousePress = async:callback(SDHUD_mousePress),
			mouseRelease = async:callback(SDHUD_mouseRelease),
			mouseMove = async:callback(SDHUD_mouseMove),
		}
		-- Outer container - arranges widgets in SDHUD_rows
		SDHUD_rows = {
			type = ui.TYPE.Flex,
			name = "SDHUD_rows",
			props = {
				horizontal = HUD_ORIENTATION ~= "Horizontal",
				autoSize = true,
				size = v2(1,1),
			},
			content = ui.content{}
		}
		SDHUD.layout.content:add(SDHUD_rows)
		
		-- Main container - arranges icons in columns
		-- Initialize as UI element
		SDHUD_columns = ui.create{
			type = ui.TYPE.Flex,
			name = "SDHUD_columns",
			order = "middle",
			props = {
				horizontal = HUD_ORIENTATION == "Horizontal",
				autoSize = true,
				size = v2(1,1),
			},
			content = ui.content{}
		}
		SDHUD_rows.content:add(SDHUD_columns)
		-- Add row widgets (temperature bar, wetness bar, etc.) to SDHUD_rows
		for widgetName, widget in pairs(G_rowWidgets) do
			SDHUD_rows.content:add(widget)
		end
		SDHUD:update()
		-- Add column widgets (icons, thermometer, text) to SDHUD_columns
		for widgetName, widget in pairs(G_columnWidgets) do
			SDHUD_columns.layout.content:add(widget)
		end
		SDHUD_columns:update()
		--print(SDHUD_columns.layout.content)
		-- Stable order, tidy look
		
		table.sort(SDHUD_columns.layout.content, function(a,b) return (a.order or a.layout.order or "zzz") < (b.order or b.layout.order or "zzz") end)
		if HUD_ORIENTATION == "Horizontal" then
			if G_hudLayerSize and HUD_Y_POS < G_hudLayerSize.y/2 then
				table.sort(SDHUD_rows.content, function(a,b) return (a.order or a.layout.order or "zzz") > (b.order or b.layout.order or "zzz") end)
			else
				table.sort(SDHUD_rows.content, function(a,b) return (a.order or a.layout.order or "zzz") < (b.order or b.layout.order or "zzz") end)
			end
		else
			if G_hudLayerSize and HUD_X_POS > G_hudLayerSize.x/2 then
				table.sort(SDHUD_rows.content, function(a,b) return (a.order or a.layout.order or "zzz") > (b.order or b.layout.order or "zzz") end)
			else
				table.sort(SDHUD_rows.content, function(a,b) return (a.order or a.layout.order or "zzz") < (b.order or b.layout.order or "zzz") end)
			end
		end
		refreshUiVisibility()
		-- Nudge left if vanilla buffs crowd us
		buffShiftPX = calculateLeftShift()
		applyDisplayPos()
		G_rowsNeedUpdate = true
		G_columnsNeedUpdate = true
		G_iconSizeNeedsUpdate = true
	end
	
	if reupdate then
		SDHUD:update()
		reupdate = false
	end
	if G_iconSizeNeedsUpdate then
		for widgetName, widget in pairs(G_columnWidgets) do
			local aspectRatio = widget.aspectRatio or widget.layout and widget.layout.aspectRatio
			if not aspectRatio then
				local size = widget.props and widget.props.size or widget.layout and widget.layout.props and widget.layout.props.size
				if size then
					aspectRatio = size.x/size.y
				else
					aspectRatio = 1
				end
			end
			if widget.props and widget.props.size then
				widget.props.size = v2(HUD_ICON_SIZE*aspectRatio, HUD_ICON_SIZE)
			elseif widget.layout and widget.layout.props and widget.layout.props.size then
				widget.layout.props.size = v2(HUD_ICON_SIZE*aspectRatio, HUD_ICON_SIZE)
			end
			if widget.layout then
				widget:update()
			end
		end
		G_iconSizeNeedsUpdate = false
		G_columnsNeedUpdate = true
	end
	if G_rowsNeedUpdate then
		local totalWidth = 0
		--SDHUD_columns.layout.content = ui.content {}
		local totalWidth = 0
		for widgetName, widget in pairs(G_columnWidgets) do
			if widget.props and widget.props.size then
				totalWidth = totalWidth + widget.props.size.x
			elseif widget.layout and widget.layout.props and widget.layout.props.size then
				totalWidth = totalWidth + widget.layout.props.size.x
			end
		end
		--print("column width:",totalWidth)
		
		SDHUD_rows.content = ui.content {SDHUD_columns}
		for widgetName, widget in pairs(G_rowWidgets) do
			SDHUD_rows.content:add(widget)
			local thickness = widget.layout.thicknessMult and totalWidth *  widget.layout.thicknessMult or widget.layout.props.size.y
			local minThickness = (widget.layout.minThicknessByIconSize or 0) * HUD_ICON_SIZE
			widget.layout.props.size = v2(totalWidth, math.max(minThickness, thickness))
			widget:update()
			--print("added row",widgetName, widget.layout.props.size)
		end
		if HUD_ORIENTATION == "Horizontal" then
			if G_hudLayerSize and HUD_Y_POS < G_hudLayerSize.y/2 then
				table.sort(SDHUD_rows.content, function(a,b) return (a.order or a.layout.order or "zzz") > (b.order or b.layout.order or "zzz") end)
			else
				table.sort(SDHUD_rows.content, function(a,b) return (a.order or a.layout.order or "zzz") < (b.order or b.layout.order or "zzz") end)
			end
			SDHUD_rows.props.align = nil
			SDHUD_rows.props.arrange = nil
			SDHUD_columns.layout.props.align  =  nil
			SDHUD_columns.layout.props.arrange = nil
		else
			if G_hudLayerSize and HUD_X_POS > G_hudLayerSize.x/2 then
				table.sort(SDHUD_rows.content, function(a,b) return (a.order or a.layout.order or "zzz") > (b.order or b.layout.order or "zzz") end)
				SDHUD_columns.layout.props.align  =  ui.ALIGNMENT.End
				SDHUD_columns.layout.props.arrange = ui.ALIGNMENT.End
			else
				table.sort(SDHUD_rows.content, function(a,b) return (a.order or a.layout.order or "zzz") < (b.order or b.layout.order or "zzz") end)
				SDHUD_columns.layout.props.align  =  ui.ALIGNMENT.Start
				SDHUD_columns.layout.props.arrange = ui.ALIGNMENT.Start
			end
			if G_hudLayerSize and HUD_Y_POS > G_hudLayerSize.y/2 then
				SDHUD_rows.props.align = ui.ALIGNMENT.End
				SDHUD_rows.props.arrange = ui.ALIGNMENT.End
			else
				SDHUD_rows.props.align = ui.ALIGNMENT.Start
				SDHUD_rows.props.arrange = ui.ALIGNMENT.Start
			end
		end

		SDHUD:update()
		G_rowsNeedUpdate = false
	end
	if G_columnsNeedUpdate then
		SDHUD_columns.layout.content = ui.content{}
		local totalWidth = 0
		for widgetName, widget in pairs(G_columnWidgets) do
			--print("added column",widgetName)
			SDHUD_columns.layout.content:add(widget)
			if widget.props and widget.props.size then
				totalWidth = totalWidth + widget.props.size.x
			elseif widget.layout and widget.layout.props and widget.layout.props.size then
				totalWidth = totalWidth + widget.layout.props.size.x
			end
		end
		table.sort(SDHUD_columns.layout.content, function(a,b) return (a.order or a.layout.order or "zzz") < (b.order or b.layout.order or "zzz") end)
		--print("column width:",totalWidth)
		SDHUD_columns:update()
		for widgetName, widget in pairs(G_rowWidgets) do
			--widget.layout.props.size = v2(totalWidth, widget.layout.props.size.y)
			local thickness = widget.layout.thicknessMult and totalWidth *  widget.layout.thicknessMult or widget.layout.props.size.y
			local minThickness = (widget.layout.minThicknessByIconSize or 0) * HUD_ICON_SIZE
			widget.layout.props.size = v2(totalWidth, math.max(minThickness, thickness))
			widget:update()
		end
		SDHUD:update()
		G_columnsNeedUpdate = false
		reupdate = true
	elseif false then	
		
		--if math.random() < 0.9 then
		--	SDHUD:update()
		--	return
		--end
		-- Reset and repack content
		
		-- Add row widgets (temperature bar, wetness bar, etc.) to SDHUD_rows
		for widgetName, widget in pairs(G_rowWidgets) do
			SDHUD_rows.content:add(widget)
		end
		SDHUD:update()
		-- Add column widgets (icons, thermometer, text) to SDHUD_columns
		for widgetName, widget in pairs(G_columnWidgets) do
			SDHUD_columns.layout.content:add(widget)
		end
		SDHUD_columns:update()
		--print(SDHUD_columns.layout.content)
		-- Stable order, tidy look
		table.sort(SDHUD_rows.content, function(a,b) return (a.order or a.layout.order or "zzz") < (b.order or b.layout.order or "zzz") end)
		table.sort(SDHUD_columns.layout.content, function(a,b) return (a.order or a.layout.order or "zzz") < (b.order or b.layout.order or "zzz") end)
		refreshUiVisibility()
		-- Nudge left if vanilla buffs crowd us
		buffShiftPX = calculateLeftShift()
		applyDisplayPos()
	end
end

--table.insert(G_refreshWidgetJobs, G_updateSDHUD)

-- ───────────────────────────────────────────────────────────── HUD toggle ─────────────────────────────────────────────────────────────────

input.registerTriggerHandler("ToggleHUD", async:callback(function()
	refreshUiVisibility()
	log(3, "hud toggled -> " .. tostring(SDHUD.layout.props.visible))
end))

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ UI mode reactions													│
-- ╰────────────────────────────────────────────────────────────────────╯

local function UiModeChanged(data)
	if not SDHUD then return end
	refreshUiVisibility()
	refreshVisibility = 3
	currentUiMode = data.newMode
end

table.insert(G_UiModeChangedJobs, UiModeChanged)

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Mouse wheel = scale while dragging									│
-- ╰────────────────────────────────────────────────────────────────────╯

local function onMouseWheel(vertical)
	if SDHUD.layout.userData.isDragging then
		settingsSection:set("HUD_ICON_SIZE", math.max(5, HUD_ICON_SIZE + vertical))
		log(5, "icon size -> " .. tostring(settingsSection:get("HUD_ICON_SIZE")))
		G_iconSizeNeedsUpdate = true
	end
end

table.insert(G_mousewheelJobs, onMouseWheel)

-- ──────────────────────────────────────────────────────── configure initial position ────────────────────────────────────────────────────────

local function onLoad(originalData)
	local layerId = ui.layers.indexOf("HUD")

	settingsSection:set("HUD_X_POS", math.floor(math.max(0, math.min(HUD_X_POS, G_hudLayerSize.x))))
	settingsSection:set("HUD_Y_POS", math.floor(math.max(0, math.min(HUD_Y_POS, G_hudLayerSize.y - HUD_ICON_SIZE))))
	updateSDVignette(0)
	G_updateSDHUD()
end

table.insert(G_onLoadJobs, onLoad)

-- ────────────────────────────────────────────────────────────  update ───────────────────────────────────────────────────────────────

function refreshUI()
	G_updateSDHUD()
end

local function onFrame(dt)
	local now = core.getRealTime()
	
	if now > lastUpdate + 0.2 then
		lastUpdate = now
		G_updateSDHUD()
		refreshUiVisibility()
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
			applyDisplayPos()
			lastUpdate = now
		end
	end
end

--table.insert(G_onFrameJobsSluggish, onFrame)
table.insert(G_sluggishScheduler[2], onFrame)
G_onFrameJobsSluggish.uiOnFrame = onFrame