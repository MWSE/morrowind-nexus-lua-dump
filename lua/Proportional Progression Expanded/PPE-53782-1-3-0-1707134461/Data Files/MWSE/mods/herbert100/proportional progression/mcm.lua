--[[ this file will deal with creating the MCM and updating the MCM copy of the config whenever relevant settings are changed
    *) it will also make sure certain values are always in accepted ranges, and it will generate new config entries if 
        the relevant settings are changed.
    *) lastly, it provides an `update` function that will be run whenever the MCM menu is closed (ie, the config is saved).
        *) this `update` function will be used by `main.lua` to update the computation variables that are used during runtime.
]]

local utils = require("herbert100.proportional progression.config.utils")

-- local log = require("herbert100.proportional progression.log")
local log = require("herbert100.logger").new("PPE/mcm")

local Skills_Module = include("SkillsModule")

local config = require("herbert100.proportional progression.config")

local template ---@type mwseMCMTemplate

local registered = false

-- these next two variables will be used when checking if we need to initialize new `level` and `skill_level` entries.
local old_lvl_delta = config.lvl_delta
local old_max_lvl = config.max_lvl

--- get a list of all levels, with the passed lvl_delta and lvl_num 
-- nil values will default to current config values
---@param lvl_delta integer? # the lvl delta 
---@param max_lvl integer? # the maximum level
local function get_lvls(lvl_delta, max_lvl)
    lvl_delta = lvl_delta or config.lvl_delta
    max_lvl = max_lvl or config.max_lvl
    local lvls = {}
    for lvl=0, max_lvl, lvl_delta do
        table.insert(lvls, lvl)
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
    local new_lvl_delta, new_max_lvl = config.lvl_delta, config.max_lvl 
    log("about to update level settings")
    if old_lvl_delta == new_lvl_delta and old_max_lvl ==  new_max_lvl then 
        log("no level settings to update.")
        return
    end

    local new_lvls = get_lvls(new_lvl_delta, new_max_lvl)
    log(function()
        local inspect, old_lvls = require("inspect").inspect, get_lvls(old_lvl_delta, old_max_lvl)
        return "updating level settings with\n\tnew_lvls: %s\n\told_lvls: %s\n\told_max_lvl: %s",
            inspect(new_lvls), inspect(old_lvls), old_max_lvl
    end)
    -- update the config
    log("updating level options")
    -- this loop will set a default value of each of the new levels that were added.
    for _, new_lvl in ipairs(new_lvls) do
        -- dont do anything in this case because this value has already been set in the last configuration.
        if new_lvl % old_lvl_delta == 0 and new_lvl <= old_max_lvl then 
            goto continue 
        end

        log:debug("creating options for level %s", new_lvl)
        for i, cfg in ipairs{config.level.modifiers, config.skill_level.modifiers} do
            local cfg_name = i == 1 and "level" or "skill_level"
            if new_lvl > old_max_lvl then
                cfg[new_lvl] = cfg[new_lvl] or cfg[old_max_lvl]
                log:trace("new_lvl (%i) >= old_max_lvl (%i), setting %s[%i] to be %s[new_lvl] or %s[old_max_lvl], whichever exists.",
                    new_lvl, old_max_lvl, cfg_name, new_lvl, cfg_name, cfg_name
                )
            else
                local old_prev_lvl = new_lvl - new_lvl % old_lvl_delta
                local old_next_lvl = old_prev_lvl + old_lvl_delta
                local t = (new_lvl - old_prev_lvl)/old_lvl_delta

                cfg[new_lvl] = math.lerp(cfg[old_prev_lvl], cfg[old_next_lvl], t)
                
                log:trace("interpolating value of %s[%i] from old levels %i and %i. setting\n\t\z
                    %s[%i] = %s == lerp(%s, %s, %s)",
                    cfg_name, new_lvl, old_prev_lvl, old_next_lvl,
                    cfg_name, new_lvl, cfg[new_lvl], cfg[old_prev_lvl], cfg[old_next_lvl], t
                )
            end
        end
        ::continue::
    end
    -- record that lvl_delta and lvl_nums have changed
    old_lvl_delta, old_max_lvl = new_lvl_delta, new_max_lvl
end


