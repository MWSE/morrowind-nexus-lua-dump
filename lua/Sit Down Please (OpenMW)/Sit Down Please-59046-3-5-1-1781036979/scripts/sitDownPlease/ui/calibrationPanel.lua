---@omw-context none
local module = {}

function module.preferredLayer()
    -- In this mod stack a Windows-layer Lua root can be created with Interface
    -- mode active but still render behind gameplay. Modal is a proven visible
    -- custom UI layer here (CraftingFramework/OpenMWHookshot).
    return "Modal"
end

function module.uiSize(env, layerName)
    local ui = assert(env.ui, "calibration.panel.uiSize requires env.ui")
    local util = assert(env.util, "calibration.panel.uiSize requires env.util")
    local okLayer, layerSize = pcall(function()
        local layerIndex = ui.layers and ui.layers.indexOf and ui.layers.indexOf(layerName) or nil
        local layer = layerIndex and ui.layers[layerIndex] or nil
        return layer and layer.size or nil
    end)
    if okLayer and layerSize and layerSize.x and layerSize.y and layerSize.x > 0 and layerSize.y > 0 then
        return layerSize
    end
    local okScreen, screen = pcall(ui.screenSize)
    if okScreen and screen and screen.x and screen.y then return screen end
    return util.vector2(1280, 720)
end

