--[[ this file will deal with creating the MCM and updating the MCM copy of the config whenever relevant settings are changed
    *) it will also make sure certain values are always in accepted ranges, and it will generate new config entries if 
        the relevant settings are changed.
    *) lastly, it provides an `update` function that will be run whenever the MCM menu is closed (ie, the config is saved).
        *) this `update` function will be used by `main.lua` to update the computation variables that are used during runtime.
]]



local CONSTANTS = require("herbert100.proportional progression.CONSTANTS")

local log = require("herbert100.proportional progression.log")

local extra_sliders = {}


local mcm_config = require("herbert100.proportional progression.mcm.config_handler")



--this table is responsible for generating the MCM menu and handling any changes that are made to setting sduring runtime.
local mcm = { config = mcm_config,
    -- this function is run whenever the MCM is closed. it will be defined later, when we want to update the variables we use during computations.
    update = function() end
}

-- these next two variables will be used when checking if we need to initialize new `level` and `skill_level` entries.
local old_lvl_delta = mcm_config.lvl_delta
local old_max_lvl = mcm_config.max_lvl

--- get a list of all levels, with the passed lvl_delta and lvl_num 
-- nil values will default to current config values
---@param lvl_delta integer? # the lvl delta 
---@param max_lvl integer? # the maximum level
function mcm.get_lvls(lvl_delta, max_lvl)
    lvl_delta = lvl_delta or mcm.config.lvl_delta
    max_lvl = max_lvl or mcm.config.max_lvl
    local lvls = {}
    for lvl=0,max_lvl,lvl_delta do
        lvls[#lvls+1] = lvl
    end
    return lvls
end


--[[this function updates the `level` and `skill_level` tables, if `lvl_delta` or `max_lvl` have changed.
    this is how it does that:
        *) if increments of lvl_delta overlap with increments of old_lvl_delta, we use the old values 
        *) if there is no overlap, we linearly interpolate between the values
            *) for example, if old_lvl_delta == 10 and new_lvl_delta == 5, with level[10] == 1.5 and level[20] == 1, then the new values will be 
                level[10] = 1.5, level[15] = 1.25, level[20] = 1

        *) if we're trying to assign a modifier to a level that's higher than the maximum level from the previous configuration, we set it to 
            *) any previous value of that setting, if it exists; otherwise, we set it to the value of the old maximum level setting.
                *) for example, let's say the previous configuration was `old_lvl_delta == 10` and `old_max_lvl == 100`
                    if the new configuration wants to set a value above 100, eg, it wants to set a default for skill_level[115], it would:
                    *) check if skill_level[115] has ever been set; if it has, it will use that value 
                    *) otherwise, it will set skill_level[115] = skill_level[100].
]]
local function update_levels()
    local new_lvl_delta, new_max_lvl = mcm.config.lvl_delta, mcm.config.max_lvl 

    if old_lvl_delta == new_lvl_delta and old_max_lvl ==  new_max_lvl then 
        log:debug("No level settings to update.")
        return
    end

    local new_lvls = mcm.get_lvls(new_lvl_delta, new_max_lvl)
    local old_lvls = mcm.get_lvls(old_lvl_delta, old_max_lvl)

    if mcm_config.log_level > 1 then 
        log:debug(string.format("new_lvls: %s", json.encode(new_lvls) ))
        log:debug(string.format("old_lvls: %s", json.encode(old_lvls) ))
        log:debug(string.format("old_max_lvl: %s", old_max_lvl ))
    end
    -- update the config
    log:debug("updating level options")
    -- this loop will set a default value of each of the new levels that were added.
    for _,new_lvl in ipairs(new_lvls) do
        --[[ if `new_lvl` is a multiple of `old_lvl_delta`, and if `new_lvl <= old_max_lvl`, 
            then the `level` and `skill_level` modifiers will already be present in `mcm.config`. 
            so, we don't have to do anything in this case.
        ]]
        -- dont do anything in this case because this value has already been set in the last configuration.
        if new_lvl % old_lvl_delta == 0 and new_lvl <= old_max_lvl then goto continue end

        log:debug("creating options for level " .. new_lvl .. ".")

        if new_lvl > old_max_lvl then
            -- initialize it to the previous highest level
            mcm.config.level.modifiers[new_lvl] = mcm.config.level.modifiers[new_lvl] or mcm.config.level.modifiers[old_max_lvl]
            mcm.config.skill_level.modifiers[new_lvl] = mcm.config.skill_level.modifiers[new_lvl] or mcm.config.skill_level.modifiers[old_max_lvl]
            if mcm_config.log_level > 1 then 
                log:debug(string.format("new_lvl >= max_old_lvl, setting new values to be those of the max old_lvl, or to the values stored in the config if it exists\n\t\t\z
                    level[%i]       = %i\n\t\t\z
                    skill_level[%i] = %i",
                    new_lvl, mcm.config.level.modifiers[new_lvl], new_lvl, mcm.config.skill_level.modifiers[new_lvl]
                ))
            end
        else
            -- we know new_lvl < max_old_lvl, which means the following two levels will exist in `mcm_config`
            local old_lower_lvl = new_lvl - new_lvl % old_lvl_delta     -- greatest multiple of `max_old_lvl` that's smaller than `new_lvl`
            local old_higher_lvl = old_lower_lvl + old_lvl_delta        -- smallest multiple of `max_old_lvl` that's greater than `new_lvl`

            --[[`t` is a number between 0 and 1 that represents the position of `new_lvl` on the line connecting `old_lower_lvl` to `old_higher_lvl`.
                *) for example:
                    if `new_lvl == old_lower_lvl` then `t == 0`
                    if `new_lvl == old_higher_lvl` then 
                        `new_lvl - old_lower_lvl == lvl_delta`, so 
                        `t == (old_higher_lvl - old_lower_lvl)/ old_lvl_delta == 1`
            ]]
            local t = (new_lvl - old_lower_lvl)/ old_lvl_delta
            --[[ a and b will denote the value of the `level` (and then the `skill_level`) modifiers at `old_lower_lvl` and `old_higher_lvl`, respectively.
                we'll then use linear interpolation to set the default value of `new_lvl` in the respective table. 

                    *) this is just a fancy way of saying we'll set `modifiers[new_lvl]` to a value between `modifiers[old_lower_lvl]` and `modifiers[old_higher_lvl]`,
                            based on how close `new_lvl` is to `old_lower_lvl` and `old_higher_lvl`.
                    
                    *) an example would probably make this a lot clearer:
                        let's say `old_lvl_delta == 10`, `old_lower_lvl == 10`, `old_higher_lvl == 20`, and `new_lvl == 14`. (the value of `new_lvl_delta` doesn't matter right now.)

                        then `t == 0.4`, because `14` is "40% of the way between `10` and `20`".

                        so, if `modifiers[10] == 200` and `modifiers[20] == 100`, then `modifiers[new_lvl]` would be "40% of the way between `200` and `100`". ie, `modifiers[new_lvl] == 160`. 
                            
                        (remember that values are stored as integers in this stage. this is also why we have to floor stuff.)
            ]]
            local a,b
            
            a,b  = mcm.config.level.modifiers[old_lower_lvl], mcm.config.level.modifiers[old_higher_lvl]

            mcm.config.level.modifiers[new_lvl] = math.lerp(a,b, t)

            a,b  = mcm.config.skill_level.modifiers[old_lower_lvl], mcm.config.skill_level.modifiers[old_higher_lvl]
            mcm.config.skill_level.modifiers[new_lvl] = math.lerp(a,b, t)
            
            if mcm.config.log_level > 1 then 
                log:trace(string.format("have new_lvl < max_old_lvl\n\t\t\z
                        old_lower_lvl: %i\n\t\t\z
                        old_higher_lvl: %i\n\t\t\z
                        t: %.3f", old_lower_lvl, old_higher_lvl, t)
                )
                log:debug(
                    "" .. new_lvl .. "  < max_old_lvl, interpolating new values from old values"
                    .. "\n\t\tlevel[" .. new_lvl .. "] = " .. mcm.config.level.modifiers[new_lvl] .. ", interpolated from "
                    .. "level[" .. old_lower_lvl .. "] = " .. mcm.config.level.modifiers[old_lower_lvl] .. " and "
                    .. "level[" .. old_higher_lvl .. "] = " .. mcm.config.level.modifiers[old_higher_lvl] 
                    .. "\n\t\tskill_level[" .. new_lvl .. "] = " .. mcm.config.skill_level.modifiers[new_lvl] .. ", interpolated from "
                    .. "skill_level[" .. old_lower_lvl .. "] = " .. mcm.config.skill_level.modifiers[old_lower_lvl] ..  " and "
                    .. "skill_level[" .. old_higher_lvl .. "] = " .. mcm.config.skill_level.modifiers[old_higher_lvl] 
                )
            end
        end
        ::continue::
    end
    -- record that lvl_delta and lvl_nums have changed
    old_lvl_delta, old_max_lvl = new_lvl_delta, new_max_lvl
end
---@class new_page_params
---@field page_name string 
---@field page_description string
---@field tbl_name string the table in `config` to use 
---@field skill_specific (boolean|nil) is it a skill table or a level/level_specific table?

local Page_Manager = {
    pages = {}, ---@type table<string, mwseMCMPage>
    template = nil, ---@type mwseMCMTemplate?
}

--- make a page with the given information
---@param p new_page_params
function Page_Manager.create_page(p)
    local page
    local tbl = mcm_config[p.tbl_name]
    -- only make a sidebar if asked
    if mcm_config.enable_sidebars then
        page = Page_Manager.template:createSideBarPage({ label = p.page_name , description = p.page_description})
    else
        page =Page_Manager.template:createPage({ label = p.page_name, description = p.page_description })
    end
    Page_Manager.pages[p.tbl_name] = page

    page:createYesNoButton({
        label = "Enable " .. p.page_name,
        variable = mwse.mcm.createTableVariable({ id = "enable", table = tbl}),
    })
    if p.skill_specific then 
        local skill_names = {}
        -- record all the names in an array, and then sort it alphabetically
        for name, _ in pairs(mcm_config.skill.modifiers) do skill_names[#skill_names+1] = name end
        table.sort(skill_names)
        
        for _, skill_name in pairs(skill_names) do -- the index is literally meaningless because the table got sorted
            --[[
add spaces before showing skills in MCM
this is overkill, but it looks pretty :)
besides, MCM creation doesn't happen very much (only once per launch i think)

what exactly is going on in the for loop, though? some good old fashioned pattern matching.
the ultimate goal here is to convert one camelcase "word" to multiple words, with the first letter of each word capitalized.

*) lets see what will happen to the string "mediumArmor", as an example.
*) the `gsub` command will replace the first letter with an uppercase letter
    *) so, "mediumArmor" becomes "MediumArmor"
