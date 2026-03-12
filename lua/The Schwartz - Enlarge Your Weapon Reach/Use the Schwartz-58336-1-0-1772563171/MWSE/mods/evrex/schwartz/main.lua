---------------------------------------
-- INITIALIZED EVENT
---------------------------------------
local function initialized()
    print("The Schwartz Initialized")
end

---------------------------------------
-- CONFIG
---------------------------------------
local config = mwse.loadConfig("SchwartzConfig") or {
    enabled = true,
    npcs = true,
    creatures = true,
    multiplier = 30,
    divisor = 100,
    h2hBaseReach = 70,
    debug = false,
}

---------------------------------------
-- MCM
---------------------------------------
local function registerModConfig()

    local template = mwse.mcm.createTemplate{
        name = "The Schwartz - Enlarge Your Weapon Reach",
        headerImagePath = "MWSE/mods/evrex/schwartz/schwartz.tga",
    }

    template:saveOnClose("SchwartzConfig", config)

    local page = template:createSideBarPage{
        label = "Settings",
        description =
            "The Schwartz increases melee attack reach based on Agility.\n" ..
            "Higher Agility results in longer melee reach."
    }

    page:createYesNoButton{
        label = "Enable Mod?",
        description = "Enable or disable the mod entirely.",
        variable = mwse.mcm.createTableVariable{
            id = "enabled",
            table = config
        }
    }

    page:createYesNoButton{
        label = "Affect NPCs?",
        description = "If enabled, NPCs also gain increased reach based on Agility.",
        variable = mwse.mcm.createTableVariable{
            id = "npcs",
            table = config
        }
    }

    page:createYesNoButton{
        label = "Affect Creatures?",
        description = "If enabled, creatures also gain increased reach based on Agility.",
        variable = mwse.mcm.createTableVariable{
            id = "creatures",
            table = config
        }
    }

    page:createSlider{
        label = "Reach Multiplier",
        description =
            "Controls how strongly Agility increases melee reach.\n" ..
            "Higher values produce a stronger effect.\n" ..
            "This value will be divided by 100 internally.",
        min = 10,
        max = 300,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "multiplier",
            table = config
        }
    }

    page:createSlider{
        label = "Agility Divisor",
        description =
            "Agility is divided by this value when calculating the bonus.\n" ..
            "Lower values increase the effect; higher values reduce it.",
        min = 1,
        max = 255,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "divisor",
            table = config
        }
    }

    page:createSlider{
        label = "Hand-to-Hand Base Reach",
        description =
            "Base reach when attacking unarmed.\n" ..
            "This value is scaled and combined with the Agility bonus.\n" ..
            "This value will be divided by 100 internally.",
        min = 10,
        max = 100,
        step = 1,
        jump = 5,
        variable = mwse.mcm.createTableVariable{
            id = "h2hBaseReach",
            table = config
        }
    }

    page:createYesNoButton{
        label = "Debug Messages",
        description = "Show base, bonus, and final reach values during attacks.",
        variable = mwse.mcm.createTableVariable{
            id = "debug",
            table = config
        }
    }

    page:createButton{
        label = "Reset to Default Values",
        buttonText = "Reset",
        description = "Restore all settings to their original default values.",
        callback = function()
            config.enabled = true
            config.npcs = true
            config.creatures = true
            config.multiplier = 30
            config.divisor = 100
            config.h2hBaseReach = 70
            config.debug = false
            tes3.messageBox("The Schwartz: default settings restored.")
        end
    }

    mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)

---------------------------------------
-- REACH BONUS FORMULA
---------------------------------------
local function computeReachBonus(mobile)
    local a = mobile.agility.current
    local raw = (a / config.divisor) * (config.multiplier / 100)
    return math.floor(raw * 1000) / 1000
end

---------------------------------------
-- BEFORE ATTACK
---------------------------------------
local function beforeAttack(e)
    if not config.enabled then
        return
    end

    local mob = e.mobile
    if not mob then
        return
    end

    if not config.npcs and mob.actorType == tes3.actorType.npc then
        return
    end
    if not config.creatures and mob.actorType == tes3.actorType.creature then
        return
    end

    local rw = mob.readiedWeapon
    local weapon

    if rw and rw.object then
        weapon = rw.object
        if weapon.isRanged then
            return
        end
    else
        weapon = { reach = (config.h2hBaseReach / 100) * (config.multiplier / 100) }
    end

    if not weapon.reach then
        return
    end

    local baseReach = weapon.reach
    local bonus = computeReachBonus(mob)

    if e.attackData then
        e.attackData.reach = baseReach + bonus
    end

    if config.debug then
    tes3.messageBox(
        "Base: %.3f | Bonus: %.3f | Final: %.3f",
        baseReach,
        bonus,
        baseReach + bonus
    )
	end
end

---------------------------------------
-- EVENT REGISTRATION
---------------------------------------
event.register(tes3.event.initialized, initialized)
event.register(tes3.event.attackStart, beforeAttack)
