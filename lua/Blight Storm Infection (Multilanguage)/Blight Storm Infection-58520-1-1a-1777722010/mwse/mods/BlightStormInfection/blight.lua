local config = require("BlightStormInfection.config")
local i18n = config.i18n

-- Список ID моровых болезней
local blightDiseases = {
    "ash-chancre",
    "black-heart blight",
    "chanthrax blight",
    "ash woe blight"
}

local function checkDiseases(player)
    -- Собираем список болезней, которыми персонаж еще не болен
    local availableDiseases = {}

	for _, id in ipairs(blightDiseases) do
		if not tes3.hasSpell({ reference = player, spell = id }) then
			table.insert(availableDiseases, id)
		end
	end

	-- Выбираем случайно одну из отсутствующих болезней
	local diseaseObj
    if #availableDiseases > 0 then
        local diseaseID = availableDiseases[math.random(#availableDiseases)]
		diseaseObj = tes3.getObject(diseaseID)
	end

	return diseaseObj
end

local function onInfection(diseaseObj)
	tes3.messageBox(
		i18n("on_infection", { diseaseName = diseaseObj.name })
	)
end

local function infectPlayer(player)
	-- Ищем болезнь, которой еще нет у персонажа
	local diseaseObj = checkDiseases(player)

	-- Применяем болезнь к персонажу
    if diseaseObj then
        tes3.addSpell({ reference = player, spell = diseaseObj })
		onInfection(diseaseObj)
	end
end

local function calculateHelmetMultiplier(player)
	local helmetMultiplier = 1.0

    -- 1. Если множитель 1.0, то не нужно проверять шлем и можно сразу вернуть результат
    if config.base.helmetMultiplier == 1.0 then
        return helmetMultiplier
    end

    -- 2. Проверяем экипирован ли шлем
	local equippedHelmet = tes3.getEquippedItem({
        actor = player, 
        objectType = tes3.objectType.armor,
        slot = tes3.armorSlot.helmet
    })

    if not equippedHelmet then
		return helmetMultiplier
	end

    -- 3. Проверка наличия частей брони
    local armor = equippedHelmet.object
    if not armor.parts then
        return helmetMultiplier
    end

    -- 4. Проверяем, является ли шлем закрытым (заменяет часть тела head)
    for _, part in ipairs(armor.parts) do
        if part.type == tes3.activeBodyPart.head then
            return config.base.helmetMultiplier
        end
    end

	return helmetMultiplier
end

local function onAttemptedInfection(finalChance, roll)
	-- Оповещение о попытке заражения
	if config.base.displayInfectionAttempts then
		tes3.messageBox(i18n("roll_info", { chance = string.format("%.2f", finalChance), roll = math.floor(roll) }))
	end
end

local blight = {}
function blight.checkBlightInfection()
    local player = tes3.player
	if not player then return end

    local mobile = tes3.mobilePlayer
	if not mobile then return end

    -- 1. Проверка: находится ли персонаж на улице
	local cell = tes3.getPlayerCell()
	if not cell or cell.isInterior then return end

	-- 2. Проверка погоды (ID 7 — Blight / Моровая буря)
	local weather = tes3.getCurrentWeather()
	if not (weather and weather.index == 7) then return end

    -- 3. Проверка на иммунитет
    local resist = mobile.resistBlightDisease
    if resist >= 100 then return end

    -- 4. Расчет шанса
    local baseChance = config.base.baseChance
	-- Проверка на наличие закрытого шлема
    local helmetMultiplier = calculateHelmetMultiplier(player)

    local finalChance = baseChance * (1 - (resist / 100)) * helmetMultiplier

	-- 5. Пытаемся заразить
    local roll = math.random() * 100
	onAttemptedInfection(finalChance, roll)

	-- 6. Если попали в шанс - заражаем персонажа
    if roll <= finalChance then
		infectPlayer(player)
    end
end

return blight