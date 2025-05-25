local common = require("StormAtronach.TT.common")
local config = common.config
local default_config = common.default_config

local function modActivation()
    event.trigger("stormatronach:modActivation")
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate("Take That!")
    template:saveOnClose(config.confPath, config)
    mwse.mcm.register(template)

    local page = template:createSideBarPage{
        sidebarComponents = {
            mwse.mcm.createInfo{
                text = (
                    "Take That! by Storm Atronach\n\n" ..
                    "A modern combat mod with blocking, parrying, dodging, and spell batting. \n" ..
                    "Tweak the settings below to customize your experience. \n" ..
                    "Please visit the Nexus page for more information and support." 
                )
            }
        }
    }

    local category = page:createCategory("Settings")

    category:createOnOffButton{
        label = "Enable Mod",
        description = "Toggle the mod on or off.",
        variable = mwse.mcm.createTableVariable{id = "enabled", table = config},
        callback = modActivation
    }

    category:createKeyBinder{
        label = "Block Hotkey",
        description = "Choose a hotkey for starting the block. Mouse buttons are allowed",
        allowCombinations = true,
        allowModifierKeys = true,
        allowMouse        = true,
        variable = mwse.mcm.createTableVariable{id = "hotkey", table = config}
    }

    category:createSlider{
        label = "Block Cooldown (seconds)",
        description = "This is the cooldown for blocking. It is not the same as the block window.",
        min = 1, max = 10, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "block_cool_down_time", table = config}
    }

    category:createSlider{
        label = "Dodge Cooldown (seconds)",
        description = "This is the cooldown for dodging. It is not the same as the dodge window.",
        min = 1, max = 10, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "dodge_cool_down_time", table = config}
    }

    category:createSlider{
        label = "Block Window (seconds)",
        description = "This is the base window for blocking. Block before the enemy hits.",
        min = 0.1, max = 2, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "block_window", table = config}
    }

    category:createSlider{
        label = "Parry Window (seconds)",
        description = "This is the base window for parrying. Release the attack just before the enemy hits. Each attack will reduce the window by the factor below.",
        min = 0.1, max = 0.5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "parry_window", table = config}
    }

    category:createSlider{
        label = "Parry window reduction factor per Attack",
        description = "This is the factor that will reduce the parry window for each attack. The more you parry, the smaller the window. The contribution of each attack is removed after 0.75 seconds",
        min = 1.5, max = 5, step = 0.25, jump = 0.25, decimalPlaces = 2,
        variable = mwse.mcm.createTableVariable{id = "parry_red_per_attack", table = config}
    }

    category:createSlider{
        label = "Parry window reduction duration (seconds)",
        description = "This is the duration for the parry window reduction. The contribution of each attack is removed after this time.",
        min = 0.5, max = 5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "parry_red_duration", table = config}
    }

    category:createSlider{
        label = "Spell Batting Minimum Skill",
        description = "This is the minimum skill required to use spell batting. It just feels unrealistic to be able to bat spells with 0 skill, but it is your choice.",
        min = 0, max = 100, step = 1, jump = 5,
        variable = mwse.mcm.createTableVariable{id = "bat_min_skill", table = config}
    }

    category:createSlider{
        label = "Spell Batting Window (seconds)",
        description = "This is the window for spell batting. Release the attack just before the spell hits.",
        min = 0.1, max = 1.2, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "bat_window", table = config}
    }

    category:createSlider{
        label = "Block Shield Base %",
        description = "This is the base damage reduction when blocking with a shield.",
        min = 0, max = 100, step = 1, jump = 5,
        variable = mwse.mcm.createTableVariable{id = "block_shield_base_pc", table = config}
    }

    category:createSlider{
        label = "Block Shield Skill Multiplier",
        description = "0.5 means 50% of the block skill is added to the damage reduction formula.",
        min = 0, max = 2, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "block_shield_skill_mult", table = config}
    }

    category:createSlider{
        label = "Block Weapon Base %",
        description = "This is the base damage reduction when blocking with a weapon.",
        min = 0, max = 100, step = 1, jump = 5,
        variable = mwse.mcm.createTableVariable{id = "block_weapon_base_pc", table = config}
    }

    category:createSlider{
        label = "Blocking: Weapon Skill Multiplier",
        description = "0.2 means 20% of the weapon skill is added to the damage reduction formula.",
        min = 0, max = 2, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "block_weapon_skill_mult", table = config}
    }

    category:createOnOffButton{
        label = "Alternative calculation for weapon block. Block skill also contributes to the damage reduction when using weapon block",
        description = "If this is enabled, the block skill will also contribute to the damage reduction when using weapon block. Also, blocking will grant experience to the block skill instead of the weapon skill.",
        variable = mwse.mcm.createTableVariable{id = "block_skill_bonus_active", table = config},
    }

     category:createSlider{
        label = "Bonus from block skill when using weapon block. ",
        description = "0.2 means 20% of the block skill is added to the damage reduction formula.",
        min = 0, max = 2, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "block_weapon_blockSkill_bonus", table = config}
    }

    category:createSlider{
        label = "Blocking: Vanilla blocking cap%",
        description = "Set the vanilla blocking cap to 0 to disable vanilla blocking. Set to 50 to allow full vanilla block chance.",
        min = 0, max = 50, step = 1, jump = 1,
        variable = mwse.mcm.createTableVariable{id = "vanilla_blocking_cap", table = config}
    }

    category:createSlider{
        label = "Training: XP gain from blocking",
        description = "XP gain from blocking. Vanilla per succesful block is 2.5",
        min = 0, max = 10, step = 0.5, jump = 0.5, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "block_skill_gain", table = config}
    }

    category:createSlider{
        label = "Training: XP gain from parry",
        description = "XP gain from parrying. Vanilla per succesful attack is 1-2 depending on the weapon",
        min = 0, max = 10, step = 0.5, jump = 0.5, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "parry_skill_gain", table = config}
    }
    category:createSlider{
        label = "Training: XP gain from dodging",
        description = "XP gain from dodging. I am using 5, but there is no equivalent in vanilla.",
        min = 0, max = 10, step = 0.5, jump = 0.5, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "dodge_skill_gain", table = config}
    }

    category:createButton{
        buttonText = "Restore Defaults",
        description = "Restore all settings to their default values.",
        callback = function()
            for k, v in pairs(default_config) do
                config[k] = v
            end
            mwse.saveConfig(config.confPath, config)
            tes3.messageBox("Take That! settings restored to default. Please reopen the Take That! MCM page to see the changes.")
        end
    }

    category:createOnOffButton{
        label = "NPC Parry Active",
        description = "If this is enabled, NPCs will be able to parry your attacks.",
        variable = mwse.mcm.createTableVariable{id = "enemy_parry_active", table = config},
    }

    category:createSlider{
        label = "NPC Parry Window (seconds)",
        description = "This is the base window for NPC parrying.",
        min = 0.1, max = 0.5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "enemy_parry_window", table = config}
    }

    category:createSlider{
        label = "NPC minimum swing for parry",
        description = "This is the minimum swing that the NPC will need to achieve to parry your attack. NPC swing is randomized by the game engine",
        min = 0.1, max = 1, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "enemy_min_attackSwing", table = config}
    }
    
    category:createSlider{
        label = "Parry light magnitude",
        description = "This is the magnitude of the light effect when parrying. Set to 0 to disable the effect.",
        min = 0, max = 100, step = 1, jump = 5, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "parry_light_magnitude", table = config}
    }

       category:createSlider{
        label = "Parry light duration",
        description = "This is the magnitude of the light effect when parrying. Set to 0 to disable the effect.",
        min = 0, max = 0.5, step = 0.1, jump = 0.1, decimalPlaces = 1,
        variable = mwse.mcm.createTableVariable{id = "parry_light_duration", table = config}
    }

    category:createDropdown{
    label = "Logger Level",
    description = "Set the verbosity of the mod's log output. TRACE is most detailed, ERROR is least. Requires game reset to reflect changes.",
    options = {
        { label = "TRACE", value = "TRACE" },
        { label = "DEBUG", value = "DEBUG" },
        { label = "INFO",  value = "INFO"  },
        { label = "WARN",  value = "WARN"  },
        { label = "ERROR", value = "ERROR" }
    },
    variable = mwse.mcm.createTableVariable{
        id = "log_level",
        table = config    },
    callback = function(self)   
        common.log:setLogLevel(self.variable.value)
        common.log:debug("Logger level changed to " .. self.variable.value)
    end
    }
end
event.register("modConfigReady", registerModConfig)
