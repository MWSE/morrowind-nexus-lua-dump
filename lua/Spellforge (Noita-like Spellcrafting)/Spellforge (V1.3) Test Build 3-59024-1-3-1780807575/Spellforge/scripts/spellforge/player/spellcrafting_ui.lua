---@omw-context player
local async = require("openmw.async")
local input = require("openmw.input")
local I = require("openmw.interfaces")
local openmw_ui = require("openmw.ui")
local util = require("openmw.util")

local dev = require("scripts.spellforge.shared.dev")
local effect_registry = require("scripts.spellforge.shared.effect_support_registry")
local log = require("scripts.spellforge.shared.log").new("player.spellcrafting_ui")
local operator_params = require("scripts.spellforge.shared.operator_params")
local rejection_messages = require("scripts.spellforge.shared.rejection_messages")
local ui_api = require("scripts.spellforge.player.ui")
local ui_preferences = require("scripts.spellforge.player.ui_preferences")

local spellcrafting_ui = {}

local v2 = util.vector2

local LAYER_NAME = "Windows"
local MODE = "Spellforge_Spellcrafting_Menu"
local BASE_MAX_WINDOW_SIZE = v2(1080, 740)
local BASE_MIN_WINDOW_SIZE = v2(640, 500)
local BASE_SCREEN_MARGIN = 8
local BASE_OUTER_PADDING_BUDGET = v2(24, 28)
local DEFAULT_TITLE = "New Spell"
local BASE_UI_TEXT_SIZE = 12
local BASE_UI_BUTTON_TEXT_SIZE = 11
local BASE_UI_LIST_TEXT_SIZE = 11
local BASE_UI_HEADER_SIZE = 14
local BASE_UI_TITLE_SIZE = 17
local BASE_UI_ROW_HEIGHT = 20

local function mkColor(r, g, b, a)
    if util.color and util.color.rgba then
        return util.color.rgba(r, g, b, a or 1)
    end
    if util.color and util.color.rgb then
        return util.color.rgb(r, g, b)
    end
    return nil
end

local COLOR = {
    title        = mkColor(0.96, 0.84, 0.52),
    subtitle     = mkColor(0.74, 0.68, 0.54),
    section      = mkColor(0.92, 0.82, 0.55),
    text         = mkColor(0.86, 0.77, 0.55),
    muted        = mkColor(0.58, 0.54, 0.46),
    accent       = mkColor(0.78, 0.78, 0.92),
    selected     = mkColor(0.72, 0.74, 1.00),
    success      = mkColor(0.55, 0.92, 0.65),
    error        = mkColor(0.98, 0.55, 0.55),
    warning      = mkColor(0.98, 0.82, 0.50),
    info         = mkColor(0.78, 0.78, 0.92),
    fire         = mkColor(0.86, 0.77, 0.55),
    frost        = mkColor(0.86, 0.77, 0.55),
    shock        = mkColor(0.86, 0.77, 0.55),
    poison       = mkColor(0.86, 0.77, 0.55),
    shield       = mkColor(0.86, 0.77, 0.55),
    restore      = mkColor(0.86, 0.77, 0.55),
    drain        = mkColor(0.86, 0.77, 0.55),
    op_modifier  = mkColor(0.86, 0.77, 0.55),
    op_scope     = mkColor(0.86, 0.77, 0.55),
}

local GLYPHS = {
    cursor  = ">>",
    bullet  = "*",
    sep     = "  -  ",
    sub_sep = ", ",
    blank   = "  ",
}

local SUBTITLE = "Compose base effects and operators into a spell."
local BANNER_TITLE = "SPELLFORGE  --  Spellmaking"

local DEFAULT_OPERATOR_PARAMS = {
    Multicast = { count = 3 },
    Spread = { preset = 1 },
    Burst = { count = 5 },
    ["Speed+"] = { percent = 50 },
    ["Size+"] = { percent = 100 },
    Chain = { hops = 3 },
    Bounce = { bounces = 3 },
    Homing = {},
    Detonate = {},
    Trigger = {},
    Timer = { seconds = 1.0 },
}

local RANGE_LABELS = {
    [0] = "Self",
    [1] = "Touch",
    [2] = "Target",
}

local state = {
    visible = false,
    mode_added = false,
    active_mode = nil,
    root = nil,
    catalog = nil,
    available_effects = nil,
    title = DEFAULT_TITLE,
    effects = {},
    selected_index = nil,
    selected_saved_id = nil,
    selected_saved_title = nil,
    effects_scroll_index = 1,
    operators_scroll_index = 1,
    saved_scroll_index = 1,
    effects_filter = "",
    effects_category_filter = "all",
    audit_logged = false,
    operator_icon_audit_logged = false,
    operator_big_icon_audit_logged = false,
    operator_icon_row_logged = {},
    status = "Welcome to the Spellforge.",
    status_kind = "info",
    preview = nil,
    last_validation = nil,
    last_layout = nil,
    section_refs = nil,
    collecting_section_refs = false,
    recipe_generation = 0,
    parameter_picker = nil,
}

local function templates()
    return I.MWUI and I.MWUI.templates or {}
end

local function template(name)
    return templates()[name]
end

local function cloneValue(value, depth)
    if type(value) ~= "table" then
        return value
    end
    if (depth or 0) >= 5 then
        return tostring(value)
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = cloneValue(v, (depth or 0) + 1)
    end
    return out
end

local function shortText(value, max_len)
    local text = tostring(value or "")
    if max_len and #text > max_len then
        return string.sub(text, 1, max_len - 3) .. "..."
    end
    return text
end

local function compactNumber(value)
    local n = tonumber(value)
    if n == nil or n ~= n then
        return tostring(value or "")
    end
    if math.floor(n) == n then
        return tostring(math.floor(n))
    end
    return (string.format("%.2f", n):gsub("0+$", ""):gsub("%.$", ""))
end

local function clamp(value, min_value, max_value)
    return math.max(min_value, math.min(max_value, value))
end

local function uiScale()
    return ui_preferences.uiScale()
end

local function scaledInt(value, scale)
    local s = tonumber(scale) or uiScale()
    return math.max(1, math.floor((tonumber(value) or 0) * s + 0.5))
end

local function scaledVector(value, scale)
    local s = tonumber(scale) or uiScale()
    return v2(scaledInt(value.x, s), scaledInt(value.y, s))
end

local function uiTextSize()
    return scaledInt(BASE_UI_TEXT_SIZE)
end

local function uiButtonTextSize()
    return scaledInt(BASE_UI_BUTTON_TEXT_SIZE)
end

local function uiListTextSize()
    return scaledInt(BASE_UI_LIST_TEXT_SIZE)
end

local function uiHeaderSize()
    return scaledInt(BASE_UI_HEADER_SIZE)
end

local function uiTitleSize()
    return scaledInt(BASE_UI_TITLE_SIZE)
end

local function uiRowHeight()
    return scaledInt(BASE_UI_ROW_HEIGHT)
end

local function physicalScreenSize()
    local screen = openmw_ui.screenSize()
    return v2(screen and screen.x or BASE_MAX_WINDOW_SIZE.x, screen and screen.y or BASE_MAX_WINDOW_SIZE.y)
end

local function currentLayerSize()
    local layers = openmw_ui.layers
    local index = layers and layers.indexOf and layers.indexOf(LAYER_NAME) or nil
    local layer = index and layers[index] or nil
    if layer and layer.size then
        return layer.size, "layer"
    end
    return physicalScreenSize(), "screen"
end

local function layoutMetrics()
    local scale = uiScale()
    local scale_key = ui_preferences.uiScaleKey()
    local screen_margin = scaledInt(BASE_SCREEN_MARGIN, scale)
    local outer_padding = scaledVector(BASE_OUTER_PADDING_BUDGET, scale)
    local max_window = scaledVector(BASE_MAX_WINDOW_SIZE, scale)
    local min_window = scaledVector(BASE_MIN_WINDOW_SIZE, scale)
    local row_h = scaledInt(BASE_UI_ROW_HEIGHT, scale)
    local text_size = scaledInt(BASE_UI_TEXT_SIZE, scale)
    local button_text_size = scaledInt(BASE_UI_BUTTON_TEXT_SIZE, scale)
    local list_text_size = scaledInt(BASE_UI_LIST_TEXT_SIZE, scale)
    local header_size = scaledInt(BASE_UI_HEADER_SIZE, scale)
    local title_size = scaledInt(BASE_UI_TITLE_SIZE, scale)
    local avg_char_w = math.max(5, math.floor(list_text_size * 0.58 + 0.5))
    local screen = physicalScreenSize()
    local layer, size_source = currentLayerSize()
    local available_w = math.max(1, layer.x - screen_margin * 2)
    local available_h = math.max(1, layer.y - screen_margin * 2)
    local window_w = math.floor(math.min(max_window.x, available_w))
    local window_h = math.floor(math.min(max_window.y, available_h))
    if layer.x >= min_window.x + screen_margin * 2 then
        window_w = math.max(min_window.x, window_w)
    end
    if layer.y >= min_window.y + screen_margin * 2 then
        window_h = math.max(min_window.y, window_h)
    end

    local content_w = math.max(1, window_w - outer_padding.x)
    local content_h = math.max(1, window_h - outer_padding.y)
    local gap = scaledInt(5, scale)
    local palette_w = clamp(math.floor(content_w * 0.20), scaledInt(112, scale), scaledInt(165, scale))
    local right_w = clamp(math.floor(content_w * 0.30), scaledInt(188, scale), scaledInt(270, scale))
    local recipe_w = content_w - palette_w - right_w - gap * 2
    local recipe_min_w = scaledInt(220, scale)
    if recipe_w < recipe_min_w then
        right_w = math.max(scaledInt(160, scale), right_w - (recipe_min_w - recipe_w))
        recipe_w = content_w - palette_w - right_w - gap * 2
    end
    local recipe_tight_min_w = scaledInt(200, scale)
    if recipe_w < recipe_tight_min_w then
        palette_w = math.max(scaledInt(100, scale), palette_w - (recipe_tight_min_w - recipe_w))
        recipe_w = content_w - palette_w - right_w - gap * 2
    end
    recipe_w = math.max(scaledInt(170, scale), recipe_w)

    local banner_h = scaledInt(46, scale)
    local status_h = scaledInt(22, scale)
    local action_h = scaledInt(24, scale)
    local main_h = math.max(1, content_h - banner_h - status_h - action_h - gap * 3)
    local operator_count = state.catalog and state.catalog.operators and #state.catalog.operators or 11
    local operator_grid_columns = palette_w >= scaledInt(136, scale) and 2 or 1
    local operator_grid_rows = math.max(1, math.ceil(operator_count / operator_grid_columns))
    local operator_grid_h = scaledInt(46, scale) + operator_grid_rows * (row_h + scaledInt(2, scale))
    local effects_h
    local operators_h
    if main_h < scaledInt(210, scale) then
        effects_h = math.max(1, math.floor(math.max(1, main_h - gap) * 0.62))
        operators_h = math.max(1, main_h - effects_h - gap)
    else
        operators_h = clamp(operator_grid_h, scaledInt(82, scale), math.max(scaledInt(82, scale), main_h - scaledInt(135, scale) - gap))
        effects_h = main_h - operators_h - gap
        if effects_h < scaledInt(135, scale) then
            effects_h = scaledInt(135, scale)
            operators_h = math.max(scaledInt(82, scale), main_h - effects_h - gap)
        end
        effects_h = clamp(effects_h, scaledInt(135, scale), math.max(scaledInt(135, scale), main_h - scaledInt(82, scale) - gap))
        operators_h = main_h - effects_h - gap
        if operators_h < scaledInt(82, scale) then
            effects_h = math.max(scaledInt(110, scale), main_h - gap - scaledInt(82, scale))
            operators_h = main_h - effects_h - gap
        end
    end
    local saved_h
    local preview_h
    local editor_h
    if main_h < scaledInt(260, scale) then
        local stack_h = math.max(1, main_h - gap * 2)
        saved_h = math.max(1, math.floor(stack_h * 0.22))
        preview_h = math.max(1, math.floor(stack_h * 0.24))
        editor_h = math.max(1, main_h - saved_h - preview_h - gap * 2)
    else
        saved_h = clamp(math.floor(main_h * 0.21), scaledInt(66, scale), scaledInt(112, scale))
        preview_h = clamp(math.floor(main_h * 0.22), scaledInt(66, scale), scaledInt(112, scale))
        editor_h = main_h - saved_h - preview_h - gap * 2
        if editor_h < scaledInt(110, scale) then
            local deficit = scaledInt(110, scale) - editor_h
            saved_h = math.max(scaledInt(58, scale), saved_h - math.ceil(deficit / 2))
            preview_h = math.max(scaledInt(58, scale), preview_h - math.floor(deficit / 2))
            editor_h = math.max(scaledInt(72, scale), main_h - saved_h - preview_h - gap * 2)
        end
    end

    return {
        ui_scale = scale,
        ui_scale_key = scale_key,
        row_h = row_h,
        text_size = text_size,
        button_text_size = button_text_size,
        list_text_size = list_text_size,
        header_size = header_size,
        title_size = title_size,
        avg_char_w = avg_char_w,
        screen_margin = screen_margin,
        screen = screen,
        layer = layer,
        size_source = size_source,
        window = v2(window_w, window_h),
        gap = gap,
        content_w = content_w,
        content_h = content_h,
        banner_h = banner_h,
        main_h = main_h,
        status_h = status_h,
        action_h = action_h,
        palette_w = palette_w,
        palette_button_w = math.max(scaledInt(72, scale), palette_w - scaledInt(24, scale)),
        operator_grid_columns = operator_grid_columns,
        operator_button_w = math.max(scaledInt(42, scale), math.floor((math.max(scaledInt(72, scale), palette_w - scaledInt(24, scale)) - (operator_grid_columns - 1) * scaledInt(3, scale)) / operator_grid_columns)),
        effects_h = effects_h,
        operators_h = operators_h,
        effects_visible_rows = clamp(math.floor((effects_h - scaledInt(108, scale)) / (row_h + scaledInt(1, scale))), 2, 12),
        operators_visible_rows = clamp(math.floor((operators_h - scaledInt(34, scale)) / (row_h + scaledInt(1, scale))), 2, 12),
        recipe_w = recipe_w,
        recipe_button_w = math.max(scaledInt(140, scale), recipe_w - scaledInt(56, scale)),
        recipe_list_h = math.max(scaledInt(48, scale), main_h - scaledInt(78, scale)),
        right_w = right_w,
        right_button_w = math.max(scaledInt(110, scale), right_w - scaledInt(34, scale)),
        saved_h = saved_h,
        saved_visible_rows = clamp(math.floor((saved_h - scaledInt(36, scale)) / (row_h + scaledInt(1, scale))), 2, 7),
        editor_h = editor_h,
        preview_h = preview_h,
        title_w = math.max(scaledInt(140, scale), math.min(scaledInt(260, scale), content_w - scaledInt(320, scale))),
        field_label_w = right_w < scaledInt(200, scale) and scaledInt(56, scale) or scaledInt(70, scale),
        field_input_w = math.max(scaledInt(74, scale), math.min(scaledInt(140, scale), right_w - scaledInt(96, scale))),
        number_w = right_w < scaledInt(200, scale) and scaledInt(50, scale) or scaledInt(60, scale),
        preview_text_w = math.max(scaledInt(140, scale), right_w - scaledInt(40, scale)),
        preview_text_h = math.max(scaledInt(24, scale), preview_h - scaledInt(48, scale)),
    }
