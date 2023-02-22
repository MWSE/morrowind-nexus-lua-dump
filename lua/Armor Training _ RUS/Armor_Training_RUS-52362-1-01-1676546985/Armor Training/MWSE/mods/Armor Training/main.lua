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

    local template = mwse.mcm.createTemplate("Бег в доспехах")

    template.onClose = function()
        if resetConfig then
            resetConfig = false
            config = default_config
        end
        mwse.saveConfig(config_name, config, {indent = false})
    end

    local main_page = template:createSideBarPage({
        label = "Основные настройки",
        description = [[
        Описание настроек.

        Прирост навыка доспехов расчитывется так:

        Пока уровень навыка не достиг первого порога:
        Опыт = экипировано / 40 * Скорость_прокачки / 50 * коэфициент_движения

        Когда уровень навыка выше первого порога:
        Опыт = экипировано / 40 * Скорость прокачки / 50 * коэфициент_движения * коэфициент_первого_порога

        По достижению второго порога опыт от ношения доспехов не увеличивается.

        Где:

        экипировано - сумма надетых частей доспеха (например: Кираса добавляет 0.25)

        Скорость прокачки можно изменять в настройках (по умолчанию: 50)

        коэфициент_движения = (вид_движения/100) * (скорость/50) ^ (влияние_скорости / 100) 

        значение вид_движения можно изменить в настройках для любого типа перемещения.

        влияние_скорости можно изменять в настройках (по умолчанию: 20)

        коэфициент_первого_порога = ((второй_порог - уровень навыка) / (второй_порог - первый_порог)) ^ (Влияние Первого порога / 100)

        Влияние Первого порога можно изменить в настройках (по умолчанию: 100)
        ]]
    })

    local category_main_settings = main_page:createCategory("Основное")
    local movement_types = main_page:createCategory("Виды движения")

    category_main_settings:createSlider{
		label = "Скорость прокачки",
		description = [[
        Влияет на скорость прокачки при хотьбе. Работает, как простой множитель получаемого опыта.

        По умолчанию: 50
        ]],
    variable = mwse.mcm.createTableVariable{ id = "leveling_speed", table = config },
		min = 0, max = 300, step = 1, jump = 5
	}

    category_main_settings:createSlider{
		label = "Первый порог",
		description = [[
        Навык доспехов, начиная с этого значения, получает меньше опыта от движения, вплоть до достижения второго порога. Установленное равным второму порогу отключает замедление прокачки. Установленное равным нулю, замедляет прокачку с самого начала.

        По умолчанию: 25
        ]],
    variable = mwse.mcm.createTableVariable{ id = "soft_cap", table = config },
		min = 0, max = 100, step = 1, jump = 5
	}

    category_main_settings:createSlider{
		label = "Второй порог",
		description = [[
        По достижении этого значения навык доспехов прекращает получать опыт при движении. Установленное равным первому порогу, отключает замедление прокачки. Установленное равным нулю или значению менше, чем первый порог, отключает прокачку навыка при движении.

        По умолчанию: 50
        ]],
    variable = mwse.mcm.createTableVariable{ id = "hard_cap", table = config },
		min = 0, max = 100, step = 1, jump = 5
	}

    category_main_settings:createSlider{
		label = "Влияние Первого порога",
		description = [[
        Влияет на воздействие первого порога. По умолчанию снижение темпов роста остается неизменным. Установите это значение больше 100, чтобы оно снижалось быстрее. Установите его ниже 100, чтобы оно снижалось медленнее. Установка этого значения в 0 отключит воздействие первого порога.

        Например, при значениях первого и второго порога по умолчанию (25 и 50, соответственно):
        
     50 -> 70% от опыта до первого порога на 37 уровне навыка
     100 -> 50% от опыта до первого порога на 37 уровне навыка
     200 -> 25% от опыта до первого порога на 37 уровне навыка

        По умолчанию: 100
        ]],
    variable = mwse.mcm.createTableVariable{ id = "exp_for_soft_cap", table = config },
		min = 0, max = 300, step = 1, jump = 5
	}

    category_main_settings:createSlider{
		label = "Влияние Скорости",
		description = [[
        Влияет на воздействие скорости. По умолчанию, скорость слабо влияет на увеличение опыта. Увеличение этого значения увеличит влияние скорости.
        
        Например, при увеличении скорости от 50 до 100, значения этого параметра приведут к таким результатам:

        20  -> 15%  дополнительного опыта
        50  -> 41%  дополнительного опыта
        100 -> 100% дополнительного опыта

        По умолчанию: 20
        ]],
    variable = mwse.mcm.createTableVariable{ id = "speed_factor_exp", table = config },
		min = 0, max = 200, step = 1, jump = 5
	}

    movement_types:createSlider{
		label = "Коэфициент опыта для хотьбы",
		description = [[
        Влияет на количество опыта при хотьбе в доспехах.

        По умолчанию: 50
        ]],
    variable = mwse.mcm.createTableVariable{ id = "movement_coef_walk", table = config },
		min = 0, max = 300, step = 1, jump = 5
	}

    movement_types:createSlider{
		label = "Коэфицент опыта для бега",
		description = [[
        Влияет на количество опыта при беге в доспехах.

        По умолчанию: 100
        ]],
    variable = mwse.mcm.createTableVariable{ id = "movement_coef_run", table = config },
		min = 0, max = 300, step = 1, jump = 5
	}

    movement_types:createSlider{
		label = "Коэфицент опыта для плаванья",
		description = [[
        Влияет на количество опыта при плаванье в доспехах

        По умолчанию: 200
        ]],
    variable = mwse.mcm.createTableVariable{ id = "movement_coef_swim", table = config },
		min = 0, max = 300, step = 1, jump = 5
	}

    
    mwse.mcm.register(template)
end

event.register('modConfigReady', modConfigReady)