*) the gmatch command will pick match a pattern consisting of one uppercase letter, followed by any number of lowercase letters
    *) %u means match an uppercase letter.
    *) `?` means match zero or one occurences
    *) %l means match lower a lowercase letter 

    *) so, "MediumArmor" will basically get sent to the 'array' {"Medium", "Armor"}

*) the body of the for loop is responsible for 'gluing together' the words from the 'array'
    *) In our example, it will turn {"Medium", "Armor"} into "Medium Armor"
            ]]
            local pretty_skill_name = ""
            for word in skill_name:gsub("^%l", string.upper):gmatch("%u%l*") do 
                pretty_skill_name = pretty_skill_name .. " " .. word
            end
            local label = pretty_skill_name .. " modifier: %s"

            -- we display the pretty name, but internally use the ugly one. such is life.
            page:createDecimalSlider({ label = label,
                variable = mwse.mcm.createTableVariable{id = skill_name, table = tbl.modifiers},
                min = mcm_config.slider_min, max = mcm_config.slider_max, decimalPlaces = 2
            })
        end
    else
        -- get starting level value 
        -- this one starts at index 1 :)
        local lvls = mcm.get_lvls()
        log:debug(string.format("Making level sliders for lvls: %s\n\t\z
            lvl_delta: %i\n\t\z
            max_lvl: %i ",
            json.encode(lvls), mcm.config.lvl_delta, mcm.config.max_lvl)
        )
        for i,lvl in ipairs(lvls) do 
            local next_lvl = lvls[i+1]
            local label
            -- if this is the last level we're displaying
            if next_lvl == nil then 
                label = lvl .. "+ modifier: %s"
            else
                label = lvl .. " to " .. (next_lvl-1) .. " modifier: %s"
            end
            page:createDecimalSlider({ label = label,min = mcm_config.slider_min, max = mcm_config.slider_max, decimalPlaces = 2,
                variable = mwse.mcm.createTableVariable({id = lvl, table = tbl.modifiers}),
            })
        end
    end