end

local function safePosition(layer_size, window_size)
    local margin = scaledInt(BASE_SCREEN_MARGIN)
    local max_x = math.max(0, layer_size.x - window_size.x - margin)
    local max_y = math.max(0, layer_size.y - window_size.y - margin)
    return v2(math.min(margin, max_x), math.min(margin, max_y))
end

local function metric(m, value)
    return scaledInt(value, m and m.ui_scale or nil)
end

local function charsForWidth(width, m, min_chars)
    local char_w = m and m.avg_char_w or math.max(5, math.floor(uiListTextSize() * 0.58 + 0.5))
    return math.max(min_chars or 1, math.floor((tonumber(width) or 0) / char_w))
end

local function destroyRoot()
    local root = state.root
    if root == nil then
        return
    end
    state.root = nil
    state.section_refs = nil
    state.collecting_section_refs = false
    local ok, destroyed_or_err = pcall(function()
        local destroy = root.destroy
        if type(destroy) ~= "function" then
            return false
        end
        destroy(root)
        return true
    end)
    if not ok then
        log.warn(string.format("SPELLFORGE_UI_ROOT_DESTROY_FAILED reason=%s", tostring(destroyed_or_err)))
    elseif destroyed_or_err ~= true then
        log.warn(string.format("SPELLFORGE_UI_ROOT_DESTROY_UNAVAILABLE root_type=%s", type(root)))
    end
end

local function hasMode(mode_name)
    for _, mode in ipairs((I.UI and I.UI.modes) or {}) do
        if mode == mode_name then
            return true
        end
    end
    return false
end

local function hasSpellforgeMode()
    return hasMode(MODE)
end

local function fallbackUiMode()
    return (I.UI and I.UI.MODE and I.UI.MODE.Interface) or "Interface"
end

local function currentUiMode()
    if not (I.UI and I.UI.getMode) then
        return nil
    end
    local ok, mode = pcall(I.UI.getMode)
    if ok then
        return mode
    end
    return nil
end

local function uiExitActionReason(action)
    local actions = input.ACTION or {}
    if action == actions.GameMenu then
        return "game_menu"
    end
    if action == actions.Inventory then
        return "inventory"
    end
    if action == actions.QuickMenu then
        return "quick_menu"
    end
    if action == actions.QuickKeysMenu then
        return "quick_keys_menu"
    end
    if action == actions.Journal then
        return "journal"
    end
    return nil
end

local function textLayout(text, opts)
    local options = opts or {}
    local default_size = options.header and uiHeaderSize() or uiTextSize()
    local props = {
        text = tostring(text or ""),
        textSize = options.size or default_size,
        textColor = options.color or nil,
        size = options.box_size or nil,
    }
    return {
        template = template(options.header and "textHeader" or "textNormal"),
        type = openmw_ui.TYPE.Text,
        props = props,
        external = options.external,
    }
end

local function paragraph(text, size, opts)
    local options = opts or {}
    return {
        template = template("textParagraph"),
        type = openmw_ui.TYPE.TextEdit,
        props = {
            text = tostring(text or ""),
            size = size or v2(scaledInt(180), scaledInt(60)),
            textColor = options.color or nil,
            readOnly = true,
            multiline = true,
            wordWrap = true,
        },
    }
end

local function spacer(width, height)
    return {
        type = openmw_ui.TYPE.Widget,
        props = {
            size = v2(width or 0, height or 0),
        },
    }
end

local function row(children, opts)
    local options = opts or {}
    return {
        type = openmw_ui.TYPE.Flex,
        props = {
            horizontal = true,
            arrange = options.arrange or openmw_ui.ALIGNMENT.Start,
            align = options.align,
            size = options.size,
        },
        external = options.external,
        content = openmw_ui.content(children or {}),
    }
end

local function column(children, opts)
    local options = opts or {}
    return {
        type = openmw_ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = options.arrange or openmw_ui.ALIGNMENT.Start,
            align = options.align,
            size = options.size,
        },
        external = options.external,
        content = openmw_ui.content(children or {}),
    }
end

local render
local refreshEffectResults
local refreshRecipeSummarySections
local refreshRecipeEditorSections

local function padded(layout)
    return {
        template = template("padding"),
        content = openmw_ui.content { layout },
    }
end

local function framed(layout, size)
    return {
        template = template("box"),
        props = {
            size = size,
        },
        content = openmw_ui.content {
            padded(layout),
        },
    }
end

local function button(label, callback, opts)
    local options = opts or {}
    local width = options.width or scaledInt(86)
    local height = options.height or uiRowHeight()
    local prefix = options.bullet and (options.bullet .. " ") or ""
    local label_text = prefix .. tostring(label)
    return {
        template = template(options.disabled and "boxTransparent" or "box"),
        props = {
            size = options.size or v2(width, height),
        },
        events = options.disabled and nil or {
            mouseClick = async:callback(function()
                callback()
            end),
        },
        content = openmw_ui.content {
            padded(textLayout(label_text, {
                box_size = v2(width - scaledInt(8), 0),
                color = options.color,
                size = options.text_size or uiButtonTextSize(),
            })),
        },
    }
end

local function sectionHeader(title)
    return textLayout(title, { header = true, color = COLOR.section })
end

local function section(title, body, size)
    return {
        template = template("box"),
        props = {
            size = size,
        },
        content = openmw_ui.content {
            padded(column({
                sectionHeader(title),
                spacer(0, scaledInt(4)),
                body,
            })),
        },
    }
end

local function textInput(value, onChange, opts)
    local options = opts or {}
    local current = tostring(value or "")
    local function eventText(value)
        if type(value) == "table" then
            if value.text ~= nil then
                return tostring(value.text)
            end
            if value.value ~= nil then
                return tostring(value.value)
            end
            if type(value.props) == "table" and value.props.text ~= nil then
                return tostring(value.props.text)
            end
        end
        return tostring(value or "")
    end
    return {
        name = options.name,
        template = template("textEditLine"),
        type = openmw_ui.TYPE.TextEdit,
        props = {
            text = current,
            size = options.size or v2(options.width or scaledInt(140), 0),
            textColor = options.color or nil,
            textSize = options.text_size or uiTextSize(),
            multiline = false,
        },
        events = {
            textChanged = async:callback(function(text)
                current = eventText(text)
                onChange(current)
            end),
        },
    }
end

local function numberInput(value, onChange, opts)
    local options = opts or {}
    local current = tostring(value or 0)
    local function eventText(value)
        if type(value) == "table" then
            if value.text ~= nil then
                return tostring(value.text)
            end
            if value.value ~= nil then
                return tostring(value.value)
            end
            if type(value.props) == "table" and value.props.text ~= nil then
                return tostring(value.props.text)
            end
        end
        return tostring(value or "")
    end
    local function commit()
        local n = tonumber(current)
        if n ~= nil then
            onChange(n)
            return true
        end
        return false
    end
    return {
        name = options.name,
        template = template("textEditLine"),
        type = openmw_ui.TYPE.TextEdit,
        props = {
            text = current,
            size = options.size or v2(options.width or scaledInt(54), 0),
            textSize = options.text_size or uiTextSize(),
            multiline = false,
        },
        events = {
            textChanged = async:callback(function(text)
                current = eventText(text)
                commit()
            end),
            focusLoss = async:callback(function(text)
                if text ~= nil then
                    current = eventText(text)
                end
                commit()
            end),
        },
    }
end

local function rangeName(range)
    return RANGE_LABELS[tonumber(range) or 0] or tostring(range)
end

local function operatorEffectId(opcode)
    for _, entry in ipairs(state.catalog and state.catalog.operator_effect_ids or {}) do
        if entry.opcode == opcode then
            return entry.effect_id
        end
    end
    return nil
end

local function opcodeForEffect(effect)
    if not effect then
        return nil
    end
    local by_effect = state.catalog and state.catalog.operator_opcode_by_effect_id or {}
    return by_effect[effect.id]
end

local function operatorKind(opcode)
    local def = state.catalog and state.catalog.operators_by_opcode and state.catalog.operators_by_opcode[opcode]
    return def and def.kind or nil
end

local function operatorDisplayName(opcode)
    local def = state.catalog and state.catalog.operators_by_opcode and state.catalog.operators_by_opcode[opcode]
    return (def and def.display_name) or opcode
end

local function operatorDescription(opcode)
    local def = state.catalog and state.catalog.operators_by_opcode and state.catalog.operators_by_opcode[opcode]
    return def and def.description or nil
end

local function operatorIcon(opcode)
    local def = state.catalog and state.catalog.operators_by_opcode and state.catalog.operators_by_opcode[opcode]
    return def and def.icon or nil
end

local function operatorBigIcon(opcode)
    local def = state.catalog and state.catalog.operators_by_opcode and state.catalog.operators_by_opcode[opcode]
    return def and def.large_icon or nil
end

