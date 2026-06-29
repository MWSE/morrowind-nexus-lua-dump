-- export / import for every sun's dusk setting
-- entered from the settings page buttons, routed menu -> global (sd_g) -> here

local v2 = util.vector2
local goldColor = G_morrowindGold or getColorFromGameSettings("fontColor_color_normal")
local headerColor = getColorFromGameSettings("FontColor_color_normal_over")
local blackTexture = ui.texture { path = 'black' }

------------------------------ settings registry ------------------------------

-- resolves a key to its scope, storage section and current value
-- global keys live in the shared G_globalSettingDefaults registry, player keys in uiSettingsTemplate
local function resolveSetting(key)
	local info = G_globalSettingDefaults and G_globalSettingDefaults[key]
	if info then
		local value = storage.globalSection(info.section):get(key)
		if value == nil then value = info.default end
		return "global", info.section, value
	end
	for _, template in pairs(uiSettingsTemplate or {}) do
		for _, entry in pairs(template.settings) do
			if entry.key == key then
				local value = storage.playerSection(template.key):get(entry.key)
				if value == nil then value = entry.default end
				return "player", template.key, value
			end
		end
	end
end

-- colors serialize to hex, gaining a trailing alpha byte when not fully opaque
local function encodeValue(value)
	if type(value) == "userdata" then
		local hex = value:asHex()
		if value.a and value.a < 1 then
			hex = hex..string.format("%02X", math.floor(value.a * 255 + 0.5))
		end
		return hex
	end
	return tostring(value)
end

-- coerces a raw string back to the type of the current value
local function coerceValue(raw, current)
	local t = type(current)
	if t == "number" then
		return tonumber(raw)
	elseif t == "boolean" then
		if raw == "true" then return true end
		if raw == "false" then return false end
		return nil
	elseif t == "userdata" then
		local hex = raw:gsub("^#", "")
		if #hex == 8 then
			local r = tonumber(hex:sub(1, 2), 16)
			local g = tonumber(hex:sub(3, 4), 16)
			local b = tonumber(hex:sub(5, 6), 16)
			local a = tonumber(hex:sub(7, 8), 16)
			if r and g and b and a then return util.color.rgba(r / 255, g / 255, b / 255, a / 255) end
			return nil
		end
		local ok, color = pcall(util.color.hex, hex)
		if ok then return color end
		return nil
	end
	return raw
end

------------------------------ serialize / apply ------------------------------

