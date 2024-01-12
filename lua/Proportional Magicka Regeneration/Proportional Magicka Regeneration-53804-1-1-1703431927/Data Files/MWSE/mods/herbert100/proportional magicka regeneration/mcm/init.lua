local CONSTANTS = require("herbert100.proportional magicka regeneration.CONSTANTS")
local log = require("herbert100.proportional magicka regeneration.log")



local default_config = require("herbert100.proportional magicka regeneration.mcm.default_config")

local mcm = {
    update = function () end,
    config = mwse.loadConfig(CONSTANTS.mod_name, default_config)  ---@type MR_Config
}
log:setLogLevel(CONSTANTS.log_levels[mcm.config.log_level])


    log:debug("MR config: " .. json.encode(mcm.config))
---@diagnostic disable-next-line: need-check-nil

---@alias ACTOR_TYPE_NAMES "player"|"npc"


local formula_settings
local coeff_sliders  = {} ---@type table<"player_regen"|"npc_regen", mwseMCMDecimalSlider>

---@class formula_table_params
---@field formula_name string? #name of formula to generate values for, defaults to current `config` value.
---@field coeff number? # number to multiply entries by



--{formula_name: string?, coeff: number?}
--- make the table that's displayed in regeneration settings options
---@param params formula_table_params?
local function make_formula_table(params)
    params = params or {}
    local f = require("herbert100.proportional magicka regeneration.regeneration_formulas")[params.formula_name or mcm.config.formula_name]
    local coeff = params.coeff or 1
    return string.format([[
    40  W  ~> %.2f%% regen 
    50  W  ~> %.2f%% regen
    60  W  ~> %.2f%% regen
    70  W  ~> %.2f%% regen
    80  W  ~> %.2f%% regen
    90  W  ~> %.2f%% regen
    100 W  ~> %.2f%% regen
    125 W  ~> %.2f%% regen
    150 W  ~> %.2f%% regen
    200 W  ~> %.2f%% regen
    300 W  ~> %.2f%% regen]],
    coeff * f(40), coeff * f(50), coeff * f(60), coeff * f(70), coeff * f(80), coeff * f(90), coeff * f(100), coeff * f(125), coeff * f(150), coeff * f(200), coeff * f(300))
end

--- update the description of a regen coefficient slider
---@param tbl_index string index of the subtable for this actor
---@param name string the name to print         
---@param pronoun_subject string
---@param pronoun_dependent_possessive string
local function update_actor_regen_coeff_description(tbl_index, name, pronoun_subject, pronoun_dependent_possessive)
    local slider = coeff_sliders[tbl_index]
    if  slider == nil then return end

    local coeff = mcm.config[tbl_index].coeff
    local default_coeff = default_config[tbl_index].coeff
    slider.description = string.format("\z
        This is a flat multiplier on the %s magicka regeneration rate. \z
        Note that the rate of regeneration does not grow linearly with willpower. Here is a table of values listing \z
            the percentage of maximum magicka regenerated at different willpower values for the current slider setting:\n\n\z
        \z
        %s\n\n\z
        \z
        Changing this slider will multiply each entry in the table by the set value. For example, setting the slider to 0.75 \z
            will mean %s regenerate 0.75%% of %s maximum magicka at 100 willpower.\n\n\z
        \z
        \n\n\z
        Default: %.2f.",
        name,
        make_formula_table{coeff=coeff},
        pronoun_subject,
        pronoun_dependent_possessive,
        default_coeff
    )
end

local function update_player_slider_desc() 
    update_actor_regen_coeff_description("player_regen", "player","you","your")
end
local function update_npc_slider_desc()
    update_actor_regen_coeff_description("npc_regen","NPC","NPCs","their")
end
-- update_actor_regen_coeff_description("player_regen", "player","you","your")
-- update_actor_regen_coeff_description("npc_regen","NPC","NPCs","their")