function module.buildLayout(env)
    local ui = assert(env.ui, "calibration.panel.buildLayout requires env.ui")
    local util = assert(env.util, "calibration.panel.buildLayout requires env.util")
    local I = assert(env.I, "calibration.panel.buildLayout requires env.I")
    local async = assert(env.async, "calibration.panel.buildLayout requires env.async")
    local input = assert(env.input, "calibration.panel.buildLayout requires env.input")
    local layerName = env.layerName or module.preferredLayer()
    local refs = {}

    local screen = module.uiSize(env, layerName)
    local panelWidth = math.min(568, math.max(540, screen.x - 160))
    local panelHeight = math.min(620, math.max(604, screen.y - 96))
    local targetBoxWidth = 344
    local targetBoxGap = 0
    local rootWidth = panelWidth + targetBoxGap + targetBoxWidth
    local rootSize = util.vector2(rootWidth, panelHeight)
    local panelPosition = util.vector2((screen.x - rootWidth) / 2, (screen.y - panelHeight) / 2)
    local contentWidth = panelWidth - 48
    local nudgeGridY = 352
    local currentOffsetY = nudgeGridY + 134
    local exportRuleY = currentOffsetY + 30
    local exportTitleY = exportRuleY + 12
    local exportButtonY = exportTitleY + 30
    local nudgeTextBackgroundHeight = 56
    local moveValues = { -100, -20, -5, -1, 1, 5, 20, 100 }
    local yawValues = { -90, -45, -15, -1, 1, 15, 45, 90 }
    local TARGET_TEXT_SIZE = 13.0
    local TARGET_DETAIL_LINE_HEIGHT = 14
    local COLOR_BG = util.color.rgb(0, 0, 0)
    local COLOR_PANEL = util.color.rgb(0.03, 0.025, 0.02)
    local COLOR_BUTTON = util.color.rgb(0.08, 0.065, 0.045)
    local COLOR_BUTTON_FOCUS = util.color.rgb(0.22, 0.18, 0.11)
    local COLOR_BUTTON_DISABLED = util.color.rgb(0.035, 0.032, 0.030)
    local COLOR_TEXT = util.color.rgb(0.94, 0.92, 0.84)
    local COLOR_TEXT_DISABLED = util.color.rgb(0.42, 0.40, 0.36)
    local COLOR_MUTED = util.color.rgb(0.78, 0.74, 0.64)
    local COLOR_GOLD = util.color.rgb(1.0, 0.82, 0.42)
    local white = ui.texture { path = "white" }
    local content = ui.content {}
    local update = env.update or function() end

    local function addText(name, text, x, y, w, h, size, color, align, noWrap, manualLineBreaks)
        local layout = {
            name = name,
            type = ui.TYPE.Text,
            props = {
                position = util.vector2(x, y),
                size = util.vector2(w, h),
                text = tostring(text or ""),
                textColor = color or COLOR_TEXT,
                textShadow = true,
                textShadowColor = COLOR_BG,
                textSize = size or 15,
                textAlignH = align or ui.ALIGNMENT.Start,
                textAlignV = ui.ALIGNMENT.Center,
                multiline = manualLineBreaks == true or noWrap ~= true,
                wordWrap = manualLineBreaks ~= true and noWrap ~= true,
            },
        }
        content:add(layout)
        return layout
    end

    local function addRule(y)
        content:add({
            type = ui.TYPE.Image,
            props = {
                position = util.vector2(24, y),
                size = util.vector2(contentWidth, 1),
                resource = white,
                color = util.color.rgb(0.55, 0.47, 0.30),
                alpha = 0.8,
            },
        })
    end

    local function addButton(label, x, y, w, h, onClick, size, enabledFn)
        local function enabled()
            if not enabledFn then return true end
            local ok, value = pcall(enabledFn)
            return ok and value == true
        end
        local background = {
            name = "background",
            type = ui.TYPE.Image,
            props = {
                relativeSize = util.vector2(1, 1),
                resource = white,
                color = enabled() and COLOR_BUTTON or COLOR_BUTTON_DISABLED,
                alpha = 0.95,
            },
        }
        local textLayout = {
            name = "text",
            type = ui.TYPE.Text,
            props = {
                relativePosition = util.vector2(0.5, 0.5),
                anchor = util.vector2(0.5, 0.5),
                size = util.vector2(w - 8, h),
                text = tostring(label),
                textColor = enabled() and COLOR_TEXT or COLOR_TEXT_DISABLED,
                textShadow = true,
                textShadowColor = COLOR_BG,
                textSize = size or 14,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
            },
        }
        local buttonLayout = {
            type = ui.TYPE.Widget,
            props = {
                position = util.vector2(x, y),
                size = util.vector2(w, h),
            },
            content = ui.content {
                background,
                textLayout,
                {
                    name = "clickbox",
                    type = ui.TYPE.Widget,
                    props = { relativeSize = util.vector2(1, 1) },
                    events = {
                        mouseClick = async:callback(function()
                            if enabled() and onClick then onClick() end
                        end),
                        focusGain = async:callback(function()
                            background.props.color = enabled() and COLOR_BUTTON_FOCUS or COLOR_BUTTON_DISABLED
                            textLayout.props.textColor = enabled() and COLOR_TEXT or COLOR_TEXT_DISABLED
                            update()
                        end),
                        focusLoss = async:callback(function()
                            background.props.color = enabled() and COLOR_BUTTON or COLOR_BUTTON_DISABLED
                            textLayout.props.textColor = enabled() and COLOR_TEXT or COLOR_TEXT_DISABLED
                            update()
                        end),
                    },
                },
            },
        }
        buttonLayout.textLayout = textLayout
        buttonLayout.background = background
        buttonLayout.enabled = enabled
        content:add(buttonLayout)
        return buttonLayout
    end

    local function addTargetRows(boxX, boxY, boxW)
        local rows = env.targetDetailRows and env.targetDetailRows() or {}
        local labelX = boxX + 14
        local valueX = boxX + 84
        local valueW = boxW - 92
        local rowH = TARGET_DETAIL_LINE_HEIGHT
        local status = addText("target_status", rows.status or "None selected", labelX, boxY + 44, boxW - 28, rowH, TARGET_TEXT_SIZE, COLOR_TEXT, ui.ALIGNMENT.Start, true)
        refs.targetRows = {
            status = status,
            order = {
                "cell",
                "actor", "actorPose", "actorDetail", "actorWarnings", "actorBlockers", "actorStatus",
                "furniture", "type", "furnitureSource", "furnitureModel", "furnitureDetail", "furnitureWarnings", "furnitureBlockers",
                "focus", "focusDetail", "focusWarnings", "focusCandidates",
                "profile", "profileWarnings", "profileBlockers",
                "normalPlay",
                "safetyGate",
            },
            baseY = boxY + 76,
            rowGap = 1,
            groupGap = 13,
            profileGroupGap = 13,
            placementGateGap = 13,
        }
        local function addRow(key, label, y, height, wrap, options)
            options = options or {}
            local value = tostring(rows[key] or "")
            local valueHeight = height or rowH
            local manualLines = wrap == "manual" or options.compactDetail == true or options.compactSub == true
            local rowValueX = valueX
            local rowValueW = valueW
            local hasScale = key == "actor" or key == "furniture" or key == "focus"
            local scaleW = 86
            local textSize = options.textSize or TARGET_TEXT_SIZE
            refs.targetRows[key] = {
                labelText = label,
                defaultHeight = valueHeight,
                wrap = wrap == true,
                manualLines = manualLines,
                compactDetail = options.compactDetail == true,
                compactSub = options.compactSub == true,
                lineHeight = options.lineHeight or TARGET_DETAIL_LINE_HEIGHT,
                maxLines = options.maxLines,
                labelColor = options.labelColor,
                group = options.group or key,
                fullValueW = rowValueW,
                scaledValueW = hasScale and (rowValueW - scaleW) or rowValueW,
                scaleW = scaleW,
                sectionValueW = boxW - 28,
                section = false,
                label = addText("target_" .. key .. "_label", value ~= "" and label or "", labelX, y, 74, rowH, options.labelSize or TARGET_TEXT_SIZE, COLOR_TEXT, ui.ALIGNMENT.Start, true),
                value = addText("target_" .. key .. "_value", value, rowValueX, y, hasScale and (rowValueW - scaleW) or rowValueW, valueHeight, textSize, COLOR_TEXT, ui.ALIGNMENT.Start, wrap ~= true, manualLines),
                scale = hasScale and addText("target_" .. key .. "_scale", "", rowValueX + rowValueW - scaleW, y, scaleW, valueHeight, TARGET_TEXT_SIZE, COLOR_MUTED, ui.ALIGNMENT.Start, true) or nil,
            }
            if (options.compactDetail == true or options.compactSub == true) and refs.targetRows[key].value and refs.targetRows[key].value.props then
                refs.targetRows[key].value.props.textAlignV = ui.ALIGNMENT.Start
            end
            if refs.targetRows[key].label and refs.targetRows[key].label.props then
                refs.targetRows[key].label.props.textAlignV = ui.ALIGNMENT.Start
            end
            if refs.targetRows[key].value and refs.targetRows[key].value.props then
                refs.targetRows[key].value.props.textAlignV = ui.ALIGNMENT.Start
            end
            if refs.targetRows[key].scale and refs.targetRows[key].scale.props then
                refs.targetRows[key].scale.props.textAlignV = ui.ALIGNMENT.Start
            end
        end
        addRow("cell", "Cell", boxY + 76, rowH, nil, { textSize = TARGET_TEXT_SIZE, labelSize = TARGET_TEXT_SIZE, group = "cell" })
        addRow("actor", "Actor", boxY + 100, rowH, nil, { textSize = TARGET_TEXT_SIZE, labelSize = TARGET_TEXT_SIZE, group = "actor" })
        addRow("actorPose", "", boxY + 120, TARGET_DETAIL_LINE_HEIGHT, nil, { compactSub = true, textSize = TARGET_TEXT_SIZE, group = "actor" })
        addRow("actorDetail", "", boxY + 137, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "actor" })
        addRow("actorWarnings", "", boxY + 171, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "actor" })
        addRow("actorBlockers", "", boxY + 171, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "actor" })
        addRow("actorStatus", "", boxY + 171, TARGET_DETAIL_LINE_HEIGHT, nil, { compactSub = true, textSize = TARGET_TEXT_SIZE, group = "actor" })
        addRow("furniture", "Furniture", boxY + 190, rowH, nil, { textSize = TARGET_TEXT_SIZE, labelSize = TARGET_TEXT_SIZE, group = "furniture" })
        addRow("type", "", boxY + 208, TARGET_DETAIL_LINE_HEIGHT, nil, { compactSub = true, textSize = TARGET_TEXT_SIZE, group = "furniture" })
        addRow("furnitureSource", "", boxY + 224, TARGET_DETAIL_LINE_HEIGHT, nil, { compactSub = true, textSize = TARGET_TEXT_SIZE, group = "furniture" })
        addRow("furnitureModel", "", boxY + 240, TARGET_DETAIL_LINE_HEIGHT, nil, { compactSub = true, textSize = TARGET_TEXT_SIZE, group = "furniture" })
        addRow("furnitureDetail", "", boxY + 256, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "furniture" })
        addRow("furnitureWarnings", "", boxY + 272, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "furniture" })
        addRow("furnitureBlockers", "", boxY + 288, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "furniture" })
        addRow("focus", "Focus", boxY + 326, rowH, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, labelSize = TARGET_TEXT_SIZE, group = "focus", maxLines = 2 })
        addRow("focusDetail", "", boxY + 344, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "focus", maxLines = 4 })
        addRow("focusWarnings", "", boxY + 408, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "focus", maxLines = 2 })
        addRow("focusCandidates", "", boxY + 430, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "focus", maxLines = 2 })
        addRow("profile", "Profiles", boxY + 456, rowH, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, labelSize = TARGET_TEXT_SIZE, group = "profile", maxLines = 5 })
        addRow("profileWarnings", "", boxY + 516, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "profile" })
        addRow("profileBlockers", "", boxY + 532, TARGET_DETAIL_LINE_HEIGHT, "manual", { compactDetail = true, textSize = TARGET_TEXT_SIZE, group = "profile" })
        addRow("normalPlay", "Placement", boxY + 556, rowH, nil, { textSize = TARGET_TEXT_SIZE, labelSize = TARGET_TEXT_SIZE, group = "placement" })
        addRow("safetyGate", "Gate", boxY + 580, 42, "manual", { textSize = TARGET_TEXT_SIZE, labelSize = TARGET_TEXT_SIZE, group = "gate", maxLines = 4 })
    end

    local function addNudgeRow(axis, label, y, values)
        addText("axis_" .. axis, label, 28, y, 42, 30, 14, COLOR_TEXT, ui.ALIGNMENT.Center)
        local x = 70
        refs.nudgeButtons = refs.nudgeButtons or {}
        for _, value in ipairs(values) do
            local prefix = value > 0 and "+" or ""
            local suffix = axis == "yaw" and "°" or ""
            refs.nudgeButtons[#refs.nudgeButtons + 1] = addButton(prefix .. tostring(value) .. suffix, x, y, 50, 28, function()
                env.sendAction("nudge", env.nudgePayload(axis, value))
            end, 13, env.nudgeEnabled)
            x = x + 54
        end
    end

    content:add({
        name = "panelBackground",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(0, 0),
            size = rootSize,
            resource = white,
            color = COLOR_PANEL,
            alpha = 0.42,
        },
    })
    content:add({
        name = "readableHeaderBackground",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(10, 10),
            size = util.vector2(panelWidth - 20, 112),
            resource = white,
            color = COLOR_PANEL,
            alpha = 0.14,
        },
    })
    content:add({
        name = "readableNudgeTextBackground",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(10, 292),
            size = util.vector2(panelWidth - 20, nudgeTextBackgroundHeight),
            resource = white,
            color = COLOR_PANEL,
            alpha = 0.10,
        },
    })
    content:add({
        name = "readableCurrentOffsetBackground",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(10, currentOffsetY - 4),
            size = util.vector2(panelWidth - 20, 28),
            resource = white,
            color = COLOR_PANEL,
            alpha = 0.10,
        },
    })
    content:add({
        name = "readableExportBackground",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(10, exportRuleY + 4),
            size = util.vector2(panelWidth - 20, 74),
            resource = white,
            color = COLOR_PANEL,
            alpha = 0.12,
        },
    })
    content:add({
        name = "panelBorder",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(2, 2),
            size = util.vector2(rootWidth - 4, panelHeight - 4),
            resource = white,
            color = util.color.rgb(0.28, 0.22, 0.12),
            alpha = 0.22,
        },
    })
    content:add({
        name = "targetDivider",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(panelWidth, 10),
            size = util.vector2(1, panelHeight - 20),
            resource = white,
            color = util.color.rgb(0.55, 0.47, 0.30),
            alpha = 0.55,
        },
    })

    addText("title", "Sit Down Please: Developer Calibration", 24, 16, contentWidth, 28, 17, COLOR_GOLD, ui.ALIGNMENT.Start, true)
    addText("help", env.keyHelpText(), 24, 42, contentWidth, 22, 12, COLOR_MUTED, ui.ALIGNMENT.Start, true)
    addRule(70)
    refs.filter = addText("filter", env.modeLabel(), 24, 82, 152, 28, 13, COLOR_MUTED, ui.ALIGNMENT.Start, true)
    refs.filterButtons = {}
    refs.filterButtons.auto = addButton("Auto", 180, 80, 66, 28, function() env.setTarget("auto") end, 13)
    refs.filterButtons.sleeping = addButton("Bed", 254, 80, 62, 28, function() env.setTarget("sleeping") end, 13)
    refs.filterButtons.sitting = addButton("Seat", 324, 80, 62, 28, function() env.setTarget("sitting") end, 13)
    refs.filterButtons.station = addButton("Station", 394, 80, 82, 28, function() env.setTarget("station") end, 12)
    addRule(122)

    addText("findTitle", "1. Find Targets", 24, 134, contentWidth, 24, 16, COLOR_GOLD, ui.ALIGNMENT.Start, true)
    addText("findHelp", "Find captures the looked-at or nearest active target. Assign uses a standing NPC.", 24, 158, contentWidth, 22, 13, COLOR_MUTED, ui.ALIGNMENT.Start, true)
    refs.actionButtons = {}
    refs.actionButtons.capture = addButton("Find Target", 24, 186, 104, 30, function() env.sendAction("capture") end, 11, function() return not env.actionEnabled or env.actionEnabled("capture") end)
    refs.actionButtons.assign_nearest = addButton("Assign Nearest", 136, 186, 116, 30, function() env.sendAction("assign_nearest") end, 11, function() return not env.actionEnabled or env.actionEnabled("assign_nearest") end)
    refs.actionButtons.cycle_target = addButton("Cycle Target", 260, 186, 104, 30, function() env.sendAction("cycle_target") end, 11, function() return not env.actionEnabled or env.actionEnabled("cycle_target") end)
    refs.primaryActionButton = addButton(env.primaryActionLabel and env.primaryActionLabel() or "Apply Pose", 372, 186, 172, 30, function() env.sendAction("resume") end, 11, function() return not env.actionEnabled or env.actionEnabled("resume") end)
    refs.actionButtons.resume = refs.primaryActionButton
    refs.primaryActionText = refs.primaryActionButton and refs.primaryActionButton.textLayout or nil
    addRule(232)
    addText("testTitle", "Test actors", 24, 246, 88, 24, 13, COLOR_MUTED, ui.ALIGNMENT.Start, true)
    refs.actionButtons.spawn_test = addButton("Spawn Test NPC", 116, 242, 128, 30, function() env.sendAction("spawn_test") end, 11, function() return not env.actionEnabled or env.actionEnabled("spawn_test") end)
    refs.actionButtons.fill_furniture = addButton("Fill Cell", 252, 242, 92, 30, function() env.sendAction("fill_furniture") end, 11, function() return not env.actionEnabled or env.actionEnabled("fill_furniture") end)
    refs.actionButtons.remove_test = addButton("Clear Test Actors", 352, 242, 116, 30, function() env.sendAction("remove_test") end, 10, function() return not env.actionEnabled or env.actionEnabled("remove_test") end)
    addRule(286)

    addText("nudgeTitle", "2. Nudge", 24, 296, contentWidth, 24, 16, COLOR_GOLD, ui.ALIGNMENT.Start, true)
    addText("nudgeHelp", "Nudges affect the selected slot. Hold Left Shift to link same-furniture slots.", 24, 320, contentWidth, 22, 12, COLOR_MUTED, ui.ALIGNMENT.Start, true)
    local boxX = panelWidth + targetBoxGap
    local boxY = 10
    content:add({
        name = "targetBoxBodyBackground",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(boxX + 10, boxY + 42),
            size = util.vector2(targetBoxWidth - 20, panelHeight - 104),
            resource = white,
            color = COLOR_PANEL,
            alpha = 0.14,
        },
    })
    content:add({
        name = "targetBoxRule",
        type = ui.TYPE.Image,
        props = {
            position = util.vector2(boxX + 12, boxY + 34),
            size = util.vector2(targetBoxWidth - 24, 1),
            resource = white,
            color = util.color.rgb(0.55, 0.47, 0.30),
            alpha = 0.8,
        },
    })
    addText("targetBoxTitle", "Target", boxX + 14, boxY + 8, targetBoxWidth - 28, 24, 16, COLOR_GOLD, ui.ALIGNMENT.Start, true)
    addTargetRows(boxX, boxY, targetBoxWidth)

    addNudgeRow("x", "X", nudgeGridY, moveValues)
    addNudgeRow("y", "Y", nudgeGridY + 32, moveValues)
    addNudgeRow("z", "Z", nudgeGridY + 64, moveValues)
    addNudgeRow("yaw", "Yaw", nudgeGridY + 96, yawValues)
    refs.adjustment = addText("adjustment", env.adjustmentLabel(), 24, currentOffsetY, contentWidth, 20, 13, COLOR_TEXT, ui.ALIGNMENT.Start, true)
    addRule(exportRuleY)

    addText("finishTitle", "3. Export", 24, exportTitleY, contentWidth, 24, 16, COLOR_GOLD, ui.ALIGNMENT.Start, true)
    refs.actionButtons.print = addButton("Print to Profile", 24, exportButtonY, 156, 30, function() env.sendAction("print") end, 13, function() return not env.actionEnabled or env.actionEnabled("print") end)
    refs.actionButtons.reset = addButton("Reset to Saved", 188, exportButtonY, 156, 30, function() env.sendAction("reset") end, 13, function() return not env.actionEnabled or env.actionEnabled("reset") end)
    refs.actionButtons.clear = addButton("Clear Target", 352, exportButtonY, 156, 30, function() env.sendAction("clear") end, 13, function() return not env.actionEnabled or env.actionEnabled("clear") end)
    addButton("Close", rootWidth - 140, panelHeight - 44, 116, 30, function() env.close("button") end, 13)

    return {
        type = ui.TYPE.Widget,
        layer = layerName,
        name = "SitDownPleaseCalibrationMenuRoot",
        props = {
            position = panelPosition,
            size = rootSize,
        },
        events = {
            keyPress = async:callback(function(key)
                if key and input and input.KEY and key.code == input.KEY.Escape then
                    env.close("escape")
                end
            end),
        },
        content = content,
    }, refs
