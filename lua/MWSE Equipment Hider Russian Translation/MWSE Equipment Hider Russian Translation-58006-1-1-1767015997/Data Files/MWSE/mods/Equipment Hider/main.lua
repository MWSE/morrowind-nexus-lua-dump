local modName = "Equipment Hider"
local config = mwse.loadConfig(modName, {blocked = {}})

local slotNames = {
    ["helmet"] = "Шлем",
    ["cuirass"] = "Кираса",
    ["leftPauldron"] = "Левый наплечник",
    ["rightPauldron"] = "Правый наплечник",
    ["greaves"] = "Поножи",
    ["boots"] = "Ботинки",
    ["leftGauntlet"] = "Левая перчатка",
    ["rightGauntlet"] = "Правая перчатка",
    ["shield"] = "Щит",
    ["leftBracer"] = "Левый наруч",
    ["rightBracer"] = "Правый наруч",
    
    ["pants"] = "Штаны",
    ["shoes"] = "Обувь",
    ["shirt"] = "Рубашка",
    ["belt"] = "Пояс",
    ["robe"] = "Мантия",
    ["rightGlove"] = "Правая перчатка",
    ["leftGlove"] = "Левая перчатка",
    ["skirt"] = "Юбка",
    ["ring"] = "Кольцо",
    ["amulet"] = "Амулет",

    ["Backpack"] = "Рюкзак",-- The Crafting Framework
    ["hat"] = "Шляпа",-- Tamriel Data
}
local function getTranslatedSlotName(slotId)
    return slotNames[slotId] or slotId
end

-- Функция для создания mcmConfig с русскими названиями
local function createMcmConfig()
    local mcmConfig = { blocked = {} }
    for slotId in pairs(config.blocked) do
        local russianName = slotNames[slotId] or slotId  -- Используем перевод или ID
        mcmConfig.blocked[russianName] = true
    end
    return mcmConfig
end

local mcmConfig = createMcmConfig()

local reverseSlotNames = {}
for id, russian in pairs(slotNames) do
    reverseSlotNames[russian] = id
end

local function saveConfigFromMcm()
    -- Очищаем config.blocked
    config.blocked = {}
    
    -- Конвертируем русские названия обратно в ID
    for russianName, blocked in pairs(mcmConfig.blocked) do
        if blocked then  -- Добавляем только если действительно заблокирован
            local slotId = reverseSlotNames[russianName] or russianName
            config.blocked[slotId] = true
        end
    end
    
    mwse.saveConfig(modName, config)
end

local tHW = {2, 4, 5, 6, 8, 9, 10}
local rHP = {3, 4, 5, 11, 12, 13, 14, 19, 20, 21, 22}
local sHP = {4, 21, 22}
local rHAP = {11, 12, 13, 14}
local aBPTB = {}
local bPTB = {}
local bPTC = {}
local bPTA = {}
local bPTL = {[0] = bPTB, [1] = bPTC, [2] = bPTA}

