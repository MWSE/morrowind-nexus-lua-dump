require("diject.remains_of_the_fallen.libs.types")
local log = include("diject.remains_of_the_fallen.utils.log")
local advTable = include("diject.remains_of_the_fallen.utils.table")
local objectSerDes = include("diject.remains_of_the_fallen.libs.objectSerDes")
local itemLib = require("diject.remains_of_the_fallen.libs.item")
local bodypartChanger = require("diject.mwse_libs.bodypartChanger")
local tooltipChanger = require("diject.mwse_libs.tooltipChanger")

local this = {}

this.npcTemplate = "rotf_dpl_"

---@param from tes3reference
---@param to tes3reference
function this.transferStats(from, to)
    tes3.setStatistic{reference = to, name = "health", current = from.mobile.health.base, base = from.mobile.health.base}
    tes3.setStatistic{reference = to, name = "fatigue", current = from.mobile.fatigue.base, base = from.mobile.fatigue.base}
    tes3.setStatistic{reference = to, name = "magicka", current = from.mobile.magicka.base, base = from.mobile.magicka.base}

    local spellsToRemove = {}
    for _, spell in pairs(to.object.spells) do
        if spell.castType == tes3.spellType.spell then
            table.insert(spellsToRemove, spell)
        end
    end
    for _, spell in pairs(spellsToRemove) do
        tes3.removeSpell{reference = to, spell = spell, updateGUI = true}
    end
    for _, spell in pairs(from.object.spells) do
        if spell.castType == tes3.spellType.spell then
            tes3.addSpell{reference = to, spell = spell, updateGUI = true}
        end
    end
    for i, attr in pairs(from.mobile.attributes) do
        to.mobile.attributes[i].base = attr.base
        to.mobile.attributes[i].current = attr.current
    end
    if to.baseObject.objectType == tes3.objectType.npc then
        for i, skill in pairs(from.mobile.skills) do
            to.mobile.skills[i].base = skill.base
            to.mobile.skills[i].current = skill.current
        end
    end
end


---@class rotf.npc.createActorDuplicate.params
---@field cell tes3cell|nil
---@field position tes3vector3|nil
---@field rotation tes3vector3|nil
---@field useCustomPosition boolean|nil
---@field customActorId string|nil
---@field spawnConfig table
---@field transferConfig table
---@field createNewItemRecord boolean|nil
---@field newItemPrefix string|nil
---@field itemStatMultipliers rotf.item.decreaseItemStats.params|nil
---@field actorNameTemplate string|nil