end

-- update the sliders. this will be called when `slider_min` or `slider_max` are changed.
function Page_Manager.update_sliders()
    -- iterate through all the pages that we made
    for tbl_index, page in pairs(Page_Manager.pages) do
        log:debug(string.format("updating page: %s", tbl_index))
        -- iterate through each component (ie each setting) of the page
        for _, component in pairs(page.components) do
            -- if it has a `min` value, then it's a slider, so we change the `min` and `max`.
            if component.min then
                log:debug("component is a slider, updating min and max")
                component.min = mcm_config.slider_min
                component.max = mcm_config.slider_max
            end
        end
    end

    -- now update the extra sliders
    for _,s in pairs(extra_sliders) do
        s.min = mcm_config.slider_min
        s.max = mcm_config.slider_max
    end
end


function mcm.register()
    local template = mwse.mcm.createTemplate{ name = CONSTANTS.mod_name }
    Page_Manager.template = template


    --[[this is called whenever the MCM is closed. it will save the config to a JSON file, and 
        it will also update the calculation variables used by the mod.

        we can't use `saveOnClose` because that's just a wrapper for the `template.onClose` field. 
        in other words, using the `saveOnClose` method will overwrite the current `onClose` function, which will break MCM support.
    ]]
    template.onClose = function()
        -- update the log before doing anything else
        log:setLogLevel(CONSTANTS.log_levels[mcm.config.log_level])
        log:debug("-------------------------------------------")
        log:debug("Updating config.")
        log:debug("-------------------------------------------")
        -- this is our own internal bookkeeping
        update_levels()

        -- this will be called in `main.lua`, whenever it needs access to updated values from the `mcm.config` table.
        mcm.update()

        -- everything was updated, now it's time to save the new settings to the JSON file.
        mwse.saveConfig(CONSTANTS.mod_name, mcm_config)
    end

    -- -------------------------------------------------------------------------
    -- GENERAL SETTINGS
    -- -------------------------------------------------------------------------
    local main_page = template:createSideBarPage({ label = "General Settings",
        description = "This mod allows you to control the rate at which you earn XP.\n\n\z
                'Skill Modifiers' multiply all XP earned by the relevant skill.\n\z
                'Player Level Modifiers' multiply the XP earned when the player is a certain level.\n\z
                'Skill Level Modifiers' multiply the XP earned when the skill is a certain level.\n\n\z
            All multipliers stack with each other.\n\n\z
            For example, suppose you're level 42 and your Athletics skill is level 81. Also, suppose the 'Global scale factor' is set to 2, the \z
            'Athletics Skill modifier' is set to 1.5, the '40 to 49 Player Level modifier' is set to 0.8, and the \z
            '80-89 Skill Level modifier' is set to 0.9.\n\n\z
            Then the amount of XP you gain whenever exercising the athletics skill is multiplied by 2 * 1.5 * 0.8 * 0.9."
    })
    local general_modifiers = main_page:createCategory{label="General Modifiers", description="These apply to multiple skills, and at every level."}
    do -- create the settings on the main page
        extra_sliders[#extra_sliders+1] = general_modifiers:createDecimalSlider({label = "Global scale factor: %s", description = "This scales all earned XP.",
            variable = mwse.mcm.createTableVariable({id = "scale", table = mcm_config, }),
            min = mcm_config.slider_min, max = mcm_config.slider_max, decimalPlaces=2,
        })
        extra_sliders[#extra_sliders+1] = general_modifiers:createDecimalSlider({label = "Specialization scale factor: %s", description = "Scales XP earned by skills that correspond to your class's specialization (i.e., Magic, Stealth, Combat).",
            variable = mwse.mcm.createTableVariable({id = "specialization_modifier", table = mcm_config, }),
            min = mcm_config.slider_min, max = mcm_config.slider_max,decimalPlaces=2,
        })
        extra_sliders[#extra_sliders+1] = general_modifiers:createDecimalSlider({label = "Major skill scale factor: %s", description = "Scales XP earned by major skills.",
            variable = mwse.mcm.createTableVariable({id = "major_skill_modifier", table = mcm_config, }),
            min = mcm_config.slider_min, max = mcm_config.slider_max,decimalPlaces=2,
        })
        extra_sliders[#extra_sliders+1] = general_modifiers:createDecimalSlider({label = "Minor skill scale factor: %s", description = "Scales XP earned by minor skills.",
            variable = mwse.mcm.createTableVariable({id = "minor_skill_modifier", table = mcm_config, }),
            min = mcm_config.slider_min, max = mcm_config.slider_max,decimalPlaces=2,
        })
        extra_sliders[#extra_sliders+1] = general_modifiers:createDecimalSlider({label = "Miscellaneous skill scale factor: %s", description = "Scales XP earned by miscellaneous skills.",
            variable = mwse.mcm.createTableVariable({id = "misc_skill_modifier", table = mcm_config, }),
            min = mcm_config.slider_min, max = mcm_config.slider_max,decimalPlaces=2,
        })
        local slider_settings = main_page:createCategory{label="Slider Settings", description="These settings modify how the sliders work."}
        do -- make slider options
            do -- make the `lvl_delta` and `max_lvl` sliders.
                -- this will be used to refer to the max level slider, once it's been made.
                local max_lvl_slider
                slider_settings:createSlider({ label = "Level interval width: %s",
                    description = "Changes the number of levels governed by each slider in the Level and Skill Level pages.\z
                        For example, a value of 10 means the Level and Skill Level sliders start at '0 to 9', then '10 to 19', etc.\n\n\z
                        Setting this to 5 would make the Level and Skill Level sliders start at '0 to 4', then '5 to 9', etc.\n\n\z
                        A restart is required for the new sliders to show up in the MCM. The new sliders will be set to 'sensible' \z
                        default values, based on the values of pre-existing sliders.",
                    variable = mwse.mcm.createTableVariable({id = "lvl_delta", table = mcm_config}),

                    -- if we're lowering the level delta, we should increase the number of level ranges
                    callback = function(self)
                        log:trace("BEGIN LVL_DELTA CALLBACK ---------------------------")
                        local new_lvl_delta = self.variable.value
        
                        local old_max_lvl = mcm_config.max_lvl
                        local new_max_lvl = old_max_lvl - (old_max_lvl % new_lvl_delta)

                        max_lvl_slider.step = new_lvl_delta
                        max_lvl_slider.jump = new_lvl_delta * 3

                        if new_max_lvl + new_lvl_delta/2 < old_max_lvl  then 
                            new_max_lvl = new_max_lvl + new_lvl_delta
                        end
                        max_lvl_slider.elements.slider.widget.current = new_max_lvl
                        max_lvl_slider:updateValueLabel()
                        max_lvl_slider:update()
                        
                        log:trace("updated max_lvl_slider jump and step")
                        log:debug("new jump and step: " .. max_lvl_slider.step .. " and " .. max_lvl_slider.jump)
                        log:trace("END LVL_DELTA CALLBACK ---------------------------")
                    end,
                    min = 3, max = 25,
                    -- restartRequired = true
                })
                max_lvl_slider = slider_settings:createSlider({ label = "Maximum level: %s",
                    description = "Highest level to show sliders for. Must be a multiple of the previous setting.\n\n\z
                    For example, setting this to 30 would mean that the sliders in the Level and Skill Level sections would be \z
                    '0 to 9', '10 to 19', '20 to 29', and '30+'.  \n\n\z
                    A restart is required for the new sliders to show up in the MCM. The new sliders will be set to 'sensible' default values, based on the values of pre-existing sliders.", 
                    variable = mwse.mcm.createTableVariable({id = "max_lvl", table = mcm_config,
                        --[[ this converter will make sure `max_lvl` is always set to a multiple of `lvl_delta`
                            *) `newValue` will be the value the player tried to set the slider to.
                            
                            *) `newValue` will lie somewhere between two points `a` and `b`, where `a` and `b` are both multiples of `lvl_delta` and `a < newValue <= b`.

                            *) if `newValue` is closest to `a`, we will set it to `a`. if `newValue` is closest to `b`, we will set it to `b`. 

                            *) the point halfway between `a` and `b` is given by `a + lvl_delta/2`, so all we need to do is check whether `a + lvl_delta/2 < newValue`, 
                                then set `newValue` accordingly.
                        ]]
                        converter = function (newValue)
                            local lvl_delta = mcm_config.lvl_delta

                            --[[ in the notation from earlier, 
                                    `new_max_lvl == b == newValue` if `newValue` is a multiple of `lvl_delta`.
                                    `new_max_lvl == a` if `newValue` is not a multiple of `lvl_delta`.
                                since the following conditional will be `false` whenever `new_max_lvl == b`, it will be fine to treat `new_max_lvl` as if it is `a`.
                            ]]
                            local new_max_lvl = newValue - (newValue % lvl_delta)
                            
                            -- if `(midpoint between a and b) < newValue`, then `new_max_lvl = b`; else `new_max_lvl = a`
                            if new_max_lvl + lvl_delta/2< newValue  then 
                                new_max_lvl = new_max_lvl + lvl_delta
                            end

                            return new_max_lvl
                        end
                    }),
                    callback = function (self)
                        -- converter doesn't actually change what's shown in the UI, so we have to change that manually.
                        max_lvl_slider.elements.slider.widget.current = self.variable.value
                        max_lvl_slider:updateValueLabel()
                        log:trace("updated slider value label!")
                        max_lvl_slider.elements.slider:updateLayout()
                        log:trace("updated slider layout!")
                    end,
                    min = 0, max = 300,
                    step = mcm_config.lvl_delta,
                    jump = mcm_config.lvl_delta * 3,
                })
            end
            slider_settings:createYesNoButton({label="Gradually change level modifiers",
                description=[[If enabled, then the 'Player Level' and 'Skill Level' multipliers will gradually change as the player's level or the skill's level increases.

For example, let's say the following 'Player Level' modifiers are set: '10 to 19' = 1, and '20 to 29' = 2.

    If this setting is enabled, then these modifiers will be used at the corresponding levels:
        '10': 1.0
        '11': 1.1
        '12': 1.2
        '13': 1.3
        ... 
        '19': 1.9
        '20': 2.0

    If this setting is disabled, then these modifiers will be used at the corresponding levels:
        '10': 1.0
        '11': 1.0
        '12': 1.0
        '13': 1.0
        ... 
        '19': 1.0
        '20': 2.0

Note: This setting does not affect the number of sliders present in the MCM, it only affects how those sliders are used to calculate modifiers.]],
                    variable = mwse.mcm.createTableVariable({ id = "interpolate_level_modifiers", table = mcm_config}),
            })
            slider_settings:createDecimalSlider({ label = "Minimum slider value: %s",
                description = "This setting only affects the MCM. \nIt will change the minimum value shown by other sliders in the MCM. " ..
                "You will have to edit the source code to change the minimum/maximum value of this slider. :)",
                variable = mwse.mcm.createTableVariable({id = "slider_min", table = mcm_config}),
                min = 0, max = 5, decimalPlaces = 2,
                callback=Page_Manager.update_sliders,
            })
            slider_settings:createDecimalSlider({ label = "Maximum slider value: %s",
                description = "This setting only affects the MCM. \nIt will change the maximum value shown by other sliders in the MCM. " ..
                "You will have to edit the source code to change the minimum/maximum value of this slider. :)",
                variable = mwse.mcm.createTableVariable{id = "slider_max", table = mcm_config},
                min = 1, max = 15, decimalPlaces = 2,
                callback=Page_Manager.update_sliders,
            })
        end

        do -- make log options
            -- store the logging level as a number so that we can quickly check if we should be displaying information
            local log_options = {}
            for log_level_num=0, #CONSTANTS.log_levels do
                local log_level_str = CONSTANTS.log_levels[log_level_num]
                log_options[#log_options+1] = {label = log_level_str, value = log_level_num}
            end
            main_page:createDropdown{
                label = "Logging Level",
                description = "Determines how much information is written to the 'MWSE.log' file. Setting this to something above 'INFO' will spam the log file \z
                and probably result in worse performance. So don't do it unless you (temporarily) want detailed information about what the mod is doing (i.e. to see how \z
                    the modifiers are being calculated). The options are\n\n\z
                    'NONE': Nothing will be written to the log file (except the MCM config loading).\n\n\z
                    'INFO': Pretty much only the mod initialization message will be logged.\n\n\z
                    'DEBUG': A lot of the internal workings will be logged, such as: a skill (other than athletics) was increased, the config was loaded/updated.\n\n\z
                    'TRACE': Debug, but more. This will also log athletics skill increases, and will generally write more detailed information to the log file.",
                options = log_options,
                variable = mwse.mcm.createTableVariable{ id = "log_level", table = mcm_config },
            }
        end
    end

    -- -------------------------------------------------------------------------
    -- SKILL SETTINGS 
    -- -------------------------------------------------------------------------
    Page_Manager.create_page{ page_name = "Skill Modifiers",tbl_name = "skill", skill_specific = true,
        page_description = "This page contains XP modifiers for each skill.",
    }

    -- -------------------------------------------------------------------------
    -- LEVEL SPECIFIC
    -- -------------------------------------------------------------------------
    Page_Manager.create_page{ page_name ="Player Level Modifiers", tbl_name = "level",
        page_description = "This page contains modifiers that affect all XP gained when the player's level is in the listed range. For example, " .. 
        "if you're level 55 and the setting '50 to 59' is set to 0.60, then you will earn 60% of the XP you normally would. (Stacks with other multipliers)",
    }

    -- -------------------------------------------------------------------------
    -- SKILL LEVEL SPECIFIC
    -- -------------------------------------------------------------------------
    Page_Manager.create_page{ page_name = "Skill Level Modifiers", tbl_name ="skill_level",
        page_description = "The Skill Level page (I couldn't think of a better name) contains modifiers that affect XP gained in the listed skill level ranges. For example, " .. 
        "if your acrobatics skill is level 37 and the `30 to 39` range is set to 1.50, then you'll earn 50% more XP. ",
        }

    -- Finish up.
    template:register()
end


return mcm