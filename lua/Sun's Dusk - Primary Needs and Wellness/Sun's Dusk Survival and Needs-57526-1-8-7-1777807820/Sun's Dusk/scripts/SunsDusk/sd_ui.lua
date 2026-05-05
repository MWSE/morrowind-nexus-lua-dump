
-- ╭────────────────────────────────────────────────────────────────────╮
-- │  Sun's Dusk - UI                                                   │
-- ╰────────────────────────────────────────────────────────────────────╯


require('scripts.SunsDusk.sd_ui_settings')

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Locals                                                             │
-- ╰────────────────────────────────────────────────────────────────────╯

local settingsSection = storage.playerSection('Settings' .. MODNAME .. "UI")
local lastUpdate = core.getRealTime() - 1
local containerAlpha = 1

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
-- │ Helpers                                                            │
-- ╰────────────────────────────────────────────────────────────────────╯

-- Calculate the left shift based on active buff icons
local function calculateLeftShift()
	local iconMap = {}

	for _, spellInstance in pairs(typesActorActiveSpellsSelf) do
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

-- HUD position + anchor
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

-- Visibility
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

local function getWidgetSize(widget)
	if widget.props and widget.props.size then
		return widget.props.size
	elseif widget.layout and widget.layout.props and widget.layout.props.size then
		return widget.layout.props.size
	end
end

local function sortByOrder(content, descending)
	local function getOrder(w)
		local ud = w.userData or (w.layout and w.layout.userData)
		return ud and ud.order or "zzz"
	end
	table.sort(content, function(a, b)
		if descending then return getOrder(a) > getOrder(b) end
		return getOrder(a) < getOrder(b)
	end)
end

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Vignette                                                           │
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

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Main Updater                                                       │
-- ╰────────────────────────────────────────────────────────────────────╯

-- Stretch row widgets
local function resizeRowWidgets(totalWidth)
	for _, widget in pairs(G_rowWidgets) do
		local ud = widget.layout.userData or {}
		local thickness = ud.thicknessMult and totalWidth * ud.thicknessMult or widget.layout.props.size.y
		local minThickness = (ud.minThicknessByIconSize or 0) * HUD_ICON_SIZE
		widget.layout.props.size = v2(totalWidth, math.max(minThickness, thickness))
		widget:update()
	end
end

