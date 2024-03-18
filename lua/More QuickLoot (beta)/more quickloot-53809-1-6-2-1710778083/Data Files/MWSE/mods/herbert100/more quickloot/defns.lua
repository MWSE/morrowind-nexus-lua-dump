-- this stores the various different definitions used by the mod
---@class MQL.defns
local defns = {

    events = {
        Manager = {
            item_selected = "MQL:Manager:item_selected",
        },
    },
    
    ---@class MQL.defns.misc
    misc = {

        -- the version will get updated when `config/default.lua` is run
        -- not ideal, but this is now depcreated so whatever

        ---@deprecated use `config.version` instead
        version = 1.4, -- the current version of the mod.

        json_options = { indent=true,
            keyorder = { "version",
                "take_nearby_dist", "show_scripted", "keys", 
                -- pages/big categories
                "UI", "reg", "dead", "inanimate", "organic", "pickpocket", "services", "training", "barter", "blacklist", "advanced", "compat",
                -- important settings/small categories
                "enable", "mi", "xp", "mode", "mode_m", "default_service", 
            },
        },
        -- the installation status of graphic herbalism. this is used for compatiblity purposes
        gh = {
            never = 0,      -- graphic herbalism was never installed
            previously = 1, -- graphic herbalism was previously installed, but is not currently installed
            installed = 2,  -- graphic herbalism is installed
        },
        ac = {
            open = {
                never = 0, -- never open animated containers
                item_taken = 1, -- open animated containers when an item was taken
                on_sight = 2,   -- open animated containers whenever menu opens
            },
        
            close = {
                never = 0, -- never close animated containers
                use_ac_cfg = 1, -- use animated containers config
                always = 2,   -- always close animated containers
            },
        },
        
    
        -- specifies the quotient ring of the integers that we should use when calculating the `current_service`
        -- i.e., the number to `modulo` by.
        services_quotient = 2,
    },
    


    -- what happens to empty plants
    change_plants = {
        none = 0,       -- don't change empty plant containers
        gh = 1,         -- use graphic herbalism
        destroy = 2,    -- destroy plants
    },

    -- how should we try to discern which organic containers aren't plants?
    not_plants_src = {
        everything_plant = 0,   --treat all organic containers as plants (no source)
        plant_list = 1,         -- use `blacklist.organic` list to source a list of containers that are not plants
        gh = 2,                 --use graphic herbalism and `blacklist.organic` to source containers that are not plants
    },

    -- how should empty dead things be dealt with
    dispose = {
        none = 0,       -- no option for disposing of dead
        take_all = 1,   -- when a dead container becomes empty, replace "Take All" with "Dispose"
        on_sight = 2    -- as soon as a dead container becomes empty, dispose of it.
    },

    -- reasons why we cant loot something. used by all `Manager`s
    cant_loot = {
        no_target = 1,  -- the `target` is `nil`
        cant_see = 2,   -- cant see inside this container
        empty = 3,      -- container is empty
        disabled = 4,   -- manager is disabled
        other = 5,     -- some other reason (manager specific)
    },

    -- should we show scripted containers? if so, how?
    show_scripted = {
        dont = 0,       -- don't show scripted containers
        prefix = 1,     -- show scripted containers, but put a prefix before their names
        no_prefix = 2,  -- show scripted containers, and don't say anything about it
    },

    -- what should we do when multiple items are in a stack?
    mi = {
        one = 0,    -- always take one 
        stack = 1,  -- always take whole stack
        ratio = 2,  -- only take items if the price/weight ratio is above a specified number
        total_weight = 3,  -- take the whole stack, if it's under a certain weight
        ratio_and_total_weight = 4,  -- take the whole stack, if it's under a certain weight and ratio
        ratio_or_total_weight = 5,  -- take the whole stack, if it's under a certain weight or ratio
    },
    
    --what should we do when multiple items are in a stack, and we have a certain chance of taking each one
    mi_chance = {
        one = 0,            -- always take one 
        stack = 1,          -- always take whole stack
        total_chance = 2,   -- take the stack if the total chance is above a specified minimum
        regular = 3,        -- use settings for regular containers
        total_chance_and_regular = 4,        -- use `total_chance` AND settings for regular containers
    },

    
    
    services = {
        barter = 0,
        training = 1,
    },
    show_tooltips = {
        dont = 1,
        item = 2,
        container = 3
    },

    take_nearby = {
        never_steal = 1,    -- dont steal anything
        use_context = 2,    -- decide based on whether youre pressing the button on a stolen item
        always_steal = 3,   -- steal everything
    },

    sort_items = {
        dont = 0,                   -- dont sort items
        value_weight_ratio = 1,     -- sort byvalue/weight ratio
        value = 2,                  -- sort byvalue
        weight = 3,                 -- sort by weight
    },

    item_status = {
        deleted = 1,            -- item should be treated as if it does not exist (irreversible)
        empty = 2,              -- the item stack is empty, so the item should be treated as deleted, but this can be reversed.
        hidden = 3,             -- item should be treated as deleted, but only because it failed a "search nearby" filter
        unavailable = 4,        -- item cannot be interacted with (e.g. it should appear greyed out)
        unavailable_temp = 5,   -- item is unavailable, but only temporarily
        ok = 6,                 -- item should be treated normally
    },

    -- reason something is unavailable
    unavailable_reason = {
        equipped = 1,
        locked = 2,
        too_expensive = 3,
        stolen = 4,
        contraband = 5,
        skill_too_high = 6,
        attr_too_low = 7,
        too_big = 8,
        chance_sucks = 8,   -- the die was already cast
    },

    -- how should we decide to search for nearby objects?
    sn_cf = {
        no_other_containers = 0, -- no other containers
        same_base_obj = 1,  -- both containers have the same base object
        organic = 2,        -- both containers are organic
        -- same_owner = 3,     -- `ref.obj` and `container_ref.obj` have same owner
    },

    -- when should item chances be shown?
    ui_show_chances = {
        never = 0,      -- never show chances
        lvl = 1,        -- show chances if the relevant skill is above a certain level
        always = 2,     -- always show chances
    }

}

