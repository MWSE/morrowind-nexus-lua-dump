local translations = {
    chooseEffects = "Выбрать эффекты",
    chosenEffect = "Выбранные эффекты:",

    sortBy = "Отсортировать по:",
    sortName = "Названию",
    sortCount = "Количеству",
    sortWeight = "Весу",
    sortValue = "Стоимости",

    filterBy = "Отфильтровать по:",
    filterNone = "Отмена",
    filterMatching = "Схожим эффектам",
}

translations.mcm = {
    modName = "Алхимический фильтр",
    settings  = "Настройки",

    modEnabled = {
        label = "Включение мода",
        desc = "Включение или выключение мода и всех его функций.",
    },

    chosenEffectSticky = {
        label = "Сохранение фильтрации ингредиентов",
        desc = "Если включено, то фильтрация ингредиентов в меню алхимии сохранится до следующего открытия этого меню.",
    },

    sortSticky = {
        label = "Сохранение сортировки ингредиентов",
        desc = "Если включено, то сортировка ингредиентов в меню алхимии сохранится до следующего открытия этого меню.",
    },

    chooserHeight = {
        label = "Высота панели эффектов",
        desc = "Указывает высоту панели эффектов, которая появляется после нажатия кнопки " .. translations.chooseEffects .. ".",
    },
}

-- Taken from tes3.attributeName
translations.attribute = {
	["strength"] = "Силу",
	["intelligence"] = "Интеллект",
	["willpower"] = "Силу волу",
	["agility"] = "Ловкость",
	["speed"] = "Скорость",
	["endurance"] = "Выносливость",
	["personality"] = "Привлекательность",
	["luck"] = "Удачу",
}

-- Taken from tes3.skillName
translations.skill = {
	["Block"] = "Защиту",
	["Armorer"] = "Кузнеца",
	["Medium Armor"] = "Средние доспехи",
	["Heavy Armor"] = "Тяжелые доспехи",
	["Blunt Weapon"] = "Дробящее оружие",
	["Long Blade"] = "Длинные клинки",
	["Axe"] = "Секиры",
	["Spear"] = "Древковое оружие",
	["Athletics"] = "Атлетику",
	["Enchant"] = "Зачарование",
	["Destruction"] = "Разрушение",
	["Alteration"] = "Изменение",
	["Illusion"] = "Иллюзии",
	["Conjuration"] = "Колдовство",
	["Mysticism"] = "Мистицизм",
	["Restoration"] = "Восстановление",
	["Alchemy"] = "Алхимию",
	["Unarmored"] = "Бездоспешный бой",
	["Security"] = "Безопасность",
	["Sneak"] = "Скрытность",
	["Acrobatics"] = "Акробатику",
	["Light Armor"] = "Легкие доспехи",
	["Short Blade"] = "Короткие клинки",
	["Marksman"] = "Меткость",
	["Mercantile"] = "Торговлю",
	["Speechcraft"] = "Красноречие",
	["Hand to Hand"] = "Рукопашный бой",
}

return translations
