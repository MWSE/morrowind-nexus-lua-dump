
local Class = require("herbert100.Class")
local log = require("herbert100.Logger")(require("herbert100.more quick loot.defns").mod_name) ---@type Herbert_Logger
local config = require("herbert100.more quick loot.config")

-- =============================================================================
-- GUI
-- =============================================================================


---@alias MQL.GUI.key_names
---| "take"     take an item 
---| "take_all" take all items 
---| "open"     open the container

---@type table<MQL.GUI.key_names, string> holds the name of the button mapping to each key
local key_btn_names = {
    take = "",
    take_all = "",
    open = "",
}

---@class MQL.GUI.key_btn_arg
---@field pos number between 0 and 1, determines position in the key control block
---@field label string the text to give this button

---@alias MQL.GUI.key_btn_info table<MQL.GUI.key_names,  MQL.GUI.key_btn_arg>



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
---@class MQL.GUI : Class
---@field index integer the index of the selected item
---@field content_block tes3uiElement the block of the UI that will hold the listed items
---@field controls_block tes3uiElement the block on the bottom that will hold the controls
---@field ui_base tes3uiElement the panel that all UI elements live inside of
---@field first_dot_block tes3uiElement the "..." label that may appear at the beginning of a list
---@field last_dot_block tes3uiElement the "..." label that may appear at the end of a list
---@field item_blocks tes3uiElement[] ui element corresponding to an inventory object
---@field blocked boolean `true` if the UI is not showing the items of a container and instead showing some other message. (e.g., it's showing "Empty")
local GUI = Class{name="Quick Loot GUI", new_obj_func="no_obj_data_table",
    --- make a new GUI
    ---@param self MQL.GUI the GUI that's being made
    ---@param name string the name of the container
    ---@param key_btn_info MQL.GUI.key_btn_info? table indexed by key_name, where the value is a list containing the label for that key and the relative position in the menu
    init = function (self, name, key_btn_info)
        if log > 1 then log("GUI: about to create base_UI.") end
        -- self.items = items
        do -- remake the UI
            --
            self.ui_base = tes3ui.createMenu({id = UIIDs.base, fixedFrame = true})
            -- self.ui_base = tes3ui.createMenu({id = UIIDs.base, })
            self.ui_base.absolutePosAlignX = config.UI.menu_x_pos
            self.ui_base.absolutePosAlignY = config.UI.menu_y_pos
            self.ui_base.childAlignX = 0

            -- name the container if we're given a name 
            if name and config.UI.show_name then
                self.ui_base:createLabel({id=UIIDs.name_label, text=name}).absolutePosAlignX = 0.5
                self.ui_base:createDivider()
            end
            

            
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

            if config.UI.show_controls then 
                self.ui_base:createDivider()
                self.controls_block = self.ui_base:createBlock()
                self.controls_block.alpha = 0.75
                self.controls_block.flowDirection = "left_to_right"
                self.controls_block.widthProportional = 1.0
                self.controls_block.autoHeight = true
                self.controls_block.paddingAllSides = 3
                self.controls_block.minWidth = 300 -- new
                -- controls_block.childAlignX = 0


                for key_name, info in pairs(key_btn_info) do
                    local label = string.format("%s) %s", key_btn_names[key_name], info.label)
                    self.controls_block:createLabel({id=key_name, text = label}).absolutePosAlignX = info.pos
                end
            end


        end
        -- UI starts as blocked because the items aren't made.
        self.blocked = true
        self.ui_base:updateLayout()
    end
}



--- registers the UIIDs
function GUI.register_UIIDS()
    UIIDs.name_label = tes3ui.registerID("MQL:NameLabel")
    UIIDs.item_label = tes3ui.registerID( "MQL:ItemLabel")
    UIIDs.base = tes3ui.registerID("MQL:Menu")

end

function GUI.update_control_key_names()
    if config.keys.use_interact_btn then
        key_btn_names.take = string.upper(table.find(tes3.scanCode, tes3.getInputBinding(tes3.keybind.activate).code))
        key_btn_names.open = string.upper(table.find(tes3.scanCode, config.keys.custom.keyCode))
    else
        key_btn_names.take = string.upper(table.find(tes3.scanCode, config.keys.custom.keyCode))
        key_btn_names.open = string.upper(table.find(tes3.scanCode, tes3.getInputBinding(tes3.keybind.activate).code))
    end
    key_btn_names.take_all = string.upper(table.find(tes3.scanCode, config.keys.take_all.keyCode))
end

function GUI:destroy()
    if self.ui_base == nil then return end
    if log > 2 then log:trace("GUI: destroying menu :(") end

    self.ui_base:destroy()
    self.ui_base = nil
    self = nil
end
--- update the name label on this GUI component
---@param new_name string the new name
function GUI:update_name_label(new_name)
    if config.UI.show_name == false or new_name == nil then return end

    self.ui_base:findChild(UIIDs.name_label).text = new_name
    --[[local name_label = self.ui_base:findChild(UIIDs.name_label)
    if name_label ~= nil then
        if log > 1 then log("GUI: updating name label to " .. new_name) end
        name_label.text = new_name
        log "GUI: name label not found!"
    end]]
end

--- update the label of one or more items.
---@param new_labels table<integer, string> a table, where the key is the index of the item to update, and the value is the new label
function GUI:update_item_labels(new_labels)
    local block
    for index, new_label in pairs(new_labels) do 
        block = self.item_blocks[index]
        if block ~= nil and new_label ~= nil then
            block:findChild(UIIDs.item_label).text = new_label
        else
            log:error(string.format("GUI: tried to update an item block that didn't exist!.\n\t\z
                index:        %i\n\t\z
                #item_blocks: %i\n\t\z
                label:        %s",
                index, #self.item_blocks, new_label
            ))
        end
    end
    self.content_block:updateLayout()
end

-- mark the container as empty
function GUI:set_empty() self:block_and_show_msg("Empty") end

-- destroy the inventory window and replace it with the passed string 
---@param s string the string to print in the main block
function GUI:block_and_show_msg(s)
    self.blocked = true
    self.ui_base.visible = true
    self.content_block:destroyChildren()
    self.content_block:createLabel({text = s}).absolutePosAlignX = 0.5
    self.ui_base:updateLayout()
end
--- update the names of the keys in the controls block
---@param t table<MQL.GUI.key_names, string> the keys to relabel, and what to relabel them
function GUI:update_control_labels(t)
    if config.UI.show_controls == nil then return end

    for key_name, new_label in pairs(t) do
        self.controls_block:findChild(key_name).text = string.format("%s) %s", key_btn_names[key_name], new_label)
    end
    self.controls_block:updateLayout()
end


-- hide the UI
function GUI:hide() self.ui_base.visible = false end

-- show the UI
function GUI:show() self.ui_base.visible = true end




--- update the items in the container GUI
---@param items MQL.Item[]? the items to be shown in the GUI
function GUI:make_container_items(items)
    self.content_block:destroyChildren()
    self.blocked = false

    self.item_blocks = {}

    if log > 1 then log "GUI: about to make children" end
    -- make the item list
    for i, item in pairs(items) do

        -- Our container block for self item.
        local block = self.content_block:createBlock(); block.flowDirection = "left_to_right"
        block.autoWidth = true; block.autoHeight = true; block.paddingAllSides = 3

        self.item_blocks[i] = block

        -- Item icon.
        -- local icon = block:createImage{path = (item.icon_path or ("icons\\" .. item.object.icon))}
        local icon = block:createImage{path = item.icon_path}
        icon.borderRight = 5
        local label = block:createLabel{id=UIIDs.item_label, text = item.label}
        label.absolutePosAlignY = 0.5
    end

    -- self.content_block:updateLayout()
    -- self.UI_base.minWidth = content_block.width
    self:set_index(self.index or 1)
    
    self.ui_base:updateLayout()

    
    -- if not self.index then 
    --     self:set_index(1)
    -- else
    --     self:set_index(self.index)
    -- end
end

--[[ updates which items in the menu are visible, based on the current index
this is currently only called when either of these two things happen:
1) the `index` is set via the `set_index` method
2) an item is removed via the `delete_selected_item` method
]]
function GUI:_update_visible_items()
    -- only do stuff if the `index` isn't nil
    if self.index == nil then return end

    local inv_size, diam, remainder, radius, first_index, last_index
    inv_size = #self.item_blocks
