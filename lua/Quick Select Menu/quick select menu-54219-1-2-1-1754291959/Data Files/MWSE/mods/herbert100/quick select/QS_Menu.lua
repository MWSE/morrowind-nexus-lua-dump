local cfg = require("herbert100.quick select.config")
local log = mwse.Logger.new()



-- local TAB_ACTIVE_OVER_ALPHA = 1.0
-- local TAB_ACTIVE_LEAVE_ALPHA = 0.9
-- local TAB_UNSELECTED_OVER_ALPHA = 0.75
-- local TAB_UNSELECTED_LEAVE_ALPHA = 0.4
local TAB_ACTIVE_OVER_ALPHA = 1.0
local TAB_ACTIVE_LEAVE_ALPHA = 0.90
local TAB_UNSELECTED_OVER_ALPHA = 0.75
local TAB_UNSELECTED_LEAVE_ALPHA = 0.5

local TAB_UNDERLINE_ACTIVE_OVER_ALPHA = 1.0
local TAB_UNDERLINE_ACTIVE_LEAVE_ALPHA = 0.95
local TAB_UNDERLINE_UNSELECTED_OVER_ALPHA = 0.75
local TAB_UNDERLINE_UNSELECTED_LEAVE_ALPHA = 0.2

local TAB_LABEL_ACTIVE_OVER_ALPHA = 1.0
local TAB_LABEL_ACTIVE_LEAVE_ALPHA = 0.95
local TAB_LABEL_UNSELECTED_OVER_ALPHA = 0.9
local TAB_LABEL_UNSELECTED_LEAVE_ALPHA = 0.45




local NUMBER_LABEL_COLOR = { 1, 1, 1 }
local TAB_LABEL_COLOR = { 1, 1, 1 }
local OPTION_LABEL_COLOR = { 1, 1, 1 }


local UIDs = {
    root = tes3ui.registerID("QS:root"),
    main = tes3ui.registerID("QS:main"),
    tab_container = tes3ui.registerID("QS:tab_container"),
    option_rect = tes3ui.registerID("QS:option_rect"),
    option_number = tes3ui.registerID("QS:option_number"),
    option_label = tes3ui.registerID("QS:option_label"),
    option_icon = tes3ui.registerID("QS:option_icon"),
    tab = tes3ui.registerID("QS:tab"),
    tab_underline = tes3ui.registerID("QS:tab_underline"),
    row = tes3ui.registerID("QS:row"),
    entry = tes3ui.registerID("QS:entry"),
}

local active_menu ---@type herbert.QS.Menu?





---@class herbert.QS.Menu.tab_selected.event_data
---@field menu herbert.QS.Menu
---@field tab_index integer



---@class herbert.QS.Menu.Option
---@field name string
---@field icon_path string?
---@field select fun(self: herbert.QS.Menu.Option)
---@field header string?
---@field make_tooltip nil|false|fun(self: herbert.QS.Menu.Option, e: tes3uiEventData) method that makes a tooltip, or nil, or false


---@class herbert.QS.Menu.Tab
---@field name string
---@field color {[1|2|3]: number}
---@field get_options fun(self: herbert.QS.Menu.Tab): herbert.QS.Menu.Option[]

---@param tabs herbert.QS.Menu.Tab[] a list of all tabs being managed by this menu
---@return string
local function tabs_tostring(tabs)
    local strs = {}
    for i, t in ipairs(tabs) do
        strs[i] = t.name
    end
    return string.format('{"%s"}', table.concat(strs, '", "'))
end

---@class herbert.QS.Menu.new_params
---@field tabs herbert.QS.Menu.Tab[]
---@field tab_index integer index of the first tab to make
---@field num_rows number? number of rows to make
---@field num_cols number? number of rows to make
---@field x_scale number?
---@field y_scale number?

