-- Blood Diversity
local DefaultConfig = {
	modEnabled = true,
	arcticBlood = 5,
	ashCreatureBlood = 1,
	crustaceanBlood = 5,
	corprusBlood = 0,
	dwemerBlood = 2,
	daedraBlood = 3,
	elementalBlood = 7,
	fabricantBlood = 2,
	fishBlood = 0,
	ghostBlood = 4,
	goblinBlood = 0,
	insectBlood = 6,
	kwamaBlood = 6,
	mammalBlood = 0,
	netchBlood = 5,
	reptileBlood = 0,
	skeletalBlood = 1,
	specialBlood = 7,
	undeadBlood = 0,
	vampireBlood = 1,
}

local config = mwse.loadConfig("Blood Diversity", DefultConfig)

-- For vampirism we'll use the spell tick event to remove/add as needed.
local function onVampirismTick(e)
	if config.modEnabled then
		local object = e.target.object
		if (e.sourceInstance.state == tes3.spellState.ending) then
			return
		else
			object.blood = config.vampireBlood
		end
	end
end

local function onGhostTick(e)
	if config.modEnabled and config.ghostBlood then
		local object = e.target.object
		if (e.sourceInstance.state == tes3.spellState.ending) then
			return
		else
			object.blood = config.ghostBlood
		end
	end
end

local function onInitialized(e)
	-- Our data doesn't need to be global. It can be garbage collected 
	local data = require("Blood Diversity.data")

	-- For creatures, we only need to do this once at the start.
	if config.modEnabled then
		for object in tes3.iterateObjects(tes3.objectType.creature) do
			local arctic = data.arcticBlood[object.mesh:lower()]
			local ash = data.ashBlood[object.mesh:lower()]
			local crustacean = data.crustaceanBlood[object.mesh:lower()]
			local corprus = data.corprusBlood[object.mesh:lower()]
			local dwemer = data.dwemerBlood[object.mesh:lower()]
			local daedra = data.daedraBlood[object.mesh:lower()]
			local elemental = data.elementalBlood[object.mesh:lower()]
			local fabricant = data.fabricantBlood[object.mesh:lower()]
			local fish = data.fishBlood[object.mesh:lower()]
			local ghost = data.ghostBlood[object.mesh:lower()]
			local goblin = data.goblinBlood[object.mesh:lower()]
			local insect = data.insectBlood[object.mesh:lower()]
			local kwama = data.kwamaBlood[object.mesh:lower()]
			local mammal = data.mammalBlood[object.mesh:lower()]
			local netch = data.netchBlood[object.mesh:lower()]
			local reptile = data.reptileBlood[object.mesh:lower()]
			local skeletal = data.skeletalBlood[object.mesh:lower()]
			local special = data.specialBlood[object.mesh:lower()]
			local undead = data.undeadBlood[object.mesh:lower()]
			if (arctic) then
				object.blood = config.arcticBlood
			elseif (ash) then
				object.blood = config.ashCreatureBlood
			elseif (crustacean) then
				object.blood = config.crustaceanBlood
			elseif (corprus) then
				object.blood = config.corprusBlood
			elseif (dwemer) then
				object.blood = config.dwemerBlood
			elseif (daedra) then
				object.blood = config.daedraBlood
			elseif (elemental) then
				object.blood = config.elementalBlood
			elseif (fabricant) then
				object.blood = config.fabricantBlood
			elseif (fish) then
				object.blood = config.fishBlood
			elseif (ghost) then
				object.blood = config.ghostBlood
			elseif (goblin) then
				object.blood = config.goblinBlood
			elseif (insect) then
				object.blood = config.insectBlood
			elseif (kwama) then
				object.blood = config.kwamaBlood
			elseif (mammal) then
				object.blood = config.mammalBlood
			elseif (netch) then
				object.blood = config.netchBlood
			elseif (reptile) then
				object.blood = config.reptileBlood
			elseif (skeletal) then
				object.blood = config.skeletalBlood
			elseif (special) then
				object.blood = config.specialBlood
			elseif (undead) then
				object.blood = config.undeadBlood
			end
		end
	end

	-- Handle vampires.
	event.register("spellTick", onVampirismTick, { filter = tes3.getObject("vampire attributes") })
	-- Handle Ghost NPCs.
	event.register("spellTick", onGhostTick, { filter = tes3.getObject("ghost ability") })

	mwse.log("Initialized Blood Diversity")