-- update the sliders. this will be called when `slider_min` or `slider_max` are changed.
---@param component mwseMCMCategory?
local function update_sliders(component)
    if not component then
        for _, page in ipairs(template.pages) do
            log("updating sliders in page: %s", page.label)
            update_sliders(page)
        end
        return
    end
    log("updating all sliders in %s: %s", component.componentType, component.label)
    for _, child in pairs(component.components) do
        if child.componentType == "Category" then
            log:trace("calling update_sliders(%s)", child.label)
            update_sliders(child)
        elseif child.componentType == "PercentageSlider" and child.label:endswith("slider value") then
            log("updating min and max of slider: %s", child.label)
            child.min = config.slider_min
            child.max = config.slider_max
        end
    end

end


---@param category mwseMCMCategory
local function add_skill_sliders(category, is_custom_skill)
    local cfg
    local names_and_ids = {}
    if is_custom_skill then
        cfg = config.custom_skill.modifiers
        for id, skill in pairs(Skills_Module.skills) do
            cfg[id] = cfg[id] or 1
            table.insert(names_and_ids, {name=skill.name, id=id})
        end
    else
        cfg = config.skill.modifiers
        for _, id in pairs(tes3.skill) do
            table.insert(names_and_ids, {name=tes3.getSkillName(id), id=id})
        end
    end

    table.sort(names_and_ids, function (a, b) return a.name:lower() < b.name:lower() end)

    for _, info in ipairs(names_and_ids) do
        log:trace("adding skill slider for %q", info.name)
        category:createPercentageSlider{ label = info.name .. " modifier",
            variable = mwse.mcm.createTableVariable{id = info.id, table = cfg},
            min = config.slider_min, max = config.slider_max
        }
    end
end


---@param page mwseMCMPage
local function fill_lvl_page(page)
    local cfg
   
    -- add_lvl_sliders(skill_lvl_page, config.skill_level.modifiers)
    if page.label == "Player Level Modifiers" then
        cfg = config.level
        log("found player level modifiers")
    else
        log("found skill level modifiers")
        cfg = config.skill_level
    end
    log("page name: %s. cfg name: %s", page.label, table.find(config, cfg))

    page:createYesNoButton{label="Enable" .. page.label,
        variable=mwse.mcm.createTableVariable{id="enable", table=cfg}
    }
    local lvls = get_lvls()

    log(function() return "Making level sliders for lvls: %s\n\t\z
        lvl_delta: %i\n\t\z
        max_lvl: %i ",
        require("inspect")(lvls), config.lvl_delta, config.max_lvl
    end, nil)

    for i,lvl in ipairs(lvls) do 
        local next_lvl = lvls[i+1]
        local label
        -- if this is the last level we're displaying
        if next_lvl == nil then 
            label = lvl .. "+ modifier"
        else
            label = string.format("%i to %i modifier", lvl, next_lvl -1)
        end
        page:createPercentageSlider({ label = label, min = config.slider_min, max = config.slider_max, 
            variable = mwse.mcm.createTableVariable({id = lvl, table = cfg.modifiers}),
        })
    end
end


local function add_other_skills()
    local other_skills
    local other_skills_index
    local skill_page
    log("updating other skills")
    for _, page in pairs(template.pages) do
        if page.label == "Skill Modifiers" then
            skill_page = page
            break
        end
    end
    if not skill_page then
        log:error("could not find skill page!")
        return
    end
    for i, comp in pairs(skill_page.components) do
        if comp.componentType == "Category" and comp.label == "Other Skills" then
            other_skills = comp
            other_skills_index = i
            break
        end
    end
    if other_skills_index then
        log("found other skills category, removing it.")
        table.remove(skill_page.components, other_skills_index)
    end

    if Skills_Module and next(Skills_Module.skills) ~= nil then
        other_skills = skill_page:createCategory{label = "Other Skills",
            description="Here you will find \"all\" of the skills added via the \"Skills Module\".\n\n\t\z
                Note: If a custom skill uses version 1 of the \"Skills Module\", then it's very likely \z
                that skill won't appear in this menu until after save is loaded (and a few seconds have passed). \z
                Skills using version 2 of the \"Skills Module\" should have no trouble showing up."
        }
        other_skills:createYesNoButton{ label = "Enable Skill Modifiers",
            variable = mwse.mcm.createTableVariable({ id = "enable", table = config.custom_skill}),
        }
        add_skill_sliders(other_skills, true)
    end
end

local function remake_lvl_sliders()
    for _, page in ipairs(template.pages) do
        if not page.label:endswith("Level Modifiers") then goto next_page end
        table.clear(page.components)
        fill_lvl_page(page)
        ::next_page::
    end
end


---@type mwseMCMDropdown
local select_profile, textfield