---@class herbert.QS.Menu : herbert.Class, herbert.QS.Menu.new_params
---@field _already_selecting boolean? for internal use only.
---@field tabs herbert.QS.Menu.Tab[] a list of all tabs being managed by this menu
---@field options herbert.QS.Menu.Option[] a list of options for the current tab
---@field tab_index integer index of the current tab
---@field num_rows number
---@field num_cols number
---@field tab_container tes3uiElement
---@field main_block tes3uiElement
---@field index integer? index of selected option
---@field root tes3uiElement root of the ui structure. everything is inside the root
---@field typed_index integer number that's being typed. will be 0 instead of `nil` if no number is typed
---@field type_select_timer mwseTimer? timer that starts after an option is typed. the option will be selected when the timer ends
---@field new fun(p: herbert.QS.Menu.new_params): herbert.QS.Menu
local Menu = Herbert_Class.new {
    fields = {
        { "label_text" },
        { "index" },
        { "num_rows",  factory = function() return cfg.num_rows end },
        { "num_cols",  factory = function() return cfg.num_cols end },
        { "x_scale", default = 1, converter = function(v)
            return math.clamp(v,
                0.05, 1)
        end },
        { "y_scale", default = 1, converter = function(v)
            return math.clamp(v,
                0.05, 1)
        end },
        { "options",     tostring = Herbert_Class_utils.premade.array_tostring },
        { "root" },
        { "tab_index",   default = 1, },
        { "tabs",        tostring = tabs_tostring },
        { "typed_index", factory = function() return 0 end },
    },
    ---@param self herbert.QS.Menu
    post_init = function(self)
        log:trace("initialized menu with tabs = %s", tabs_tostring, self.tabs)
        local qs_root = tes3ui.createMenu { id = UIDs.root, fixedFrame = true }
        self.root = qs_root
        qs_root:destroyChildren()
        qs_root.alpha = 0

        if not self.tab_index or not self.tabs[self.tab_index] then
            self.tab_index = 1
        end

        -- qs_root = mm:createBlock({id=UIDs.root})
        local width, height = tes3ui.getViewportSize()
        -- log("screen size: width=%s, height=%s", width,height)

        local root_width = width * cfg.root_ui_scale * cfg.root_ui_x_scale * self.x_scale
        local root_height = height * cfg.root_ui_scale * cfg.root_ui_y_scale * self.y_scale


        qs_root.width = root_width
        qs_root.minWidth = root_width
        qs_root.maxWidth = root_width

        qs_root.height = root_height
        qs_root.minHeight = root_height
        qs_root.maxHeight = root_height

        qs_root.absolutePosAlignX = cfg.x_pos
        qs_root.absolutePosAlignY = cfg.y_pos
        qs_root.flowDirection = tes3.flowDirection.topToBottom

        local tab_container = qs_root:createBlock { id = UIDs.tab_container }
        self.tab_container = tab_container
        tab_container.flowDirection = tes3.flowDirection.leftToRight
        tab_container.width = root_width
        tab_container.minHeight = 25
        tab_container.maxHeight = 25
        tab_container.height = 25
        tab_container.childAlignY = 0.5
        tab_container.borderTop = cfg.border_rows
        tab_container.borderBottom = cfg.border_rows

        qs_root:updateLayout()

        local main_block = qs_root:createBlock { id = UIDs.main }
        main_block.flowDirection = tes3.flowDirection.topToBottom
        main_block.width = root_width
        main_block.heightProportional = 1.0

        self.main_block = main_block

        qs_root:updateLayout()


        local tab_rect, label, underline
        qs_root:updateLayout()
        local num_tabs = #self.tabs
        local TAB_SEP = cfg.border_cols
        local width_per_tab = tab_container.width / num_tabs - 2 * TAB_SEP
        for k, tab in ipairs(self.tabs) do
            local tab_name = tab.name
            tab_rect = tab_container:createRect { color = { 0, 0, 0 }, id = UIDs.tab }
            tab_rect.heightProportional = 1
            tab_rect.width = width_per_tab
            tab_rect.borderRight = TAB_SEP
            tab_rect.borderLeft = TAB_SEP
            tab_rect.flowDirection = tes3.flowDirection.topToBottom

            tab_rect:register(tes3.uiEvent.mouseOver, function(e)
                -- e.source.color = {math.random(), math.random(), math.random()}
                local src = e.source
                if k == self.tab_index then
                    src.alpha = TAB_ACTIVE_OVER_ALPHA
                    src.children[1].alpha = TAB_LABEL_ACTIVE_OVER_ALPHA
                    src.children[2].alpha = TAB_UNDERLINE_ACTIVE_OVER_ALPHA
                else
                    src.alpha = TAB_UNSELECTED_OVER_ALPHA
                    src.children[1].alpha = TAB_LABEL_UNSELECTED_OVER_ALPHA
                    src.children[2].alpha = TAB_UNDERLINE_UNSELECTED_OVER_ALPHA
                end
                src:updateLayout()
            end)
            tab_rect:register(tes3.uiEvent.mouseLeave, function(e)
                local src = e.source
                if k == self.tab_index then
                    src.alpha = TAB_ACTIVE_LEAVE_ALPHA
                    src.children[1].alpha = TAB_LABEL_ACTIVE_LEAVE_ALPHA
                    src.children[2].alpha = TAB_UNDERLINE_ACTIVE_LEAVE_ALPHA
                else
                    src.alpha = TAB_UNSELECTED_LEAVE_ALPHA
                    src.children[1].alpha = TAB_LABEL_UNSELECTED_LEAVE_ALPHA
                    src.children[2].alpha = TAB_UNDERLINE_UNSELECTED_LEAVE_ALPHA
                end
                src:updateLayout()
            end)
            tab_rect:register(tes3.uiEvent.mouseClick, function(e)
                self:change_tab(k)
            end)


            label = tab_rect:createLabel { text = tab_name }
            label.font = 1
            label.color = TAB_LABEL_COLOR
            label.wrapText = true
            label.justifyText = tes3.justifyText.center
            label.absolutePosAlignY = 0.35

            log:trace("made tab: %q", tab.name)

            underline = tab_rect:createRect { id = UIDs.tab_underline,
                color = tab.color or { math.random(), math.random(), math.random() }
            }
            underline.absolutePosAlignY = 1.0
            underline.width = width_per_tab
            underline.height = 3

            if k == self.tab_index then
                tab_rect.alpha = TAB_ACTIVE_LEAVE_ALPHA
                tab_rect.children[1].alpha = TAB_LABEL_ACTIVE_LEAVE_ALPHA
                tab_rect.children[2].alpha = TAB_UNDERLINE_ACTIVE_LEAVE_ALPHA
            else
                tab_rect.alpha = TAB_UNSELECTED_LEAVE_ALPHA
                tab_rect.children[1].alpha = TAB_LABEL_UNSELECTED_LEAVE_ALPHA
                tab_rect.children[2].alpha = TAB_UNDERLINE_UNSELECTED_LEAVE_ALPHA
            end
        end

        self:update_options()
        self:fill_tab()

        qs_root:updateLayout()

        tes3ui.enterMenuMode(qs_root.id)

        qs_root:register(tes3.uiEvent.destroy, function(e)
            self.root = nil
            active_menu = nil
            tes3ui.leaveMenuMode()
        end)
        active_menu = self
    end
}


