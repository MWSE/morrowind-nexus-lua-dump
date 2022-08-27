local default_config = {
    soft_cap = 25,
    hard_cap = 50,
    exp_for_soft_cap = 100,
    leveling_speed = 50,
    movement_coef_walk = 50,
    movement_coef_run = 100,
    movement_coef_swim = 200,
    speed_factor_exp = 20
}

local config_name = "Armor Training"
local config = mwse.loadConfig(config_name, default_config)
local EasyMCM = require("easyMCM.EasyMCM")

version = "1.0"

-- Slightly edited compared to Nimble Armor for more immersion
armorParts = {
	[0] = 0.05,	-- helmet
	[1] = 0.25,	-- cuirass
	[2] = 0.05, -- left pauldron
	[3] = 0.05, -- right pauldron
	[4] = 0.2, -- greaves
	[5] = 0.25, -- boots
	[6] = 0.05, -- left gauntlet
	[7] = 0.05, -- right gauntlet
	[8] = 0.05	-- shield
--	[9] = 0.05, -- left bracer uses the same value as left gauntlet
--	[10] = 0.05 -- right bracer uses the same value as right gauntlet
}

local function get_armor_coefs(armored_actor)
  local armor = {light = 0, medium = 0, heavy = 0}
	if armored_actor == nil then -- check for disabled actors
		return armor
	end
	for i, value in pairs(armorParts) do
		local stack = tes3.getEquippedItem{actor = armored_actor, objectType = tes3.objectType.armor, slot = i}
		if i == tes3.armorSlot.leftGauntlet or i == tes3.armorSlot.rightGauntlet then	-- if no gloves - check for bracers
			if not stack then stack = tes3.getEquippedItem{actor = armored_actor, objectType = tes3.objectType.armor, slot = i+3} end
		end
		if stack then
			local item = stack.object
			if item.weightClass == 0 then
				armor.light = armor.light + value
			elseif item.weightClass == 1 then
				armor.medium = armor.medium + value
			elseif item.weightClass == 2 then
				armor.heavy = armor.heavy + value
			end
		end
	end
  return armor
end

local function movement_check()
    if config.hard_cap < config.soft_cap then return end -- protection against stupid changes
    local base_const = 40 -- 1/40 of a point per sec of running on low skill, in full armor with default settings
	if tes3.mobilePlayer.isWalking or tes3.mobilePlayer.isRunning or tes3.mobilePlayer.isSwimming then
        local armor_worn = get_armor_coefs(tes3.mobilePlayer)
        local armor_skill = {light = tes3.mobilePlayer.lightArmor.current, medium = tes3.mobilePlayer.mediumArmor.current, heavy = tes3.mobilePlayer.heavyArmor.current}
        local softcap_coef

        local movement_coef = config.movement_coef_run / 100
        if tes3.mobilePlayer.isWalking then 
            movement_coef = config.movement_coef_walk / 100
        elseif tes3.mobilePlayer.isSwimming then
            movement_coef = config.movement_coef_swim / 100
        end

        movement_coef = movement_coef * math.pow (tes3.mobilePlayer.speed.current / 50, config.speed_factor_exp / 100 ) -- slight impact of speed by default, faster = quicker leveling (very subtle)

		if armor_worn.light > 0 and armor_skill.light < config.hard_cap then
            if armor_skill.light < config.soft_cap then
                tes3.mobilePlayer:exerciseSkill(21, armor_worn.light / base_const * config.leveling_speed / 50 * movement_coef)
            else
                softcap_coef = math.pow((config.hard_cap - armor_skill.light) / (config.hard_cap - config.soft_cap), (config.exp_for_soft_cap / 100))
                tes3.mobilePlayer:exerciseSkill(21, armor_worn.light / base_const * config.leveling_speed / 50 * softcap_coef * movement_coef)
            end
        end
        if armor_worn.medium > 0 and armor_skill.medium < config.hard_cap then
            if armor_skill.medium < config.soft_cap then
                tes3.mobilePlayer:exerciseSkill(2, armor_worn.medium / base_const * config.leveling_speed / 50 * movement_coef)
            else
                softcap_coef = math.pow((config.hard_cap - armor_skill.medium) / (config.hard_cap - config.soft_cap), (config.exp_for_soft_cap / 100))
                tes3.mobilePlayer:exerciseSkill(2, armor_worn.medium / base_const * config.leveling_speed / 50 * softcap_coef * movement_coef)
            end
        end
        if armor_worn.heavy > 0 and armor_skill.heavy < config.hard_cap then
            if armor_skill.heavy < config.soft_cap then
                tes3.mobilePlayer:exerciseSkill(3, armor_worn.heavy / base_const * config.leveling_speed / 50 * movement_coef)
            else
                softcap_coef = math.pow((config.hard_cap - armor_skill.heavy) / (config.hard_cap - config.soft_cap), (config.exp_for_soft_cap / 100))
                tes3.mobilePlayer:exerciseSkill(3, armor_worn.heavy / base_const * config.leveling_speed / 50 * softcap_coef * movement_coef)
            end
        end
	end
end

local function onLoaded()
	timer.start({iterations = -1, duration = 1, callback = movement_check, type = timer.simulate })
end