---@alias MQL.defns.sn_cf
---|`defns.sn_cf.no_other_containers`
---|`defns.sn_cf.same_base_obj`
---|`defns.sn_cf.organic`


---@alias MQL.defns.misc.ac.open
---|`defns.misc.ac.open.never`
---|`defns.misc.ac.open.item_taken`
---|`defns.misc.ac.open.on_sight`

---@alias MQL.defns.misc.ac.close
---|`defns.misc.ac.close.never`
---|`defns.misc.ac.close.use_ac_cfg`
---|`defns.misc.ac.close.always`

-- -|`defns.sn_cf.same_owner`


---@alias MQL.defns.ui_show_chances
---|`defns.ui_show_chances.never`      -- never show chances
---|`defns.ui_show_chances.lvl`        -- show chances if the relevant skill is above a certain level
---|`defns.ui_show_chances.always`     -- always show chances

---@alias MQL.defns.item_status
---|`defns.item_status.deleted`             -- item should be treated as if it does not exist
---|`defns.item_status.empty`               -- item should be treated as deleted because the item stack is empty
---|`defns.item_status.hidden`              -- item should be treated as deleted, but only because it failed a "search nearby" filter
---|`defns.item_status.unavailable`         -- item cannot be interacted with (e.g. it should appear greyed out)
---|`defns.item_status.unavailable_temp`    -- item is unavailable, but only temporarily
---|`defns.item_status.ok`                  -- item should be treated normally


---@alias MQL.defns.unavailable_reason
---| `defns.unavailable_reason.equipped`        -- item is equipped
---| `defns.unavailable_reason.locked`          -- container is locked
---| `defns.unavailable_reason.too_expensive`   -- item is too expensive 
---| `defns.unavailable_reason.stolen`          -- item is stolen
---| `defns.unavailable_reason.contraband`      -- item is contraband
---| `defns.unavailable_reason.skill_too_high`  -- your skill is too high
---| `defns.unavailable_reason.attr_too_low`    -- attribute is too low
---| `defns.unavailable_reason.too_big`         -- item wont fit in the container
---| `defns.unavailable_reason.chance_sucks`    -- the die was already cast

