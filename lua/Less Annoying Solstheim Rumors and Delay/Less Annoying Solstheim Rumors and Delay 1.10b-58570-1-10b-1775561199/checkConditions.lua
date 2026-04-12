local config = require("Less Annoying Solstheim Rumors & Delay.config")
-- Модуль, проверяющий, находится ли игрок в Морнхолде. Если модуль недоступен, то считаем, что игрок не в Морнхолде
local isMournholdModuleAvailable, getIsInMournhold = pcall(require,
    "Less Annoying Solstheim Rumors & Delay.checkIsInMournhold")

local function getSpeakerFaction(speaker)
    return speaker.object.faction and speaker.object.faction.id
end

local function getSpeakerFactionRank(speaker)
    return speaker.object.factionRank
end

local function getSpeakerRace(speaker)
    return speaker.object.race.id
end

local function isMatchingClass(speaker, className)
    return speaker.object.class.id == className
end

local function isAgent(speaker)
    return isMatchingClass(speaker, "Agent")
end

local function isCommonerOrPublican(speaker)
    return isMatchingClass(speaker, "Commoner") or isMatchingClass(speaker, "Publican")
end

local function isCaravanerOrShipmaster(speaker)
    return isMatchingClass(speaker, "Caravaner") or isMatchingClass(speaker, "Shipmaster")
end

-- Отдельной функцией, потому что за один диалог infoFilter срабатывает несколько раз
local roll100
event.register("uiActivated", function(e)
    if e.element.name == "MenuDialog" then
        roll100 = math.random(100)
    end
end)

local function hasSonOnSolstheim(speaker)
    if (roll100 > config.hasSonOnSolstheimChance) then return false end

    local faction = getSpeakerFaction(speaker)
    if faction  -- если это Рыцарь Имперского Легиона
        and (faction == "Imperial Legion")
        and (getSpeakerFactionRank(speaker) > 4) then
        return false
    end

    return true
end

local function canDiscussNewMine(speaker)
    if (roll100 > config.canDiscussNewMineChance) then return false end
    if not isCommonerOrPublican(speaker) then return false end

    return true
end

local function checkAgentRumor(speaker)
    if not isAgent(speaker) then return false end
    if (roll100 > config.agentRumorChance) then return false end

    return true
end

local function checkIsDunmerComOrPub(speaker)
    if (tes3.getJournalIndex({id = "BM_Rumors"}) ~= 10) then return false end
    if not (getSpeakerRace(speaker) == "Dark Elf") then return false end
    if not isCommonerOrPublican(speaker) then return false end

    return true
end

-- Таблица соответствий ID диалогов и функций, которые проверяют условия для этих диалогов.
local dialogues = {
    -- Стадии квеста "Остров на севере": 0, 10 - я слышал слухи, 50 - в Хууле есть лодка, 100 - я прибыл на Солстхейм.

    -- "свежие сплетни". Открывают топик "Солстхейм"
    -- Случайный имперец может рассказать о сыне-легионере, который переведен в Солстхейм (если он сам не рыцарь)
    -- Условия CS: Imperial, BM_Rumors < 10, NoLore == 0. Set BM_Rumors = 10
    ["6923112947019593"] = hasSonOnSolstheim,
    -- Данмер-обыватель/трактирщик расскажет о том, что Империя дала разрешение на добычу ресурсов на Солстхейме
    -- Условия CS: Dark Elf, BM_Rumors == 10, NoLore == 0
    ["3103210864206706477"] = canDiscussNewMine,
    -- Агент расскажет о том, что в Форте какие-то проблемы
    -- Условия CS: BM_Rumors < 50, NoLore == 0. Set BM_Rumors = 10
    ["29678150921094025770"] = checkAgentRumor,

    -- "Солстхейм".
    -- Караванщик/корабельщик расскажет, что в Хууле есть лодка.
    -- Условия CS: BM_Rumors >= 50
    ["2278720479126556737"] = isCaravanerOrShipmaster,
    -- Данмер-обыватель/трактирщик расскажет, что в Хууле должна быть лодка.
    -- Условия CS: BM_Rumors < 50. Set BM_Rumors = 50
    ["2798917491184915920"] = checkIsDunmerComOrPub, -- Disp 70
    ["1169922125955110917"] = checkIsDunmerComOrPub, -- Disp 40
    ["3095424884419930413"] = checkIsDunmerComOrPub
}

-- Наши условия дял каждого интересующего нас диалога
local function checkConditions(id, speaker)
    if tes3.player.object.level <= config.requiredPlayerLevel then return false end

    -- Проверка на Солстхейм не нужна - там у всех (вроде бы) noLore
    if config.checkIsInMournhold and isMournholdModuleAvailable then
        if getIsInMournhold() then return false end
    end

    return dialogues[id](speaker)
end

return checkConditions