---@param actorData rotf.storage.deathMapRecord
---@param params rotf.npc.createActorDuplicate.params|nil
---@return tes3reference|nil
function this.createDuplicate(actorData, params)
    if not params then params = {} end
    local newRef
    local objId
    local obj
    local objConfig = params.spawnConfig
    if not params.customActorId then
        local raceId = actorData.race:lower()
        local objPrefix = this.npcTemplate..(actorData.isFemale and "f_" or "m_")
        objId = objPrefix..raceId
        obj = tes3.getObject(objId)
        if not obj then
            objId = objPrefix.."khajiit"
        end
    else
        objId = params.customActorId
    end
    obj = tes3.getObject(objId or "")
    local cell = params.cell or tes3.getCell{id = actorData.position.cell.name, x = actorData.position.cell.x, y = actorData.position.cell.y}
    if obj and objId and objConfig and cell then
        newRef = tes3.createReference{
            object = objId,
            position = params.position or tes3vector3.new(actorData.position.x, actorData.position.y, actorData.position.z),
            orientation = params.rotation or tes3vector3.new(actorData.rotation.x, actorData.rotation.y, actorData.rotation.z),
            cell = cell
        }
        local randomizer = include("Morrowind_World_Randomizer.Randomizer")
        if randomizer then
            randomizer.StopRandomization(newRef)
        end

        bodypartChanger.saveBodyParts(newRef, actorData.raceData, {head = actorData.head, hair = actorData.hair})
        local tooltip = params.actorNameTemplate or "!name! The !ndeath!th"
        tooltip = tooltip:gsub("!name!", actorData.name)
        tooltip = tooltip:gsub("!ndeath!", tostring(actorData.deathCount + 1))
        tooltipChanger.saveTooltip(newRef, tooltip)

        local spellsToRemove = {}
        for _, spell in pairs(newRef.object.spells) do
            if spell.castType == tes3.spellType.spell then
                table.insert(spellsToRemove, spell)
            end
        end
        for _, spell in pairs(spellsToRemove) do
            tes3.removeSpell{reference = newRef, spell = spell}
        end
        for _, id in pairs(actorData.spells) do
            local spell = tes3.getObject(id)
            if not spell and actorData.customObjects[id] then
                spell = objectSerDes.restoreObject(nil, actorData.customObjects[id], {useIdFromData = true})
                tes3.addSpell{reference = newRef, spell = spell}
            end
            if spell then
                tes3.addSpell{reference = newRef, spell = spell}
            end
        end
        for i, val in ipairs(actorData.attributes) do
            tes3.setStatistic{reference = newRef, attribute = i - 1, current = val, base = val}
        end
        if newRef.baseObject.objectType == tes3.objectType.npc then
            for i, val in ipairs(actorData.skills) do
                tes3.setStatistic{reference = newRef, skill = i - 1, current = val, base = val}
            end
        end

        for stat, mulPercent in pairs(objConfig.stats) do
            local value = mulPercent / 100 * tes3.mobilePlayer[stat].base
            tes3.setStatistic{reference = newRef, name = stat, current = value, base = value}
        end
        -- health, fatigue, magicka
        for stat, val in pairs(actorData.stats) do
            local value = val * (objConfig.stats[stat] or 100) / 100
            tes3.setStatistic{reference = newRef, name = stat, current = value, base = value}
        end


        if objConfig.chanceToCorpse / 100 > math.random() then
            timer.delayOneFrame(function(e)
                tes3.modStatistic{reference = newRef, name = "health", current = -9999999}
            end)
        elseif obj.objectType == tes3.objectType.npc then
            -- tes3.addSpell{reference = newRef, spell = "ghost ability"}
            newRef.mobile.fight = 100
            newRef.mobile.chameleon = 50
            newRef.mobile.resistMagicka = 9999
            newRef.mobile:updateOpacity()
        end

        ---@param reference tes3reference
        ---@param item tes3item
        ---@param itemData jai.storage.itemData
        local function addItem(reference, item, itemData)
            local createdItem
            if itemData.condition or itemData.charge then
                tes3.addItem{reference = reference, item = item, count = 1, playSound = false, reevaluateEquipment = false, updateGUI = false} ---@diagnostic disable-line: assign-type-mismatch
                local createdData = tes3.addItemData{to = reference, item = item, updateGUI = false} ---@diagnostic disable-line: assign-type-mismatch
                if createdData then
                    createdData.charge = itemData.charge
                    createdData.condition = itemData.condition
                    createdData.count = itemData.count
                end
            else
                createdItem = tes3.addItem{reference = reference, item = item, count = itemData.count, playSound = false, reevaluateEquipment = false, updateGUI = false} ---@diagnostic disable-line: assign-type-mismatch
            end
            return createdItem
        end

        local equipped = {}
        local otherEquipnemtItems = {}
        local magicItems = {}
        local books = {}
        local miscItems = {}
        local replacementList = {}
        for i, stack in pairs(actorData.inventory) do
            local object = tes3.getObject(stack.id)
            local customObjData = actorData.customObjects[stack.id]

            if not object and customObjData then
                local data = customObjData
                if params.createNewItemRecord then
                    data = advTable.deepcopy(customObjData)
                    itemLib.multiplyItemStats(data, params.itemStatMultipliers)
                    if params.newItemPrefix and string.sub(data.name, 1, params.newItemPrefix:len()) ~= params.newItemPrefix then
                        data.name = params.newItemPrefix.." "..data.name
                    end
                end
                object = objectSerDes.restoreObject(nil, data, {useIdFromData = not params.createNewItemRecord, createNewEnchantment = params.createNewItemRecord})
                replacementList[object.id] = object
            elseif object and params.createNewItemRecord then
                local oldId = object.id
                if replacementList[oldId] then
                    object = replacementList[oldId]
                elseif object.createCopy then
                    object = object:createCopy() ---@diagnostic disable-line: missing-parameter
                    if params.itemStatMultipliers then
                        if object.enchantment then
                            local newEnch = object.enchantment:createCopy() ---@diagnostic disable-line: missing-parameter
                            object.enchantment = newEnch
                        end
                        itemLib.multiplyItemStats(object, params.itemStatMultipliers)
                    end
                    if params.newItemPrefix and string.sub(object.name, 1, params.newItemPrefix:len()) ~= params.newItemPrefix then
                        object.name = params.newItemPrefix.." "..object.name
                    end
                    replacementList[oldId] = object
                end
            end
            if not object then goto continue end

            if object.isGold then
                local goldPercent = params.transferConfig.goldPercent / 100
                if goldPercent > 0 then
                    local count = math.floor(stack.count * goldPercent)
                    addItem(newRef, object, {count = count}) ---@diagnostic disable-line: missing-fields
                end
            elseif (object.objectType == tes3.objectType.armor or object.objectType == tes3.objectType.clothing or
                    object.objectType == tes3.objectType.weapon or object.objectType == tes3.objectType.ammunition) then
                if stack.isEquipped then
                    table.insert(equipped, {object = object, data = stack})
                else
                    table.insert(otherEquipnemtItems, {object = object, data = stack})
                end
            elseif (object.objectType == tes3.objectType.alchemy or (object.objectType == tes3.objectType.book and object.enchantment)) then
                table.insert(magicItems, {object = object, data = stack})
            elseif object.objectType == tes3.objectType.book then
                table.insert(books, {object = object, data = stack})
            else
                table.insert(miscItems, {object = object, data = stack})
            end
            ::continue::
        end

        local function calcNumber(val, maxVal)
            return params.transferConfig.inPersent and math.ceil(val / 100 * maxVal) or val
        end

        local transferOtherEquipnemtCount = calcNumber(params.transferConfig.equipment, #otherEquipnemtItems)
        local transferEquippedCount = calcNumber(params.transferConfig.equipedItems, #equipped)
        local transferMagicItemsCount = calcNumber(params.transferConfig.magicItems,  #magicItems)
        local transferBooksCount = calcNumber(params.transferConfig.books, #books)
        local transferMiscCount = calcNumber(params.transferConfig.misc, #miscItems)
        local struct = {
            {transferOtherEquipnemtCount, otherEquipnemtItems},
            {transferEquippedCount, advTable.deepcopy(equipped)},
            {transferMagicItemsCount, magicItems},
            {transferBooksCount, books},
            {transferMiscCount, miscItems},
        }
        for _, data in pairs(struct) do
            for i = 1, data[1] do
                if #data[2] > 0 then
                    local itemId = math.random(1, #data[2])
                    local item = data[2][itemId]
                    addItem(newRef, item.object, item.data) ---@diagnostic disable-line: missing-fields
                    table.remove(data[2], itemId)
                end
            end
        end

        if newRef.baseObject.objectType == tes3.objectType.npc then
            for _, item in pairs(equipped) do
                newRef.mobile:equip{item = item.object}
            end
        end
        newRef.object.modified = true
    end
end

return this