local reupdate = false
function G_updateSDHUD()
	if not SDHUD then
		-- Anchor shifts depending on X coordinate
		local rawAnchor = HUD_X_POS / G_hudLayerSize.x
		local horizontalAnchor
		if rawAnchor < 0.4 then
			horizontalAnchor = rawAnchor * 1.25
		elseif rawAnchor > 0.6 then
			horizontalAnchor = 0.5 + (rawAnchor - 0.6) * 1.25
		else
			horizontalAnchor = 0.5
		end

		-- Root
		SDHUD = ui.create({
			type = ui.TYPE.Container,
			layer = HUD_LOCK and 'Scene' or 'Modal',
			name = "SDHUD",
			props = {
				position = v2(HUD_X_POS, HUD_Y_POS),
				anchor = v2(horizontalAnchor, 0),
				alpha = containerAlpha,
			},
			content = ui.content {},
			userData = { windowStartPosition = v2(HUD_X_POS, HUD_Y_POS) }
		})
		log(5, "hud container spawned")

		-- Drag & Drop
		SDHUD_mousePress = function(data, elem)
			if data.button == 1 then
				if not SDHUD.layout.userData then SDHUD.layout.userData = {} end
				SDHUD.layout.userData.isDragging = true
				SDHUD.layout.userData.lastMousePos = data.position
			end
			SDHUD:update()
		end
		SDHUD_mouseRelease = function(data, elem)
			if SDHUD.layout.userData then SDHUD.layout.userData.isDragging = false end
			SDHUD:update()
		end
		SDHUD_mouseMove = function(data, elem)
			if SDHUD.layout.userData and SDHUD.layout.userData.isDragging then
				local delta = data.position - SDHUD.layout.userData.lastMousePos
				SDHUD.layout.userData.lastMousePos = data.position
				settingsSection:set("HUD_X_POS", math.floor((settingsSection:get("HUD_X_POS") or HUD_X_POS) + delta.x))
				settingsSection:set("HUD_Y_POS", math.floor((settingsSection:get("HUD_Y_POS") or HUD_Y_POS) + delta.y))
				G_rowsNeedUpdate = true
				applyDisplayPos()
			end
		end
		SDHUD.layout.events = {
			mousePress = async:callback(SDHUD_mousePress),
			mouseRelease = async:callback(SDHUD_mouseRelease),
			mouseMove = async:callback(SDHUD_mouseMove),
		}

		-- Row flex (holds column flex, Temperature bar, etc.)
		SDHUD_rows = {
			type = ui.TYPE.Flex,
			name = "SDHUD_rows",
			props = {
				horizontal = HUD_ORIENTATION ~= "Horizontal",
				autoSize = true,
				size = v2(1, 1),
			},
			content = ui.content {}
		}
		SDHUD.layout.content:add(SDHUD_rows)

		-- Column flex: needs icons
		SDHUD_columns = ui.create {
			type = ui.TYPE.Flex,
			name = "SDHUD_columns",
			props = {
				horizontal = HUD_ORIENTATION == "Horizontal",
				autoSize = true,
				size = v2(1, 1),
			},
			content = ui.content {},
			userData = {
				order = "middle",
			},
		}
		SDHUD_rows.content:add(SDHUD_columns)

		-- Adding registered columns
		for _, w in pairs(G_rowWidgets) do SDHUD_rows.content:add(w) end
		SDHUD:update()
		for _, w in pairs(G_columnWidgets) do SDHUD_columns.layout.content:add(w) end
		SDHUD_columns:update()
		sortByOrder(SDHUD_columns.layout.content, false)

		-- Finalize
		refreshUiVisibility()
		buffShiftPX = calculateLeftShift()
		applyDisplayPos()
		G_rowsNeedUpdate = true
		G_columnsNeedUpdate = true
		G_iconSizeNeedsUpdate = true
	end

	-- Consume a deferred re-update scheduled by the columns branch.
	if reupdate then
		SDHUD:update()
		reupdate = false
	end

	-- Icon resize: rescale every column widget to HUD_ICON_SIZE, preserving aspect ratios.
	if G_iconSizeNeedsUpdate then
		for _, widget in pairs(G_columnWidgets) do
			-- prefer explicit aspectRatio, fall back to current size, then square
			local ud = widget.userData or (widget.layout and widget.layout.userData)
			local aspectRatio = ud and ud.aspectRatio
			if not aspectRatio then
				local size = getWidgetSize(widget)
				aspectRatio = size and (size.x / size.y) or 1
			end
			local newSize = v2(HUD_ICON_SIZE * aspectRatio, HUD_ICON_SIZE)
			if widget.props and widget.props.size then
				widget.props.size = newSize
			elseif widget.layout and widget.layout.props and widget.layout.props.size then
				widget.layout.props.size = newSize
			end
			if widget.layout then widget:update() end
		end
		G_iconSizeNeedsUpdate = false
		G_columnsNeedUpdate = true
	end

	-- Rows pass: rebuild row flex, resize to column width, sort + align by HUD quadrant.
	if G_rowsNeedUpdate then
		local totalWidth = 0
		for _, widget in pairs(G_columnWidgets) do
			local size = getWidgetSize(widget)
			if size then totalWidth = totalWidth + size.x end
		end

		-- Rebuild rows, needs icons first
		SDHUD_rows.content = ui.content { SDHUD_columns }
		for _, w in pairs(G_rowWidgets) do SDHUD_rows.content:add(w) end
		resizeRowWidgets(totalWidth)

		-- Stack rows depending on Y coordinate
		local descending
		if HUD_ORIENTATION == "Horizontal" then
			if G_hudLayerSize and HUD_Y_POS < G_hudLayerSize.y / 2 then
				descending = true
			end
		else
			if G_hudLayerSize and HUD_X_POS > G_hudLayerSize.x / 2 then
				descending = true
			end
		end
		sortByOrder(SDHUD_rows.content, descending)

		-- Vertical mode special arrangement
		if HUD_ORIENTATION == "Horizontal" then
			SDHUD_rows.props.align = nil
			SDHUD_rows.props.arrange = nil
			SDHUD_columns.layout.props.align = nil
			SDHUD_columns.layout.props.arrange = nil
		else
			if G_hudLayerSize and HUD_X_POS > G_hudLayerSize.x / 2 then
				SDHUD_columns.layout.props.align = ui.ALIGNMENT.End
				SDHUD_columns.layout.props.arrange = ui.ALIGNMENT.End
			else
				SDHUD_columns.layout.props.align = ui.ALIGNMENT.Start
				SDHUD_columns.layout.props.arrange = ui.ALIGNMENT.Start
			end
			if G_hudLayerSize and HUD_Y_POS > G_hudLayerSize.y / 2 then
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

	-- Rebuild column flex, re-measure width, restretch bars to match
	-- Schedules SDHUD:update() for next frame
	if G_columnsNeedUpdate then
		SDHUD_columns.layout.content = ui.content {}
		local totalWidth = 0
		for _, widget in pairs(G_columnWidgets) do
			SDHUD_columns.layout.content:add(widget)
			local size = getWidgetSize(widget)
			if size then totalWidth = totalWidth + size.x end
		end
		sortByOrder(SDHUD_columns.layout.content, false)
		SDHUD_columns:update()

		resizeRowWidgets(totalWidth)

		SDHUD:update()
		G_columnsNeedUpdate = false
		reupdate = true
	end
