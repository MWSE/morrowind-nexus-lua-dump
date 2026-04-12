local i18n = mwse.loadTranslations("MWSE Dark Brotherhood Delayed")

-- Блокируем оригинальный скрипт
local function stopDBAttackScript()
    local script = "dbattackScript"
    if tes3.getLegacyScriptRunning({ script = script }) then
        tes3.stopLegacyScript({ script = script })
    end
end

local function onSleepInterrupt()
    tes3.messageBox(i18n("on_interrupt_message"))
end

local stopAttacks

local function getSafeSpawnPosition(sideOffset)
    local player = tes3.player
    local distance = 128
    -- Направление назад
    local direction = player.forwardDirection * -1

    -- Пускаем луч чуть выше уровня пола
    local ray = tes3.rayTest({
        position = player.position + (player.rightDirection * sideOffset) + tes3vector3.new(0, 0, 20),
        direction = direction,
        maxDistance = distance,
        ignore = { player }
    })

    -- Если луч во что-то попал, берем точку удара и чуть отступаем назад к игроку
    if ray and ray.intersection then
        return ray.intersection + (player.forwardDirection * 30)
    end

    -- Если препятствий нет, просто возвращаем точку на полной дистанции
    return player.position + (direction * distance) + (player.rightDirection * sideOffset)
end

local function checkRest(e)
    stopDBAttackScript()
    -- Если Архиканоник еще не готов говорить с вами, И Дагот Ур не убит - атак быть не должно
    if tes3.getJournalIndex({id = "B8_MeetVivec"}) < 5
        and tes3.getJournalIndex({id = "C3_DestroyDagoth"}) < 50 then
        return
    end

    -- Если мы начали работать на Тьениуса - прекращаем атаки
    if tes3.getJournalIndex({id = "TR05_People"}) >= 1 then
        stopAttacks()
        return
    end

    -- Инициализация данных игрока для хранения количества атак
    tes3.player.data.dbAttackInfo = tes3.player.data.dbAttackInfo or { attacksCarried = 0, assassinsCount = 0 }
    local data = tes3.player.data.dbAttackInfo

    -- Определение параметров атаки в зависимости от уровня персонажа
    local playerLevel = tes3.player.object.level
    local difficultyLevel, baseSpawnChance, assassinId
    if playerLevel >= 30 then
        difficultyLevel, baseSpawnChance, assassinId = 5, 90, "db_assassin4"
    elseif playerLevel >= 20 then
        difficultyLevel, baseSpawnChance, assassinId = 4, 70, "db_assassin3"
    elseif playerLevel >= 10 then
        difficultyLevel, baseSpawnChance, assassinId = 3, 50, "db_assassin2"
    elseif playerLevel >= 4 then
        difficultyLevel, baseSpawnChance, assassinId = 2, 40, "db_assassin1"
    else
        difficultyLevel, baseSpawnChance, assassinId = 1, 20, "db_assassin1b"
    end

    -- Определяем, будем ли спавним ассасинов
    local roll100 = math.random(100)
    local finalSpawnChance = baseSpawnChance - (data.attacksCarried * 10)
    if roll100 > finalSpawnChance then return end

    -- Количество ассасинов
    if difficultyLevel >= 4 then
        data.assassinsCount = math.min(data.assassinsCount + 1, 2)
    else
        data.assassinsCount = 1
    end

    -- Остановка сна и сообщение
    e.interrupted = true
    onSleepInterrupt()

    -- Спавн ассасинов
    local sideOffset = 0
    for _ = 1, data.assassinsCount do
        local spawnPosition = getSafeSpawnPosition(sideOffset)

        local assassin = tes3.createReference({
            object = assassinId,
            position = spawnPosition,
            orientation = tes3.player.orientation:copy(),
            cell = tes3.player.cell
        })

        -- Смещение каждого следующего ассасина чуть в сторону
        sideOffset = sideOffset + 40
        -- Заставляем искать игрока
        assassin.mobile:startCombat(tes3.player.mobile)
    end

    -- Обновляем количество проведенных атак
    data.attacksCarried = data.attacksCarried + 1
    if data.attacksCarried > 8 then -- Максимальное количество нападений достигнуто
        stopAttacks()
        return
    end

    -- Установка глобальной переменной для самой игры. Наверное связана установкой 10, но само не включает
    tes3.setGlobal("DBAttack", 1)
    -- Обновление журнала, если еще не было сделано
    if tes3.getJournalIndex({id = "TR_dbAttack"}) < 10 then
        tes3.updateJournal({id = "TR_DBAttack", index = 10})
    end
end

local function startAttacks()
    event.register("calcRestInterrupt", checkRest)
end

function stopAttacks()
    event.unregister("calcRestInterrupt", checkRest)
end

local function onInitialized()
    startAttacks()
end
event.register("initialized", onInitialized)