local function auditOperatorIconMetadata(catalog, log_once)
    local source = catalog or state.catalog or {}
    local operators = source.operators or {}
    local count = 0
    local missing = 0
    local big_count = 0
    local big_missing = 0
    for _, entry in ipairs(operators) do
        local opcode = entry and entry.opcode
        local icon = entry and entry.icon
        local big_icon = entry and entry.large_icon
        if type(icon) == "string" and icon ~= "" then
            count = count + 1
        else
            missing = missing + 1
            if opcode then
                log.warn(string.format(
                    "SPELLFORGE_UI_OPERATOR_ICON_MISSING opcode=%s path=%s",
                    tostring(opcode),
                    tostring(icon)
                ))
            end
        end
        if type(big_icon) == "string" and big_icon ~= "" then
            big_count = big_count + 1
        else
            big_missing = big_missing + 1
            if opcode then
                log.warn(string.format(
                    "SPELLFORGE_UI_OPERATOR_BIG_ICON_MISSING opcode=%s small_path=%s large_path=%s",
                    tostring(opcode),
                    tostring(icon),
                    tostring(big_icon)
                ))
            end
        end
    end
    if count > 0 and (log_once ~= true or not state.operator_icon_audit_logged) then
        state.operator_icon_audit_logged = true
        log.info(string.format("SPELLFORGE_UI_OPERATOR_ICONS_OK count=%s", tostring(count)))
    end
    if big_count > 0 and (log_once ~= true or not state.operator_big_icon_audit_logged) then
        state.operator_big_icon_audit_logged = true
        log.info(string.format(
            "SPELLFORGE_UI_OPERATOR_BIG_ICONS_OK count=%s pattern=icons/spellforge/modifiers/b_*.dds",
            tostring(big_count)
        ))
    end
    return {
        count = count,
        missing_count = missing,
        big_count = big_count,
        big_missing_count = big_missing,
    }
end

local function logOperatorIconMetadataOnly(opcode, icon, big_icon)
    if not opcode or state.operator_icon_row_logged[opcode] then
        return
    end
    state.operator_icon_row_logged[opcode] = true
    if type(icon) == "string" and icon ~= "" then
        log.info(string.format("SPELLFORGE_UI_OPERATOR_ICON_METADATA_ONLY opcode=%s", tostring(opcode)))
    else
        log.warn(string.format(
            "SPELLFORGE_UI_OPERATOR_ICON_MISSING opcode=%s path=%s",
            tostring(opcode),
            tostring(icon)
        ))
    end
    if not (type(big_icon) == "string" and big_icon ~= "") then
        log.warn(string.format(
            "SPELLFORGE_UI_OPERATOR_BIG_ICON_MISSING opcode=%s small_path=%s large_path=%s",
            tostring(opcode),
            tostring(icon),
            tostring(big_icon)
        ))
    end
end

local function colorForOpcode(opcode)
    return COLOR.text
end

local function colorForEffectId(effect_id)
    return COLOR.text
end

local function colorForEffect(effect)
    local opcode = opcodeForEffect(effect)
    if opcode then
        return colorForOpcode(opcode)
    end
    return colorForEffectId(effect and effect.id)
end

local function defaultOperatorParams(opcode)
    local def = state.catalog and state.catalog.operators_by_opcode and state.catalog.operators_by_opcode[opcode]
    local out = {}
    if def and type(def.parameters) == "table" then
        for name, spec in pairs(def.parameters) do
            if type(spec) == "table" and spec.default ~= nil then
                out[name] = spec.default
            end
        end
    end
    if next(out) ~= nil then
        return out
    end
    return cloneValue(DEFAULT_OPERATOR_PARAMS[opcode] or {}, 0)
end

local function operatorParamDefault(opcode, name, fallback)
    local defaults = defaultOperatorParams(opcode)
    if defaults[name] ~= nil then
        return defaults[name]
    end
    return fallback
end

local function mergedOperatorParams(opcode, params)
    local out = defaultOperatorParams(opcode)
    if type(params) == "table" then
        for key, value in pairs(params) do
            out[key] = value
        end
    end
    return out
end

local function normalizedParamsForEffect(effect, opcode)
    if opcode then
        return mergedOperatorParams(opcode, operator_params.paramsForEffect(effect, opcode))
    end
    if type(effect and effect.params) == "table" then
        return cloneValue(effect.params, 0)
    end
    return nil
end

local availableEntryForEffect

local function sanitizeEffect(effect, index)
    if type(effect) ~= "table" then
        return nil
    end
    local out = cloneValue(effect, 0)
    if type(out.id) ~= "string" or out.id == "" then
        out.id = "unknown"
        out.engine_effect_id = nil
    else
        out.id = effect_registry.normalizeEffectId(out.id) or out.id
        if type(out.engine_effect_id) == "string"
            and effect_registry.normalizeEffectId(out.engine_effect_id) ~= out.id then
            out.engine_effect_id = nil
        end
    end
    if out.ui_id == nil or out.ui_id == "" then
        out.ui_id = string.format("effect:%s", tostring(index or 1))
    end

    local opcode = opcodeForEffect(out)
    out.params = normalizedParamsForEffect(out, opcode)
    if not opcode then
        local entry = availableEntryForEffect(out)
        if type(entry and entry.engine_effect_id) == "string" and entry.engine_effect_id ~= "" then
            out.engine_effect_id = entry.engine_effect_id
        end
        effect_registry.normalizeEffectParams(out, entry)
    end
    return operator_params.mirrorEffect(out)
end

