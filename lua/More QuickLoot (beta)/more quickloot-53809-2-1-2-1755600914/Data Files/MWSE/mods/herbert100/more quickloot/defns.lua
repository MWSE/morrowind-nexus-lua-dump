--- Abstract interface for the items shown in the quickloot GUI.
---@class herbert.MQL.Item
---@field count integer how many of the object are there (in total). default = 1
---@field value integer the value of this item stack, i.e., `object.value`


--- A physical item. This is the type of item that's used by a majority of the quickloot menus.
---@class herbert.MQL.Item.Physical : herbert.MQL.Item
---@field object tes3alchemy|tes3apparatus|tes3armor|tes3book|tes3clothing|tes3ingredient|tes3item|tes3light|tes3lockpick|tes3misc|tes3probe|tes3repairTool|tes3weapon
---@field box_handle mwseSafeObjectHandle a reference to the box that this item lives inside of
---@field data tes3itemData|nil
---@field equipped true|nil Only used by some containers. Will be `true` if the item is equipped,
--- AND we are not allowed to take equipped items. Otherwise, this is `nil`.
--- Again, this may be `nil` even if the item is in fact equipped.
--- and `nil` otherwise.

--- Items used by the `Training` menu.
---@class herbert.MQL.Item.Training : herbert.MQL.Item
---@field skill tes3skill
---@field max_lvl integer the highest value this skill can be trained to
---@field value integer the cost of training this skill



-- notice that we do not return anything here



-- this stores the various different definitions used by the mod
---@class herbert.MQL.defns
local defns = {



    ---@class herbert.MQL.defns.misc
    misc = {

        -- the version will get updated when `config/default.lua` is run
        -- not ideal, but this is now depcreated so whatever

        ---@deprecated use `config.version` instead
        version = 1.4, -- the current version of the mod.

        -- the installation status of graphic herbalism. this is used for compatiblity purposes
        gh = {
            never = 0,      -- graphic herbalism was never installed
            previously = 1, -- graphic herbalism was previously installed, but is not currently installed
            installed = 2,  -- graphic herbalism is installed
        },
        ac = {
            open = {
                never = 0,      -- never open animated containers
                item_taken = 1, -- open animated containers when an item was taken
                on_sight = 2,   -- open animated containers whenever menu opens
            },

            close = {
                never = 0,      -- never close animated containers
                use_ac_cfg = 1, -- use animated containers config
                always = 2,     -- always close animated containers
            },
        },
    },



    -- what happens to empty plants
    change_plants = {
        none = 0,    -- don't change empty plant containers
        gh = 1,      -- use graphic herbalism
        destroy = 2, -- destroy plants
    },

    -- how should we try to discern which organic containers aren't plants?
    not_plants_src = {
        everything_plant = 0, --treat all organic containers as plants (no source)
        plant_list = 1,       -- use `blacklist.organic` list to source a list of containers that are not plants
        gh = 2,               --use graphic herbalism and `blacklist.organic` to source containers that are not plants
    },



    -- should we show scripted containers? if so, how?
    show_scripted = {
        dont = 0,      -- don't show scripted containers
        prefix = 1,    -- show scripted containers, but put a prefix before their names
        no_prefix = 2, -- show scripted containers, and don't say anything about it
    },



    show_tooltips = {
        dont = 1,
        item = 2,
        container = 3
    },

    take_nearby = {
        never_steal = 1,  -- dont steal anything
        use_context = 2,  -- decide based on whether youre pressing the button on a stolen item
        always_steal = 3, -- steal everything
    },

    sort_items = {
        dont = 0,               -- dont sort items
        value_weight_ratio = 1, -- sort byvalue/weight ratio
        value = 2,              -- sort byvalue
        weight = 3,             -- sort by weight
    },



    -- how should we decide to search for nearby objects?
    sn_cf = {
        no_other_containers = 0, -- no other containers
        same_base_obj = 1,       -- both containers have the same base object
        organic = 2,             -- both containers are organic
        -- same_owner = 3,     -- `ref.obj` and `container_ref.obj` have same owner
    },

    -- when should item chances be shown?
    ui_show_chances = {
        never = 0,  -- never show chances
        lvl = 1,    -- show chances if the relevant skill is above a certain level
        always = 2, -- always show chances
    }

}
-- what should we do when multiple items are in a stack?
---@enum herbert.MQL.defns.mi
defns.mi = {
    one = 0,   -- always take one
    stack = 1, -- always take whole stack
    ratio = 2, -- only take items if the price/weight ratio is above a specified number
}