local function update_formula_settings_description()
    formula_settings.description = "Choose the appropriate regeneration formula. Here are the formula values for your current selection, \z
    not taking into account Player or NPC coefficients:\n\n" .. make_formula_table()
end

-- update the descriptions in the MCM to reflect new formula values
local function update_mcm_descriptions()
    update_formula_settings_description()
    update_player_slider_desc()
    update_npc_slider_desc()
end

function mcm.register()
    local template = mwse.mcm.createTemplate(CONSTANTS.mod_name)
    -- whenever the mcm is closed, the variables are updated and then the descriptions are updated.
    template.onClose = function() 
         -- update the log_level 
        log:setLogLevel(CONSTANTS.log_levels[mcm.config.log_level])
        log:debug("Log level updated to " .. CONSTANTS.log_levels[mcm.config.log_level])

        mcm.update()
        -- update_mcm_descriptions()

        mwse.saveConfig(CONSTANTS.mod_name, mcm.config)
    end


    local page = template:createSideBarPage()
    page.label = CONSTANTS.mod_name
    page.description = "Yet another lua implementation of magicka regeneration."
    page.noScroll = false

    
    local settings = page:createCategory("General Regeneration Settings")


    -- =========================================================================
    -- REGENERATION SETTINGS
    -- =========================================================================
    do -- make formula options
        local options = {}
        for key, _ in pairs(require("herbert100.proportional magicka regeneration.regeneration_formulas")) do 

            -- first letter gets capitalized and "_" gets replaced with " "
            local pretty_key = key:gsub("^%l", string.upper):gsub("_", " ")

            options[#options+1] = { label = pretty_key, value = key }
        end
        formula_settings = page:createDropdown{ label = "Regeneration formula to use",
            description = "",
            options = options, variable = mwse.mcm.createTableVariable{ id = "formula_name", table = mcm.config},
            callback = update_formula_settings_description
        }

    end
    -- combat settings 
    -- Note: If you change this setting during combat, the new value will only take effect once combat ends. (Reloading a save will bypass this.)
    settings:createDecimalSlider({
        label = "Combat regeneration rate multiplier: ",
        description = string.format("\z
            For example, setting this to 0.33 will mean that during combat, all actors will regenerate a third of the magicka they would otherwise.\n\n\z
                \z
                Setting this to 0 will disable magicka regeneration during combat.\n\n\z
                \z
                Default: %.2f", 
            default_config.combat_mult
        ),
        -- "At a slider value of 1, you will 50 willpower, you will regenerate 0.3% of your maximum magicka per scond at 50 willpower; ." ..,
        min = 0.1, max = 2, step = .05, jump = .1,
        variable = mwse.mcm.createTableVariable{id = "combat_mult", table = mcm.config}
    })
    do -- make atronach settings 
        local atronach_settings = settings:createCategory{label="Atronach Settings"}
        settings:createDecimalSlider({
            label = "Atronach multiplier: %s",
            description = string.format("\z
                Regeneration penalty given by the Atronach birthsign.\n\n\z
                    \z
                    Setting this to 0.25 will mean actors with the Atronach birthsign will regenerate 25%% of the magicka they would otherwise.\n\n\z
                    \z
                    Setting this to 0 will disable magicka regeneration for actors with the Atronach birthsign.\n\n\z
                    \z
                    Default: %.2f.",
                default_config.atronach_mult
            ),
            min = 0, max = 1, step = .05, jump = .1,
            variable = mwse.mcm.createTableVariable{id = "atronach_mult", table = mcm.config},
        })
        settings:createYesNoButton({
            label = "Enable magicka regeneration when resting",
            description = "\z
                If enabled, Atronachs will be able to regeneration magicka when resting, taking the above multiplier into account.\n\n\z
                \z
                If disabled, Atronachs will not regenerate magicka when resting.\n\n\z
                \z
                Note: This setting only affects what happens when you're resting. This does not impact magicka regeneration when waiting.\z
            ",
            variable = mwse.mcm.createTableVariable{id = "atronachs_can_sleep", table = mcm.config},
        })
        settings:createYesNoButton({
            label = "Enable magicka regeneration when waiting",
            description = "\z
                If enabled, Atronachs will be able to regeneration magicka when waiting, taking the above multiplier into account.\n\n\z
                \z
                If disabled, Atronachs will not regenerate any magicka when waiting.\n\n\z
                \z
                Note: This setting does not affect what happens when resting. Magicka regeneration when resting is controlled by a separate setting.\z
            ",
            variable = mwse.mcm.createTableVariable{id = "atronachs_can_wait", table = mcm.config},
        })
        settings:createYesNoButton({
            label = "Enable magicka regeneration when traveling",
            description = "\z
                If enabled, Atronachs will be able to regeneration magicka when traveling, taking the Atronach regeneration multiplier into account.\n\n\z
                \z
                Disabling this will mean that Atronachs will have to walk if they want to regenerate magicka while traveling.\z
                \z
            ",
            variable = mwse.mcm.createTableVariable{id = "atronachs_can_travel", table = mcm.config},
        })
        settings:createYesNoButton{
            label = 'Atronachs have "Stunted Magicka"',
            description = '\z
                This setting controls how the mod detects which actors should be considered Atronachs. \z
                You may want to change this setting if you have a mod that adds new birthsigns or modifies the "Atronach" birthsign.\n\n\z
                \z
                If true, actors with the "Stunted Magicka" effect will be considered Atronachs.\n\n\z
                \z
                Note: If both this setting and the "wombburn" setting are enabled, then an actor will be considered an Atronach if they \z
                    have "Stunted Magicka" or the "wombburn" spell (or both).\n\n\z
                \z
                Default: Yes\z
            ',
            variable = mwse.mcm.createTableVariable{id = "atronach_stunted_test", table = mcm.config},
        }
        settings:createYesNoButton{
            label = 'Atronachs have "wombburn" spell',
            description = '\z
                This setting controls how the mod detects which actors should be considered Atronachs. \z
                You may want to change this setting if you have a mod that adds new birthsigns or modifies the "Atronach" birthsign.\n\n\z
                \z
                If true, actors with the "wombburn" spell will be considered Atronachs.\n\n\z
                \z
                Note: If both this setting and the "Stunted Magicka" setting are enabled, then an actor will be considered an Atronach if they \z
                    have "Stunted Magicka" or the "wombburn" spell (or both).\n\n\z
                \z
                Default: Yes\z
            ',
            variable = mwse.mcm.createTableVariable{id = "atronach_wombburn_test", table = mcm.config},
        }
    end

    do -- make player regen settings
        
        local category = page:createCategory("Player Regeneration Settings")
        category:createYesNoButton({ label = "Enable magicka regeneration",
            variable = mwse.mcm.createTableVariable{id = "enable", table = mcm.config.player_regen},
        })
        coeff_sliders.player_regen = category:createDecimalSlider({
            label = "Regeneration rate multiplier: %s",
            description = "",
            min = 0.01, max = 5, step = 0.05, jump = 0.1,
                variable = mwse.mcm.createTableVariable{id = "coeff", table = mcm.config.player_regen},
            callback = update_player_slider_desc
        })
        
        category:createDecimalSlider({label = "Poll Rate: once every %s seconds",
            description = string.format("\z
                How many times per second should magicka regeneration be calculated?\n\n\z
                    This setting does not affect the rate of regeneration, it only affects how frequently calculations are done.\n\n\z
                    \z
                    Higher values will (theoretically) result in better performance, at the expense of more 'choppy' regeneration.\n\n\z
                    \z
                    For example, setting this to 0.5 would mean magicka is added to the the actor's mana pool every 0.5 seconds.\n\z
                    If the formula says someone should regenerate 10 magicka per second, they will get 5 magicka every 0.5 seconds.\n\z
                    If, instead, the poll rate is set to 0.1, then that same person will receive 1 magicka every 0.1 seconds.\n\n\z
                    \z
                    Default: once every %i seconds.",
                default_config.player_regen.poll_rate
            ),
            min = 0.1, max = 2, step = .05, jump = .1,
            variable = mwse.mcm.createTableVariable {id = "poll_rate", table = mcm.config.player_regen},
        })
    end
    do -- make npc regen settings
        
        local category = page:createCategory("NPC Regeneration Settings")
        category:createYesNoButton({ label = "Enable magicka regeneration",
            variable = mwse.mcm.createTableVariable{id = "enable", table = mcm.config.npc_regen},
        })
        coeff_sliders.npc_regen = category:createDecimalSlider({
            label = "Regeneration rate multiplier: %s",
            description = "",
            min = 0.01, max = 5, step = 0.05, jump = 0.01,
                variable = mwse.mcm.createTableVariable{id = "coeff", table = mcm.config.npc_regen},
            callback = update_npc_slider_desc
        })
        
        category:createDecimalSlider({label = "Poll Rate: once every %s seconds",
            description = string.format("\z
                How many times per second should magicka regeneration be calculated?\n\n\z
                    This setting does not affect the rate of regeneration, it only affects how frequently calculations are done.\n\n\z
                    \z
                    Higher values will (theoretically) result in better performance, at the expense of more 'choppy' regeneration.\n\n\z
                    \z
                    For example, setting this to 0.5 would mean magicka is added to the the actor's mana pool every 0.5 seconds.\n\z
                    If the formula says someone should regenerate 10 magicka per second, they will get 5 magicka every 0.5 seconds.\n\z
                    If, instead, the poll rate is set to 0.1, then that same person will receive 1 magicka every 0.1 seconds.\n\n\z
                    \z
                    Default: once every %i seconds.",
                default_config.npc_regen.poll_rate
            ),
            min = 0.1, max = 2, step = .05, jump = .1,
            variable = mwse.mcm.createTableVariable {id = "poll_rate", table = mcm.config.npc_regen},
        })
    end
    update_mcm_descriptions()

    do -- make log options
        local log_options = {}
        for log_level_num=0, #CONSTANTS.log_levels do 
            local log_level_str = CONSTANTS.log_levels[log_level_num]
            log_options[#log_options+1] = {label = log_level_str, value = log_level_num}
        end
        if log then
            log:debug("logging options are " .. json.encode(log_options))
        end

        local log_settings = page:createCategory("Log Settings")
        
        local log_desc = "\z
            Change the current logging settings. You can probably ignore this setting. A value of \"NONE\" or \"INFO\" is recommended, \n\z
                unless you're troubleshooting something. Here is an explanation of the options:\n\n\t\z
                \z
                NONE: Absolutely nothing will be printed to the log.\n\n\t\z
                \z
                INFO: Only basic information will be logged, ie: the mod initialized and MCM settings were registered.\n\n\t\z
                \z
                DEBUG: An excessive amount of interal information will be added to the log file, eg: the formula was updated, modifiers were changed, splines were made etc.\n\t\t\z
                    Your log file will be spammed, and you will may notice a drop in performance.\n\n\t\z
                \z
                TRACE: An even more excessive amount of internal information will be added to the log file.\n\t\t\z
                    Your log file will be spammed relentlessly. Everything else will be drowned out by the noise. You will likely notice a drop in performance.\n\n\z
                \z
            Default: " .. CONSTANTS.log_levels[default_config.log_level]

        log_settings.description = log_desc
        log_settings:createDropdown({
                label = "Logging Level",
                description = log_desc,
                options = log_options,
                variable = mwse.mcm.createTableVariable{ id = "log_level", table = mcm.config }
            })
    end

    -- update the descriptions before registering so they're not blank
    update_mcm_descriptions()
    template:register()


end


return mcm