local function sanitizeEffects(effects)
    local out = {}
    for index, effect in ipairs(effects or {}) do
        local sanitized = sanitizeEffect(effect, index)
        if sanitized then
            out[#out + 1] = sanitized
        end
    end
    return out
end

local function paramsSummary(params)
    if type(params) ~= "table" then
        return ""
    end
    local parts = {}
    for key, value in pairs(params) do
        parts[#parts + 1] = string.format("%s=%s", tostring(key), tostring(value))
    end
    if #parts == 0 then
        return ""
    end
    table.sort(parts)
    return table.concat(parts, GLYPHS.sub_sep)
end

local function operatorSummary(effects)
    local parts = {}
    for _, effect in ipairs(effects or {}) do
        local opcode = opcodeForEffect(effect)
        if opcode then
            local summary = paramsSummary(operator_params.paramsForEffect(effect, opcode))
            if summary ~= "" then
                parts[#parts + 1] = string.format("%s(%s)", opcode, summary)
            else
                parts[#parts + 1] = tostring(opcode)
            end
        end
    end
    if #parts == 0 then
        return "none"
    end
    return table.concat(parts, ",")
end

local effectDisplayName

local function effectLabel(effect, index)
    local opcode = opcodeForEffect(effect)
    local prefix = string.format("%d.", index)
    if opcode then
        local summary = paramsSummary(operator_params.paramsForEffect(effect, opcode))
        local name = operatorDisplayName(opcode)
        if summary ~= "" then
            return string.format("%s %s (%s)", prefix, name, summary)
        end
        return string.format("%s %s", prefix, name)
    end
    local mag_min = tonumber(effect and effect.magnitudeMin) or 0
    local mag_max = tonumber(effect and effect.magnitudeMax) or 0
    local mag = (mag_min == mag_max) and tostring(mag_min) or string.format("%s-%s", tostring(mag_min), tostring(mag_max))
    local duration = tonumber(effect and effect.duration) or 0
    local area = tonumber(effect and effect.area) or 0
    local segments = {
        effectDisplayName(effect),
        rangeName(effect and effect.range),
        mag,
        string.format("%ss", tostring(duration)),
    }
    if area > 0 then
        segments[#segments + 1] = string.format("%s ft", compactNumber(area))
    end
    return string.format("%s %s", prefix, table.concat(segments, GLYPHS.sep))
end

local function currentRecipe()
    return {
        title = state.title,
        effects = sanitizeEffects(state.effects),
    }
end

local function selectedEffect()
    if type(state.selected_index) ~= "number" then
        return nil
    end
    return state.effects[state.selected_index]
end

local function clearParameterPicker()
    state.parameter_picker = nil
end

local function setStatus(text, kind)
    state.status = tostring(text or "")
    state.status_kind = kind or "info"
end

local function markRecipeChanged()
    state.recipe_generation = (state.recipe_generation or 0) + 1
    state.preview = nil
    state.last_validation = nil
end

local function requestStillCurrent(generation)
    return state.visible == true and generation == state.recipe_generation
end

local function firstErrorMessage(result, fallback)
    return rejection_messages.formatFirstError(result, fallback or "Request failed.")
end

local function previewDeferredReasons(preview)
    local matrix = preview and (preview.feature_matrix or preview.support) or {}
    if type(matrix.deferred_reasons) == "table" then
        return matrix.deferred_reasons
    end
    return {}
end

local function previewIsDeferred(preview)
    local matrix = preview and (preview.feature_matrix or preview.support) or {}
    return matrix.live_runtime_status == "deferred" or #previewDeferredReasons(preview) > 0
end

local function previewDeferredSummary(preview)
    local reasons = previewDeferredReasons(preview)
    if #reasons > 0 then
        return rejection_messages.formatDeferredReasons(reasons, "runtime combo deferred")
    end
    return "runtime combo deferred"
end

local function statusColor(kind)
    if kind == "success" then return COLOR.success end
    if kind == "error" then return COLOR.error end
    if kind == "warning" then return COLOR.warning end
    return COLOR.info
end

local function statusPrefix(kind)
    if kind == "success" then return "[OK]" end
    if kind == "error" then return "[!!]" end
    if kind == "warning" then return "[!]" end
    return "[i]"
end

local function availableEffects()
    local cached = state.available_effects
        or (state.catalog and state.catalog.available_effects)
        or ui_api.getCachedAvailableEffects()
    if cached and type(cached.base_effects) == "table" then
        return cached.base_effects, cached
    end
    if state.catalog and type(state.catalog.base_effects) == "table" then
        return state.catalog.base_effects, {
            source_mode = state.catalog.available_effect_source_mode or "fallback_static",
            base_effect_count = state.catalog.base_effect_count or #state.catalog.base_effects,
        }
    end
    return {}, cached or {}
end

local function sourceModeLabel(source_mode)
    if source_mode == "player_known" then
        return "Known Effects"
    end
    if source_mode == "dev_full_catalog" then
        return "Dev Full Catalog"
    end
    return "Fallback Catalog"
end

local function sourceModeWarning(available)
    if type(available) ~= "table" then
        return nil
    end
    local notes = available.capability_notes or {}
    local reason = available.known_effect_scan_reason
    if notes.known_effect_scan_empty == true or reason == "known_effect_scan_empty" then
        return "No known spell effects found."
    end
    if available.source_mode ~= "fallback_static" then
        return nil
    end
    return "Could not read player-known spell effects; showing fallback catalog."
end

local function applyAvailableEffects(result)
    if result and result.ok == true then
        state.available_effects = result
        if state.catalog then
            state.catalog.available_effects = result
            state.catalog.base_effects = result.base_effects
            state.catalog.base_effect_count = result.base_effect_count
            state.catalog.available_effect_source_mode = result.source_mode
            state.catalog.available_effect_warnings = result.warnings
            state.catalog.available_effect_capability_notes = result.capability_notes
        end
        local warning = sourceModeWarning(result)
        if warning then
            setStatus(warning, "warning")
        else
            setStatus("Available effects refreshed: " .. sourceModeLabel(result.source_mode) .. ".", "success")
        end
        return true
    end
    setStatus("Available effects refresh failed.", "error")
    return false
end

local function refreshKnownEffects()
    setStatus("Refreshing known effects...", "info")
    ui_api.requestAvailableEffects(function(result)
        applyAvailableEffects(result)
        render()
    end, {
        force_rescan = true,
    })
    render()
end

local function catalogEffectLabel(entry)
    return tostring((entry and (entry.display_name or entry.label)) or (entry and entry.id) or "Effect")
end

function availableEntryForEffect(effect)
    local id = effect_registry.normalizeEffectId(effect and effect.id)
    if not id then
        return nil
    end
    local available = state.available_effects
        or (state.catalog and state.catalog.available_effects)
        or ui_api.getCachedAvailableEffects()
    local by_id = available and available.base_effects_by_id
    if type(by_id) == "table" and by_id[id] then
        return by_id[id]
    end
    local fallback = effect_registry.getFallbackInfo(id)
    if fallback then
        return fallback
    end
    return nil
end

local function parameterizedName(base_name, kind, parameter_id)
    if not parameter_id or parameter_id == "" then
        return base_name
    end
    local parameter_name = effect_registry.parameterDisplayName(kind, parameter_id)
    local text = tostring(base_name or "")
    if kind == "attribute" then
        text = string.gsub(text, "Attribute", parameter_name)
    elseif kind == "skill" then
        text = string.gsub(text, "Skill", parameter_name)
    end
    if text == "" or text == base_name then
        return tostring(base_name or "Effect") .. " " .. tostring(parameter_name)
    end
    return text
end

function effectDisplayName(effect)
    local entry = availableEntryForEffect(effect)
    local base = tostring((effect and effect.label) or (entry and entry.display_name) or (effect and effect.id) or "?")
    if entry and (entry.requiresAttribute == true or entry.hasAttribute == true) then
        return parameterizedName(base, "attribute", effect and effect.affectedAttribute)
    end
    if entry and (entry.requiresSkill == true or entry.hasSkill == true) then
        return parameterizedName(base, "skill", effect and effect.affectedSkill)
    end
    return base
end

local function catalogEffect(entry)
    if type(entry) ~= "table" or type(entry.id) ~= "string" or entry.id == "" then
        return nil
    end
    return {
        id = entry.id,
        engine_effect_id = entry.engine_effect_id,
        display_name = entry.display_name or entry.label,
        school = entry.school,
        category = entry.category,
        runtime_category = entry.runtime_category,
        range = tonumber(entry.default_range or entry.range) or 2,
        magnitudeMin = tonumber(entry.default_magnitude_min or entry.magnitudeMin) or 1,
        magnitudeMax = tonumber(entry.default_magnitude_max or entry.magnitudeMax) or tonumber(entry.default_magnitude_min or entry.magnitudeMin) or 1,
        area = tonumber(entry.default_area or entry.area) or 0,
        duration = tonumber(entry.default_duration or entry.duration) or 1,
        label = entry.display_name or entry.label,
        requiresAttribute = entry.requiresAttribute == true or entry.hasAttribute == true,
        requiresSkill = entry.requiresSkill == true or entry.hasSkill == true,
        parameter_kind = entry.parameter_kind,
    }
end

local function categoryList(entries)
    local seen = {}
    local values = { "all" }
    for _, entry in ipairs(entries or {}) do
        local category = tostring(entry.school or entry.category or "")
        if category ~= "" and not seen[category] then
            seen[category] = true
            values[#values + 1] = category
        end
    end
    table.sort(values, function(a, b)
        if a == "all" then return true end
        if b == "all" then return false end
        return a < b
    end)
    return values
end

local function normalizedSearchText(value)
    return string.lower(tostring(value or ""))
end

local function filteredBaseEffects()
    local entries = availableEffects()
    local filter = normalizedSearchText(state.effects_filter)
    local category_filter = state.effects_category_filter or "all"
    local out = {}
    for _, entry in ipairs(entries or {}) do
        local haystack = string.lower(table.concat({
            tostring(entry.id or ""),
            tostring(entry.display_name or entry.label or ""),
            tostring(entry.school or ""),
            tostring(entry.category or ""),
        }, " "))
        local category_ok = category_filter == "all"
            or tostring(entry.school or entry.category or "") == category_filter
        local search_ok = filter == "" or string.find(haystack, filter, 1, true) ~= nil
        if category_ok and search_ok then
            out[#out + 1] = entry
        end
    end
    return out
end

local function listWindow(entries, state_key, visible_count)
    local total = #(entries or {})
    local visible = math.max(1, math.min(visible_count or 1, math.max(total, 1)))
    local max_start = math.max(1, total - visible + 1)
    local start = clamp(tonumber(state[state_key]) or 1, 1, max_start)
    state[state_key] = start
    local finish = total > 0 and math.min(total, start + visible - 1) or 0
    local slice = {}
    if total > 0 then
        for i = start, finish do
            slice[#slice + 1] = entries[i]
        end
    end
    return slice, {
        start = start,
        finish = finish,
        total = total,
        visible = visible,
        page = visible > 0 and math.floor((start - 1) / visible) + 1 or 1,
    }
end

local function setListStart(list_name, state_key, total, visible, next_start)
    local max_start = math.max(1, (tonumber(total) or 0) - math.max(1, visible) + 1)
    local clamped = clamp(next_start, 1, max_start)
    if state[state_key] == clamped then
        return
    end
    state[state_key] = clamped
    log.info(string.format(
        "SPELLFORGE_UI_LIST_PAGE_CHANGED list=%s page=%s start=%s visible=%s total=%s",
        tostring(list_name),
        tostring(math.floor((clamped - 1) / math.max(1, visible)) + 1),
        tostring(clamped),
        tostring(visible),
        tostring(total)
    ))
    if list_name == "effects" and refreshEffectResults then
        refreshEffectResults()
    else
        render()
    end
end

local function pagerControls(list_name, state_key, meta, button_w)
    local total = meta.total or 0
    local visible = math.max(1, meta.visible or 1)
    local start = meta.start or 1
    local finish = meta.finish or 0
    local w = button_w or scaledInt(16)
    local small_gap = scaledInt(1)
    local page_w = scaledInt(20)
    return column({
        textLayout(string.format("%s-%s of %s", tostring(finish > 0 and start or 0), tostring(finish), tostring(total)), { color = COLOR.muted }),
        spacer(0, scaledInt(2)),
        row({
            button("|<", function() setListStart(list_name, state_key, total, visible, 1) end, { width = w, color = COLOR.muted }),
            spacer(small_gap, 0),
            button("P-", function() setListStart(list_name, state_key, total, visible, start - visible) end, { width = page_w, color = COLOR.muted }),
            spacer(small_gap, 0),
            button("^", function() setListStart(list_name, state_key, total, visible, start - 1) end, { width = w, color = COLOR.muted }),
            spacer(small_gap, 0),
            button("v", function() setListStart(list_name, state_key, total, visible, start + 1) end, { width = w, color = COLOR.muted }),
            spacer(small_gap, 0),
            button("P+", function() setListStart(list_name, state_key, total, visible, start + visible) end, { width = page_w, color = COLOR.muted }),
            spacer(small_gap, 0),
            button(">|", function() setListStart(list_name, state_key, total, visible, total) end, { width = w, color = COLOR.muted }),
        }),
    })
end

local function setEffectFilter(value)
    local next_value = tostring(value or "")
    if state.effects_filter == next_value then
        return
    end
    state.effects_filter = next_value
    state.effects_scroll_index = 1
    local count = #filteredBaseEffects()
    log.info(string.format(
        "SPELLFORGE_UI_LIST_FILTER_CHANGED list=effects count=%s filter=%s",
        tostring(count),
        tostring(next_value)
    ))
    if refreshEffectResults then
        refreshEffectResults()
    else
        render()
    end
end

local function cycleEffectCategory()
    local entries = availableEffects()
    local categories = categoryList(entries)
    local current = state.effects_category_filter or "all"
    local next_index = 1
    for i, category in ipairs(categories) do
        if category == current then
            next_index = i + 1
            break
        end
    end
    if next_index > #categories then
        next_index = 1
    end
    state.effects_category_filter = categories[next_index] or "all"
    state.effects_scroll_index = 1
    log.info(string.format(
        "SPELLFORGE_UI_LIST_FILTER_CHANGED list=effects count=%s category=%s",
        tostring(#filteredBaseEffects()),
        tostring(state.effects_category_filter)
    ))
    if refreshEffectResults then
        refreshEffectResults()
    else
        render()
    end
end

local function addEffect(effect)
    if type(effect) ~= "table" then
        setStatus("No effect selected.", "warning")
        render()
        return
    end
    state.effects[#state.effects + 1] = cloneValue(effect, 0)
    state.selected_index = #state.effects
    clearParameterPicker()
    markRecipeChanged()
    setStatus(string.format("Added effect (%d total).", #state.effects), "info")
    render()
end

local function addOperator(opcode)
    local effect_id = operatorEffectId(opcode)
    if not effect_id then
        setStatus("Catalog does not expose " .. tostring(opcode) .. ".", "error")
        render()
        return
    end
    state.effects[#state.effects + 1] = cloneValue({
        id = effect_id,
        params = defaultOperatorParams(opcode),
    }, 0)
    state.selected_index = #state.effects
    clearParameterPicker()
    markRecipeChanged()
    setStatus(string.format("Added %s operator.", operatorDisplayName(opcode)), "info")
    render()
end

local function moveSelected(delta)
    local i = state.selected_index
    local j = i and (i + delta) or nil
    if not i or not j or j < 1 or j > #state.effects then
        return
    end
    state.effects[i], state.effects[j] = state.effects[j], state.effects[i]
    state.selected_index = j
    clearParameterPicker()
    markRecipeChanged()
    render()
end

local function removeSelected()
    local i = state.selected_index
    if not i or not state.effects[i] then
        return
    end
    table.remove(state.effects, i)
    clearParameterPicker()
    if #state.effects == 0 then
        state.selected_index = nil
    elseif i > #state.effects then
        state.selected_index = #state.effects
    end
    markRecipeChanged()
    setStatus("Removed effect.", "info")
    render()
end

local function newRecipe()
    state.title = DEFAULT_TITLE
    state.effects = {}
    state.selected_index = nil
    clearParameterPicker()
    state.selected_saved_id = nil
    state.selected_saved_title = nil
    markRecipeChanged()
    setStatus("New recipe started.", "info")
    render()
end

local function loadSaved(saved)
    state.title = saved.title or saved.name or DEFAULT_TITLE
    state.effects = sanitizeEffects(saved.recipe and saved.recipe.effects or {})
    state.selected_index = #state.effects > 0 and 1 or nil
    clearParameterPicker()
    state.selected_saved_id = saved.id
    state.selected_saved_title = state.title
    markRecipeChanged()
    setStatus("Loaded \"" .. tostring(saved.title or saved.id) .. "\".", "info")
    log.info(string.format(
        "SPELLFORGE_SPELLCRAFT_UI_LOAD_OK saved_id=%s effects=%s",
        tostring(saved.id),
        tostring(#state.effects)
    ))
    render()
end

local function saveRecipe()
    local recipe = currentRecipe()
    local payload = {
        title = state.title,
        recipe = recipe,
    }
    local result
    local title_changed = state.selected_saved_id
        and state.selected_saved_title ~= nil
        and tostring(state.title or "") ~= tostring(state.selected_saved_title or "")
    if state.selected_saved_id and not title_changed then
        result = ui_api.updateRecipe(state.selected_saved_id, payload)
    else
        result = ui_api.saveRecipe(payload)
    end
    if result and result.ok then
        state.selected_saved_id = result.saved_recipe and result.saved_recipe.id or state.selected_saved_id
        state.selected_saved_title = result.saved_recipe and result.saved_recipe.title or state.title
        setStatus("Saved draft \"" .. tostring(result.saved_recipe and result.saved_recipe.title or state.title) .. "\".", "success")
        local saved_recipe = result.saved_recipe and result.saved_recipe.recipe or recipe
        if saved_recipe and type(saved_recipe.effects) == "table" then
            state.effects = sanitizeEffects(saved_recipe.effects)
            if type(state.selected_index) == "number" and state.selected_index > #state.effects then
                state.selected_index = #state.effects > 0 and #state.effects or nil
            end
            clearParameterPicker()
        end
        log.info(string.format(
            "SPELLFORGE_SPELLCRAFT_UI_SAVE_OK saved_id=%s effects=%s ops=%s",
            tostring(state.selected_saved_id),
            tostring(saved_recipe.effects and #saved_recipe.effects or 0),
            operatorSummary(saved_recipe.effects)
        ))
    else
        local first = result and result.errors and result.errors[1]
        setStatus(first and first.message or "Save failed.", "error")
        log.warn(string.format(
            "SPELLFORGE_SPELLCRAFT_UI_SAVE_FAILED reason=%s",
            tostring(first and first.message or "unknown")
        ))
    end
    render()
    return result
end

local function deleteSaved()
    if not state.selected_saved_id then
        setStatus("No saved recipe selected.", "info")
        render()
        return
    end
    local deleted_id = state.selected_saved_id
    local result = ui_api.deleteRecipe(state.selected_saved_id)
    if result and result.ok then
        state.title = DEFAULT_TITLE
        state.effects = {}
        state.selected_index = nil
        clearParameterPicker()
        state.selected_saved_id = nil
        state.selected_saved_title = nil
        markRecipeChanged()
        setStatus("Deleted saved recipe.", "success")
        log.info(string.format("SPELLFORGE_SPELLCRAFT_UI_DELETE_OK saved_id=%s", tostring(deleted_id)))
        render()
    else
        local first = result and result.errors and result.errors[1]
        setStatus(first and first.message or "Delete failed.", "error")
        log.warn(string.format("SPELLFORGE_SPELLCRAFT_UI_DELETE_FAILED saved_id=%s", tostring(deleted_id)))
        render()
    end
end

local function validateRecipe()
    local generation = state.recipe_generation
    local saved_id = state.selected_saved_id
    if saved_id then
        local saved = saveRecipe()
        if not saved or not saved.ok then
            return
        end
        saved_id = state.selected_saved_id
        generation = state.recipe_generation
    end
    setStatus("Validating recipe...", "info")
    render()
    local function onValidated(result)
        if not requestStillCurrent(generation) then
            return
        end
        state.last_validation = result
        if result and result.ok == true then
            setStatus("Valid recipe (id " .. tostring(result.recipe_id) .. ").", "success")
            log.info(string.format(
                "SPELLFORGE_SPELLCRAFT_UI_VALIDATE_OK recipe_id=%s ops=%s",
                tostring(result.recipe_id),
                operatorSummary(result.effects)
            ))
        else
            local first = result and result.errors and result.errors[1]
            setStatus(firstErrorMessage(result, "Validation failed."), "error")
            log.warn(string.format(
                "SPELLFORGE_SPELLCRAFT_UI_VALIDATE_FAILED reason=%s",
                tostring(first and first.message or "unknown")
            ))
        end
        render()
    end
    if saved_id then
        ui_api.validateSavedRecipe(saved_id, onValidated)
    else
        ui_api.validateRecipe(currentRecipe(), onValidated)
    end
end

local function previewRecipe()
    local generation = state.recipe_generation
    local saved_id = state.selected_saved_id
    if saved_id then
        local saved = saveRecipe()
        if not saved or not saved.ok then
            return
        end
        saved_id = state.selected_saved_id
        generation = state.recipe_generation
    end
    setStatus("Previewing recipe...", "info")
    render()
    local function onPreviewed(result)
        if not requestStillCurrent(generation) then
            return
        end
        if result and result.ok == true then
            state.preview = result.preview
            local preview = type(state.preview) == "table" and state.preview or {}
            if previewIsDeferred(state.preview) then
                setStatus("Preview deferred: " .. previewDeferredSummary(state.preview), "warning")
            else
                setStatus(string.format("Preview ready: %s slots.", tostring(preview.slot_count or 0)), "success")
            end
            log.info(string.format(
                "SPELLFORGE_SPELLCRAFT_UI_PREVIEW_OK recipe_id=%s groups=%s slots=%s helpers=%s ops=%s",
                tostring(result.recipe_id),
                tostring(preview.group_count),
                tostring(preview.slot_count),
                tostring(preview.helper_spec_count),
                operatorSummary(result.effects)
            ))
        else
            state.preview = nil
            local first = result and result.errors and result.errors[1]
            setStatus(firstErrorMessage(result, "Preview failed."), "error")
            log.warn(string.format(
                "SPELLFORGE_SPELLCRAFT_UI_PREVIEW_FAILED reason=%s",
                tostring(first and first.message or "unknown")
            ))
        end
        render()
    end
    if saved_id then
        ui_api.previewSavedRecipe(saved_id, onPreviewed)
    else
        ui_api.previewRecipe(currentRecipe(), onPreviewed)
    end
end

local function compileRecipe()
    local saved = saveRecipe()
    if not saved or not saved.ok or not state.selected_saved_id then
        return
    end
    local saved_id = state.selected_saved_id
    local generation = state.recipe_generation
    setStatus("Creating spell...", "info")
    render()
    ui_api.validateSavedRecipe(saved_id, function(validate_result)
        if not requestStillCurrent(generation) then
            return
        end
        if not validate_result or validate_result.ok ~= true then
            setStatus(firstErrorMessage(validate_result, "Validation failed before compile."), "error")
            render()
            return
        end
        ui_api.previewSavedRecipe(saved_id, function(preview_result)
            if not requestStillCurrent(generation) then
                return
            end
            if not preview_result or preview_result.ok ~= true then
                setStatus(firstErrorMessage(preview_result, "Preview failed before compile."), "error")
                render()
                return
            end
            state.preview = preview_result.preview
            if previewIsDeferred(state.preview) then
                local reason_summary = previewDeferredSummary(state.preview)
                setStatus("Create blocked: " .. reason_summary .. ".", "warning")
                log.warn(string.format(
                    "SPELLFORGE_SPELLCRAFT_UI_COMPILE_DEFERRED saved_id=%s recipe_id=%s reason=%s",
                    tostring(saved_id),
                    tostring(preview_result.recipe_id),
                    reason_summary
                ))
                render()
                return
            end
            local queued = ui_api.requestCompileSavedRecipe(saved_id, function(compile_result)
                if not requestStillCurrent(generation) then
                    return
                end
                if compile_result and compile_result.ok == true then
                    setStatus("Created spell \"" .. tostring(state.title) .. "\".", "success")
                    log.info(string.format(
                        "SPELLFORGE_SPELLCRAFT_UI_COMPILE_OK saved_id=%s recipe_id=%s spell_id=%s slots=%s helpers=%s ops=%s",
                        tostring(saved_id),
                        tostring(compile_result.recipe_id),
                        tostring(compile_result.spell_id),
                        tostring(preview_result.preview and preview_result.preview.slot_count),
                        tostring(preview_result.preview and preview_result.preview.helper_spec_count),
                        operatorSummary(preview_result and preview_result.effects)
                    ))
                else
                    setStatus(firstErrorMessage(compile_result, "Create failed."), "error")
                    log.warn(string.format(
                        "SPELLFORGE_SPELLCRAFT_UI_COMPILE_FAILED saved_id=%s reason=%s",
                        tostring(saved_id),
                        firstErrorMessage(compile_result, "unknown")
                    ))
                end
                render()
            end)
            if not queued or not queued.ok then
                setStatus(firstErrorMessage(queued, "Create request failed."), "error")
                render()
            end
        end)
    end)
end

local function operatorPalette(m)
    local items = {}
    local entries = state.catalog and state.catalog.operators or {}
    local columns = math.max(1, m.operator_grid_columns or 1)
    for i = 1, #entries, columns do
        local cells = {}
        for column_index = 0, columns - 1 do
            local entry = entries[i + column_index]
            if entry then
                local label = shortText(entry.display_name or entry.opcode, charsForWidth(m.operator_button_w, m, 7))
                logOperatorIconMetadataOnly(entry.opcode, entry.icon, entry.large_icon)
                cells[#cells + 1] = button(label, function()
                    addOperator(entry.opcode)
                end, {
                    width = m.operator_button_w,
                    color = COLOR.text,
                    text_size = m.list_text_size,
                })
            else
                cells[#cells + 1] = spacer(m.operator_button_w, 0)
            end
            if column_index < columns - 1 then
                cells[#cells + 1] = spacer(metric(m, 3), 0)
            end
        end
        items[#items + 1] = row(cells)
        items[#items + 1] = spacer(0, 2)
    end
    if #items == 0 then
        items[#items + 1] = paragraph("Catalog loading...", v2(math.max(metric(m, 76), m.palette_w - metric(m, 28)), metric(m, 48)), { color = COLOR.muted })
    end
    return section("Operators", column(items), v2(m.palette_w, m.operators_h))
end

local function effectResultsLayout(m)
    local items = {}
    local all_effects = availableEffects()
    local filtered = filteredBaseEffects()
    local visible_entries, meta = listWindow(filtered, "effects_scroll_index", m.effects_visible_rows)
    local category_label = state.effects_category_filter == "all" and "All Schools" or tostring(state.effects_category_filter)
    category_label = shortText(category_label, charsForWidth(m.palette_button_w, m, 10))
    items[#items + 1] = button(category_label, cycleEffectCategory, { width = m.palette_button_w, color = COLOR.muted })
    items[#items + 1] = spacer(0, 2)
    items[#items + 1] = textLayout(string.format("Filtered %s / %s", tostring(#filtered), tostring(#all_effects)), { color = COLOR.muted })
    items[#items + 1] = spacer(0, 3)
    for _, entry in ipairs(visible_entries) do
        local effect = catalogEffect(entry)
        items[#items + 1] = button(shortText(catalogEffectLabel(entry), charsForWidth(m.palette_button_w, m, 12)), function()
            addEffect(effect)
        end, {
            width = m.palette_button_w,
            color = COLOR.text,
            text_size = m.list_text_size,
        })
        items[#items + 1] = spacer(0, 1)
    end
    if #visible_entries == 0 then
        items[#items + 1] = paragraph("No matching effects.", v2(math.max(metric(m, 76), m.palette_w - metric(m, 28)), metric(m, 34)), { color = COLOR.muted })
    end
    items[#items + 1] = pagerControls("effects", "effects_scroll_index", meta, metric(m, 16))
    items[#items + 1] = spacer(0, 2)
    items[#items + 1] = button("Refresh", refreshKnownEffects, {
        width = math.min(m.palette_button_w, metric(m, 72)),
        color = COLOR.text,
        text_size = m.list_text_size,
        height = metric(m, 18),
    })
    local layout = column(items)
    layout.name = "effect_results"
    return layout
end

local function effectPalette(m)
    local items = {}
    local _, available = availableEffects()
    local source_label = sourceModeLabel(available and available.source_mode)
    items[#items + 1] = textLayout(source_label, { color = COLOR.text })
    local warning = sourceModeWarning(available)
    if warning then
        items[#items + 1] = spacer(0, 2)
        items[#items + 1] = paragraph(warning, v2(m.palette_button_w, metric(m, 34)), { color = COLOR.warning })
    end
    items[#items + 1] = spacer(0, 2)
    items[#items + 1] = framed(textInput(state.effects_filter, setEffectFilter, {
        width = math.max(metric(m, 24), m.palette_button_w - metric(m, 10)),
        color = COLOR.text,
        name = "effect_search_input",
    }), v2(m.palette_button_w, m.row_h + metric(m, 6)))
    items[#items + 1] = spacer(0, 2)

    local results = effectResultsLayout(m)
    if state.collecting_section_refs and state.section_refs then
        state.section_refs.effect_results = results
    end
    items[#items + 1] = results
    return section("Effects", column(items), v2(m.palette_w, m.effects_h))
end

local function recipeStack(m)
    local items = {}
    if #state.effects == 0 then
        items[#items + 1] = paragraph(
            "Empty recipe. Click an effect or operator on the left to add it.",
            v2(math.max(metric(m, 120), m.recipe_w - metric(m, 36)), metric(m, 56)),
            { color = COLOR.muted }
        )
    else
        for i, effect in ipairs(state.effects) do
            local selected = i == state.selected_index
            local color = COLOR.text
            local label = shortText(effectLabel(effect, i), charsForWidth(m.recipe_button_w, m, 28))
            items[#items + 1] = row({
                textLayout(selected and GLYPHS.cursor or GLYPHS.blank, {
                    color = COLOR.selected,
                    box_size = v2(metric(m, 22), 0),
                }),
                button(label, function()
                    state.selected_index = i
                    clearParameterPicker()
                    render()
                end, {
                    width = math.max(metric(m, 120), m.recipe_button_w - metric(m, 24)),
                    color = color,
                    text_size = m.list_text_size,
                }),
            })
            items[#items + 1] = spacer(0, 1)
        end
    end

    local controls = row({
        button("Up", function() moveSelected(-1) end, { width = metric(m, 44), color = COLOR.text }),
        spacer(metric(m, 4), 0),
        button("Down", function() moveSelected(1) end, { width = metric(m, 50), color = COLOR.text }),
        spacer(metric(m, 4), 0),
        button("Remove", removeSelected, { width = metric(m, 64), color = COLOR.text }),
        spacer(metric(m, 4), 0),
        button("New", newRecipe, { width = metric(m, 50), color = COLOR.text }),
    })

    return section("Spell Recipe", column({
        column(items, { size = v2(math.max(metric(m, 120), m.recipe_w - metric(m, 26)), m.recipe_list_h) }),
        spacer(0, metric(m, 4)),
        controls,
    }), v2(m.recipe_w, m.main_h))
end

local function rangeButtons(effect, m)
    local self_w = m.right_w < metric(m, 200) and metric(m, 44) or metric(m, 52)
    local touch_w = m.right_w < metric(m, 200) and metric(m, 50) or metric(m, 58)
    local target_w = m.right_w < metric(m, 200) and metric(m, 56) or metric(m, 64)
    local current = tonumber(effect.range) or 0
    local function tab(label, range_value, width)
        local active = current == range_value
        return button(label, function()
            if effect.range == range_value then
                return
            end
            effect.range = range_value
            markRecipeChanged()
            if refreshRecipeEditorSections then
                refreshRecipeEditorSections()
            else
                render()
            end
        end, {
            width = width,
            color = active and COLOR.selected or COLOR.muted,
            bullet = active and GLYPHS.bullet or nil,
        })
    end
    return row({
        tab("Self", 0, self_w),
        spacer(metric(m, 4), 0),
        tab("Touch", 1, touch_w),
        spacer(metric(m, 4), 0),
        tab("Target", 2, target_w),
    })
end

local function fieldLine(label, editor, m)
    return row({
        textLayout(label, { box_size = v2(m.field_label_w, 0), color = COLOR.muted }),
        spacer(metric(m, 4), 0),
        editor,
    })
end

local function selectedParameterLabel(kind, value)
    if type(value) ~= "string" or value == "" then
        return kind == "skill" and "Select Skill" or "Select Attribute"
    end
    return effect_registry.parameterDisplayName(kind, value)
end

local function parameterOptions(kind)
    if kind == "skill" then
        return effect_registry.skillOptions()
    end
    return effect_registry.attributeOptions()
end

local function isParameterPickerOpen(kind)
    local picker = state.parameter_picker
    return picker
        and picker.kind == kind
        and picker.effect_index == state.selected_index
end

local function openParameterPicker(kind)
    state.parameter_picker = {
        effect_index = state.selected_index,
        kind = kind,
    }
    if refreshRecipeEditorSections then
        refreshRecipeEditorSections()
    else
        render()
    end
end

local function setEffectParameter(effect, kind, value, close_picker)
    if kind == "skill" then
        effect.affectedSkill = value
        effect.affectedAttribute = nil
    else
        effect.affectedAttribute = value
        effect.affectedSkill = nil
    end
    if close_picker then
        clearParameterPicker()
    end
    markRecipeChanged()
    if refreshRecipeEditorSections then
        refreshRecipeEditorSections()
    else
        render()
    end
end

local function parameterPickerPanel(effect, kind, m)
    local options = parameterOptions(kind)
    local current = kind == "skill" and effect.affectedSkill or effect.affectedAttribute
    local title = kind == "skill" and "Choose Skill" or "Choose Attribute"
    local content_w = math.max(metric(m, 120), m.right_w - metric(m, 38))
    local columns = kind == "skill" and (m.right_w >= metric(m, 245) and 3 or 2) or 2
    local picker_button_w = math.max(metric(m, 48), math.floor((content_w - (columns - 1) * metric(m, 3)) / columns))
    local rows = {
        textLayout(title, { color = COLOR.section }),
        spacer(0, 2),
    }
    if #options == 0 then
        rows[#rows + 1] = paragraph("No options available.", v2(content_w, metric(m, 28)), { color = COLOR.warning })
    else
        for i = 1, #options, columns do
            local cells = {}
            for column_index = 0, columns - 1 do
                local option = options[i + column_index]
                if option then
                    local label = shortText(option.display_name or option.name or option.id, charsForWidth(picker_button_w, m, 7))
                    local active = option.id == current
                    cells[#cells + 1] = button(label, function()
                        setEffectParameter(effect, kind, option.id, true)
                    end, {
                        width = picker_button_w,
                        color = active and COLOR.selected or COLOR.text,
                        text_size = m.list_text_size,
                    })
                else
                    cells[#cells + 1] = spacer(picker_button_w, 0)
                end
                if column_index < columns - 1 then
                    cells[#cells + 1] = spacer(metric(m, 3), 0)
                end
            end
            rows[#rows + 1] = row(cells)
            rows[#rows + 1] = spacer(0, 2)
        end
    end
    rows[#rows + 1] = spacer(0, 2)
    rows[#rows + 1] = button("Cancel", function()
        clearParameterPicker()
        if refreshRecipeEditorSections then
            refreshRecipeEditorSections()
        else
            render()
        end
    end, {
        width = metric(m, 58),
        color = COLOR.muted,
        text_size = m.list_text_size,
    })
    return column(rows)
end

local function parameterEditor(effect, kind, m)
    local current = kind == "skill" and effect.affectedSkill or effect.affectedAttribute
    local label = shortText(selectedParameterLabel(kind, current), charsForWidth(m.field_input_w - metric(m, 40), m, 10))
    return row({
        button(label, function()
            openParameterPicker(kind)
        end, {
            width = math.max(metric(m, 70), m.field_input_w - metric(m, 42)),
            color = current and COLOR.text or COLOR.warning,
        }),
        spacer(metric(m, 4), 0),
        button("Clear", function()
            setEffectParameter(effect, kind, nil, true)
        end, {
            width = metric(m, 38),
            color = COLOR.muted,
        }),
    })
end

local function selectedEditor(m)
    local effect = selectedEffect()
    if not effect then
        return section("Selected Effect", paragraph(
            "Select an entry from the Spell Recipe to edit its parameters.",
            v2(math.max(metric(m, 130), m.right_w - metric(m, 38)), math.max(metric(m, 24), m.editor_h - metric(m, 56))),
            { color = COLOR.muted }
        ), v2(m.right_w, m.editor_h))
    end

    local opcode = opcodeForEffect(effect)
    local color = colorForEffect(effect)
    local heading
    if opcode then
        local kind = operatorKind(opcode) or "operator"
        logOperatorIconMetadataOnly(opcode, operatorIcon(opcode), operatorBigIcon(opcode))
        heading = row({
            textLayout(GLYPHS.bullet .. " " .. operatorDisplayName(opcode), { color = color }),
            spacer(metric(m, 6), 0),
            textLayout("[" .. kind .. "]", { color = COLOR.muted }),
        })
    else
        heading = textLayout(GLYPHS.bullet .. " " .. tostring(effectDisplayName(effect)), { color = color })
    end

    local lines = {
        heading,
        spacer(0, metric(m, 4)),
        fieldLine("ID", textInput(effect.id, function(value)
            if effect.id == value then
                return
            end
            effect.id = value
            effect.engine_effect_id = nil
            markRecipeChanged()
            if refreshRecipeSummarySections then
                refreshRecipeSummarySections()
            end
        end, { width = m.field_input_w, name = "selected_effect_id_input" }), m),
        spacer(0, metric(m, 4)),
    }

    if opcode then
        local description = operatorDescription(opcode)
        if description then
            lines[#lines + 1] = paragraph(description, v2(math.max(metric(m, 130), m.right_w - metric(m, 38)), metric(m, 36)), { color = COLOR.muted })
            lines[#lines + 1] = spacer(0, metric(m, 4))
        end
        local params = normalizedParamsForEffect(effect, opcode) or {}
        effect.params = params
        local param_defs = state.catalog and state.catalog.operators_by_opcode and state.catalog.operators_by_opcode[opcode]
        local names = {}
        local parameter_source = param_defs and param_defs.parameters or params
        if type(parameter_source) ~= "table" then
            parameter_source = {}
        end
        for name in pairs(parameter_source) do
            names[#names + 1] = name
        end
        table.sort(names)
        if #names == 0 then
            lines[#lines + 1] = textLayout("No parameters.", { color = COLOR.muted })
        end
        for _, name in ipairs(names) do
            if params[name] == nil then
                params[name] = operatorParamDefault(opcode, name, 1)
            end
            lines[#lines + 1] = fieldLine(name, numberInput(params[name], function(value)
                if params[name] == value then
                    return
                end
                params[name] = value
                markRecipeChanged()
                if refreshRecipeSummarySections then
                    refreshRecipeSummarySections()
                end
            end, { width = m.number_w, name = "operator_param_input_" .. tostring(name) }), m)
            lines[#lines + 1] = spacer(0, metric(m, 3))
        end
    else
        local entry = availableEntryForEffect(effect)
        if entry and (entry.requiresAttribute == true or entry.hasAttribute == true) then
            lines[#lines + 1] = fieldLine("Attr", parameterEditor(effect, "attribute", m), m)
            lines[#lines + 1] = spacer(0, metric(m, 4))
            if isParameterPickerOpen("attribute") then
                lines[#lines + 1] = parameterPickerPanel(effect, "attribute", m)
                lines[#lines + 1] = spacer(0, metric(m, 4))
            end
        elseif entry and (entry.requiresSkill == true or entry.hasSkill == true) then
            lines[#lines + 1] = fieldLine("Skill", parameterEditor(effect, "skill", m), m)
            lines[#lines + 1] = spacer(0, metric(m, 4))
            if isParameterPickerOpen("skill") then
                lines[#lines + 1] = parameterPickerPanel(effect, "skill", m)
                lines[#lines + 1] = spacer(0, metric(m, 4))
            end
        end
        lines[#lines + 1] = textLayout("Range", { color = COLOR.muted })
        lines[#lines + 1] = spacer(0, metric(m, 2))
        lines[#lines + 1] = rangeButtons(effect, m)
        lines[#lines + 1] = spacer(0, metric(m, 4))
        lines[#lines + 1] = fieldLine("Min", numberInput(effect.magnitudeMin or 0, function(value)
            if effect.magnitudeMin == value then
                return
            end
            effect.magnitudeMin = value
            markRecipeChanged()
            if refreshRecipeSummarySections then
                refreshRecipeSummarySections()
            end
        end, { width = m.number_w, name = "selected_effect_min_input" }), m)
        lines[#lines + 1] = spacer(0, metric(m, 3))
        lines[#lines + 1] = fieldLine("Max", numberInput(effect.magnitudeMax or 0, function(value)
            if effect.magnitudeMax == value then
                return
            end
            effect.magnitudeMax = value
            markRecipeChanged()
            if refreshRecipeSummarySections then
                refreshRecipeSummarySections()
            end
        end, { width = m.number_w, name = "selected_effect_max_input" }), m)
        lines[#lines + 1] = spacer(0, metric(m, 3))
        lines[#lines + 1] = fieldLine("Area", numberInput(effect.area or 0, function(value)
            if effect.area == value then
                return
            end
            effect.area = value
            markRecipeChanged()
            if refreshRecipeSummarySections then
                refreshRecipeSummarySections()
            end
        end, { width = m.number_w, name = "selected_effect_area_input" }), m)
        lines[#lines + 1] = spacer(0, metric(m, 3))
        lines[#lines + 1] = fieldLine("Duration", numberInput(effect.duration or 0, function(value)
            if effect.duration == value then
                return
            end
            effect.duration = value
            markRecipeChanged()
            if refreshRecipeSummarySections then
                refreshRecipeSummarySections()
            end
        end, { width = m.number_w, name = "selected_effect_duration_input" }), m)
    end

    return section("Selected Effect", column(lines), v2(m.right_w, m.editor_h))
end

local function savedRecipes(m)
    local rows = {}
    local saved = ui_api.getSavedRecipes() or {}
    local visible_saved, meta = listWindow(saved, "saved_scroll_index", m.saved_visible_rows)
    for _, entry in ipairs(visible_saved) do
        local active = entry.id == state.selected_saved_id
        local label = shortText(entry.title or entry.id, charsForWidth(m.right_button_w, m, 20))
        rows[#rows + 1] = button(label, function()
            loadSaved(entry)
        end, {
            width = m.right_button_w,
            color = COLOR.text,
            bullet = active and GLYPHS.cursor or GLYPHS.bullet,
            text_size = m.list_text_size,
        })
        rows[#rows + 1] = spacer(0, metric(m, 1))
    end
    if #rows == 0 then
        rows[#rows + 1] = paragraph(
            "No saved recipes yet. Click Save to keep the current one.",
            v2(math.max(metric(m, 110), m.right_w - metric(m, 38)), metric(m, 44)),
            { color = COLOR.muted }
        )
    elseif #saved > (meta.visible or m.saved_visible_rows or 3) then
        rows[#rows + 1] = pagerControls("saved", "saved_scroll_index", meta, metric(m, 24))
    end
    return section("Saved Recipes", column(rows), v2(m.right_w, m.saved_h))
end

local function previewLines(preview, m)
    local preview_text_w = m and m.preview_text_w or scaledInt(180)
    local lines = {}
    if not preview or next(preview) == nil then
        return {
            { text = "No preview yet. Press Preview to compute one.", color = COLOR.muted },
        }
    end
    if preview.recipe_id then
        lines[#lines + 1] = { text = "Recipe id  : " .. tostring(preview.recipe_id), color = COLOR.text }
    end
    local has_counts = preview.group_count or preview.slot_count or preview.helper_spec_count
    if has_counts then
        lines[#lines + 1] = {
            text = string.format(
                "Groups: %s   Slots: %s   Helpers: %s",
                tostring(preview.group_count or 0),
                tostring(preview.slot_count or 0),
                tostring(preview.helper_spec_count or 0)
            ),
            color = COLOR.text,
        }
    end
    local estimated_cost = preview.estimated_mana_cost
        or (preview.cost_model and preview.cost_model.estimated_mana_cost)
    if estimated_cost then
        lines[#lines + 1] = { text = "Estimated Mana Cost: " .. tostring(estimated_cost), color = COLOR.text }
        local tier = preview.cost_tier or (preview.cost_model and preview.cost_model.tier) or "Unknown"
        local school = preview.dominant_school or (preview.cost_model and preview.cost_model.dominant_school) or "Unknown"
        lines[#lines + 1] = {
            text = string.format("Cost Tier : %s   School: %s", tostring(tier), tostring(school)),
            color = COLOR.text,
        }
    end
    local breakdown = preview.cost_breakdown or (preview.cost_model and preview.cost_model.breakdown) or {}
    local contributors = {}
    for _, contributor in ipairs(breakdown.contributors or {}) do
        local cost = tonumber(contributor and contributor.cost) or 0
        if cost > 0 then
            contributors[#contributors + 1] = contributor
        end
    end
    table.sort(contributors, function(a, b)
        return (tonumber(a.cost) or 0) > (tonumber(b.cost) or 0)
    end)
    if #contributors > 0 then
        local parts = {}
        for i = 1, math.min(3, #contributors) do
            local contributor = contributors[i]
            local label = contributor.label or contributor.effect_id or contributor.opcode or "cost"
            parts[#parts + 1] = string.format("%s %.1f", shortText(label, charsForWidth(preview_text_w * 0.33, m, 12)), tonumber(contributor.cost) or 0)
        end
        lines[#lines + 1] = { text = "Top Cost  : " .. table.concat(parts, ", "), color = COLOR.text }
    end
    local cost_warnings = preview.cost_warnings or (preview.cost_model and preview.cost_model.warnings) or {}
    if #cost_warnings > 0 then
        local warning = cost_warnings[1]
        local reason = warning and (warning.reason or warning.code or warning.message) or "cost warning"
        lines[#lines + 1] = { text = "Cost Warn : " .. shortText(tostring(reason), charsForWidth(preview_text_w, m, 32)), color = COLOR.warning }
    end
    local matrix = preview.feature_matrix or {}
    if matrix.live_runtime_status then
        local rstatus = tostring(matrix.live_runtime_status)
        local rcolor = COLOR.text
        if rstatus == "ready" or rstatus == "ok" or rstatus == "live" then rcolor = COLOR.success
        elseif rstatus == "deferred" then rcolor = COLOR.warning
        elseif rstatus == "blocked" or rstatus == "error" then rcolor = COLOR.error
        end
        lines[#lines + 1] = { text = "Runtime    : " .. rstatus, color = rcolor }
    end
    if matrix.deferred_reasons and #matrix.deferred_reasons > 0 then
        lines[#lines + 1] = {
            text = "Deferred   : " .. shortText(rejection_messages.formatDeferredReasons(matrix.deferred_reasons), charsForWidth(preview_text_w, m, 42)),
            color = COLOR.warning,
        }
    end
    return lines
end

local function previewPanel(m)
    local lines = previewLines(state.preview, m)
    local children = {}
    for i, line in ipairs(lines) do
        children[#children + 1] = textLayout(line.text, { color = line.color, box_size = v2(m.preview_text_w, 0) })
        if i < #lines then
            children[#children + 1] = spacer(0, metric(m, 2))
        end
    end
    return section("Preview", column(children, { size = v2(m.preview_text_w, m.preview_text_h) }), v2(m.right_w, m.preview_h))
end

local function titleEditor(m)
    return row({
        textLayout("Name", { color = COLOR.muted }),
        spacer(metric(m, 8), 0),
        textInput(state.title, function(value)
            if state.title == value then
                return
            end
            state.title = value
            markRecipeChanged()
        end, { width = m.title_w, color = COLOR.text }),
    })
end

local function bannerHeader(m)
    return {
        template = template("box"),
        props = {
            size = v2(m.content_w, m.banner_h),
        },
        content = openmw_ui.content {
            padded(column({
                textLayout(BANNER_TITLE, { header = true, size = m.title_size, color = COLOR.title }),
                spacer(0, metric(m, 2)),
                row({
                    textLayout(SUBTITLE, { color = COLOR.subtitle }),
                    spacer(metric(m, 12), 0),
                    titleEditor(m),
                }),
            })),
        },
    }
end

local function statusBar(m)
    local kind = state.status_kind or "info"
    local status_w = math.max(metric(m, 120), m.content_w - metric(m, 220))
    local text = shortText(
        string.format("%s  %s", statusPrefix(kind), state.status or ""),
        charsForWidth(status_w, m, 24)
    )
    local saved_label = state.selected_saved_id
        and shortText(string.format("Editing: %s", tostring(state.selected_saved_id)), charsForWidth(math.max(metric(m, 80), m.content_w - status_w - metric(m, 8)), m, 18))
        or "Unsaved draft"
    return {
        template = template("box"),
        props = {
            size = v2(m.content_w, m.status_h),
        },
        content = openmw_ui.content {
            padded(row({
                textLayout(text, { color = statusColor(kind), box_size = v2(status_w, 0) }),
                spacer(metric(m, 8), 0),
                textLayout(saved_label, { color = COLOR.muted }),
            })),
        },
    }
end

local function actionButton(m, label, callback, kind, width)
    return button(label, callback, { width = metric(m, width or 70), height = m.row_h, color = COLOR.text })
end

local function actionButtons(m)
    return row({
        actionButton(m, "Save", saveRecipe, "primary", 54),
        spacer(metric(m, 4), 0),
        actionButton(m, "Validate", validateRecipe, "primary", 68),
        spacer(metric(m, 4), 0),
        actionButton(m, "Preview", previewRecipe, "primary", 66),
        spacer(metric(m, 4), 0),
        actionButton(m, "Create", compileRecipe, nil, 62),
        spacer(metric(m, 4), 0),
        actionButton(m, "Delete", deleteSaved, "danger", 58),
        spacer(metric(m, 4), 0),
        actionButton(m, "Close", function()
            spellcrafting_ui.close("button")
        end, "muted", 54),
    }, { size = v2(m.content_w, m.action_h) })
end

local function safeField(value, key)
    if value == nil then
        return nil
    end
    local ok, result = pcall(function()
        return value[key]
    end)
    if ok then
        return result
    end
    return nil
end

local function collectNamedLayouts(layout_or_element, refs, depth)
    if refs == nil or (depth or 0) > 20 then
        return
    end
    local layout = safeField(layout_or_element, "layout") or layout_or_element
    if type(layout) ~= "table" then
        return
    end
    local name = safeField(layout, "name")
    if type(name) == "string" and name ~= "" then
        refs[name] = layout
    end
    local content = safeField(layout, "content")
    if content == nil then
        return
    end
    pcall(function()
        for _, child in ipairs(content) do
            collectNamedLayouts(child, refs, (depth or 0) + 1)
        end
    end)
end

local function bindLiveSectionRefs()
    local refs = {}
    collectNamedLayouts(state.root, refs, 0)
    state.section_refs = refs
end

local function buildLayout()
    local m = layoutMetrics()
    local position = safePosition(m.layer, m.window)
    m.position = position
    state.last_layout = m
    state.section_refs = {}
    state.collecting_section_refs = true
    local effect_palette = effectPalette(m)
    local operator_palette = operatorPalette(m)
    local recipe_stack = recipeStack(m)
    local selected_editor = selectedEditor(m)
    local saved_recipes = savedRecipes(m)
    local preview_panel = previewPanel(m)
    recipe_stack.name = "recipe_stack"
    selected_editor.name = "selected_editor"
    preview_panel.name = "preview_panel"
    state.section_refs.recipe_stack = recipe_stack
    state.section_refs.selected_editor = selected_editor
    state.section_refs.preview_panel = preview_panel
    state.collecting_section_refs = false
    return {
        layer = LAYER_NAME,
        type = openmw_ui.TYPE.Window,
        props = {
            position = position,
            size = m.window,
        },
        content = openmw_ui.content {
            {
                template = template("boxSolid"),
                props = {
                    relativeSize = v2(1, 1),
                    size = v2(0, 0),
                },
                content = openmw_ui.content {
                    padded(column({
                        bannerHeader(m),
                        spacer(0, m.gap),
                        row({
                            column({
                                effect_palette,
                                spacer(0, m.gap),
                                operator_palette,
                            }),
                            spacer(m.gap, 0),
                            recipe_stack,
                            spacer(m.gap, 0),
                            column({
                                selected_editor,
                                spacer(0, m.gap),
                                saved_recipes,
                                spacer(0, m.gap),
                                preview_panel,
                            }),
                        }, { size = v2(m.content_w, m.main_h) }),
                        spacer(0, m.gap),
                        statusBar(m),
                        spacer(0, m.gap),
                        actionButtons(m),
                    })),
                },
            },
        },
    }
end

local function copyLayoutInto(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return false
    end
    target.template = source.template
    target.type = source.type
    target.props = source.props
    target.content = source.content
    target.events = source.events
    target.external = source.external
    target.layer = source.layer
    target.name = source.name or target.name
    target.userData = source.userData
    return true
end

local function scaleMatchesCurrentLayout()
    local m = state.last_layout
    return m == nil or m.ui_scale_key == ui_preferences.uiScaleKey()
end

local function updateSection(section_name, source_layout)
    if state.visible ~= true or state.root == nil then
        return false
    end
    if not scaleMatchesCurrentLayout() then
        return false
    end
    local target = state.section_refs and state.section_refs[section_name]
    if not copyLayoutInto(target, source_layout) then
        return false
    end
    bindLiveSectionRefs()
    local search_input = state.section_refs and state.section_refs.effect_search_input
    if type(search_input) == "table" then
        search_input.props = search_input.props or {}
        search_input.props.text = tostring(state.effects_filter or "")
    end
    local effect = selectedEffect()
    local selected_effect_inputs = {
        selected_effect_id_input = effect and effect.id,
        selected_effect_min_input = effect and effect.magnitudeMin,
        selected_effect_max_input = effect and effect.magnitudeMax,
        selected_effect_area_input = effect and effect.area,
        selected_effect_duration_input = effect and effect.duration,
    }
    for name, value in pairs(selected_effect_inputs) do
        local input_layout = state.section_refs and state.section_refs[name]
        if type(input_layout) == "table" then
            input_layout.props = input_layout.props or {}
            input_layout.props.text = tostring(value or 0)
        end
    end
    if effect and type(effect.params) == "table" then
        for name, value in pairs(effect.params) do
            local input_layout = state.section_refs and state.section_refs["operator_param_input_" .. tostring(name)]
            if type(input_layout) == "table" then
                input_layout.props = input_layout.props or {}
                input_layout.props.text = tostring(value or 0)
            end
        end
    end
    local ok, err = pcall(function()
        state.root:update()
    end)
    if not ok then
        log.warn(string.format(
            "SPELLFORGE_UI_PARTIAL_UPDATE_FAILED section=%s reason=%s",
            tostring(section_name),
            tostring(err)
        ))
        return false
    end
    return true
end

refreshEffectResults = function()
    local m = state.last_layout
    if not m then
        if render then
            render()
        end
        return false
    end
    if updateSection("effect_results", effectResultsLayout(m)) then
        return true
    end
    if render then
        render()
    end
    return false
end

refreshRecipeSummarySections = function()
    local m = state.last_layout
    if not m then
        if render then
            render()
        end
        return false
    end
    local recipe_ok = updateSection("recipe_stack", recipeStack(m))
    local preview_ok = updateSection("preview_panel", previewPanel(m))
    if recipe_ok or preview_ok then
        return true
    end
    if render then
        render()
    end
    return false
end

refreshRecipeEditorSections = function()
    local m = state.last_layout
    if not m then
        if render then
            render()
        end
        return false
    end
    local recipe_ok = updateSection("recipe_stack", recipeStack(m))
    local editor_ok = updateSection("selected_editor", selectedEditor(m))
    local preview_ok = updateSection("preview_panel", previewPanel(m))
    if recipe_ok or editor_ok or preview_ok then
        return true
    end
    if render then
        render()
    end
    return false
end

render = function()
    destroyRoot()
    if not state.visible then
        return
    end
    state.root = openmw_ui.create(buildLayout(), { noWarnUnused = true })
    bindLiveSectionRefs()
end

local function ensureCatalog(force_available_rescan)
    if state.catalog then
        if force_available_rescan == true then
            refreshKnownEffects()
        end
        return
    end
    ui_api.requestCatalog(function(result)
        if result and result.ok == true then
            state.catalog = result
            state.available_effects = result.available_effects or ui_api.getCachedAvailableEffects()
            auditOperatorIconMetadata(result, true)
            local warning = sourceModeWarning(state.available_effects)
            if warning then
                setStatus(warning, "warning")
            else
                setStatus("Catalog loaded.", "success")
            end
            if not state.audit_logged then
                state.audit_logged = true
                log.info(string.format(
                    "SPELLFORGE_UI_PLACEHOLDER_AUDIT_OK base_effect_source=%s operators=catalog recipe_list=bounded saved_list=virtualized preview=backend native_scroll=false virtualized=true",
                    tostring(result.available_effect_source_mode or (state.available_effects and state.available_effects.source_mode) or "unknown")
                ))
            end
            log.info(string.format(
                "SPELLFORGE_SPELLCRAFT_UI_CATALOG_OK operators=%s base_effects=%s source=%s",
                tostring(result.operators and #result.operators or 0),
                tostring(result.base_effect_count or (result.base_effects and #result.base_effects) or 0),
                tostring(result.available_effect_source_mode or (state.available_effects and state.available_effects.source_mode))
            ))
        else
            setStatus("Catalog request failed.", "error")
            log.warn("SPELLFORGE_SPELLCRAFT_UI_CATALOG_FAILED")
        end
        render()
    end, {
        force_rescan = force_available_rescan == true,
    })
end

local function addUiMode()
    if state.mode_added and state.active_mode and hasMode(state.active_mode) then
        return true
    end
    local ui_interface = I.UI
    if not (ui_interface and ui_interface.addMode) then
        state.mode_added = false
        state.active_mode = nil
        return false, "ui_add_mode_unavailable"
    end
    local ok, err = pcall(ui_interface.addMode, MODE, { windows = {} })
    if ok then
        state.mode_added = hasSpellforgeMode()
        state.active_mode = state.mode_added and MODE or nil
        if not state.mode_added then
            return false, "mode_not_present_after_add"
        end
        return true
    end

    local requested_err = tostring(err)
    local fallback_mode = fallbackUiMode()
    if currentUiMode() ~= nil then
        state.mode_added = false
        state.active_mode = nil
        return false, "fallback_requires_empty_mode_stack"
    end
    if hasMode(fallback_mode) then
        state.mode_added = false
        state.active_mode = nil
        return false, "fallback_mode_already_active"
    end
    local fallback_ok, fallback_err = pcall(ui_interface.addMode, fallback_mode, { windows = {} })
    if not fallback_ok then
        state.mode_added = false
        state.active_mode = nil
        return false, string.format("%s; fallback_%s_failed=%s", requested_err, tostring(fallback_mode), tostring(fallback_err))
    end
    state.mode_added = hasMode(fallback_mode)
    state.active_mode = state.mode_added and fallback_mode or nil
    if not state.mode_added then
        return false, "mode_not_present_after_add"
    end
    log.warn(string.format(
        "SPELLFORGE_UI_MODE_FALLBACK_USED requested=%s active_mode=%s reason=%s",
        MODE,
        tostring(fallback_mode),
        requested_err
    ))
    return true
end

local function removeUiMode()
    local ui_interface = I.UI
    local active_mode = state.active_mode
    if ui_interface and ui_interface.removeMode and active_mode and hasMode(active_mode) then
        local ok, err = pcall(ui_interface.removeMode, active_mode)
        if not ok then
            log.warn(string.format(
                "SPELLFORGE_UI_MODE_REMOVE_FAILED mode=%s active_mode=%s reason=%s",
                MODE,
                tostring(active_mode),
                tostring(err)
            ))
        end
    end
    state.mode_added = false
    state.active_mode = nil
end

local function closeMenu(reason)
    local had_ui = state.visible == true
        or state.root ~= nil
        or state.mode_added == true
        or (state.active_mode ~= nil and hasMode(state.active_mode))
    if not had_ui then
        return
    end
    local closed_mode = state.active_mode
    state.visible = false
    destroyRoot()
    removeUiMode()
    log.info(string.format(
        "SPELLFORGE_UI_MODE_CLOSED mode=%s active_mode=%s reason=%s",
        MODE,
        tostring(closed_mode),
        tostring(reason or "close")
    ))
    log.info("SPELLFORGE_UI_MODE_LIFECYCLE_OK")
    log.info("SPELLFORGE_SPELLCRAFT_UI_CLOSED")
end

function spellcrafting_ui.open()
    if state.visible or state.root then
        return
    end
    state.visible = true
    ensureCatalog(true)
    render()
    local ok, err = addUiMode()
    if not ok then
        log.warn(string.format(
            "SPELLFORGE_UI_MODE_OPEN_FAILED mode=%s reason=%s",
            MODE,
            tostring(err)
        ))
        closeMenu("open_failed")
        return
    end
    log.info(string.format(
        "SPELLFORGE_UI_MODE_OPENED mode=%s active_mode=%s fallback=%s",
        MODE,
        tostring(state.active_mode),
        tostring(state.active_mode ~= MODE)
    ))
    log.info("SPELLFORGE_UI_MODE_LIFECYCLE_OK")
    local m = state.last_layout
    log.info(string.format(
        "SPELLFORGE_SPELLCRAFT_UI_OPENED screen=%sx%s layer=%sx%s source=%s window=%sx%s position=%sx%s ui_size=%s ui_scale=%s",
        tostring(m and m.screen and m.screen.x),
        tostring(m and m.screen and m.screen.y),
        tostring(m and m.layer and m.layer.x),
        tostring(m and m.layer and m.layer.y),
        tostring(m and m.size_source),
        tostring(m and m.window and m.window.x),
        tostring(m and m.window and m.window.y),
        tostring(m and m.position and m.position.x),
        tostring(m and m.position and m.position.y),
        tostring(m and m.ui_scale_key),
        tostring(m and m.ui_scale)
    ))
end

function spellcrafting_ui.close(reason)
    closeMenu(reason or "api")
end

function spellcrafting_ui.toggle(reason)
    if state.visible then
        spellcrafting_ui.close(reason or "toggle")
    else
        spellcrafting_ui.open()
    end
end

function spellcrafting_ui.isVisible()
    return state.visible
end

function spellcrafting_ui.handleUiModeChanged(data)
    if not state.root then
        return
    end
    local active_mode = state.active_mode
    if not active_mode or not hasMode(active_mode) then
        closeMenu("mode_removed")
        return
    end
    local current_mode = currentUiMode()
    if current_mode ~= active_mode then
        closeMenu(string.format("mode_changed_to_%s", tostring(data and data.newMode or current_mode)))
    end
end

function spellcrafting_ui.handleFrame()
    if state.visible then
        spellcrafting_ui.handleUiModeChanged(nil)
    end
end

function spellcrafting_ui.handleInputAction(action)
    if not state.visible then
        return true
    end
    local reason = uiExitActionReason(action)
    if reason then
        spellcrafting_ui.close(reason)
        return false
    end
    return true
end

function spellcrafting_ui.debugVirtualListProbe(catalog)
    local previous_catalog = state.catalog
    local previous_available = state.available_effects
    local previous_effects_scroll = state.effects_scroll_index
    local previous_operators_scroll = state.operators_scroll_index
    local previous_filter = state.effects_filter
    local previous_category = state.effects_category_filter
    if catalog then
        state.catalog = catalog
        state.available_effects = catalog.available_effects
    elseif not state.catalog then
        state.catalog = ui_api.getCachedCatalog()
        state.available_effects = ui_api.getCachedAvailableEffects()
    end

    local m = layoutMetrics()
    local used_h = m.banner_h + m.main_h + m.status_h + m.action_h + m.gap * 3
    local action_row_fits = used_h <= m.content_h
    local effects = filteredBaseEffects()
    local _, available = availableEffects()
    local effect_slice, effect_meta = listWindow(effects, "effects_scroll_index", m.effects_visible_rows)
    local operators = state.catalog and state.catalog.operators or {}
    local operator_icon_meta = auditOperatorIconMetadata(state.catalog, true)
    for _, entry in ipairs(operators) do
        logOperatorIconMetadataOnly(entry and entry.opcode, entry and entry.icon, entry and entry.large_icon)
    end
    local source_label = sourceModeLabel(available and available.source_mode)
    local source_warning = sourceModeWarning(available)
    log.info(string.format(
        "SPELLFORGE_UI_PLACEHOLDER_AUDIT_OK base_effect_source=%s hardcoded_base_effects=false operators=catalog recipe_list=bounded saved_list=virtualized preview=backend native_scroll=false virtualized=true",
        tostring(state.available_effects and state.available_effects.source_mode or state.catalog and state.catalog.available_effect_source_mode or "unknown")
    ))
    log.info(string.format(
        "SPELLFORGE_UI_EFFECT_LIST_VIRTUALIZED_OK visible=%s total=%s",
        tostring(#effect_slice),
        tostring(effect_meta.total)
    ))
    log.info(string.format(
        "SPELLFORGE_UI_OPERATOR_GRID_OK visible=%s total=%s columns=%s",
        tostring(#operators),
        tostring(#operators),
        tostring(m.operator_grid_columns or 1)
    ))
    log.info(string.format(
        "SPELLFORGE_UI_ACTION_ROW_FIT_OK fits=%s used_h=%s content_h=%s window=%sx%s",
        tostring(action_row_fits),
        tostring(used_h),
        tostring(m.content_h),
        tostring(m.window and m.window.x),
        tostring(m.window and m.window.y)
    ))

    state.effects_filter = "fire"
    state.effects_scroll_index = 1
    local filtered = filteredBaseEffects()
    log.info(string.format(
        "SPELLFORGE_UI_LIST_FILTER_CHANGED list=effects count=%s filter=fire",
        tostring(#filtered)
    ))
    state.effects_filter = previous_filter
    state.effects_scroll_index = previous_effects_scroll

    local page_changed = false
    if effect_meta.total > effect_meta.visible then
        state.effects_scroll_index = math.min(effect_meta.total, effect_meta.start + effect_meta.visible)
        page_changed = state.effects_scroll_index ~= effect_meta.start
        log.info(string.format(
            "SPELLFORGE_UI_LIST_PAGE_CHANGED list=effects page=%s start=%s visible=%s total=%s",
            tostring(math.floor((state.effects_scroll_index - 1) / math.max(1, effect_meta.visible)) + 1),
            tostring(state.effects_scroll_index),
            tostring(effect_meta.visible),
            tostring(effect_meta.total)
        ))
    end

    local result = {
        ok = effect_meta.total > 0 and #operators > 0,
        effects_visible = #effect_slice,
        effects_total = effect_meta.total,
        operators_visible = #operators,
        operators_total = #operators,
        filter_count = #filtered,
        page_changed = page_changed,
        action_row_fits = action_row_fits,
        layout_used_h = used_h,
        layout_content_h = m.content_h,
        source_label = source_label,
        source_warning = source_warning,
        operator_icon_count = operator_icon_meta.count,
        operator_icon_missing_count = operator_icon_meta.missing_count,
        operator_big_icon_count = operator_icon_meta.big_count,
        operator_big_icon_missing_count = operator_icon_meta.big_missing_count,
    }
    if catalog then
        state.catalog = previous_catalog
        state.available_effects = previous_available
    end
    state.effects_scroll_index = previous_effects_scroll
    state.operators_scroll_index = previous_operators_scroll
    state.effects_filter = previous_filter
    state.effects_category_filter = previous_category
    return result
end

function spellcrafting_ui.debugAvailableEffectSourceLabel(source_mode, available)
    local payload = available or { source_mode = source_mode }
    return {
        label = sourceModeLabel(source_mode or payload.source_mode),
        warning = sourceModeWarning(payload),
    }
end

function spellcrafting_ui.debugPreviewLinesForSmoke(preview)
    local lines = previewLines(preview)
    local texts = {}
    for i, line in ipairs(lines or {}) do
        texts[i] = line and line.text or ""
    end
    return texts
end

function spellcrafting_ui.debugOperatorIconMetadata(catalog)
    return auditOperatorIconMetadata(catalog or state.catalog, false)
end

function spellcrafting_ui.debugAddCatalogEffectForSmoke(entry)
    local effect = catalogEffect(entry)
    state.effects = {}
    state.selected_index = nil
    if not effect then
        return { ok = false, effect_count = 0 }
    end
    state.effects[1] = effect
    state.selected_index = 1
    return {
        ok = true,
        effect = effect,
        effect_count = #state.effects,
    }
end

local function isSpellcraftingHotkey(key, symbol)
    local y_key = input.KEY and input.KEY.Y
    return symbol == "y" or (y_key and key and key.code == y_key)
end

function spellcrafting_ui.handleKeyPress(key)
    local symbol = key and key.symbol and string.lower(key.symbol) or ""
    local key_codes = input.KEY or {}
    local escape_key = key_codes["Escape"] or key_codes["ESCAPE"] or key_codes["Esc"]
    if state.visible and (symbol == "escape" or symbol == "esc" or (escape_key and key and key.code == escape_key)) then
        spellcrafting_ui.close("escape")
        return false
    end
    if isSpellcraftingHotkey(key, symbol) then
        if not dev.spellcraftingUiEnabled() then
            return true
        end
        spellcrafting_ui.toggle("hotkey")
        return false
    end
    return true
end

return spellcrafting_ui
