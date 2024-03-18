
local defns = require("herbert100.more quickloot.defns")
local log = Herbert_Logger() ---@type herbert.Logger
local config = require("herbert100.more quickloot.config") ---@type MQL.config
local Key_Label = require("herbert100.more quickloot.GUI.Key_Label")
local Modifier_Key_Label = require("herbert100.more quickloot.GUI.Modifier_Key_Label")
-- =============================================================================
-- GUI
-- =============================================================================


local COLORS = {
    unavailable = nil,
    unavailable_selected = nil,
    ok = nil,
    ok_selected = nil,
}

-- local function get_ok_color()
--     return tes3ui.getPalette(tes3.palette.normalColor)
-- end

-- local function get_ok_selected_color()
--     return tes3ui.getPalette(tes3.palette.activeColor)
    
-- end

-- local function get_unavailable_color()
--     return tes3ui.getPalette(tes3.palette.journal)
-- end

-- local function get_unavailable_selected_color()
--     return tes3ui.getPalette(tes3.palette.activeColor)
-- end

local MAX_NAME_LEN = 30
local ICON_SIZE = 40
local ITEM_LABEL_MIN_WIDTH = 175 -- 120 then 150
local GOLD_OFFSET = 30
local WEIGHT_OFFSET = 10

-- -@class MQL.GUI.status_text_params
-- -@field text string? the text to show
-- -@field justify tes3.justifyText? any `justifyText` parameters
-- -@field wrap boolean? should the text be wrapped?




---@class MQL.GUI.deleted_item
---@field table_index integer the index in the internal tables
---@field ui_index integer the index in the `tes3uiElement` blocks


---@class MQL.GUI.new_params
---@field items MQL.Item[]? a list of items to manage
---@field name string? the name of this container, if not `nil`
---@field key_labels MQL.GUI.Key_Label.keybinds? table indexed by key_name, where the value is a list containing the label for that key and the relative position in the menu
---@field m_key_labels MQL.GUI.Key_Label.keybinds? table indexed by key_name, where the value is a list containing the label for that MODIFIED key and the relative position in the menu
---@field status_text string should a status block be made? or the string to make the status block
---@field icon_size integer? how big should icons be?
---@field value_icon string? path for value icon
---@field weight_icon string? path for weight icon



local UIIDs = { item_label = nil, base = nil, name_label = nil }

--[[##GUI
roughly speaking, the GUI should have no idea what's going on.
it should only do as it's told. i.e., its behavior should be completely determined by a `Manager`.
A `Manager` is always responsible for:
1) setting the name label
2) specifying the control labels
3) providing a list of items to render
4) determining what happens when the player tries to take items/talk to the container
5) saying when things should be removed from a container.