---@param index integer
---@param parent tes3uiElement
function Menu:make_option_block(index, parent)
    local option = self.options[index]

    log("making option %s: %s", index, option)
    log:trace("self.options = %s", self.options)
    local color = self.tabs[self.tab_index].color or { 1, 1, 1 }


    -- local OPTION_OVER_ALPHA = 0.45
    -- local OPTION_LEAVE_ALPHA = 0.1
    -- local OPTION_OVER_ALPHA =  0.5
    -- local OPTION_LEAVE_ALPHA = 0.2
    local OPTION_OVER_ALPHA = cfg.option_over_alpha
    local OPTION_LEAVE_ALPHA = cfg.option_leave_alpha

    local rect = parent:createRect { id = UIDs.option_rect, color = color }
    rect.flowDirection = tes3.flowDirection.topToBottom
    -- rect.childAlignX = 0.5
    rect.childAlignY = 0.5
    rect.childAlignX = 0.5
    -- rect.borderAllSides = 0.00 * rect.height
    rect.widthProportional = 1
    rect.heightProportional = 1
    rect.alpha = OPTION_LEAVE_ALPHA



    rect:register(tes3.uiEvent.mouseOver, function()
        if rect.alpha == OPTION_OVER_ALPHA then return end
        if self.type_select_timer then
            self.type_select_timer:cancel()
        end
        rect.alpha = OPTION_OVER_ALPHA
        self.index = index
        log("in mouse over for an option. setting selected index to %s", index)
        self.typed_index = 0
        parent:updateLayout()
    end)
    rect:register(tes3.uiEvent.mouseLeave, function()
        if rect.alpha == OPTION_LEAVE_ALPHA then return end
        if self.type_select_timer then
            self.type_select_timer:cancel()
        end
        rect.alpha = OPTION_LEAVE_ALPHA
        self.index = nil
        self.typed_index = 0
        rect:updateLayout()
    end)

    rect:register(tes3.uiEvent.mouseClick, function(e)
        self:destroy()
        -- tes3ui.leaveMenuMode()
        timer.delayOneFrame(function()
            self:select_option(index)
        end)
    end)



    local number_label = rect:createLabel { id = UIDs.option_number, text = tostring(index) }
    number_label.absolutePosAlignX = 0.075
    number_label.absolutePosAlignY = 0.075
    number_label.color = NUMBER_LABEL_COLOR




    local label_text, icon_path, header_text, icon, icon_height, icon_width
    if not option then
        -- label_text = "N/A"
        label_text = ""
        -- icon_path = "icons\\gold.tga"
    else
        label_text = option.name
        icon_path = option.icon_path
        header_text = option.header
        -- tooltips
        if option.make_tooltip then
            rect:register(tes3.uiEvent.help, function(e) option:make_tooltip(e) end)
        end
    end
    if cfg.show_icons and icon_path then
        icon = rect:createImage { id = UIDs.option_icon, path = icon_path }
        parent:updateLayout()
        -- icon.maxHeight = math.min(0.3 * rect.height, 20)
        -- icon.maxWidth = math.min(0.3 * rect.width, 20)
        icon_height = math.min(0.45 * rect.height, 70)
        icon.height = icon_height
        icon.width = math.min(icon_height, 0.45 * rect.width, 70)
        icon:updateLayout()

        -- icon.absolutePosAlignX = 0.5
        -- icon.absolutePosAlignY = 0.3
        icon.borderTop = 0.1 * parent.height
        icon.scaleMode = true
        -- icon:updateLayout()
    end




    parent:updateLayout()

    local label = rect:createLabel { id = UIDs.option_label, text = label_text }
    label.color = OPTION_LABEL_COLOR
    label.widthProportional = 0.9
    label.absolutePosAlignX = 0.5
    label.wrapText = true
    if icon then
        label.borderTop = 0.1 * parent.height
    else
        label.absolutePosAlignY = 0.5
    end


    if header_text then
        local header_label = rect:createLabel { id = UIDs.option_label, text = option.header }
        header_label.color = OPTION_LABEL_COLOR
        header_label.absolutePosAlignX = 0.5
        header_label.absolutePosAlignY = 0.075
    end

    parent:updateLayout()
    return rect
