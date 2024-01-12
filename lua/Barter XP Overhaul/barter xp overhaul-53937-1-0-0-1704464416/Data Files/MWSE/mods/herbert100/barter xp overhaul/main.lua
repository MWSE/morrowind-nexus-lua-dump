local mod = require ("herbert100.barter xp overhaul.mod")
local log = require("herbert100").Logger("Barter XP Overhaul") ---@type herbert.Logger
local config = require("herbert100.barter xp overhaul.config")


-- event priorities, used to make sure things properly update when the MCM is closed.
local offer_priority, skill_priority

-- =============================================================================
-- MAKE MCM
-- =============================================================================
local mcm = {}
mod.mcm = mcm -- if anyone wants to access the `mcm` table (maybe they want to change `mcm.update`, idk)

local reload_mod = false
-- make MCM
function mcm.register()
    local template = mwse.mcm.createTemplate{ name = "Barter XP Overhaul", onClose = function () mcm.update(); mwse.saveConfig("Barter XP Overhaul", config) end,}

    local page = template:createSideBarPage{ label="Settings", 
        description="This mod gives you XP whenever you successfully barter with an NPC.\n\n\z
            \z
            XP will be awarded based on the total amount being traded, as well as how effectively you haggled. (You will get more XP if you haggle prices down when buying or up when selling.)\n\n\z
            \z
            XP is rewarded in such a way that it's more beneficial to make larger sales (up to a certain point). For example, you'll get more XP for performing one sale worth 1,000 gold than you would for performing two sales worth 500 gold.\n\n\z
            \z
            The bonus XP obtained from haggling is calculated based on the total amount of gold you saved in the transaction. It is more beneficial to perform one sale where you save 100 gold than two sales where you save 50 gold. (This is different from the base game.)\z
        ",
    }

    -- make new mcm variable with the given id. used to save those precious keystrokes
    local function nv(id) return mwse.mcm.createTableVariable{id=id,table=config} end

    page:createYesNoButton{label="Enable", variable=nv("enable"),
        description="This setting determines whether XP should be awarded when bartering through the regular barter menu. If this is disabled, you won't gain XP from traditional bartering through the normal menu.\n\n\z
            \z
            If this setting is disabled, this mod can still be used by other mods to award XP.\n\n\z
            \z
            For example, if you disable this setting but enable the \"Award Barter XP\" setting in \"More QuickLoot\", then you will still gain XP from bartering through QuickLoot menus.\z
        ",
    }
    page:createYesNoButton{label="Block vanilla XP rewards", variable=nv("exercise_skill_enable"), 
        description="If enabled, the vanilla formula for awarding barter XP will not be used.\n\n\z
            \z
            Default: enabled.\z
        "
    }
    page:createDecimalSlider{label="Total XP Coefficient", variable = nv("coeff"), max=7.5, 
        description="The total amount of XP you earn while bartering will be multiplied by this number. \z
            (This also affected the bonus XP gained from haggling.)\n\n\z
            This setting will take effect before any modifiers specified by other mods (such as Proportional Progression).\z
        ",
    }
    page:createDecimalSlider{label="Haggling XP Coefficient", variable = nv("haggle_coeff"), max=7.5, 
        description="The extra XP you earn from haggling will be multiplied by this number.\n\n\z
            \z
            This setting will take effect before any modifiers specified by other mods (such as Proportional Progression).\z
        ",
    }

    

    -- -------------------------------------------------------------------------
    -- ADVANCED SETTINGS
    -- -------------------------------------------------------------------------
    local adv_settings = page:createCategory{label="Advanced Settings", description="You probably don't have to worry about these, but they're here anyway." }

    adv_settings:createYesNoButton{label="Claim barterOffer Event?", variable=nv("barter_offer_claim"), 
        description="If enabled, lower priority mods won't happen when the barterOffer event triggers.\n\n Default: disabled."}
    adv_settings:createSlider{label="barterOffer Event priority", variable=nv("barter_offer_priority"), min=-1000,max=1000, 
        description="Mods that register the barterOffer event with a higher priority will run before this mod.\n\n\z
            If a mod doesn't specify its priority then its priority is 0.\n\n\z
            The default setting is -1, so that we can allow other mods to alter whether a barter attempt succeeds or not."}
    adv_settings:createSlider{label="exerciseSkill Event priority", variable=nv("exercise_skill_priority"), min=-1000,max=1000, description="The exercise skill event is used to Mods that register the exerciseSkill event with a higher priority will run before this mod.\n\nIf a mod doesn't specify its priority then its priority is 0.\n\n The default setting is -1."}
    -- add a reload button if debugging. (experimental)

    log:add_to_MCM(page, config)

    if log.level >= log.LEVEL.DEBUG then
        adv_settings:createButton{label="Reload mod (EXPERIMENTAL)", buttonText='RELOAD',
            description="Reload the mod file. This is experimental, so it might break things.",
            callback=function () 
                tes3.messageBox("Reloading mod...")
                reload_mod = true
            end
        }
    end
    template:register()
end


-- called whenever the game is first launched, and then each time the MCM is closed. 
-- this function makes sure the mod is appropriately enabled/disabled, and updates the priority if applicable
function mcm.update()
    local update_reg = require("herbert100").update_registration
    -- if the priority changed (or if we're reloading the mod), unregister the event with older priority
    if offer_priority ~= config.barter_offer_priority or reload_mod then 
        update_reg{event="barterOffer", callback=mod.barter_offer, register=false, priority=offer_priority }
    end
    offer_priority = config.barter_offer_priority

    if skill_priority ~= config.exercise_skill_priority or reload_mod then
        update_reg{event="exerciseSkill", callback=mod.block_vanilla_xp, register=false, priority=skill_priority }
    end
    
    skill_priority = config.exercise_skill_priority
    if reload_mod then
        mod = dofile("herbert100.barter xp overhaul.mod") --update the mod
        reload_mod = false
    end
    -- update the event registration status
    update_reg{event="barterOffer", callback=mod.barter_offer, 
        register=config.enable, priority=skill_priority
    }
    update_reg{event="exerciseSkill", callback=mod.block_vanilla_xp, 
        register=config.exercise_skill_enable and config.enable, 
        priority=skill_priority 
    }
    mod.mcm = mcm -- if anyone wants to access the `mcm` table (maybe they want to change `mcm.update`, idk)

end


-- =============================================================================
-- REGISTER EVENTS
-- =============================================================================
event.register(tes3.event.modConfigReady, mcm.register) 
event.register(tes3.event.initialized, function () -- update the mod and print an initializion message once the game is initialized
    mcm.update()
    log:info("Mod initialized.")
end)