end

function module.nextTargetRowGap(layouts, rows, order, index, key, row, displayType, resolvedType, targetMetadata)
    local gap = tonumber(layouts and layouts.rowGap) or 0
    local thisGroup = row and row.group or key
    local nextGroup = nil
    local nextVisibleKey = nil

    for nextIndex = index + 1, #(order or {}) do
        local nextKey = order[nextIndex]
        local nextValue = rows and rows[nextKey] or ""
        if nextKey == "type" and targetMetadata then
            nextValue = tostring(rows and rows.furniture or "") ~= ""
                and targetMetadata.typeDisplayValue(resolvedType or displayType, nextValue, rows and rows.slot)
                or ""
        end
        if nextValue ~= "" then
            nextVisibleKey = nextKey
            nextGroup = layouts and layouts[nextKey] and layouts[nextKey].group or nextKey
            break
        end
    end

    if nextGroup ~= nil and nextGroup ~= thisGroup then
        gap = tonumber(layouts and layouts.groupGap) or gap
        if nextVisibleKey == "profile" then
            gap = tonumber(layouts and layouts.profileGroupGap) or gap
        elseif thisGroup == "placement" and nextGroup == "gate" then
            gap = tonumber(layouts and layouts.placementGateGap) or gap
        end
    end
    return gap
end

return module
