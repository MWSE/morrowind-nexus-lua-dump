-- these store all the different constants used by this mod.
---@class MQL.defns
local defns = {

    mod_name = "More Quick Loot",       -- the name of the mod
    version = 0.9,                      -- the current version of the mod

    -- the installation status of graphic herbalism. this is used for compatiblity purposes
    gh_status = {
        never = 0,      -- graphic herbalism was never installed
        previously = 1, -- graphic herbalism was previously installed, but is not currently installed
        currently = 2,  -- graphic herbalism is installed
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
        plant_list = 1,         -- use `config.plants_blacklist` list to source a list of containers that are not plants
        gh = 2,                 --use graphic herbalism and `config.plants_blacklist` to source containers that are not plants
    },

    -- how should empty dead things be dealt with
    dispose = {
        none = 0,       -- no option for disposing of dead
        take_all = 1,   -- when a dead container becomes empty, replace "Take All" with "Dispose"
        on_sight = 2    -- as soon as a dead container becomes empty, dispose of it.
    },

    cant_loot = {
        no_target = 1,  -- the `target` is `nil`
        cant_see = 2,   -- cant see inside this container
        empty = 3,      -- container is empty
        disabled = 4,   -- manager is disabled
        locked = 5,     -- container is locked
        trapped = 6,    -- container is trapped (and looting trapped containers is disabled)
    },

    -- should we show scripted containers? if so, how?
    show_scripted = {
        dont = 0,       -- don't show scripted containers
        prefix = 1,     -- show scripted containers, but put a prefix before their names
        no_prefix = 2,  -- show scripted containers, and don't say anything about it
    },

    -- what should we do when multiple items are in a stack?
    multiple_items = {
        one = 0,    -- always take one 
        stack = 1,  -- always take whole stack
        ratio = 2,  -- only take items if the price/weight ratio is above a specified number
        total_weight = 3,  -- take the whole stack, if it's under a certain weight
        ratio_and_total_weight = 4,  -- take the whole stack, if it's under a certain weight and ratio
        ratio_or_total_weight = 5,  -- take the whole stack, if it's under a certain weight or ratio
    },
    
    --what should we do when multiple items are in a stack, and we have a certain chance of taking each one
    chance_multiple_items = {
        one = 0,            -- always take one 
        stack = 1,          -- always take whole stack
        total_chance = 2,   -- take the stack if the total chance is above a specified minimum
        regular = 3,        -- use settings for regular containers
        total_chance_and_regular = 4,        -- use `total_chance` AND settings for regular containers
    },
}

---@alias MQL.defns.multiple_items
---| `defns.multiple_items.one`                     take only one item
---| `defns.multiple_items.stack`                   take the whole stack
---| `defns.multiple_items.ratio`                   take all items if the price/weight ratio is above a specified number. otherwise take one
---| `defns.multiple_items.total_weight`            take all items if the total weight is under this number. otherwise take one
---| `defns.multiple_items.ratio_and_total_weight`  take all items if the ratio AND total weight are good. otherwise take one
---| `defns.multiple_items.ratio_or_total_weight`   take all items if the ratio OR total weight are good. otherwise take one


---@alias MQL.defns.chance_multiple_items
---| `defns.chance_multiple_items.one`                          take only one item
---| `defns.chance_multiple_items.stack`                        take the whole stack
---| `defns.chance_multiple_items.total_chance`                 take all items if the total chance is above a certain minimum
---| `defns.chance_multiple_items.regular`                      use settings for regular containers
---| `defns.chance_multiple_items.total_chance_and_regular`     use total_chance and regular settings


---@alias MQL.defns.show_scripted
---| `defns.show_scripted.dont` dont show any scripted containers
---| `defns.show_scripted.prefix` show scripted containers, but put a prefix before their names
---| `defns.show_scripted.no_prefix` show scripted containers, and don't say anything about it


-- keeps track of the current install status of graphic herbalism
---@alias MQL.defns.gh_status
---| `defns.gh_status.never`      -- graphic herbalism was never installed
---| `defns.gh_status.previously` -- graphic herbalism was previously installed, but is not currently installed
---| `defns.gh_status.currently`  -- graphic herbalism is installed


-- what happens to empty plants
---@alias MQL.defns.change_plants
---| `defns.change_plants.none` no changes
---| `defns.change_plants.gh` use graphic herbalism to change plants
---| `defns.change_plants.destroy` destroy plants after looting


-- how should we try to discern which organic containers aren't plants?
---@alias MQL.defns.not_plants_src
---| `defns.not_plants_src.everything_plant`  treat all organic containers as plants (no source)
---| `defns.not_plants_src.plant_list`        use `config.plants_blacklist` list to source a list of containers that are not plants
---| `defns.not_plants_src.gh`                use graphic herbalism and `config.plants_blacklist` to source containers that are not plants


-- how should empty dead things be dealt with
---@alias MQL.defns.dispose_dead 
---| `defns.dispose.none`     no option for disposing of dead
---| `defns.dispose.take_all` when a dead container becomes empty, replace "Take All" with "Dispose"
---| `defns.dispose.auto`     as soon as a dead container becomes empty, dispose of it.


---@alias MQL.defns.cant_loot
---| `defns.cant_loot.no_target` target is `nil`
---| `defns.cant_loot.cant_see` cant see inside container
---| `defns.cant_loot.empty` container is empty
---| `defns.cant_loot.disabled` manager is disabled
---| `defns.cant_loot.locked` container is locked
---| `defns.cant_loot.trapped` container is trapped (and looting trapped containers is disabled)

return defns