end
event.register("initialized", onInitialized)

-- MCM

local function registerMCM()
	local template = mwse.mcm.createTemplate("Blood Diversity")
	template.onClose = function(self)
		mwse.saveConfig("Blood Diversity", config)
		onInitialized(e)
	end
	
	local page = template:createSideBarPage()
	page.label = "Настройки"
	page.description = "Blood Diversity\n\nBlood Diversity предоставляет новые типы крови для существ Morrowind, Tribunal, Bloodmoon, официальных плагинов и различных модов, основанных на реальном мире и лоре."
	page.noScroll = false
	
	local category = page:createCategory("")
	
	local enableButton = category:createOnOffButton({
		label = "Включить Blood Diversity",
		description = "Включить Blood Diversity\n\nОпределяет, включен ли мод и изменены ли типы крови врагов.\n\nПо-умолчанию: Вкл",
		variable = mwse.mcm:createTableVariable{id = "modEnabled", table = config},
	})
	
	local arcticCreaturesDropdown = category:createDropdown({
		label = "Арктические существа",
		description = "Арктические существа\n\nОпределяет тип крови северных существ, таких как Риклинг, Грахл и Карстааг.\n\nПо-умолчанию: Синяя кровь",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "arcticBlood", table = config}
	})
	
	local arcticCreaturesDropdown = category:createDropdown({
		label = "Пепельные существа",
		description = "Пепельные существа\n\nОпределяет тип крови для существ Шестого Дома, таких как Пепельные Зомби и Спящие.\n\n\nПо-умолчанию: Серая пыль",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "ashCreatureBlood", table = config}
	})
	
	local crustaceanDropdown = category:createDropdown({
		label = "Ракообразные существа",
		description = "Ракообразные существа\n\nОпределяет тип крови у водных существ, таких как Грязекраб и Дреуг.\n\nПо-умолчанию: Синяя кровь",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "crustaceanBlood", table = config}
	})
	
	local corprusDropdown = category:createDropdown({
		label = "Жертвы корпруса",
		description = "Жертвы корпруса\n\nОпределяет тип крови у существ, пораженных божественной болезнью, таких как Ловчий корпруса и Ягрум Багарн.\n\nПо-умолчанию: Красная кровь",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "corprusBlood", table = config}
	})
	
	local dwemerDropdown = category:createDropdown({
		label = "Двемерские автоматоны",
		description = "Двемерские автоматоны\n\nОпределяет тип крови для двемерских анимункулов, таких как Сфера-центурион и Паровой центурион.\n\nПо-умолчанию: Золотые искры",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "dwemerBlood", table = config}
	})
	
	local daedraDropdown = category:createDropdown({
		label = "Даэдра",
		description = "Даэдра\n\nОпределяет тип крови для существ Обливиона, таких как Дремора и Скампы.\n\nПо-умолчанию: Черный ихор",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "daedraBlood", table = config}
	})
	
	local elementalDropdown = category:createDropdown({
		label = "Элементальные существа",
		description = "Элементалные существа\n\nОпределяет тип крови для существ с природными свойствами, таких как Атронахи и Спригганы.\n\nПо-умолчанию: Энергия элементалов",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "elementalBlood", table = config}
	})
	
	local fabricantDropdown = category:createDropdown({
		label = "Фабриканты",
		description = "Фабриканты\n\nОпределяет тип крови для анимункулов Сота Сила.\n\nПо-умолчанию: Золотые искры",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "fabricantBlood", table = config}
	})
	
	local fishDropdown = category:createDropdown({
		label = "Рыба",
		description = "Рыба\n\nОпределяет тип крови у водных существ, таких как Рыба-убийца.\n\nПо-умолчанию: Красная кровь",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "fishBlood", table = config}
	})
	
	local ghostDropdown = category:createDropdown({
		label = "Призраки",
		description = "Призраки\n\nОпределяет тип крови неживых существ, таких как Дух предков, а также призраков-NPC.\n\nПо-умолчанию: Зеленая эктоплазма",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "ghostBlood", table = config}
	})
	
	local goblinDropdown = category:createDropdown({
		label = "Гоблины",
		description = "Гоблины\n\nОпределяет тип крови для связанных с Малакатом существ, таких как гоблины.\n\nПо-умолчанию: Красная кровь",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "goblinBlood", table = config}
	})
	
	local insectDropdown = category:createDropdown({
		label = "Насекомые",
		description = "Насекомые\n\nОпределяет тип крови у инсектоидных существ, таких как Никс-гончая и Шалк.\n\nПо-умолчанию: Оранжевая гемолимфа",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "insectBlood", table = config}
	})
	
	local kwamaDropdown = category:createDropdown({
		label = "Квама",
		description = "Квама\n\nОпределяет тип крови для таких форм Квама, как Квама-Воин и Скриб.\n\nПо-умолчанию: Оранжевая гемолимфа",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "kwamaBlood", table = config}
	})
	
	local mammalDropdown = category:createDropdown({
		label = "Млекопитающие",
		description = "Млекопитающие\n\nОпределяет тип крови у млекопитающих зверей, таких как Медведи и Волки.\n\nПо-умолчанию: Красная кровь",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "mammalBlood", table = config}
	})
	
	local netchDropdown = category:createDropdown({
		label = "Нетч",
		description = "Нетч\n\nОпределяет тип крови Нетчей.\n\nПо-умолчанию: Синяя кровь",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "netchBlood", table = config}
	})
	
	local reptilsDropdown = category:createDropdown({
		label = "Рептилии",
		description = "Рептилии\n\nОпределяет тип крови рептилий, таких как Гуар и Кагути.\n\nПо-умолчанию: Красная кровь",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "reptileBlood", table = config}
	})
	
	local skeletalDropdown = category:createDropdown({
		label = "Скелеты",
		description = "Скелеты\n\nОпределяет тип крови для неживых существ, таких как Лич и Скелет.\n\nПо-умолчанию: Серая пыль",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "skeletalBlood", table = config}
	})
	
	local specialDropdown = category:createDropdown({
		label = "Особые существа",
		description = "Особые существаn\n\nОпределяет тип крови у существ, которых коснулись божественные силы, таких как Дагот Ур и Вивек.\n\nПо-умолчанию: Энергия элементалов",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "specialBlood", table = config}
	})
	
	local undeadDropdown = category:createDropdown({
		label = "Нежить",
		description = "нежить\n\nОпределяет тип крови для зомбиподобной нежити, такой как Ходячий труп и Костяной волк.\n\nПо-умолчанию: Красная кровь",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "undeadBlood", table = config}
	})
	local vampireDropdown = category:createDropdown({
		label = "Вампиры",
		description = "Вампиры\n\nОпределяет тип крови для NPC, зараженных вампиризмом.\n\nПо-умолчанию: Серая пыль",
		options = {
			{label = "Красная кровь", value = 0},
			{label = "Серая пыль", value = 1},
			{label = "Золотые искры", value = 2},
			{label = "Черный ихор", value = 3},
			{label = "Зеленая эктоплазма", value = 4},
			{label = "Синяя кровь", value = 5},
			{label = "Оранжевая гемолимфа ", value = 6},
			{label = "Энергия элементалов", value = 7},
		},
		variable = mwse.mcm:createTableVariable{id = "vampireBlood", table = config}
	})
	
	mwse.mcm.register(template)
end

event.register("modConfigReady", registerMCM)