-- Модуль, отвечающий за отключение Луи Чернозема. Если модуля нет - Луи на месте со старта игры.
pcall(require, "Less Annoying Solstheim Rumors & Delay.louis_beauchamp")
-- Модуль, устанавливающий и проверяющий наши условия для диалогов
local checkConditions = require("Less Annoying Solstheim Rumors & Delay.checkConditions")

-- ID диалогов, которые нам нужны
local targetIds = {
    -- "свежие сплетни"
    ["6923112947019593"] = true, -- Сын переведен в Солтсхейм
    ["3103210864206706477"] = true, -- Империя дала разрешение на добычу
    ["29678150921094025770"] = true, -- В Форте какие-то проблемы

    -- "Солстхейм"
    ["2278720479126556737"] = true, -- Ужасное место
    ["2798917491184915920"] = true, -- Там есть Имперский форт
    ["1169922125955110917"] = true, -- Промерзлый остров на севере
    ["3095424884419930413"] = true, -- Ужасное место. Слишком холодно
}

local function onInfoFilter(e)
    -- Диалоги, которые движок отбрасывает до нас. Не трогаем
    if not e.passes then return end

    local dialogueId = e.info.id
    -- Оставшися диалоги. Не трогаем те, которые нам не нужны
    if not targetIds[dialogueId] then return end

    local speaker = e.reference

    -- Непрошедшие наши условия - блокируем
    if not checkConditions(dialogueId, speaker) then
        e.passes = false
        return
    end
end

local function onInitialized()
    event.register("infoFilter", onInfoFilter)
end
event.register("initialized", onInitialized)