---@alias MQL.defns.sort_items
---|`defns.sort_items.dont`                 -- dont sort items
---|`defns.sort_items.value_weight_ratio`   -- sort by value/weight ratio
---|`defns.sort_items.value`                -- sort by value
---|`defns.sort_items.weight`               -- sort by weight


---@alias MQL.defns.take_nearby
---|`defns.take_nearby.never_steal`    dont steal anything
---|`defns.take_nearby.use_context`    decide based on whether youre pressing the button on a stolen item
---|`defns.take_nearby.always_steal`   steal everything

---@alias MQL.defns.services
---|`defns.services.barter` barter
---|`defns.services.training` training


---@alias MQL.defns.service_mode
---|`defns.service_mode.barter` buying
---|`defns.service_mode.training` selling

---@alias MQL.defns.mi
---| `defns.mi.one`                     take only one item
---| `defns.mi.stack`                   take the whole stack
---| `defns.mi.ratio`                   take all items if the price/weight ratio is above a specified number. otherwise take one
---| `defns.mi.total_weight`            take all items if the total weight is under this number. otherwise take one
---| `defns.mi.ratio_and_total_weight`  take all items if the ratio AND total weight are good. otherwise take one
---| `defns.mi.ratio_or_total_weight`   take all items if the ratio OR total weight are good. otherwise take one


---@alias MQL.defns.mi_chance
---| `defns.mi_chance.one`                          take only one item
---| `defns.mi_chance.stack`                        take the whole stack
---| `defns.mi_chance.total_chance`                 take all items if the total chance is above a certain minimum
---| `defns.mi_chance.regular`                      use settings for regular containers
---| `defns.mi_chance.total_chance_and_regular`     use total_chance and regular settings


---@alias MQL.defns.show_scripted
---| `defns.show_scripted.dont` dont show any scripted containers
---| `defns.show_scripted.prefix` show scripted containers, but put a prefix before their names
---| `defns.show_scripted.no_prefix` show scripted containers, and don't say anything about it


---@alias MQL.defns.show_tooltips
---| `defns.show_tooltips.dont` dont show any tooltips
---| `defns.show_tooltips.item` show tooltips for the selected item
---| `defns.show_tooltips.container` show tooltips for the container



-- what happens to empty plants
---@alias MQL.defns.change_plants
---| `defns.change_plants.none` no changes
---| `defns.change_plants.gh` use graphic herbalism to change plants
---| `defns.change_plants.destroy` destroy plants after looting


-- how should we try to discern which organic containers aren't plants?
---@alias MQL.defns.not_plants_src
---| `defns.not_plants_src.everything_plant`  treat all organic containers as plants (no source)
---| `defns.not_plants_src.plant_list`        use `blacklist.organic` list to source a list of containers that are not plants
---| `defns.not_plants_src.gh`                use graphic herbalism and `blacklist.organic` to source containers that are not plants


-- how should empty dead things be dealt with
---@alias MQL.defns.dispose_dead 
---| `defns.dispose.none`     no option for disposing of dead
---| `defns.dispose.take_all` when a dead container becomes empty, replace "Take All" with "Dispose"
---| `defns.dispose.auto`     as soon as a dead container becomes empty, dispose of it.


---@alias MQL.defns.cant_loot
---| `defns.cant_loot.no_target`    target is `nil`
---| `defns.cant_loot.cant_see`     cant see inside container
---| `defns.cant_loot.empty`        container is empty
---| `defns.cant_loot.disabled`     manager is disabled
---| `defns.cant_loot.other`        some other reason (manager specific)


-- keeps track of the current install status of graphic herbalism
---@alias MQL.defns.misc.gh
---| `defns.misc.gh.never`      -- graphic herbalism was never installed
---| `defns.misc.gh.previously` -- graphic herbalism was previously installed, but is not currently installed
---| `defns.misc.gh.installed`  -- graphic herbalism is installed

return defns