end
--table.insert(G_refreshWidgetJobs, G_updateSDHUD)

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

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Hud Toggle                                                         │
-- ╰────────────────────────────────────────────────────────────────────╯

input.registerTriggerHandler("ToggleHUD", async:callback(function()
	refreshUiVisibility()
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

table.insert(G_UiModeChangedJobs, UiModeChanged)

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Mouse wheel = scale while dragging                                 │
-- ╰────────────────────────────────────────────────────────────────────╯

local function onMouseWheel(vertical)
	if SDHUD.layout.userData.isDragging then
		settingsSection:set("HUD_ICON_SIZE", math.max(5, HUD_ICON_SIZE + vertical))
		log(5, "icon size -> " .. tostring(settingsSection:get("HUD_ICON_SIZE")))
		G_iconSizeNeedsUpdate = true
	end
end

table.insert(G_mousewheelJobs, onMouseWheel)

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ OnLoad                                                             │
-- ╰────────────────────────────────────────────────────────────────────╯

local function onLoad(originalData)
	local layerId = ui.layers.indexOf("HUD")

	settingsSection:set("HUD_X_POS", math.floor(math.max(0, math.min(HUD_X_POS, G_hudLayerSize.x))))
	settingsSection:set("HUD_Y_POS", math.floor(math.max(0, math.min(HUD_Y_POS, G_hudLayerSize.y - HUD_ICON_SIZE))))
	updateSDVignette(0)
	G_updateSDHUD()
end

table.insert(G_onLoadJobs, onLoad)

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ Updating                                                           │
-- ╰────────────────────────────────────────────────────────────────────╯

function refreshUI()
	G_updateSDHUD()
end

local function onFrameSluggish(dt)
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
	elseif not HUD_LEFT_SHIFT_FAST_UPDATE and HUD_LEFT_SHIFT_PER_BUFF > 0 then
		local newLeftShift = calculateLeftShift()
		if newLeftShift ~= buffShiftPX then
			buffShiftPX = newLeftShift
			applyDisplayPos()
			lastUpdate = now
		end
	end
end

--table.insert(G_onFrameJobsSluggish, onFrameSluggish)
table.insert(G_sluggishScheduler[2], onFrameSluggish)
G_onFrameJobsSluggish.uiOnFrame = onFrameSluggish

local function onFrame()
	if not HUD_LEFT_SHIFT_FAST_UPDATE or HUD_LEFT_SHIFT_PER_BUFF == 0 then return end
	local newLeftShift = calculateLeftShift()
	if newLeftShift ~= buffShiftPX then
		buffShiftPX = newLeftShift
		applyDisplayPos()
	end
end
G_onFrameJobs.uiOnFrame = onFrame

local function setAlpha(alpha)
	containerAlpha = alpha
	if SDHUD then
		SDHUD.layout.props.alpha = containerAlpha
		SDHUD:update()
	end
end

G_eventHandlers.SunsDusk_setAlpha = setAlpha