--[[general strategy:
- let's say we want to display `n` items. this means that (in the ideal scenario):
- `(n-1)/2` items should be shown above the current index
- `1` item should be shown at the current index
- `(n-1)/2 items should be shown below the current index.
**HOWEVER**, there are a few complications:
1) we can't display `1/2` of an element, so things get a bit more complicated when `max_disp_items` is odd.
    - my solution is to show the extra item at the bottom, since that seems preferable to showing them at the top.

2) the "`(n-1)/2` before and `(n-1)/2` after" approach only works in the ideal scenario: when the container is sufficiently large and we're in the middle of it.
    - in practice, there often won't be `(n-1)/2` items before the current index, or perhaps there won't be `(n-1)/2` items after the current index.
    - we should address this by keeping track of the items that can actually show up before a given index (and similarly for after the index).
    - then, we should add these unshown terms to the end (or beginning) of the list of shown items.
    - this approach would do things like:
        - if we're at index `1`, show `n-1` items after the current index
        - if we're at index `2`, show `1` item before the current index and `n-2` items after the current index.
        - etc
]]
    do -- set `first_index` and `last_index`
        diam = config.UI.max_disp_items - 1 -- total number of items to show before/after the current index
        remainder = diam % 2                -- whether this number is even or odd
        radius = (diam  - remainder)/2      -- divide and `floor`


        first_index = self.index - radius
        last_index = self.index + radius + remainder -- add back the remainder so this gets 1 extra term if `max_disp_items` is odd
        -- if `first_index` is too small
        if first_index < 1 then
            -- add the extra terms to `last_index`, then set `first_index` to 1
            -- take the min to make sure its `<= inv_size`
            last_index = math.min(inv_size, last_index + (1 - first_index))
            first_index = 1
        -- otherwise, see if `last_index` is too big
        elseif last_index > inv_size then
            -- the number of extra indices is `last_index - inv_size`. these should be subtracted so that `first_index` is smaller.
            -- take the max to make sure its `>= 1`
            first_index = math.max(1, first_index - (last_index - inv_size))
            last_index = inv_size
        -- else: we know `first_index >= 1` and `last_index <= inv_size`, so we dont have to do anything
        end
    end

    do -- update the visibility of the `...` at the beginning and end of the list, depending on whether we're showing the 
        -- first and last items
        if first_index > 1 then 
            self.first_dot_block.visible = true
        else                    
            self.first_dot_block.visible = false 
        end

        if last_index < inv_size then   
            self.last_dot_block.visible = true
        else                            
            self.last_dot_block.visible = false 
        end
    end

    -- show or hide the items, depending on which indices are valid
    for i, block in pairs(self.item_blocks) do
        block.visible = first_index <= i and i <= last_index
    end
end

function GUI:set_index(index)
    local inv_size = #self.item_blocks
    if inv_size == 0 then return end

    index = math.clamp(index,1, inv_size)
    if index == self.index then
        self.item_blocks[index]:findChild(UIIDs.item_label).color = tes3ui.getPalette("active_color")
        return
    -- if `index ~= self.index` and `self.index` is still valid, deselect it
    elseif self.index ~= nil and self.index <= inv_size then
        -- select the old option
        self.item_blocks[self.index]:findChild(UIIDs.item_label).color = tes3ui.getPalette("normal_color")
    end
    self.index = index
    self.item_blocks[index]:findChild(UIIDs.item_label).color = tes3ui.getPalette("active_color")


    self:_update_visible_items()

    self.content_block:updateLayout()
end

function GUI:increment_index()
    if self.index ~= nil then
        self:set_index(self.index + 1)
    end
end

function GUI:decrement_index()
    if self.index ~= nil then
        self:set_index(self.index - 1)
    end
end

function GUI:delete_selected_item()
    if log > 1 then log("GUI: about to delete index: " .. self.index, ". list size: " .. #self.item_blocks) end

    -- remove the old block from the list of managed items and mark it as invisible. 
    -- it will be properly destroyed once the GUI is destroyed, since it's still going to be a child of `self.ui_base`
    local old_block = table.remove(self.item_blocks, self.index)
    old_block.visible = false
    -- update the index
    self.index = math.min(self.index, #self.item_blocks)
    
    if log > 1 then
        log(("GUI: deleted object at index. now current index is: %i\n\t\z
            list size is now: %i"):format(self.index, #self.item_blocks)
        )
    end
    -- if there are actually items left
    if self.index ~= 0 then
        self.item_blocks[self.index]:findChild(UIIDs.item_label).color = tes3ui.getPalette("active_color")
        self:_update_visible_items()
    end
    
    
end


return GUI