end

function Menu:fill_tab()
    local row
    local num_rows, num_cols = self.num_rows, self.num_cols

    local main_block = self.main_block
    local k = 1
    local ROW_BORDER = cfg.border_rows
    local COL_BORDER = cfg.border_cols
    local OPTION_BG_ALPHA = cfg.option_bg_alpha
    for _ = 1, num_rows do
        row = main_block:createBlock { id = UIDs.row }
        row.width = main_block.width
        row.height = main_block.height / num_rows - 2 * ROW_BORDER
        row.borderBottom = ROW_BORDER
        row.borderTop = ROW_BORDER

        for _ = 1, num_cols do
            local block = row:createRect { id = UIDs.entry, color = { 0, 0, 0 } }
            block.alpha = OPTION_BG_ALPHA
            block.width = row.width / num_cols - 2 * COL_BORDER
            block.height = row.height
            block.borderLeft = COL_BORDER
            block.borderRight = COL_BORDER
            block.flowDirection = tes3.flowDirection.topToBottom

            row:updateLayout()

            self:make_option_block(k, block)
            k = k + 1
            block:updateLayout()
        end
    end
    self.root:updateLayout()
end

function Menu:destroy()
    if self.type_select_timer then
        self.type_select_timer:cancel()
    end

    if cfg.select_on_key_release and self.index and not self._already_selecting then
        log("condition hit!")
        timer.delayOneFrame(function()
            self:select_option(self.index)
        end)
    end

    if self.root then
        self.root:destroy()
        self.root = nil
    elseif self.type_select_timer then
        self.type_select_timer:cancel()
    end
end

function Menu:update_options()
    self.options = self.tabs[self.tab_index]:get_options()
    log("updated options to %s", self.options)
end

---@return tes3uiElement?
function Menu:get_option_block(index)
    log("trying to get block with index = %s", index)
    local row = 1 + math.floor((index - 1) / self.num_cols)
    local blk = self.main_block.children[row]
    if not blk then
        log("couldn't find blk! row = %s", row)
        return
    end
    local col = 1 + (index - 1) % self.num_cols
    blk = blk.children[col]
    if not blk then
        log("couldn't find blk! col = %s", col)
        return
    end
    blk = blk.children[1]
    if not blk then
        log("block didn't have the correct structure :(. row = %s. col = %s", row, col)
        return
    end
    log("found block %q, have row = %s, col = %s",
        function() return blk.children[3] and blk.children[3].text, row, col end)
    return blk