The `GUI` is only responsible for:
1) keeping track of what item is currently selected.
2) Displaying things to the player, based on what the manager says should be displayed.
]]
---@class MQL.GUI : herbert.Class
---@field items MQL.Item[] the list of items in the GUI. this is synced with the relevant `Manager`.
---@field visible_indices integer[] a list of all items that are currently visible.
---@field index integer the index of the selected item
---@field content_block tes3uiElement the block of the UI that will hold the listed items
---@field controls_block tes3uiElement the block on the bottom that will hold the controls
---@field controls_block_m tes3uiElement the block on the bottom that will hold the controls
---
---@field icon_block tes3uiElement? the block that holds item icons in the content block
---@field name_block tes3uiElement? the block that holds item names in the content block
---@field value_block tes3uiElement? the block that holds item values in the content block
---@field weight_block tes3uiElement? the block that holds item weights in the content block
---@field ui_base tes3uiElement the panel that all UI elements live inside of
---@field first_dot_block tes3uiElement the "..." label that may appear at the beginning of a list
---@field last_dot_block tes3uiElement the "..." label that may appear at the end of a list
---@field blocked boolean `true` if the UI is not showing the items of a container and instead showing some other message. (e.g., it's showing "Empty")
---@field status_label tes3uiElement? the status label, if it exists
---@field status_divider tes3uiElement? the status label, if it exists
---@field icon_size integer the size of the icons
---@field value_icon string path for value icon
---@field weight_icon string path for weight icon
--- 
---@field key_label MQL.GUI.Key_Label
---@field m_key_label MQL.GUI.Modifier_Key_Label
---@field new fun(options:MQL.GUI.new_params): MQL.GUI create a new `GUI`
local GUI = Herbert_Class{name="GUI", new_obj_func="no_obj_data_table",
    --- make a new GUI
    ---@param self MQL.GUI the GUI that's being made
    ---@param params MQL.GUI.new_params
    init = function (self, params)
        log("about to create base_UI.")

        self.items = params.items
        self.visible_indices = {}
        self.icon_size = params.icon_size or ICON_SIZE
        self.value_icon = params.value_icon or "icons/gold.tga"
        self.weight_icon = params.weight_icon or "icons/weight.tga"
        -- self.items = items
        do -- remake the UI
            --
            self.ui_base = tes3ui.createMenu({id = UIIDs.base, fixedFrame = true})
            -- self.ui_base = tes3ui.createMenu({id = UIIDs.base, })
            self.ui_base.absolutePosAlignX = config.UI.menu_x_pos
            self.ui_base.absolutePosAlignY = config.UI.menu_y_pos
            self.ui_base.childAlignX = 0.5
            self.ui_base.childAlignY = 0.5
            self.ui_base.autoWidth = true -- new
            self.ui_base.minWidth = 200 -- was 150

            -- name the container if we're given a name 
            self:_make_label_block(params.name)
            
        do -- make dot block and content block
            self.first_dot_block = self.ui_base:createBlock()
            local first_dot_block = self.first_dot_block
            first_dot_block.flowDirection = "top_to_bottom"
            first_dot_block.widthProportional = 1.0
            first_dot_block.autoHeight = true
            first_dot_block.paddingAllSides = 3
            first_dot_block.minWidth = 150 -- new
            first_dot_block.childAlignX = 0

            local first_dot_label = first_dot_block:createLabel({text = "..."})
            first_dot_label.absolutePosAlignX = 0.5
            first_dot_block.visible = false

            
            self.content_block = self.ui_base:createBlock()
            local content_block = self.content_block
            content_block.childAlignX = 0

            content_block.widthProportional = 1.0 -- new

            content_block.flowDirection = "top_to_bottom"
            content_block.autoHeight = true
            content_block.autoWidth = true

            self.last_dot_block = self.ui_base:createBlock()
            local last_dot_block = self.last_dot_block
            last_dot_block.flowDirection = "top_to_bottom"
            last_dot_block.widthProportional = 1.0
            last_dot_block.autoHeight = true
            last_dot_block.paddingAllSides = 3
            last_dot_block.minWidth = 150 -- new
            last_dot_block.childAlignX = 0

            local last_dot_label = last_dot_block:createLabel({text = "..."})
            last_dot_label.absolutePosAlignX = 0.5
            last_dot_block.visible = false
        end
        -- if config.UI.enable_status_bar and params.status_text then
            self.status_divider = self.ui_base:createDivider()
            self.status_label = self.ui_base:createLabel{text=params.status_text}
            self.status_label.wrapText = true
            self.status_label.justifyText = tes3.justifyText.center
            self.status_label.widthProportional = 1.0
            
            self.status_label.childAlignX = 0.05
        if not (config.UI.enable_status_bar and params.status_text) then
            self.status_divider.visible = false
            self.status_label.visible = false
        end
        -- end
        self.key_label = Key_Label.new(self.ui_base, params.key_labels)
        self.m_key_label = Modifier_Key_Label.new(self.ui_base, params.m_key_labels, nil, false)
        end
        -- UI starts as blocked because the items aren't made.
        self.blocked = true
        self.ui_base:updateLayout()
    end,
    obj_metatable = {
        ---@param self MQL.GUI
        __tostring = function(self)
            local name_block =  self.labels_block and self.labels_block:findChild(UIIDs.name_label)
            local label = name_block and name_block.text
            return string.format("%s(label=%q, blocked=%s)", self.__secrets.name, label, self.blocked)
        end,
    }
}



-- internal function that makes the `label` block of a quickloot menu
function GUI:_make_label_block(name)

    ---@type tes3uiElement
    self.labels_block = self.ui_base:createBlock()
    self.labels_block.flowDirection=tes3.flowDirection.leftToRight

    self.labels_block.autoHeight=true
    self.labels_block.widthProportional = 1
    self.labels_block.paddingAllSides = 0
    self.labels_block.paddingTop = 2
    self.labels_block.paddingBottom = 1
    self.labels_block.paddingRight = 0
    self.labels_block.autoWidth=true
    
    local name_label = self.labels_block:createLabel({id=UIIDs.name_label or ""})
    if not config.UI.show_name then
        name_label.alpha = 0
    end
    self:set_name_label(name, true)
    if not config.UI.show_name then
        name_label.alpha = 0
    end
    -- local name_label = self.labels_block:createLabel({id="MQL:LabelsBlock:Name", text=new_name})
    local gold = self.labels_block:createImage{id=UIIDs.gold_label, path="icons/gold.tga"}
    local weight = self.labels_block:createImage{id=UIIDs.weight_label, path="icons/weight.tga"}


    local labels = {name_label, gold, weight}
    for _,label in ipairs(labels) do
        label.autoHeight = true
        label.autoWidth = true
        label.paddingTop = 11

    end
    for _,label in ipairs({gold, weight}) do
        label.autoHeight = true
        label.autoWidth = true
        label.paddingLeft = 0
        label.paddingRight = 0
        label.minWidth = 16
        label.maxWidth = 16

    end
    name_label.minWidth = ITEM_LABEL_MIN_WIDTH
    -- name_label.absolutePosAlignX = 0.05
    -- name_label.positionX = 3

    self.ui_base:updateLayout()

    self.labels_divider = self.ui_base:createDivider()
end


-- internal function that updates the size and position of the things in the labels block, so that the gold and weight icons are properly positioned.
-- should be called when the contents block is updated in some way
function GUI:_resize_labels_block()
    self.ui_base:updateLayout()


    local new_name_width = self.name_block.width + self.icon_size + GOLD_OFFSET
    local name_label = self.labels_block:findChild(UIIDs.name_label)

    name_label.width = new_name_width
    name_label.minWidth = new_name_width
    name_label.maxWidth = new_name_width


    local gold = self.labels_block:findChild(UIIDs.gold_label)
    gold.absolutePosAlignX = (new_name_width + (self.value_block.width)/2 )/self.ui_base.width

    local weight = self.labels_block:findChild(UIIDs.weight_label)
    weight.absolutePosAlignX = (new_name_width + self.value_block.width + (self.weight_block.width - WEIGHT_OFFSET)/2)/self.ui_base.width
    self.ui_base:updateLayout()
end



--- make the item list, and save the `items` to the GUI
---@param items MQL.Item[] the items to make
function GUI:make_item_blocks(items)
    self.items = items
    self.visible_indices = {}
    -- table.sort(items)
    self.content_block:destroyChildren()
    -- self.ui_base:updateLayout()
    self.blocked = false
    
    self.labels_block:findChild(UIIDs.gold_label).visible = true
    self.labels_block:findChild(UIIDs.weight_label).visible = true


    self.content_block.flowDirection = tes3.flowDirection.leftToRight


    log "making item blocks"
    -- make the item list
    self.icon_block = self.content_block:createBlock({id=UIIDs.icon_block})
    self.icon_block.flowDirection=tes3.flowDirection.topToBottom
    self.icon_block.childAlignY = 0.5
    self.icon_block.paddingAllSides = 3
    self.icon_block.autoHeight = true
    self.icon_block.width = self.icon_size
    self.icon_block.minHeight = 45
    self.icon_block.paddingTop = math.max(2,(self.icon_size-30)/2)

    -- self.icon_block.paddingAllSides = 4


    ---@type tes3uiElement
    self.name_block = self.content_block:createBlock({id=UIIDs.name_block})
    self.value_block = self.content_block:createBlock({id=UIIDs.value_block})
    self.weight_block = self.content_block:createBlock({id=UIIDs.weight_block})
    

    for _, block in ipairs{self.name_block, self.value_block, self.weight_block} do 
        block.childAlignY = 0.5
        block.autoHeight = true
        block.autoWidth = true
        -- block.paddingTop = 11
        block.paddingTop = math.max(3,(self.icon_size-20)/2)
        block.paddingRight = 15
        block.flowDirection = tes3.flowDirection.topToBottom
        block.paddingAllSides = 3
    end

    -- name_block.minWidth = self.labels_block:findChild(UIIDs.name_label).width
    self.name_block.minWidth = ITEM_LABEL_MIN_WIDTH

    self.value_block.minWidth = self.icon_size + GOLD_OFFSET
    self.value_block.paddingLeft = GOLD_OFFSET
    self.value_block.childAlignX = 0.5
    
    self.weight_block.minWidth = self.icon_size + WEIGHT_OFFSET - 15
    self.weight_block.paddingRight = WEIGHT_OFFSET
    self.weight_block.childAlignX = 0.5


    for i, item in ipairs(self.items) do
        local icon = self.icon_block:createImage{path=item:get_icon_path()}
        -- icon:setPropertyInt("MQL:index",i)
        icon.paddingAllSides = 3
        icon.minHeight = self.icon_size
        icon.minWidth = self.icon_size
        

        local name = self.name_block:createLabel{text = item:get_name_label()}

        local value = self.value_block:createLabel{text = item:get_value_label()}
        local weight = self.weight_block:createLabel{text = item:get_weight_label()}

        for _, label in ipairs{name, value, weight} do
            label.minHeight = self.icon_size
            label.paddingAllSides = 3
            -- label.wrapText = false
            -- label.positionY = 0.5
            label.visible = false
        end

        icon.visible = false
        name.visible = false
        value.visible = false
        weight.visible = false

    end

    if log >= log.LEVEL.TRACE then
        log:trace "made items. printing items"
        for i,v in ipairs(self.items) do
            log:trace("%i: %s", i, v)
        end
    end
    self.ui_base:updateLayout()

end




--- update visible items in the `GUI`, and updates their colors as well
---@param selected_index integer the index of the selected item
function GUI:update_visible_items(selected_index)

    local num_items = #self.items

    for i=#self.visible_indices, 1, -1 do
        local index = self.visible_indices[i]
        self.name_block.children[index].visible = false
        self.icon_block.children[index].visible = false
        self.value_block.children[index].visible = false
        self.weight_block.children[index].visible = false
        self.visible_indices[i] = nil
    end

    local visible_remaining = config.UI.max_disp_items - 1

    -- indices of items we should make visible (and update the colors of)
    self.visible_indices[1] = selected_index

    -- handle the case when `max_disp_items` is odd: in this case, we should show an extra item at the end
    local remainder = visible_remaining % 2
    local half_remaining = (visible_remaining-remainder) / 2

    
    local remaining_before = half_remaining -- how many items we should try to show before `selected_index`
    local remaining_after = half_remaining + remainder  -- how many items we should try to show after `selected_index`

    
    -- i counts down, j counts up
    local i,j = selected_index, selected_index

    
    -- try to show items before the index
    while i > 1 and remaining_before > 0 do
        i = i - 1

        if self.items[i].status >= defns.item_status.unavailable then
            table.insert(self.visible_indices, i)
            remaining_before = remaining_before - 1
        end
    end

    -- add the extra indices to remaining after (if we couldnt add everything)
    remaining_after = remaining_after + remaining_before
    -- try to show items after the index
    while j < num_items and remaining_after > 0 do
        j = j + 1

        if self.items[j].status >= defns.item_status.unavailable then
            table.insert(self.visible_indices, j)
            remaining_after = remaining_after - 1
        end
    end

    -- if we stopped early when showing items before the current index, and we couldn't show enough items after the index, then
    -- go back and try to show more items before the index
    while i > 1 and remaining_after > 0 do
        i = i - 1

        if self.items[i].status >= defns.item_status.unavailable then
            table.insert(self.visible_indices, i)
            remaining_after = remaining_after - 1
        end
    end

    local fdv, ldv = false, false
    while i > 1 do
        i = i - 1
        if self.items[i].status >= defns.item_status.ok then 
            fdv = true
            break 
        end
    end

    while j < num_items do
        j = j + 1

        if self.items[j].status >= defns.item_status.unavailable then
            ldv = true
            break
        end
    end

    self.first_dot_block.visible = fdv
    self.last_dot_block.visible = ldv

    -- now we actually update the items
    local color -- the color to use

    for _, index in ipairs(self.visible_indices) do
        -- if the item is okay, use `ok` colors
        if self.items[index].status == defns.item_status.ok then
            -- check if the item is selected
            color = (index == selected_index and COLORS.ok_selected) or COLORS.ok
        else
            -- if the item is unavailable, use unavailable colors (and check if the item is selected)
            color = (index == selected_index and COLORS.unavailable_selected) or COLORS.unavailable
        end
        -- set them visible
        self.icon_block.children[index].visible = true
        self.name_block.children[index].visible = true
        self.value_block.children[index].visible = true
        self.weight_block.children[index].visible = true

        -- update their color
        self.name_block.children[index].color = color
        self.value_block.children[index].color = color
        self.weight_block.children[index].color = color
    end

    self:_resize_labels_block()
end

-- update the item at the specified index
function GUI:update_item_name_label(index)
    if self.name_block.children[index] then 
        self.name_block.children[index].text = self.items[index]:get_name_label()
        self.ui_base:updateLayout()
    else
        log:error("tried to update item labels but children[index] was nil!.\n\t\z
            index: %i\n\t\z
            #children: %i\n\t\z
            #items: %i\n\t\z
            #item: %s",
            function ()
                return index, #self.name_block.children, #self.items, self.items[index]
            end
        )
    end
end

-- update the item at the specified index
function GUI:update_item_labels(index)
    if self.name_block.children[index] then
        self.name_block.children[index].text = self.items[index]:get_name_label()
        self.weight_block.children[index].text = self.items[index]:get_weight_label()
        self.value_block.children[index].text = self.items[index]:get_value_label()
        self.ui_base:updateLayout()
    else
        log:error("tried to update item labels but children[index] was nil!.\n\t\z
            index: %i\n\t\z
            #children: %i\n\t\z
            #items: %i\n\t\z
            #item: %s",
            function ()
                return index, #self.name_block.children, #self.items, self.items[index]
            end
        )
    end
end

-- update the item at the specified index
function GUI:update_item_price_label(index)
    if self.value_block.children[index] then 
        self.value_block.children[index].text = self.items[index]:get_value_label()
        self.ui_base:updateLayout()
    else
        log:error("tried to update item labels but children[index] was nil!.\n\t\z
            index: %i\n\t\z
            #children: %i\n\t\z
            #items: %i\n\t\z
            #item: %s",
            function ()
                return index, #self.name_block.children, #self.items, self.items[index]
            end
        )
    end
end

function GUI:update_all_item_labels(dont_update_gui)
    for i, item in ipairs(self.items) do
        self.name_block.children[i].text = item:get_name_label()
    end
    if dont_update_gui then return end
    self.ui_base:updateLayout()
end
--- update all the items in the GUI
function GUI:update_all_items()
    for i, item in ipairs(self.items) do
        self.name_block.children[i].text = item:get_name_label()
        self.value_block.children[i].text = item:get_value_label()
        self.weight_block.children[i].text = item:get_weight_label()
    end
    self.ui_base:updateLayout()

end



--- registers the UIIDs
function GUI.register_UIIDS_and_COLORS()
    UIIDs.base = tes3ui.registerID "MQL:Menu"
    
    
    UIIDs.name_label = tes3ui.registerID "MQL:NameLabel"
    UIIDs.gold_label =  tes3ui.registerID "MQL:GoldLabel"
    UIIDs.weight_label =  tes3ui.registerID "MQL:WeightLabel"
    
    UIIDs.item_label = tes3ui.registerID "MQL:ItemLabel"

    COLORS.ok = tes3ui.getPalette(tes3.palette.normalColor)
    COLORS.ok_selected = tes3ui.getPalette(tes3.palette.activeColor)
    COLORS.unavailable = tes3ui.getPalette(tes3.palette.journalFinishedQuestOverColor)
    COLORS.unavailable_selected = tes3ui.getPalette(tes3.palette.activeOverColor)
end

-- =============================================================================
-- METHODS THAT UPDATE THE GUI
-- =============================================================================

--- update the name label on this GUI component
---@param new_name string the new name
function GUI:set_name_label(new_name, override_cfg)
    if not override_cfg and config.UI.show_name == false or new_name == nil then return end

    if #new_name >= MAX_NAME_LEN then
        new_name = string.format("%s...", new_name:sub(1,MAX_NAME_LEN-3))
    end
    self.labels_block:findChild(UIIDs.name_label).text = new_name
end


--- update the text in the status label of the GUI
---@param text string the new text to show in the status label
function GUI:set_status_label(text)
    -- local should_update = false
    if not text then
        -- should_update = self.status_divider.visible == true
        self.status_divider.visible = false
        self.status_label.visible = false
        
    elseif config.UI.enable_status_bar then
        -- should_update = self.status_divider.visible == false
        self.status_label.text = tostring(text)
        self.status_divider.visible = true
        self.status_label.visible = true
    end
    -- if should_update then
        -- self.ui_base:updateLayout()
    -- end
end









-- =============================================================================
-- HIDE OR DESTROY THE GUI
-- =============================================================================

-- destroy the inventory window and replace it with the passed string 
---@param s string the string to print in the main block
function GUI:block_and_show_msg(s)
    self.blocked = true
    self.ui_base.visible = true

    self.labels_block:findChild(UIIDs.gold_label).visible = false
    self.labels_block:findChild(UIIDs.weight_label).visible = false
    self.labels_block:findChild(UIIDs.name_label).width = nil
    self.labels_block:findChild(UIIDs.name_label).maxWidth = nil
    self.labels_block:updateLayout()

    self.content_block:destroyChildren()
    self.content_block:createLabel({text = s}).absolutePosAlignX = 0.5
    self.first_dot_block.visible = false
    self.last_dot_block.visible = false
    self.ui_base:updateLayout()
end




-- hide the UI
function GUI:hide() self.ui_base.visible = false end

-- show the UI
function GUI:show() self.ui_base.visible = true end

-- destroy this GUI and all its related data
function GUI:destroy()
    if self.ui_base == nil then return end
    log:trace("destroying menu :(")

    self.ui_base:destroy()
    self.ui_base = nil
end

function GUI.find_menu()
    return tes3ui.findMenu(UIIDs.base)
end

return GUI