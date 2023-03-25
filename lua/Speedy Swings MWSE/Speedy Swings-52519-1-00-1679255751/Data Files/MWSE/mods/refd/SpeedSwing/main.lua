-- The function to call on the initialized event.
local function initialized() -- 1.

    -- Print a "Ready!" statement to the MWSE.log file.
    print("Speedy Swings Initialized") --2.
end

local config = mwse.loadConfig("SpeedSwingConfig") or {
enabled = true,
npcs = true,
creatures = true,
penalty = true,
handtoHandBonus = false,
magnitude = 100,
threshold = 50,
speedCap = false,
capValue = 50,
}

local function registerModConfig()
    EasyMCM = require("easyMCM.EasyMCM")
    local template = EasyMCM.createTemplate("Speedy Swings")
    template:saveOnClose("SpeedSwingConfig", config)
    local page = template:createSideBarPage{label="Settings"}
	page.sidebar:createInfo{
	text = "Speedy Swings by Refolde. A MSWE mod that allows an actor's Speed stat to influence their weapon swing and bow draw speeds."
	}
	page:createOnOffButton{
    label = "Enable Mod?",
    variable = EasyMCM.createTableVariable{
        id = "enabled",
        table = config
    }
}
	page:createOnOffButton{
    label = "Affect NPCs?",
	description = "Whether or not NPCs will be affected by this mod",
    variable = EasyMCM.createTableVariable{
        id = "npcs",
        table = config
    }
}
	page:createOnOffButton{
    label = "Affect creatures?",
	description = "Whether or not creatures will be affected by this mod",
    variable = EasyMCM.createTableVariable{
        id = "creatures",
        table = config
    }
}
	page:createOnOffButton{
    label = "Low Speed Penalty",
	description = "Whether or not having low speed (below the stat threshold set in the settings) will penalize swing speed. If disabled, vanilla swing speeds will be the slowest you can go.",
    variable = EasyMCM.createTableVariable{
        id = "penalty",
        table = config
    }
}
	page:createOnOffButton{
    label = "Hand to Hand Bonus",
	description = "Whether or not to give Hand to Hand a fatigue damage bonus based on speed (above threshold) to make up for the fact that its speed is not affected by the mod. Really really optional.",
    variable = EasyMCM.createTableVariable{
        id = "handtoHandBonus",
        table = config
    }
}
	page:createSlider{
		label = "Magnitude",
		description = "Determines how much each point of the speed stat affects swing speed. 100 is the default value. Lower values means Speed has less impact, higher values means more.",
		min = 1,
        max = 200,
        step = 1,
        jump = 10,
		variable = mwse.mcm.createTableVariable{
		id = "magnitude",
			table = config
		}
	}
	page:createSlider{
		label = "Threshold",
		description = "What value your Speed should be to be at 'vanilla' swing speeds. 50 Speed is the default value. Anything below will be slower, above will be faster.",
		min = 1,
        max = 100,
        step = 1,
        jump = 10,
		variable = mwse.mcm.createTableVariable{
		id = "threshold",
			table = config
		}
	}
	page:createOnOffButton{
    label = "Speed Cap",
	description = "Enabling this puts a cap on how much Speed will affect your weapon swings, meaning your Speed stat will stop contributing to weapon swings after a certain point.",
    variable = EasyMCM.createTableVariable{
        id = "speedCap",
        table = config
    }
}
	page:createSlider{
		label = "Cap Value",
		description = "Only works if Speed Cap is enabled. Cap Value is a value that is added to the Threshold to determine when points in Speed stop contributing to attack speed. For example, a threshold of 50 and a Cap Value of 35 would cap the speed at 85.",
		min = 1,
        max = 200,
        step = 1,
        jump = 10,
		variable = mwse.mcm.createTableVariable{
		id = "capValue",
			table = config
		}
	}
    EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)



local function beforeAttack(e)
if config.enabled == false then return end
if config.npcs == false and e.mobile.actorType == 1 then return end
if config.creatures == false and e.mobile.actorType == 0 then return end
local speedValue = e.mobile.speed.current
if config.speedCap == true then
local maxSpeed = config.threshold + config.capValue
if speedValue > maxSpeed then
speedValue = maxSpeed
end
end
local thresholdModifier = (1 - (config.threshold / 100))
local formula = (thresholdModifier + (speedValue / 100))
if config.penalty == false and formula < 1 then return end
local magnitudeModifier = (1 + ((formula - 1 ) * (config.magnitude / 100)))
	e.attackSpeed = e.attackSpeed * magnitudeModifier 
end

local function handToHand(e)
if config.handtoHandBonus == false then return end
if config.npcs == false and e.attacker.actorType == 1 then return end
if e.attacker.actorType == 0 then return end
local formula = ((1 - (config.threshold / 100)) + (e.attacker.speed.current / 100))
if formula < 1 then return end
e.fatigueDamage = e.fatigueDamage * formula
end

-- Register our initialized function to the initialized event.
event.register(tes3.event.initialized, initialized) --3.
event.register(tes3.event.attackStart, beforeAttack)
event.register(tes3.event.damageHandToHand, handToHand)