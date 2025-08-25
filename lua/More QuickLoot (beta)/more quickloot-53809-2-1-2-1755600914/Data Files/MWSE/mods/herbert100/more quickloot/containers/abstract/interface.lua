
---@generic Item_Type
---@class herbert.MQL.Container.history.entry<Item_Type> : {item: `Item_Type`, num_removed: integer}

---@generic T
---@alias herbert.MQL.Container.history herbert.MQL.Container.history.entry<T>[]


--- Interface for something that stores items and can interact with the quickloot GUI.
--- This class specifies the API contract for the quickloot GUI and should not be interacted with directly.
---@class herbert.MQL.Container
---@field handle mwseSafeObjectHandle A safe handle for the reference currently being targeted by this container.
--- Note that physical containers may have several relevant handles. 
--- In the case of having multiple handles, this one will align most closely with the reference currently being looked at by the player.
---@field items herbert.MQL.Item[]              aAlist of items in the container.
---@field history herbert.MQL.Container.history<herbert.MQL.Item> stack of items that are being bought
---@field disabled boolean is the container disabled?
local Container = { cls_name = "Container" }


---@param ref tes3reference
---@return herbert.MQL.Container
function Container.new(ref)
	error("Not implemented!")
end


--- Should this container be re-enabled for a given reference?
---@param ref tes3reference The reference to potentially enable the container for.
---@return -1|0|1 result If -1, don't enable. if 0, enable but hide contents. if 1, enable and show contents
---@return string? contents hidden reason. The reason why the contents should be hidden. This should only be erturned if the first return result is `0`.
function Container:can_enable(ref)
	error("Not implemented!")
end

--- Enable the container for a particular reference.
---@param ref tes3reference
function Container:enable(ref)
	error("Not implemented!")
end

--- Disables the container
function Container:disable()
	error("Not implemented!")
end


--- Destroy the container, and end any associated timers/events, etc.
function Container:destruct() end


--- get the number of items that should be taken, based on current config settings.
--- should only be called if `item.count >= 1`
---@param item herbert.MQL.Item the item to take
---@param bulk boolean are we doing a batch take?
---@param modifier_pressed boolean is the modifier key pressed?
---@return integer num_to_take
---@return herbert.MQL.defns.can_take_err_code? err_code Only returned if `val == 0`. This provides information about why an item should be greyed out. any reason we could only take 0?
function Container:get_num_to_take(item, bulk, modifier_pressed)
	error("Not implemented!")
end

--- This is responsible for controlling all behavior that happens when a button is pressed
---@param selected_item herbert.MQL.Item? Item to do the action on
---@param action herbert.MQL.Action The action to perform
---@return boolean successful
function Container:do_action(selected_item, action)
	error("Not implemented!")
end

--- Gets the action labels, depending on the context
---@param item herbert.MQL.Item? The item to generate action names for.
---@param modifier_pressed boolean Is the modifier key pressed?
---@return string[]
function Container:get_action_names(item, modifier_pressed, equip_key_pressed)
	error("Not implemented!")
end


--- Name of the container. appears at the top of the GUI.
---@return string label
function Container:get_title()
	error("Not implemented!")
end

--- Information to show below the top of the GUI. 
--- This is used, for example to display the buyer/seller gold in the Barter menu.
---@return string[]? label
function Container:get_subtitles()
	error("Not implemented!")
end

--- Returns the text to show in the status bar, if any.
---@return string? The text to display
---@return number[]|nil color The color to display the text in. If `nil`, the default color will be used.
function Container:get_status_bar_text()
	error("Not implemented!")
end


--- Makes all the items.
function Container:make_items()
	error("Not implemented!")
end

-- =============================================================================
-- ITEM METHODS
-- =============================================================================


---Checks if the item at the given index can be taken.
---Returns -1 if the item should be hidden, 0 if the item should be greyed out, and 1 if the item can be taken.
---This should always return `-1` if `item.count <= 0`.
---@param item herbert.MQL.Item
---@return -1|0|1 val
---@return herbert.MQL.defns.can_take_err_code? err_code Only returned if `val == 0`. This provides information about why an item should be greyed out. only returned if `val < 1`
function Container:can_take_item(item)
	error("Not implemented!")
end

--- Takes an item.
--- This method assumes that the item can be taken. and that `num_to_take` is a positive integer.
---@param item herbert.MQL.Item the item to take
---@param num_to_take integer The number of items being taken. This must be a positive integer.
---@param take_all boolean are we taking a bunch of things?
---@param equip_key_pressed boolean are we taking a bunch of things?
---@return integer num_taken the number of things that were actually taken.
function Container:take_item(item, num_to_take, take_all, equip_key_pressed)
	error("Not implemented!")
end



-- -----------------------------------------------------------------------------
-- UI ITEM METHODS
-- -----------------------------------------------------------------------------

--- Gets the name of the item, taking into account the number of items that may be taken.
---@param item herbert.MQL.Item
---@param num integer How many of these items is the user thinking about taking?
---@return string
function Container:format_item_name(item, num)
	error("Not implemented!")
end


--- Formats the item weight.
---@param item herbert.MQL.Item
---@param num integer
---@return string
function Container:format_item_value(item, num)
	error("Not implemented!")
end


---@param item herbert.MQL.Item
---@return string
function Container:format_item_weight(item, num)
	error("Not implemented!")
end

--- Checks if a tooltip can be made for this item.
---@param item herbert.MQL.Item 
---@return boolean
function Container:can_make_item_tooltip(item)
	error("Not implemented!")
end

--- Makes a tooltip for the given item. This should only be called if `can_make_item_tooltip` returns `true`.
---@param item herbert.MQL.Item 
---@return tes3uiElement? tooltip
function Container:make_item_tooltip(item)
	error("Not implemented!")
end


--- Gets the background color of an item, if appropriate.
--- This is used, for example, to display borders around enchanted items.
---@return number[]?
---@param item herbert.MQL.Item 
---@return number[]?
function Container:get_item_bg_color(item)
	error("Not implemented!")
end

--- Gets the icon path of an item.
---@param item herbert.MQL.Item The index of item herbert.MQL.Item
---@return string
function Container:get_item_icon_path(item)
	error("Not implemented!")
end

return Container