local function buildExportText()
	local globals = {}
	local players = {}
	for key, info in pairs(G_globalSettingDefaults or {}) do
		local value = storage.globalSection(info.section):get(key)
		if value == nil then value = info.default end
		globals[#globals + 1] = key.." = "..encodeValue(value)
	end
	for _, template in pairs(uiSettingsTemplate or {}) do
		local section = storage.playerSection(template.key)
		for _, entry in pairs(template.settings) do
			local value = section:get(entry.key)
			if value == nil then value = entry.default end
			players[#players + 1] = entry.key.." = "..encodeValue(value)
		end
	end
	table.sort(globals)
	table.sort(players)
	local lines = { "-- Sun's Dusk settings, edit values then press Apply", "" }
	for _, line in ipairs(globals) do lines[#lines + 1] = line end
	lines[#lines + 1] = ""
	for _, line in ipairs(players) do lines[#lines + 1] = line end
	return table.concat(lines, "\n")
end

-- replays the in-game preset cascade in one synchronous pass, so a sparse
-- "use a preset then finetune a few keys" config expands the same way the live
-- cascade would: global preset fills the difficulty / ui presets, those fill their
-- individual keys, and anything listed explicitly wins on top
local function composeSettings(explicit)
	local result = {}
	local function overlay(preset)
		if not preset then return end
		for key, value in pairs(preset) do result[key] = value end
	end

	-- level 1: global preset seeds the difficulty / ui presets and a few extras
	local globalPreset = explicit.GLOBAL_PRESET
	if globalPreset and globalPreset ~= "Custom" and GlobalPresets and GlobalPresets[globalPreset] then
		overlay(GlobalPresets[globalPreset].global)
		overlay(GlobalPresets[globalPreset].player)
	end

	-- level 2: difficulty / ui presets fill their own individual keys
	local difficulty = explicit.DIFFICULTY_PRESET or result.DIFFICULTY_PRESET
	if difficulty and DifficultyPresets then overlay(DifficultyPresets[difficulty]) end
	local hud = explicit.HUD_PRESET or result.HUD_PRESET
	if hud and HUDPresets then overlay(HUDPresets[hud]) end

	-- level 3: explicit values always win
	overlay(explicit)
	return result
end

-- parses "key = value" lines, recomposes presets, then writes the result
-- player keys set directly, global keys ride the built-in OMWSettingsGlobalSet event
-- preset cascades stay suppressed across the write, the composition already expanded them
local function applyImportText(text)
	-- collect the explicitly listed values, typed from each setting's current value
	local explicit = {}
	for line in (text.."\n"):gmatch("(.-)\n") do
		local key, raw = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
		if key then
			local _, _, current = resolveSetting(key)
			if current ~= nil then
				local value = coerceValue(raw, current)
				if value ~= nil then explicit[key] = value end
			end
		end
	end

	local result = composeSettings(explicit)

	-- raise suppression in both the player and the global environment
	G_importingSettings = true
	core.sendGlobalEvent("SunsDusk_SetImportFlag", { on = true })

	local applied = 0
	for key, value in pairs(result) do
		local scope, section = resolveSetting(key)
		if scope == "global" then
			core.sendGlobalEvent("OMWSettingsGlobalSet", { groupKey = section, settingKey = key, value = value })
			applied = applied + 1
		elseif scope == "player" then
			storage.playerSection(section):set(key, value)
			applied = applied + 1
		end
	end

	-- lift suppression once the change subscriptions have settled
	local clearTime = core.getRealTime() + 0.5
	G_onFrameJobs["settingsImportClearFlag"] = function()
		if core.getRealTime() >= clearTime then
			G_importingSettings = false
			core.sendGlobalEvent("SunsDusk_SetImportFlag", { on = false })
			G_onFrameJobs["settingsImportClearFlag"] = nil
		end
	end
	return applied
end

------------------------------ window ------------------------------

local ioElement
local importBuffer = ""

local function closeIO()
	if ioElement then
		ioElement:destroy()
		ioElement = nil
	end
	importBuffer = ""
	if G_mousewheelJobs then G_mousewheelJobs["sunsDuskSettingsIO"] = nil end
	--I.UI.setMode()
end

-- bordered text button with hover feedback, redraws through the window root
local function dialogButton(label, onClick)
	local focussed = false
	local pressed = false
	-- button label
	local labelText = {
		template = I.MWUI.templates.textNormal,
		props = {
			text = label,
			textColor = goldColor,
			textAlignH = ui.ALIGNMENT.Center,
			textAlignV = ui.ALIGNMENT.Center,
			autoSize = false,
			size = v2(130, 26),
		},
	}
	local function applyColor()
		labelText.props.textColor = (pressed or focussed) and headerColor or goldColor
		if ioElement then ioElement:update() end
	end
	labelText.events = {
		mouseClick = async:callback(onClick),
		focusGain = async:callback(function() focussed = true applyColor() end),
		focusLoss = async:callback(function() focussed = false pressed = false applyColor() end),
		mousePress = async:callback(function() pressed = true applyColor() end),
		mouseRelease = async:callback(function() pressed = false applyColor() end),
	}
	return {
		template = I.MWUI.templates.box,
		content = ui.content { labelText },
	}
end

local function openIO(mode)
	if ioElement then ioElement:destroy() end
	importBuffer = ""
	--I.UI.setMode("Interface", { windows = {} })

	local isImport = mode == "import"
	local screen = ui.screenSize()
	local boxWidth = 520
	local textSize = 16
	local lineHeight = math.ceil(textSize * 1.3)
	local viewportHeight = 320
	local bottomPad = lineHeight

	-- full pixel height needed to show every line of the given text
	local function fieldHeightFor(text)
		local _, newlines = text:gsub("\n", "")
		return math.max(viewportHeight, (newlines + 1) * lineHeight + bottomPad)
	end

	-- scroll state, recomputed on import as the text grows
	local fieldText = isImport and "" or buildExportText()
	local fieldHeight = fieldHeightFor(fieldText)
	local ioScrollOffset = 0
	local ioContentHeight = fieldHeight
	local ioScrollable = fieldHeight > viewportHeight

	-- editable field, prefilled on export, captured on import
	local textEdit = {
		template = I.MWUI.templates.textEditBox,
		props = {
			text = fieldText,
			textSize = textSize,
			size = v2(boxWidth, fieldHeight),
		},
	}

	-- oversized inner panel, panned by the wheel inside the clip viewport
	local scroller = {
		type = ui.TYPE.Widget,
		props = {
			size = v2(boxWidth, fieldHeight),
			position = v2(0, 0),
		},
		content = ui.content { textEdit },
	}
	-- fixed clip viewport
	local viewport = {
		type = ui.TYPE.Widget,
		props = {
			size = v2(boxWidth, viewportHeight),
		},
		content = ui.content { scroller },
	}

	-- pan the field, clamp to range
	local function scrollIO(direction)
		local maxOffset = math.max(0, ioContentHeight - viewportHeight + bottomPad)
		ioScrollOffset = math.max(0, ioScrollOffset - direction * lineHeight)
		ioScrollOffset = math.min(maxOffset, ioScrollOffset)
		scroller.props.position = v2(0, -ioScrollOffset)
		if ioElement then ioElement:update() end
	end

	-- capture imports, regrow the field so every pasted line can be reached
	if isImport then
		textEdit.events = {
			textChanged = async:callback(function(text)
				importBuffer = text
				-- keep the layout text in sync; a later :update() reapplies props
				-- and would otherwise wipe what was typed back to the initial value
				textEdit.props.text = text
				local newHeight = fieldHeightFor(text)
				if newHeight ~= fieldHeight then
					fieldHeight = newHeight
					scroller.props.size = v2(boxWidth, fieldHeight)
					textEdit.props.size = v2(boxWidth, fieldHeight)
					ioContentHeight = fieldHeight
					ioScrollable = fieldHeight > viewportHeight
					scrollIO(0)
				end
			end),
		}
	end

	-- wheel scrolls the field while the dialog is open
	if G_mousewheelJobs then
		G_mousewheelJobs["sunsDuskSettingsIO"] = function(direction)
			if ioScrollable then scrollIO(direction) end
		end
	end

	-- title
	local title = {
		template = I.MWUI.templates.textHeader,
		props = {
			text = isImport and "Import Sun's Dusk Settings" or "Export Sun's Dusk Settings",
			textSize = 22,
		},
	}
	-- usage hint
	local hint = {
		template = I.MWUI.templates.textParagraph,
		props = {
			text = isImport and "Paste your settings, then press Apply." or "Select all (Ctrl+A) and copy (Ctrl+C).",
			size = v2(boxWidth, 0),
		},
	}
	-- button row
	local buttons
	if isImport then
		buttons = {
			dialogButton("Apply", function()
				local applied = applyImportText(importBuffer)
				closeIO()
				ui.showMessage(("Sun's Dusk: applied "..applied.." settings"))
			end),
			{ template = I.MWUI.templates.interval },
			dialogButton("Cancel", function() closeIO() end),
		}
	else
		buttons = { dialogButton("Close", function() closeIO() end) }
	end
	local buttonRow = {
		type = ui.TYPE.Flex,
		props = { horizontal = true, autoSize = true, arrange = ui.ALIGNMENT.Center },
		content = ui.content(buttons),
	}

	-- stacked dialog body
	local body = {
		type = ui.TYPE.Flex,
		props = { horizontal = false, autoSize = true, arrange = ui.ALIGNMENT.Center },
		content = ui.content {
			title,
			{ props = { size = v2(0, 6) } },
			hint,
			{ props = { size = v2(0, 10) } },
			{ template = I.MWUI.templates.box, content = ui.content { viewport } },
			{ props = { size = v2(0, 12) } },
			buttonRow,
		},
	}
	-- centered dialog
	local dialog = {
		template = I.MWUI.templates.boxSolid,
		props = { relativePosition = v2(0.5, 0.5), anchor = v2(0.5, 0.5) },
		content = ui.content { {
			template = I.MWUI.templates.padding,
			content = ui.content { body },
		} },
	}

	-- root must be a Text widget to capture the Escape keypress
	ioElement = ui.create {
		layer = 'Modal',
		type = ui.TYPE.Text,
		props = { text = "", size = screen, autoSize = false },
		events = {
			keyPress = async:callback(function(e)
				if e.code == input.KEY.Escape then closeIO() end
			end),
		},
		content = ui.content {
			-- dim backdrop
			{
				type = ui.TYPE.Image,
				props = { resource = blackTexture, relativeSize = v2(1, 1), alpha = 0.55 },
				events = {
					mousePress = async:callback(function() if not isImport then closeIO() end end),
				},
			},
			dialog,
		},
	}
end

------------------------------ event ------------------------------

-- routed from the menu buttons via sd_g, data = { action = "export" | "import" }
G_eventHandlers.SunsDusk_SettingsIO = function(data)
	local action = data and data.action
	if action == "export" or action == "import" then openIO(action) end
end