end

---@return boolean successful
function Menu:unhighlight_index(index)
    log("trying to unhighlight index = %s", index)
    local blk = self:get_option_block(index)
    if not blk then return false end

    blk:triggerEvent("mouseLeave")
    return true
end

---@return boolean successful
function Menu:highlight_index(index)
    log("trying to highlight index = %s", index)
    local blk = self:get_option_block(index)
    if not blk then return false end

    blk:triggerEvent("mouseOver")
    return true
end

---@return boolean successful
function Menu:number_typed(num)
    if self.type_select_timer then
        self.type_select_timer:cancel()
    end

    log("updating typed number from %s to %s", self.typed_index, num + self.typed_index * 10)
    num = num + self.typed_index * 10

    local new_blk = self:get_option_block(num)
    if not new_blk then return false end

    if self.index then
        self:unhighlight_index(self.index)
    end
    new_blk:triggerEvent("mouseOver")

    self.typed_index = num


    if num * 10 < #self.options then
        self.type_select_timer = timer.start { duration = cfg.big_number_time, type = timer.real, callback = function(e)
            self:destroy()
            self._already_selecting = true
            timer.delayOneFrame(function()
                self:select_option(num)
            end, timer.real)
        end }
    else
        self.type_select_timer = timer.start { duration = 0.05, type = timer.real, callback = function(e)
            self:destroy()
            timer.delayOneFrame(function()
                self._already_selecting = true
                self:select_option(num)
            end, timer.real)
        end }
    end
    return true
end

function Menu:select_option(index)
    index = index or self.index
    log("trying to select option with index %s", index)
    if not index then return end
    local option = self.options[index]
    if option then
        log("option exists! selecting %s", option)
        option:select()
    else
        log("option didnt exist")
    end
end

--changes the selected tab
function Menu:change_tab(tab_index)
    self.index = nil
    local old_tab_index = self.tab_index
    self.tab_index = tab_index
    if old_tab_index then
        self.tab_container.children[old_tab_index]:triggerEvent("mouseLeave")
    end
    self.tab_container.children[tab_index]:triggerEvent("mouseLeave")

    self:update_options()
    self.main_block:destroyChildren()
    self:fill_tab()

    event.trigger("herbert:QS:tab_selected", { menu = self, tab_index = tab_index })
end

function Menu:next_tab()
    self:change_tab(1 + self.tab_index % #self.tabs)
end

function Menu:prev_tab()
    self:change_tab(1 + (self.tab_index - 2) % #self.tabs)
end

function Menu:is_valid() return self.root ~= nil end

-- these callbacks are here so that they work with any implementation of this menu

---@param e keyDownEventData
local function number_key_pressed(e)
    -- 2 == 1 and 11 == 0, got it?
    if active_menu and e.keyCode >= 2 and e.keyCode <= 11 then
        log("key pressed: %s", e.keyCode - 1)
        active_menu:number_typed((e.keyCode - 1) % 10)
    end
end


local function arrow_key_right()
    if active_menu and active_menu:is_valid() then
        active_menu:next_tab()
    end
end

local function arrow_key_left()
    if active_menu and active_menu:is_valid() then
        active_menu:prev_tab()
    end
end

local scroll_blocked = false

---@param e mouseWheelEventData
local function mouse_wheel(e)
    if scroll_blocked then return end
    scroll_blocked = true
    timer.start { callback = function() scroll_blocked = false end, duration = cfg.mouse_scroll_block_time, type = timer.real }
    if e.delta > 0 then
        arrow_key_left()
    else
        arrow_key_right()
    end
end
local register_event = cfg.livecoding and livecoding and livecoding.registerEvent or event.register

register_event(tes3.event.keyDown, arrow_key_left, { filter = tes3.scanCode.keyLeft })
register_event(tes3.event.keyDown, arrow_key_right, { filter = tes3.scanCode.keyRight })
register_event(tes3.event.keyDown, arrow_key_left, { filter = tes3.scanCode.a })
register_event(tes3.event.keyDown, arrow_key_right, { filter = tes3.scanCode.d })
register_event(tes3.event.mouseWheel, mouse_wheel)
register_event(tes3.event.keyDown, number_key_pressed)

return Menu