local function initialized()
    event.register("loaded", onLoaded)
    print(string.format("[Vengyre] Armor Training initialized. Version: %s.", version))
end

event.register("initialized", initialized)

local resetConfig = false

local function modConfigReady()

    local template = mwse.mcm.createTemplate("Armor Training")

    template.onClose = function()
        if resetConfig then
            resetConfig = false
            config = default_config
        end
        mwse.saveConfig(config_name, config, {indent = false})
    end

    local main_page = template:createSideBarPage({
        label = "Main Settings",
        description = [[
        Armor Training settings menu.

        Experience gain per second is as follows:

        Before softcap value of a skill:
        XP Gain = armor_worn / 40 * leveling speed / 50 * movement_coef

        After softcap value of a skill:
        XP Gain = armor_worn / 40 * leveling speed / 50 * movement_coef * softcap_coef

        No experience gain after hardcap value of a skill.

        Where:

        armor_worn is the fraction of armor worn (e.g. Cuirass contributes 0.25)

        leveling speed can be tweaked directly (default: 50)

        movement_coef = (movement type multiplier/100) * (speed/50) ^ (exponential factor for speed / 100) 

        movement type multiplier can vary for walking, running, and swimming (configurable)
        exponential factor for speed can be tweaked directly (default: 20)

        softcap_coef = ((hard cap - skill value) / (hard cap - soft cap)) ^ (exponential factor for soft cap / 100)

        exponential factor for soft cap can be tweaked (default: 100)
        ]]
    })

    local category_main_settings = main_page:createCategory("Main")
    local movement_types = main_page:createCategory("Movement Types")

    category_main_settings:createSlider{
		label = "Leveling Speed",
		description = [[
        Affects the leveling speed from walking. Works as a flat multiplier to experience gained.

        Default: 50
        ]],
    variable = mwse.mcm.createTableVariable{ id = "leveling_speed", table = config },
		min = 0, max = 300, step = 1, jump = 5
	}

    category_main_settings:createSlider{
		label = "Softcap Value",
		description = [[
        Armor skills at and above this value will gain less experience from movement, up until the hardcap value. Set equal to hardcap to remove the gradual slowdown. Set to 0 to have leveling slowdown begin straight away.

        Default: 25
        ]],
    variable = mwse.mcm.createTableVariable{ id = "soft_cap", table = config },
		min = 0, max = 100, step = 1, jump = 5
	}

    category_main_settings:createSlider{
		label = "Hardcap Value",
		description = [[
        Armor skills at and above this value will gain no experience from movement. Set equal to softcap to remove the gradual slowdown. Set to 0 to disable the mod. Setting it below the softcap also disables the mod.

        Default: 50
        ]],
    variable = mwse.mcm.createTableVariable{ id = "hard_cap", table = config },
		min = 0, max = 100, step = 1, jump = 5
	}

    category_main_settings:createSlider{
		label = "Exponential Factor for Softcap",
		description = [[
        Affects the softcap impact. By default, growth decline is flat. Set this value above 100 to have it decline faster. Set it below 100 to have it decline slower. Setting this to 0 effectively disables the soft cap.

        Examples (with default soft and hard caps, 25 and 50 respectively):
        
        50 -> 70% of non-softcapped exp gained at 37 skill
        100 -> 50% of non-softcapped exp gained at 37 skill
        200 -> 25% of non-softcapped exp gained at 37 skill

        Default: 100
        ]],
    variable = mwse.mcm.createTableVariable{ id = "exp_for_soft_cap", table = config },
		min = 0, max = 300, step = 1, jump = 5
	}

    category_main_settings:createSlider{
		label = "Exponential Factor for Speed",
		description = [[
        Affects the speed impact. By default, Speed slightly affects the leveling speed from movement. Increase this value to increase the Speed impact.
        
        Examples:

        20 -> 15% extra gain with 100 Speed vs 50 Speed
        50 -> 41% extra gain with 100 Speed vs 50 Speed
        100 -> 100% extra gain with 100 Speed vs 50 Speed

        Default: 20
        ]],
    variable = mwse.mcm.createTableVariable{ id = "speed_factor_exp", table = config },
		min = 0, max = 200, step = 1, jump = 5
	}

    movement_types:createSlider{
		label = "Movement Coeficient for Walking",
		description = [[
        Affects the amount of experience gained from walking in armor.

        Default: 50
        ]],
    variable = mwse.mcm.createTableVariable{ id = "movement_coef_walk", table = config },
		min = 0, max = 300, step = 1, jump = 5
	}

    movement_types:createSlider{
		label = "Movement Coeficient for Running",
		description = [[
        Affects the amount of experience gained from running in armor.

        Default: 100
        ]],
    variable = mwse.mcm.createTableVariable{ id = "movement_coef_run", table = config },
		min = 0, max = 300, step = 1, jump = 5
	}

    movement_types:createSlider{
		label = "Movement Coeficient for Swimming",
		description = [[
        Affects the amount of experience gained from swimming in armor.

        Default: 200
        ]],
    variable = mwse.mcm.createTableVariable{ id = "movement_coef_swim", table = config },
		min = 0, max = 300, step = 1, jump = 5
	}

    
    mwse.mcm.register(template)
end

event.register('modConfigReady', modConfigReady)