local function update_profile_list_options()
    local new_options = {}
    local profile_names = utils.get_all_profile_names()
    table.sort(profile_names)
    for _, profile_name in pairs(profile_names) do
        local option = {label = profile_name, value = profile_name}
        table.insert(new_options, option)
    end
    select_profile.options = new_options
end


local function update_select_profile_dropdown_selection()
    for _, option in ipairs(select_profile.options) do
        if option.label == config.profile_name then
            select_profile:selectOption(option)
            return
        end
    end
end


local profile_select_variable = mwse.mcm.createCustom{
    getter = function () return config.profile_name end,
    setter = function (_, newValue)
        if newValue == config.profile_name then return end

        log:trace("trying to change to profile %q", newValue)

        if utils.change_profile(config, newValue) then
            log:trace("successfully changed to profile %q", newValue)
            return
        end

        log:trace("couldn't change to profile %q. trying to create it instead.", newValue)

        if utils.create_profile(config, newValue) then
            log:trace("successfully created profile %q", newValue)
        else
            log:trace("couldn't create profile %q.", newValue)
        end
    end
}

local function register()
    template = mwse.mcm.createTemplate{ name = "Proportional Progression Expanded", onSearch=function (searchText)
        return string.find("ppe modifiers", searchText:lower(), nil, true) ~= nil
    end}

    template.onClose = function()

        local payload = {mod_name = "Proportional Progression Expanded"}
        payload = event.trigger("herbert:MCM_closed", payload)

        log("-------------------------------------------")
        log("Updating config. Profile: %q", config.profile_name)
        log("-------------------------------------------")
        update_levels()

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
            For example, suppose you're level 42 and your Athletics skill is level 81. Also, suppose the 'Global scale factor' is set to 200%, the \z
            'Athletics Skill modifier' is set to 150%, the '40 to 49 Player Level modifier' is set to 80%, and the \z
            '80-89 Skill Level modifier' is set to 90%.\n\n\z
            Then the amount of XP you gain whenever exercising the athletics skill is multiplied by 200% * 150% * 80% * 90% = 216%."
    })
    local general_modifiers = main_page:createCategory{label="General Modifiers", description="These apply to multiple skills, and at every level."}
    do -- create the settings on the main page
        general_modifiers:createPercentageSlider({label = "Global scale factor", description = "This scales all earned XP.",
            variable = mwse.mcm.createTableVariable({id = "scale", table = config, }),
            min = config.slider_min, max = config.slider_max, 
        })
        general_modifiers:createPercentageSlider({label = "Specialization scale factor", description = "Scales XP earned by skills that correspond to your class's specialization (i.e., Magic, Stealth, Combat).",
            variable = mwse.mcm.createTableVariable({id = "specialization_modifier", table = config, }),
            min = config.slider_min, max = config.slider_max,
        })
        general_modifiers:createPercentageSlider({label = "Major skill scale factor", description = "Scales XP earned by major skills.",
            variable = mwse.mcm.createTableVariable({id = "major_skill_modifier", table = config, }),
            min = config.slider_min, max = config.slider_max,
        })
        general_modifiers:createPercentageSlider({label = "Minor skill scale factor", description = "Scales XP earned by minor skills.",
            variable = mwse.mcm.createTableVariable({id = "minor_skill_modifier", table = config, }),
            min = config.slider_min, max = config.slider_max,
        })
        general_modifiers:createPercentageSlider({label = "Miscellaneous skill scale factor", description = "Scales XP earned by miscellaneous skills.",
            variable = mwse.mcm.createTableVariable({id = "misc_skill_modifier", table = config, }),
            min = config.slider_min, max = config.slider_max,
        })
        local slider_settings = main_page:createCategory{label="Slider Settings", description="These settings modify how the sliders work."}
        do -- make slider options
            do -- make the `lvl_delta` and `max_lvl` sliders.
                -- this will be used to refer to the max level slider, once it's been made.
                local max_lvl_slider


                local function max_lvl_converter(max, delta)
                    max = max or config.max_lvl
                    delta = delta or config.lvl_delta

                    local new_max = max - (max % delta)
                    if new_max + delta/2 < max  then 
                        return new_max + delta
                    end
                    return new_max
                end

                slider_settings:createSlider({ label = "Levels per level slider",
                    description = "Changes the number of levels governed by each slider in the Level and Skill Level pages.\z
                        For example, a value of 10 means the Level and Skill Level sliders start at '0 to 9', then '10 to 19', etc.\n\n\z
                        Setting this to 5 would make the Level and Skill Level sliders start at '0 to 4', then '5 to 9', etc.",
                    variable = mwse.mcm.createTableVariable({id = "lvl_delta", table = config}),

                    callback = function(self)
                        log:trace("BEGIN LVL_DELTA CALLBACK ---------------------------")
                        local delta = self.variable.value

                        max_lvl_slider.step = delta
                        max_lvl_slider.jump = delta * 3

                        -- update the value of the max level slider, then update it (will also call its callback method)
                        max_lvl_slider.variable.value = max_lvl_converter(nil, delta)
                        max_lvl_slider:updateWidgetValue()
                        max_lvl_slider:updateValueLabel()
                        max_lvl_slider:update()
                        
                        log:trace("updated max_lvl_slider jump and step")
                        log:debug("new jump and step: %s and %s", max_lvl_slider.jump, max_lvl_slider.step)
                        log:trace("END LVL_DELTA CALLBACK ---------------------------")
                    end,
                    min = 3, 
                    max = 25,
                })
                max_lvl_slider = slider_settings:createSlider({ label = "Maximum level",
                    description = "Highest level to show sliders for. Must be a multiple of the previous setting.\n\n\z
                        For example, setting this to 30 would mean that the sliders in the Level and Skill Level sections would be \z
                        '0 to 9', '10 to 19', '20 to 29', and '30+'.", 
                    variable = mwse.mcm.createTableVariable{id = "max_lvl", table = config, converter = max_lvl_converter },
                    callback=function ()
                        update_levels()
                        remake_lvl_sliders()
                    end,
                    min = 0,
                    max = 300,
                    step = config.lvl_delta,
                    jump = config.lvl_delta * 3,
                })
            end
            slider_settings:createYesNoButton({label="Gradually change level modifiers",
                description=[[If enabled, then the 'Player Level' and 'Skill Level' multipliers will gradually change as the player's level or the skill's level increases.

For example, let's say the following 'Player Level' modifiers are set: '10 to 19' = 100%, and '20 to 29' = 200%.

    If this setting is enabled, then these modifiers will be used at the corresponding levels:
        '10': 100%
        '11': 110%
        '12': 120%
        '13': 130%
        ... 
        '19': 190%
        '20': 200%

    If this setting is disabled, then these modifiers will be used at the corresponding levels:
        '10': 100%
        '11': 100%
        '12': 100%
        '13': 100%
        ... 
        '19': 100%
        '20': 200%

Note: This setting does not affect the number of sliders present in the MCM, it only affects how those sliders are used to calculate modifiers.]],
                    variable = mwse.mcm.createTableVariable({ id = "interpolate_level_modifiers", table = config}),
            })
            slider_settings:createPercentageSlider({ label = "Minimum slider value",
                description = "This setting only affects the MCM. \nIt will change the minimum value shown by other sliders in the MCM. \z
                    You will have to edit the source code to change the minimum/maximum value of this slider. :)",
                variable = mwse.mcm.createTableVariable({id = "slider_min", table = config}),
                min = 0, max = 5, 
                callback=update_sliders,
            })
            slider_settings:createPercentageSlider({ label = "Maximum slider value",
                description = "This setting only affects the MCM. \nIt will change the maximum value shown by other sliders in the MCM. \z
                    You will have to edit the source code to change the minimum/maximum value of this slider. :)",
                variable = mwse.mcm.createTableVariable{id = "slider_max", table = config},
                min = 1, max = 15, 
                callback=update_sliders,
            })
        end

        do -- make log options
            local adv = main_page:createCategory{label="Advanced Settings",
                description="These settings let you change the logging level and the event priority for the `exerciseSkill` event.\n\n\z
                    Changing the event priority will determine whether xp modifiers from this mod should happen before or after xp modifiers from other mods.\n\n\z
                    Mods with a higher priority will do their things first. You can typically find the priority a mod is using by looking at their 'main.lua' file in \"Data Files/MWSE/mods/MOD_NAME\".\n\n\z
                    If a priority isn't specified, then it's treated as though it were 0.\n\n\z
                    The default priority is -2, so that this mod modifies xp after most other mods, and also after mods that want to modify xp after other mods.\z
                ",
            }
            adv:createTextField{label="exerciseSkill event priority", 
                variable=mwse.mcm.createTableVariable{id="priority",table=config, converter=tonumber},
            }
            log:add_to_MCM{component=adv,config=config}

        end
    end

    -- -------------------------------------------------------------------------
    -- SKILL SETTINGS 
    -- -------------------------------------------------------------------------
    do -- skill settings

        -- only make a sidebar if asked
        local page = template:createSideBarPage{ label = "Skill Modifiers", 
            description = "This page contains XP modifiers for each skill.\n\n\z
                Modifiers for custom skills added via the \"Skills Module\" can be found at the bottom, in the \"Other Skills\" section. \z
                (This section will only exist if custom skills are added.) \z
                Skills that were added by version 1 of the  \"Skills Module\" will likely only appear once a save has been loaded and a few seconds have passed."
        }

        page:createYesNoButton{ label = "Enable Skill Modifiers",
            variable = mwse.mcm.createTableVariable({ id = "enable", table = config.skill}),
        }
        add_skill_sliders(page)
        add_other_skills()
       
    end
    -- -------------------------------------------------------------------------
    -- LEVEL/SKILL LEVEL SPECIFIC
    -- -------------------------------------------------------------------------

    fill_lvl_page(template:createSideBarPage{ label = "Player Level Modifiers",
        description = "This page contains modifiers that affect all XP gained when the player's level is in the listed range. For example, \z 
            if you're level 55 and the setting '50 to 59' is set to 0.60, then you will earn 60% of the XP you normally would. \z
            (Stacks with other multipliers)"
    })

    fill_lvl_page(template:createSideBarPage{ label = "Skill Level Modifiers",
        description = "The Skill Level page (I couldn't think of a better name) contains modifiers that affect XP gained in the \z
            listed skill level ranges. For example, if your acrobatics skill is level 37 and the `30 to 39` range is set to 1.50, \z
            then you'll earn 50% more XP. ",
    })

    local profile_settings = template:createSideBarPage{label="Profiles",
        description = string.format("Here you can create different profiles and swap between them. \z
            These allow you to easily save and change your settings on the fly, and they \z
            provide a more convenient way to use different settings for different characters.\n\n\z
            \z
            The currently selected profile will be saved automatically whenever you make a new profile, change your selected profile, or close the MCM.\n\n\z
            \z
            Each time the game is loaded, the most recently used profile will be used. (But you can change to a different profile through this page.)\n\n\z
            \z
            There is currently no way to delete profiles from within the MCM. \z
            If you would like to delete an old profile, you will have to do that manually.\n\z
            Profiles are stored in %q.", utils.full_profiles_path)
    }

    

    select_profile = profile_settings:createDropdown{label = "Change profiles", 
        description = "You can use this setting to change between any of your created profiles.\n\n\z
            All changes will be saved whenever you make a new profile, select a different profile, or close the MCM.", 
        options = {},
        variable = profile_select_variable,
    }
    update_profile_list_options()

    textfield = profile_settings:createTextField{
        label = "Create a new profile",
        description = "If you enter the name of an existing profile, then the mod will simply change to that profile. Nothing will be overwritten.\n\n\z
            The newly created profile will be created using the settings of the previous profile. \z
            If you want the new profile to be created with default settings, then you can do this by pressing the \"Reset\" button AFTER creating a new profile.",
        buttonText = "Create",
        variable = profile_select_variable,
    }



    local reset_settings = profile_settings:createCategory{label="Reset Profile"}
    reset_settings:createButton{ label = "Import original Proportional Progression config", 
        buttonText = "Import",
        callback = function() utils.import_NC_config(config) end,
    }
    reset_settings:createButton{ label = "Reset all values to default.", 
        buttonText = "Reset",
        callback = function()
            utils.reset_to_default(config)
        end,
    }

    -- Finish up.
    template:register()
    registered = true
end


-- support for V1 skills, since they don't get registered when the game starts
event.register("SkillsModule:SkillActiveChanged", function()
    timer.start{duration=2, callback=add_other_skills} 
end)

event.register("OtherSkills:Ready", function()
    timer.start{duration=2, callback=add_other_skills} 
end)


local function update_settings(e)
    old_lvl_delta = config.lvl_delta
    old_max_lvl = config.max_lvl
    
    if registered then
        update_sliders()
        remake_lvl_sliders()
    
        update_profile_list_options()
    
        update_select_profile_dropdown_selection()
        textfield.elements.inputField.text = e.profile_name
    end
end

---@param e PPE.events.profile_created.data
event.register("PPE:profile_created", function (e)
    if registered then
        update_profile_list_options()
    end

    update_settings(e)
end)

event.register("PPE:profile_changed", update_settings)

event.register(tes3.event.modConfigReady, register)