local function oBPA(e)
    if not (e.reference == tes3.player or e.reference == tes3.player1stPerson) then
        return
    end

    if not bPTB[e.index] then
        if not e.object and e.bodyPart and e.bodyPart.partType == 0 then
            bPTB[e.index] = e.bodyPart
            aBPTB[e.index] = e.manager:getActiveBodyPart(0, e.index)
        end
    end

    if e.object then
        local slot
        if e.object.objectType == tes3.objectType.clothing then
            slot = table.find(tes3.clothingSlot, e.object.slot)
            if (e.bodyPart and e.bodyPart.partType == 1) and (slot and not config.blocked[slot]) then
                bPTC[e.index] = e.bodyPart
            end
        elseif e.object.objectType == tes3.objectType.armor then
            slot = table.find(tes3.armorSlot, e.object.slot)
            if (e.bodyPart and e.bodyPart.partType == 2) and (slot and not config.blocked[slot]) then
                bPTA[e.index] = e.bodyPart
            end
        end

        if slot == "shield" and e.reference.mobile.weaponReady then
            local wS = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.weapon})
            if wS and table.find(tHW, wS.object.type) then
                return false
            end
        end

        if slot and config.blocked[slot] then
            if e.reference == tes3.player then
                if slot == "helmet" and e.index == 0 then
                    local hair = e.manager:getActiveBodyPart(0, 1)
                    hair.bodyPart = bPTB[1]
                elseif slot == "robe" then
                    for layer, bPTX in pairs(bPTL) do
                        for _, part in pairs(rHP) do
                            local aBP = e.manager:getActiveBodyPart(layer, part)
                            if layer == 0 and part ~= 5 then
                                aBP = aBPTB[part]
                            end

                            if not ((table.find(sHP, part) and not (layer == 1 and part == 4 and not bPTC[5]))
                            and not config.blocked["skirt"]
                            and tes3.getEquippedItem(
                                {actor = tes3.player, objectType = tes3.objectType.clothing, slot = 7}
                            )) then
                                aBP.bodyPart = bPTX[part]
                            end
                        end
                    end
                elseif slot == "skirt" then
                    for layer, bPTX in pairs(bPTL) do
                        for _, part in pairs(sHP) do
                            local aBP = e.manager:getActiveBodyPart(layer, part)
                            if layer == 0 then
                                aBP = aBPTB[part]
                            end
                            aBP.bodyPart = bPTX[part]
                        end
                    end
                end
            elseif e.reference == tes3.player1stPerson then
                if slot == "robe" then
                    for layer, bPTX in pairs(bPTL) do
                        for _, part in pairs(rHAP) do
                            local aBP = e.manager:getActiveBodyPart(layer, part)
                            aBP.bodyPart = bPTX[part]
                        end
                    end
                end
            end

            timer.frame.delayOneFrame(function ()
                table.clear(bPTC)
                table.clear(bPTA)
            end)
            return false
        end
    end
end

local function update()
    tes3.player:updateEquipment()
    tes3.player1stPerson:updateEquipment()
end

local function updateNIMM(e)
    if (e.reference == tes3.player or e.reference == tes3.player1stPerson) and not tes3.menuMode() then
        update()
    end
end

local function clear()
    table.clear(aBPTB)
    table.clear(bPTB)
    table.clear(bPTC)
    table.clear(bPTA)
end

local function oL()
    clear()
    update()
end

event.register(tes3.event.modConfigReady, function ()
    local EasyMCM = require("EasyMCM.EasyMCM")
    local template = EasyMCM.createTemplate("Скрыть снаряжение")
    --template:saveOnClose(modName, mcmConfig)
    template.onClose = function()
    saveConfigFromMcm()
    end
    template:register()

    template:createExclusionsPage{
        label = "Скрытые",
        description = "Заблокированные предметы не будут отображаться на теле персонажа.",
        showAllBlocked = true,
        variable = EasyMCM.createTableVariable{
            id = "blocked",
            table = mcmConfig
        },
        filters = {
            {
                label = "Доспехи",
                callback = (
                    function ()
                        local armorSlots = {}
                        for slot, _ in pairs(tes3.armorSlot) do
                            table.insert(armorSlots, getTranslatedSlotName(slot))
                        end
                        return armorSlots
                    end
                )
            },
            {
                label = "Одежда",
                callback = (
                    function ()
                        local clothingSlots = {}
                        for slot, _ in pairs(tes3.clothingSlot) do
                            if slot ~= "amulet" and slot ~= "belt" and slot ~= "ring" then
                                table.insert(clothingSlots, getTranslatedSlotName(slot))
                            end
                        end
                        return clothingSlots
                    end
                )
            }
        }
    }
end)

event.register(tes3.event.initialized, function ()
    event.register(tes3.event.bodyPartAssigned, oBPA, {priority = -6})
    event.register(tes3.event.menuExit, update)
    event.register(tes3.event.equipped, updateNIMM)
    event.register(tes3.event.weaponUnreadied, updateNIMM)
    event.register(tes3.event.uiActivated, clear, {filter = "MenuRaceSex"})
    event.register(tes3.event.loaded, oL)
    mwse.log("[%s]: Enabled", modName)
end)