
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

-- true if visible widgets should sort to the end of the content (right/bottom)
local function columnsVisibilityDescending()
	if not G_hudLayerSize then return false end
	if HUD_ORIENTATION == "Horizontal" then
		return HUD_X_POS > G_hudLayerSize.x / 2
	end
	return HUD_Y_POS > G_hudLayerSize.y / 2
end

local function sortByOrder(content, descending, byVisibility, visibilityDescending)
	local function getOrder(w)
		local ud = w.userData or (w.layout and w.layout.userData)
		return ud and ud.order or "zzz"
	end
	local function getAlpha(w)
		local ud = w.userData or (w.layout and w.layout.userData)
		if ud and ud.effectiveAlpha ~= nil then return ud.effectiveAlpha end
		return 1
	end
	local function isStickToEdge(w)
		local ud = w.userData or (w.layout and w.layout.userData)
		return ud and ud.stickToEdge == true
	end
	table.sort(content, function(a, b)
		-- stickToEdge pushes visible flagged widgets to the screen edge
		-- evaluated first so flagged widgets land outside any visibility group
		if visibilityDescending ~= nil then
			local sa = isStickToEdge(a) and getAlpha(a) > 0
			local sb = isStickToEdge(b) and getAlpha(b) > 0
			if sa ~= sb then
				if visibilityDescending then return sb end
				return sa
			end
		end
		if byVisibility then
			local aa, ab = getAlpha(a), getAlpha(b)
			if aa ~= ab then
				if visibilityDescending then return aa < ab end
				return aa > ab
			end
		end
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
		sortByOrder(SDHUD_columns.layout.content, false, HUD_SORT_BY_VISIBILITY, columnsVisibilityDescending())

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
			-- skins may protrude past the icon square (e.g. wetness strip)
			local heightMult = (ud and ud.heightMult) or 1
			local newSize = v2(HUD_ICON_SIZE * aspectRatio, HUD_ICON_SIZE * heightMult)
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
			SDHUD_columns.layout.props.arrange = nil
			-- taller skins protrude below the row, so top-align the squares
			SDHUD_columns.layout.props.align = ui.ALIGNMENT.Start
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
		sortByOrder(SDHUD_columns.layout.content, false, HUD_SORT_BY_VISIBILITY, columnsVisibilityDescending())
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

-- listens to the menu mousewheel trigger published by selectRenderer/colorPicker,
-- so dragging-to-resize works while a menu (e.g. the settings page) is open

G_mousewheelJobs["sunsDuskUI"] = onMouseWheel

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

-- ╭────────────────────────────────────────────────────────────────────╮
-- │ StatsWindow integration                                            │
-- ╰────────────────────────────────────────────────────────────────────╯

if I.StatsWindow then
	local C = I.StatsWindow.Constants

	-- box and section
	I.StatsWindow.addBoxToPane('sunsDuskStatsBox', C.Panes.LEFT, {
		placement = {
			type = C.Placement.AFTER,
			target = C.DefaultBoxes.HEALTH_BOX,
			priority = 25,
		}
	})
	I.StatsWindow.addSectionToBox('sunsDuskStats', 'sunsDuskStatsBox', {})

	-- hunger
	I.StatsWindow.addLineToSection('sunsDuskHunger', 'sunsDuskStats', {
		label = "Hunger",
		labelColor = C.Colors.DEFAULT_LIGHT,
		type = C.LineType.PROGRESS_BAR,
		placement = {
			type = C.Placement.TOP,
			priority = 1,
		},
		value = function()
			local hunger = saveData and saveData.m_hunger and saveData.m_hunger.hunger or 0
			local value = NEEDS_HUNGER and math.floor(hunger * 100) or 100
			return {
				value = value,
				max = 100,
				color = util.color.rgb(190 / 255, 110 / 255, 30 / 255), -- orangeish
				size = v2(130, I.StatsWindow.Templates.STATS.LINE_HEIGHT),
				textColor = value == 100 and C.Colors.DAMAGED or nil,
			}
		end,
		tooltip = function()
			if not NEEDS_HUNGER or not saveData or not saveData.m_hunger then return nil end
			local hungerData = saveData.m_hunger
			local skinData = G_iconPacks.hunger[H_SKIN]
			local hungerTexture
			if skinData.stages > 1 then
				local hungerLevel = math.max(0, math.floor(hungerData.hunger * skinData.stages - 0.00001))
				hungerTexture = skinData.base.."hunger_"..hungerLevel..skinData.extension
			else
				hungerTexture = skinData.base.."hunger"..skinData.extension
			end
			-- mirror HUD tooltip
			local desc = math.floor(hungerData.hunger*100).."%"
			if hungerData.longLastingDuration then
				desc = desc.."\nWell fed: "..formatTimeLeft(hungerData.longLastingDuration)
			end
			if hungerData.currentHungerBuff == nil then
				desc = desc.."\nLoading..."
			elseif hungerData.currentHungerBuff == false then
				desc = desc.."\nNo effects"
			else
				desc = desc.."\n"..(tooltips[hungerData.currentHungerBuff] or "Error: "..tostring(hungerData.currentHungerBuff))
			end
			if hungerData.currentFoodProfile == "fasting" then
				desc = desc.."\n\n"..(tooltips[hungerData.currentFoodProfile] or "Error: "..tostring(hungerData.currentFoodProfile))
			end
			return I.StatsWindow.TooltipBuilders.ICON({
				icon = {
					bgr = H_BACKGROUND == "Classic" and (skinData.base.."BlankTexture"..skinData.extension) or hungerTexture,
					bgrColor = H_BACKGROUND == "Classic" and H_BACKGROUND_COLOR or util.color.rgb(0,0,0),
					fgr = hungerTexture,
					fgrColor = H_COLOR,
				},
				title = "Hunger",
				description = desc,
			})
		end,
		visibleFn = function() return STATS_WINDOW_SECTION and NEEDS_HUNGER end,
	})

	-- thirst
	I.StatsWindow.addLineToSection('sunsDuskThirst', 'sunsDuskStats', {
		label = "Thirst",
		labelColor = C.Colors.DEFAULT_LIGHT,
		type = C.LineType.PROGRESS_BAR,
		placement = {
			type = C.Placement.AFTER,
			target = 'sunsDuskHunger',
			priority = 1,
		},
		value = function()
			local thirst = saveData and saveData.m_thirst and saveData.m_thirst.thirst or 0
			local value = NEEDS_THIRST and math.floor(thirst * 100) or 100
			return {
				value = value,
				max = 100,
				color = util.color.rgb(0, 160 / 255, 170 / 255), -- cyanish
				size = v2(130, I.StatsWindow.Templates.STATS.LINE_HEIGHT),
				textColor = value == 100 and C.Colors.DAMAGED or nil,
			}
		end,
		tooltip = function()
			if not NEEDS_THIRST or not saveData or not saveData.m_thirst then return nil end
			local thirstData = saveData.m_thirst
			local skinData = G_iconPacks.thirst[T_SKIN]
			local thirstTexture
			if skinData.stages > 1 then
				local thirstLevel = math.max(0, math.floor(thirstData.thirst * skinData.stages - 0.00001))
				thirstTexture = skinData.base.."thirst_"..thirstLevel..skinData.extension
			else
				thirstTexture = skinData.base.."thirst"..skinData.extension
			end
			-- mirror HUD tooltip
			local desc = math.floor(thirstData.thirst*100).."%"
			if thirstData.longLastingDuration then
				desc = desc.."\nWell fed: "..formatTimeLeft(thirstData.longLastingDuration)
			end
			if thirstData.currentThirstBuff == nil then
				desc = desc.."\nLoading..."
			elseif thirstData.currentThirstBuff == false then
				desc = desc.."\nNo effects"
			else
				desc = desc.."\n"..(tooltips[thirstData.currentThirstBuff] or "Error: "..tostring(thirstData.currentThirstBuff))
			end
			return I.StatsWindow.TooltipBuilders.ICON({
				icon = {
					bgr = T_BACKGROUND == "Classic" and (skinData.base.."BlankTexture"..skinData.extension) or thirstTexture,
					bgrColor = T_BACKGROUND == "Classic" and T_BACKGROUND_COLOR or util.color.rgb(0,0,0),
					fgr = thirstTexture,
					fgrColor = T_COLOR,
				},
				title = "Thirst",
				description = desc,
			})
		end,
		visibleFn = function() return STATS_WINDOW_SECTION and NEEDS_THIRST end,
	})

	-- tiredness
	I.StatsWindow.addLineToSection('sunsDuskSleep', 'sunsDuskStats', {
		label = "Tiredness",
		labelColor = C.Colors.DEFAULT_LIGHT,
		type = C.LineType.PROGRESS_BAR,
		placement = {
			type = C.Placement.AFTER,
			target = 'sunsDuskThirst',
			priority = 1,
		},
		value = function()
			local tiredness = saveData and saveData.m_sleep and saveData.m_sleep.tiredness or 0
			local value = NEEDS_TIREDNESS and math.floor(tiredness * 100) or 100
			return {
				value = value,
				max = 100,
				color = util.color.rgb(120 / 255, 60 / 255, 160 / 255), -- deep purple
				size = v2(130, I.StatsWindow.Templates.STATS.LINE_HEIGHT),
				textColor = value == 100 and C.Colors.DAMAGED or nil,
			}
		end,
		tooltip = function()
			if not NEEDS_TIREDNESS or not saveData or not saveData.m_sleep then return nil end
			local sleepData = saveData.m_sleep
			local skinData = G_iconPacks.sleep[S_SKIN]
			local tirednessTexture
			if skinData.stages > 1 then
				local tirednessLevel = math.max(0, math.floor(sleepData.tiredness * skinData.stages - 0.00001))
				tirednessTexture = skinData.base.."sleep_"..tirednessLevel..skinData.extension
			else
				tirednessTexture = skinData.base.."sleep"..skinData.extension
			end
			-- mirror HUD tooltip
			local desc = math.floor(sleepData.tiredness*100).."%"
			if sleepData.longLastingDuration then
				desc = desc.."\nWell fed: "..formatTimeLeft(sleepData.longLastingDuration)
			end
			if sleepData.wellRestedPool > 0 then
				local avgBedRank = sleepData.wellRestedBedRankWeighted / sleepData.wellRestedPool
				local tierName = math.floor(avgBedRank) >= 2 and "Well Rested" or "Rested"
				local minutesRemaining = sleepData.wellRestedPool * HOURS_PER_RESTED_STATE * 6 * 60 / 1.5
				desc = desc.."\n"..tierName..": "..formatTimeLeft(minutesRemaining).." (+"..f1(avgBedRank * 5).."%)"
			end
			if sleepData.currentTirednessBuff == nil then
				desc = desc.."\nLoading..."
			elseif sleepData.currentTirednessBuff == false then
				desc = desc.."\nNo effects"
			else
				desc = desc.."\n"..(tooltips[sleepData.currentTirednessBuff] or "Error: "..tostring(sleepData.currentTirednessBuff))
			end
			local tooltip = I.StatsWindow.TooltipBuilders.ICON({
				icon = {
					bgr = S_BACKGROUND == "Classic" and (skinData.base.."BlankTexture"..skinData.extension) or tirednessTexture,
					bgrColor = S_BACKGROUND == "Classic" and S_BACKGROUND_COLOR or util.color.rgb(0,0,0),
					fgr = tirednessTexture,
					fgrColor = S_COLOR,
				},
				title = "Tiredness",
				description = desc,
			})
			-- sleeping profile row
			if sleepData.currentSleepingProfile then
				local sleepProfileTexture = getTexture(skinData.base.."sleep_"..sleepData.currentSleepingProfile..skinData.extension)
				local name
				if sleepData.currentSleepingProfile == "morninglark" then
					name = "Morning Lark"
				elseif sleepData.currentSleepingProfile == "nightowl" then
					name = "Night Owl"
				else
					name = "Insomniac"
				end
				local row = {
					type = ui.TYPE.Flex,
					props = {
						horizontal = true,
					},
					content = ui.content {
						{
							props = {
								size = v2(16, 16),
							},
							content = ui.content {
								{
									type = ui.TYPE.Image,
									props = {
										resource = S_BACKGROUND == "Classic" and getTexture(skinData.base.."BlankTexture"..skinData.extension) or sleepProfileTexture,
										color = S_BACKGROUND == "Classic" and S_BACKGROUND_COLOR or util.color.rgb(0,0,0),
										relativeSize = v2(1,1),
									}
								},
								{
									type = ui.TYPE.Image,
									props = {
										resource = sleepProfileTexture,
										color = S_COLOR,
										relativeSize = v2(1,1),
									}
								}
							}
						},
						{
							template = I.StatsWindow.Templates.BASE.textNormal,
							props = {
								text = " "..name,
							}
						}
					}
				}
				tooltip.content.padding.content.tooltip.content.headerRow.content.titleFlex.content:add(row)
			end
			return tooltip
		end,
		visibleFn = function() return STATS_WINDOW_SECTION and NEEDS_TIREDNESS end,
	})

	-- dirtiness
	I.StatsWindow.addLineToSection('sunsDuskClean', 'sunsDuskStats', {
		label = "Dirtiness",
		labelColor = C.Colors.DEFAULT_LIGHT,
		type = C.LineType.PROGRESS_BAR,
		placement = {
			type = C.Placement.AFTER,
			target = 'sunsDuskSleep',
			priority = 1,
		},
		value = function()
			local dirt = saveData and saveData.m_clean and saveData.m_clean.dirt or 0
			local value = NEEDS_CLEAN and math.floor(dirt * 100) or 0
			return {
				value = value,
				max = 100,
				color = util.color.rgb(140 / 255, 95 / 255, 55 / 255), -- earthy brown
				size = v2(130, I.StatsWindow.Templates.STATS.LINE_HEIGHT),
				textColor = value == 100 and C.Colors.DAMAGED or nil,
			}
		end,
		tooltip = function()
			if not NEEDS_CLEAN or not saveData or not saveData.m_clean then return nil end
			local cleanData = saveData.m_clean
			local skinData = G_iconPacks.clean[C_SKIN or "Velothi (Transparent)"]
			local cleanTexture
			if skinData.stages > 1 then
				local cleanLevel = math.max(0, math.floor(cleanData.dirt * skinData.stages - 0.00001))
				cleanTexture = skinData.base.."clean_"..cleanLevel..skinData.extension
			else
				cleanTexture = skinData.base.."clean"..skinData.extension
			end
			-- mirror HUD tooltip
			local desc = math.floor(cleanData.dirt*100).."%"
			if cleanData.currentCleanBuff == nil then
				desc = desc.."\nLoading..."
			elseif cleanData.currentCleanBuff == false then
				desc = desc.."\nNo effects"
			else
				desc = desc.."\n"..(tooltips[cleanData.currentCleanBuff] or "Error: "..tostring(cleanData.currentCleanBuff))
			end
			if cleanData.currentSoapBuff then
				desc = desc.."\n"..(tooltips[cleanData.currentSoapBuff] or "Error: "..tostring(cleanData.currentSoapBuff))
			end
			if cleanData.currentBugMuskBuff then
				desc = desc.."\n"..(tooltips[cleanData.currentBugMuskBuff] or "Error: "..tostring(cleanData.currentBugMuskBuff))
			end
			if cleanData.currentHouseBuff then
				desc = desc.."\n"..(tooltips[cleanData.currentHouseBuff] or "Error: "..tostring(cleanData.currentHouseBuff))
			end
			if cleanData.activeProductBuffs then
				for _, buff in pairs(cleanData.activeProductBuffs) do
					desc = desc.."\n"..(tooltips[buff] or "Error: "..tostring(buff))
				end
			end
			if cleanData.currentLocationDirtModifier then
				desc = desc.."\n"..(tooltips[cleanData.currentLocationDirtModifier] or "Error: "..tostring(cleanData.currentLocationDirtModifier))
			end
			if cleanData.currentWeatherDirtModifier then
				desc = desc.."\n"..(tooltips[cleanData.currentWeatherDirtModifier] or "Error: "..tostring(cleanData.currentWeatherDirtModifier))
			end
			return I.StatsWindow.TooltipBuilders.ICON({
				icon = {
					bgr = C_BACKGROUND == "Classic" and (skinData.base.."BlankTexture"..skinData.extension) or cleanTexture,
					bgrColor = C_BACKGROUND == "Classic" and C_BACKGROUND_COLOR or util.color.rgb(0,0,0),
					fgr = cleanTexture,
					fgrColor = C_COLOR,
				},
				title = "Dirtiness",
				description = desc,
			})
		end,
		visibleFn = function() return STATS_WINDOW_SECTION and NEEDS_CLEAN end,
	})

	-- temperature (custom bar mirroring HUD m_temp)
	I.StatsWindow.addLineToSection('sunsDuskTemp', 'sunsDuskStats', {
		label = "Temperature",
		labelColor = C.Colors.DEFAULT_LIGHT,
		type = C.LineType.CUSTOM,
		placement = {
			type = C.Placement.AFTER,
			target = 'sunsDuskClean',
			priority = 1,
		},
		value = function()
			local outerW = 130
			local outerH = I.StatsWindow.Templates.STATS.LINE_HEIGHT
			-- MWUI borders inset child content by `border` px on each side
			local borderInset = 2
			local barWidth = outerW - borderInset * 2
			local barHeight = outerH - borderInset * 2
			-- empty placeholder until temp data exists
			if not saveData or not saveData.m_temp or not saveData.m_temp.currentTemp or not G_makeBarSegment2 then
				return {
					name = 'value',
					template = I.MWUI.templates.borders,
					props = { size = v2(outerW, outerH) },
					content = ui.content {},
				}
			end

			-- normalize to bar range
			local racialThresholds = getRacialTemperatureThresholds()
			local minTemp = -10
			local maxTemp = racialThresholds.hotMin + 10
			local tempRange = maxTemp - minTemp
			local normalizedValue = math.min(1, math.max(0, (saveData.m_temp.currentTemp - minTemp) / tempRange))
			local normalizedValueTarget = math.min(1, math.max(0, (saveData.m_temp.targetTemp - minTemp) / tempRange))

			-- always simple bar; MWUI borders match the default progress bar's thickness
			local bartarget = G_makeBarSegment2(normalizedValueTarget, barWidth, barHeight)
			local bar = G_makeBarSegment2(normalizedValue, barWidth, barHeight)

			-- arrow indicator
			local tempDiff = math.abs(saveData.m_temp.targetTemp - saveData.m_temp.currentTemp) * (G_temperatureRate or 1)
			local arrow, arrowSize, arrowPosition, arrowAnchor, arrowColor
			if tempDiff > 1 then
				arrowSize = math.min(barHeight*0.7, 3 + math.floor(tempDiff/30 * barHeight))
				if normalizedValue < 0.5 then
					arrowPosition = v2(math.max(arrowSize, bar.position.x), math.floor(barHeight/2))
					arrowAnchor = v2(1, 0.5)
				else
					arrowPosition = v2(math.min(barWidth - arrowSize, bar.position.x + bar.size.x), math.floor(barHeight/2))
					arrowAnchor = v2(0, 0.5)
				end
				if saveData.m_temp.targetTemp > saveData.m_temp.currentTemp then
					arrow = "arrowRight"
					arrowColor = util.color.rgb(0.8, 0.5, 0.1)
				else
					arrow = "arrowLeft"
					arrowColor = util.color.rgb(0.5, 0.5, 1)
				end
				if tempDiff > 10 then
					arrow = arrow.."2"
				end
			end

			-- alpha logic from HUD: same-side bars get strong/weak treatment, different-side both weak
			local sameSide = (normalizedValue < 0.5) == (normalizedValueTarget < 0.5)
			if sameSide then
				local targetCloser = math.abs(normalizedValueTarget - 0.5) < math.abs(normalizedValue - 0.5)
				bar, bartarget = bartarget, bar
				if targetCloser then
					bar.alpha = 1.0
					bartarget.alpha = 0.4
				else
					bar.alpha = 0.4
					bartarget.alpha = 1.0
				end
			else
				bar.alpha = 0.4
				bartarget.alpha = 0.4
			end

			-- threshold markers
			local segmentsContent = ui.content {}
			if TEMP_SEGMENTS then
				local thresholdTemps = {
					5,
					racialThresholds.comfortableMin,
					racialThresholds.comfortableMax,
					racialThresholds.warmMax,
				}
				for _, temp in ipairs(thresholdTemps) do
					segmentsContent:add(G_createTempMarker(temp, minTemp, maxTemp, barWidth, barHeight, 0))
				end
			end

			-- assemble layers
			local content = ui.content {}
			content:add({
				type = ui.TYPE.Image,
				props = {
					resource = bartarget.texture,
					size = bartarget.size,
					position = bartarget.position,
					alpha = bartarget.alpha,
					tileH = false,
					tileV = false,
				}
			})
			content:add({
				type = ui.TYPE.Image,
				props = {
					resource = bar.texture,
					size = bar.size,
					position = bar.position,
					alpha = bar.alpha,
					tileH = false,
					tileV = false,
				}
			})
			if TEMP_SEGMENTS then
				content:add({
					type = ui.TYPE.Widget,
					props = { relativeSize = v2(1, 1) },
					content = segmentsContent,
				})
			end
			if arrow then
				content:add({
					type = ui.TYPE.Image,
					props = {
						resource = getTexture("textures/SunsDusk/"..arrow..".png"),
						color = arrowColor,
						size = v2(arrowSize, arrowSize),
						position = arrowPosition,
						anchor = arrowAnchor,
						tileH = false,
						tileV = false,
					}
				})
			end
			-- wetness overlay strip across the bottom
			if saveData.m_temp.water then
				local wetness = saveData.m_temp.water.wetness or 0
				content:add({
					type = ui.TYPE.Image,
					props = {
						resource = getTexture('white'),
						color = util.color.hex("0a5e8f"),
						relativeSize = v2(wetness, 0.18),
						relativePosition = v2(0.5, 1),
						anchor = v2(0.5, 1),
						tileH = false,
						tileV = false,
						alpha = 0.85,
					}
				})
			end

			-- centered "current > target" overlay, matches StatsWindow bar text
			content:add({
				template = I.StatsWindow.Templates.BASE.textNormal,
				props = {
					anchor = v2(0.5, 0.5),
					relativePosition = v2(0.5, 0.5),
					text = formatTemperatureShort(saveData.m_temp.currentTemp).."°>"..formatTemperatureShort(saveData.m_temp.targetTemp).."°",
					textColor = C.Colors.DEFAULT,
					textSize = I.StatsWindow.Templates.STATS.TEXT_SIZE,
										textShadow = true,
					textShadowColor = util.color.rgb(0,0,0),
				}
			})

			return {
				name = 'value',
				template = I.MWUI.templates.borders,
				props = { size = v2(outerW, outerH) },
				content = content,
			}
		end,
		tooltip = function()
			if not NEEDS_TEMP or not saveData or not saveData.m_temp then return nil end
			local desc = G_temperatureWidgetTooltip or ""
			if desc == "" then
				desc = math.floor(saveData.m_temp.currentTemp or 0).."°"
			end
			return I.StatsWindow.TooltipBuilders.TEXT({ text = desc, width = 555})
		end,
		visibleFn = function() return STATS_WINDOW_SECTION and NEEDS_TEMP end,
	})
end