---@alias herbert.MQL.defns.sn_cf
---|`defns.sn_cf.no_other_containers`
---|`defns.sn_cf.same_base_obj`
---|`defns.sn_cf.organic`


---@alias herbert.MQL.defns.misc.ac.open
---|`defns.misc.ac.open.never`
---|`defns.misc.ac.open.item_taken`
---|`defns.misc.ac.open.on_sight`

---@alias herbert.MQL.defns.misc.ac.close
---|`defns.misc.ac.close.never`
---|`defns.misc.ac.close.use_ac_cfg`
---|`defns.misc.ac.close.always`

-- -|`defns.sn_cf.same_owner`


---@alias herbert.MQL.defns.ui_show_chances
---|`defns.ui_show_chances.never`      -- never show chances
---|`defns.ui_show_chances.lvl`        -- show chances if the relevant skill is above a certain level
---|`defns.ui_show_chances.always`     -- always show chances


---@alias herbert.MQL.defns.sort_items
---|`defns.sort_items.dont`                 -- dont sort items
---|`defns.sort_items.value_weight_ratio`   -- sort by value/weight ratio
---|`defns.sort_items.value`                -- sort by value
---|`defns.sort_items.weight`               -- sort by weight


---@alias herbert.MQL.defns.take_nearby
---|`defns.take_nearby.never_steal`    dont steal anything
---|`defns.take_nearby.use_context`    decide based on whether youre pressing the button on a stolen item
---|`defns.take_nearby.always_steal`   steal everything


---@alias herbert.MQL.defns.show_scripted
---| `defns.show_scripted.dont` dont show any scripted containers
---| `defns.show_scripted.prefix` show scripted containers, but put a prefix before their names
---| `defns.show_scripted.no_prefix` show scripted containers, and don't say anything about it


---@alias herbert.MQL.defns.show_tooltips
---| `defns.show_tooltips.dont` dont show any tooltips
---| `defns.show_tooltips.item` show tooltips for the selected item
---| `defns.show_tooltips.container` show tooltips for the container



-- what happens to empty plants
---@alias herbert.MQL.defns.change_plants
---| `defns.change_plants.none` no changes
---| `defns.change_plants.gh` use graphic herbalism to change plants
---| `defns.change_plants.destroy` destroy plants after looting


-- how should we try to discern which organic containers aren't plants?
---@alias herbert.MQL.defns.not_plants_src
---| `defns.not_plants_src.everything_plant`  treat all organic containers as plants (no source)
---| `defns.not_plants_src.plant_list`        use `blacklist.organic` list to source a list of containers that are not plants
---| `defns.not_plants_src.gh`                use graphic herbalism and `blacklist.organic` to source containers that are not plants




-- keeps track of the current install status of graphic herbalism
---@alias herbert.MQL.defns.misc.gh
---| `defns.misc.gh.never`      -- graphic herbalism was never installed
---| `defns.misc.gh.previously` -- graphic herbalism was previously installed, but is not currently installed
---| `defns.misc.gh.installed`  -- graphic herbalism is installed


---@enum herbert.MQL.defns.equipped_type
defns.equipped_types = {
    weapons = 1,
    armor = 2,
    clothing = 3,
    jewelry = 4,
    accessories = 5, -- belts, gloves, etc
}

---@enum herbert.MQL.defns.cant_take_reason
defns.cant_take = {
    unavailable = 1,
    wont_fit = 2,
    didnt_exist = 3,
    locked = 4
}

---@enum herbert.MQL.ActionType
defns.ActionType = {
    Take = 1,    -- take one item
    TakeAll = 2, -- take all items
    Open = 3,    -- open the container
    Undo = 4     -- undo taking something
}



---@class herbert.MQL.Action
---@field ty herbert.MQL.ActionType The type of action
---@field modifier_held boolean Is the modifier key held?
---@field equip_modifier_held boolean Is the equip modifier key held?


---@enum herbert.MQL.defns.can_take_err_code? err_code Only returned if `val == 0`. This provides information about why an item should be greyed out.
defns.can_take_err_codes = {
    NO_ITEM_SELECTED = 0, -- No item was selected.

    NO_DESIRED_ITEMS = 1, -- Nothing worth taking.
    -- physical containers

    EQUIPPED = 2,  -- The item is equipped AND we aren't allowed to take this kind of equipped item.
    LOCKED = 3,    -- Container is locked.
    TRAPPED = 4,   -- Container is trapped.
    NOT_SNEAKING = 5, -- We can't take this item because we aren't sneaking, and it would be a crime to take it.
    DOESNT_FIT = 6, -- Not enough storage capacity.
    -- pickpocketing / organic

    CHANCE_SUCKS = 7, -- Our chance to take it is below the minimum chance, as specified in the MCM.

    -- services

    NOT_ENOUGH_GOLD = 8, -- We don't have enough gold to buy this item, or the merchant does not have enough gold to buy it.

    -- barter

    STOLEN = 9,   -- Item is stolen and the merchant is not a smuggler.
    CONTRABAND = 10, -- Item is contraband and the merchant is not a smuggler.

    -- training

    SKILL_TOO_HIGH = 11, -- Our skill is too high to be trained any more.
    ATTR_TOO_LOW = 12, -- The attribute related to this skill is not high enough.
}


---@class herbert.MQL.events.Container.item_selected
---@field index integer index of the item in the container
---@field item herbert.MQL.Item item being selected


---@class herbert.MQL.events.pick_container
---@field ref tes3reference reference to make a container for
---@field obj tes3object|tes3container|tes3npc|tes3creature
---@field container_cls herbert.MQL.Container? container class to pick
---@field is_organic boolean is this container organic?
---@field scripted boolean is this a scripted container?
---@field base_id string lowercase base_id of the object, to check against blacklists
---@field claim boolean
---@field block boolean

---@class herbert.MQL.events.container_picked
---@field ref tes3reference reference to make a container for
---@field obj tes3object|tes3container|tes3npc|tes3creature
---@field container_cls herbert.MQL.Container? container class to pick
---@field is_organic boolean is this container organic?
---@field scripted boolean is this a scripted container?
---@field base_id string lowercase base_id of the object, to check against blacklists


--- can be filtered by container class
---@class herbert.MQL.events.Container.reactivate
---@field container herbert.MQL.Container
---@field block boolean
---@field claim boolean



---@alias herbert.MQL.events.Container.items_changed.severity
---|1 Only the selected item needs to be updated.
---|2 All items need to be updated.

--- This event triggers when a containers items have been updated.
---@class herbert.MQL.events.Container.items_changed
---@field container herbert.MQL.Container The container whose items have changed.
---@field severity herbert.MQL.events.Container.items_changed.severity



-- Triggers when the state of an item
-- This event can be filtered by the class name.
---@class herbert.MQL.events.Container.title_updated
---@field container herbert.MQL.Container
---@field block boolean
---@field claim boolean



-- This event fires whenever a container successfully returns an item
---@class herbert.MQL.events.Container.item_returned
---@field container herbert.MQL.Container
---@field item herbert.MQL.Item
---@field num_returned integer The number of items taken.
---@field claim boolean

-- -@field index integer index of the item in the container



-- This event can be filtered by the class name
---@class herbert.MQL.events.gui_destroyed
---@field container herbert.MQL.Container
---@field gui herbert.MQL.GUI

-- This event can be filtered by the class name
---@class herbert.MQL.events.item_selected
---@field container herbert.MQL.Container
---@field item herbert.MQL.Item
---@field gui herbert.MQL.GUI


-- This event can be filtered by the class name
---@class herbert.MQL.events.Container.invalidated
---@field container herbert.MQL.Container


--- This gets triggered when a container has no items that can be displayed.
--- i.e., when `can_take_item(item)` returns `-1` for all items in a container.
-- This event can be filtered by the class name
---@class herbert.MQL.events.Container.empty
---@field container herbert.MQL.Container

-- This event can be filtered by the class name
---@class herbert.MQL.events.modifier_state_updated
---@field pressed boolean


---@enum herbert.MQL.event
defns.EVENT_IDS = {
    container_picked = "herbert:MQL.container_picked",
    pick_container = "herbert:MQL.pick_container",
    controls_updated = "herbert:MQL.controls_updated",
    title_updated = "herbert:MQL.title_updated",
    reactivate_container = "herbert:MQL.reactivate_container",
    container_status_text_updated = "herbert:MQL.container_status_text_updated",
    container_item_returned = "herbert:MQL.container_item_returned",
    container_invalidated = "herbert:MQL.container_invalidated",
    container_empty = "herbert:MQL.container_empty",
    gui_destroyed = "herbert:MQL.gui_destroyed",
    item_selected = "herbert:MQL.item_selected",
    equip_modifier_state_updated = "herbert:MQL.equip_modifier_state_updated",
    modifier_state_updated = "herbert:MQL.modifier_state_updated",
    container_items_changed = "herbert:MQL.container_items_changed",
    config_updated = "herbert:MQL.config_updated",
}


return defns
