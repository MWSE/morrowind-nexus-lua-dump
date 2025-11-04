-- thanks to:
-- https://www.nexusmods.com/morrowind/mods/53977?tab=files
local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local time = require('openmw_aux.time')

local crimes = require('openmw.interfaces').Crimes

local cmn = require('Scripts.Scribo.common')
local msg = core.l10n('Scribo', 'en')

local attributes = types.Actor.stats.attributes
local dynamic = types.Actor.stats.dynamic
local skills = types.NPC.stats.skills
local player = world.players[1]

local inCombat = false

local availableColors = {}
local inkwellsUsed = {}

local global = {
    emptyScrollId = nil,
    emptyBookId = nil,
    rippedPageId = nil,
    inkwells = nil,
    origami = nil

}

local asHTML = false
local uncontrolEdit = false

local function removeItem(data)
    if data.item then
        data.item:remove(1)
    end
end

local function removeItemByID(bookid)

    local item = types.Actor.inventory(player):find(bookid)
    if item then
        removeItem({
            item = item
        })
    end
end
local function addNewItem(itemid, count, inventory)
    if not inventory then
        inventory = types.Actor.inventory(player)
    end
    if not count then
        count = 1
    end

    local item = world.createObject(itemid, count)
    if item and item:moveInto(inventory) then
        return true
    end
    return false
end
local function ensureItemCount(itemid, requiredCount, inventory)
    if not inventory then
        inventory = types.Actor.inventory(player)
    end
    if not requiredCount then
        requiredCount = 1
    end
    -- Гарантирует наличие определенного количества предмета
    if inventory:countOf(itemid) < requiredCount then
        local missing = requiredCount - inventory:countOf(itemid)
        addNewItem(itemid, missing, inventory)
    end
end

local function createBook(data)
    local template = types.Book.createRecordDraft(data)
    local newBookRecord = world.createRecord(template)
    return newBookRecord.id
end
local function createMisc(data)

    local misc = types.Miscellaneous.createRecordDraft({
        name = data.name,
        isKey = false,
        model = data.model,
        weight = data.weight,
        value = data.value,
        icon = data.icon
    })

    local miscRecord = world.createRecord(misc)
    return miscRecord.id
end

local function initBooks()
    -- Поиск ID пустой книги и свитка
    for _, book in pairs(types.Book.records) do
        if book.name == cmn.emptyBookName then
            global.emptyBookId = book.id
        end
        if book.name == cmn.emptyScrollName then
            global.emptyScrollId = book.id
        end
    end
    -- Инициализация пустых книг и свитков
    if not global.emptyBookId then
        global.emptyBookId = createBook(cmn.bookTemplates[1])
    end
    if not global.emptyScrollId then
        global.emptyScrollId = createBook(cmn.bookTemplates[2])
    end
end
local function initMisc()
    global.inkwells = {}
    global.origami = {}

    -- ищем уже созданные чернильницы и оригами
    for _, misc in ipairs(types.Miscellaneous.records) do
        if misc.name == cmn.ripedPageName then
            global.rippedPageId = misc.id
        end

        for _, inkwell in ipairs(cmn.inkwellTemplates) do
            if inkwell.model == misc.model then
                table.insert(global.inkwells, {
                    id = misc.id,
                    colorName = inkwell.colorName,
                    colorNameShort = inkwell.colorNameShort
                })
            end
        end
        for _, origami in ipairs(cmn.origamiTemplates) do
            if origami.model == misc.model then
                table.insert(global.origami, {
                    id = misc.id,
                    model = origami.model,
                    icon = origami.icon,
                    name = origami.name
                })
            end
        end
    end

    if not global.rippedPageId then
        global.rippedPageId = createMisc(cmn.bookTemplates[3])
    end
    -- дополняем оригами не найденными шаблонами
    for _, template in ipairs(cmn.origamiTemplates) do
        local foundOrigami = false
        for _, origami in ipairs(global.origami) do
            if origami.model == template.model then
                foundOrigami = true
                break
            end
        end
        if not foundOrigami then
            local miscId = createMisc(template)
            table.insert(global.origami, {
                id = miscId,
                model = template.model,
                icon = template.icon,
                name = template.name
            })
        end
    end
    -- создаем чернильницы
    if #global.inkwells == 0 then
        for _, template in ipairs(cmn.inkwellTemplates) do
            local inkwellId = createMisc(template)
            table.insert(global.inkwells, {
                id = inkwellId,
                colorName = template.colorName,
                colorNameShort = template.colorNameShort
            })
        end
    end
end

local function updateInkwellStatus(itemid)
    local inventory = types.Actor.inventory(player)
    local inkwellsCount = inventory:countOf(itemid) or 0

    if inkwellsCount == 0 then
        inkwellsUsed[itemid] = 0
    end
end
local function updateInkwellsStatus()
    updateInkwellStatus(cmn.inkwellID)
    for _, inkwell in ipairs(global.inkwells) do
        updateInkwellStatus(inkwell.id)
    end
end

local function closeInterface(data)
    player:sendEvent('SetUiMode', {})
    -- if data.book.isScroll then
    --     player:sendEvent('SetUiMode', {
    --         mode = 'Scroll'
    --     })
    -- else
    --     player:sendEvent('SetUiMode', {
    --         mode = 'Book'
    --     })
    -- end
    -- if data.inventory then
    --     player:sendEvent('SetUiMode', {
    --         mode = 'Interface'
    --     })
    -- end
end

local function isEmptyScroll(bookid)
    local bookRecord = types.Book.record(bookid)

    -- Список ID редактируемых свитков
    local editableScrolls = {
        [cmn.dirtyPageID] = true,
        [cmn.cleanPageID] = true,
        [global.emptyScrollId] = true
    }

    -- Проверяем, является ли это редактируемым свитком
    if bookRecord.isScroll and editableScrolls[bookRecord.id] then
        return true
    else
        return false
    end
end
local function isWritableBook(bookid)
    local bookRecord = types.Book.record(bookid)

    if uncontrolEdit and not bookRecord.enchant then
        return true
    end

    if isEmptyScroll(bookid) then
        return true
    end
    -- Проверяем, является ли это обычной книгой, создаваемой модом
    if not bookRecord.isScroll and cmn.isGenBook(bookRecord.id) then
        return true
    end

    return false
end

local function isCopyableBook(bookid)
    local bookRecord = types.Book.record(bookid)

    -- Проверяем, является ли это обычной книгой, создаваемой модом
    if cmn.isGenBook(bookRecord.id) then
        local copyName = msg("copy", {
            name = ""
        })

        if cmn.ends_with(bookRecord.name, copyName) then
            return false
        end
    end

    if isEmptyScroll(bookid) then
        return false -- пустые свитки не копируются
    end

    for _, oriami in ipairs(global.origami) do
        if bookRecord.model == oriami.model then
            return false -- оригами не копируются
        end
    end

    return true
end

local function hasWritingMaterials()
    local inventory = types.Actor.inventory(player)
    local hasQuill = (inventory:find(cmn.quillID) ~= nil)
    local hasInkwell = (inventory:find(cmn.inkwellID) ~= nil)

    if not hasInkwell and not hasQuill then
        player:sendEvent('ShowMessage', {
            message = msg("noInkQuill")
        })
        return false
    elseif not hasInkwell then
        player:sendEvent('ShowMessage', {
            message = msg("noInk")
        })
        return false
    elseif not hasQuill then
        player:sendEvent('ShowMessage', {
            message = msg("noQuill")
        })
        return false
    end

    return true
end
local function hasPages(bookid)
    local bookRecord = types.Book.record(bookid)
    -- Проверка наличия материалов в инвентаре
    local inventory = types.Actor.inventory(player)
    local hasCleanPage = inventory:find(cmn.cleanPageID)
    local hasEmptyScroll = inventory:find(global.emptyScrollId)

    if not hasCleanPage and not hasEmptyScroll then
        player:sendEvent('ShowMessage', {
            message = msg("noPage")
        })
        return false
    end

    if bookRecord.enchant and not hasEmptyScroll then
        player:sendEvent('ShowMessage', {
            message = msg("noFinePage")
        })
        return false
    end

    return true
end

local function magicBookRequiredLevel(bookid)
    local bookRecord = types.Book.record(bookid)
    if bookRecord.enchant then
        local effects = core.magic.enchantments.records[bookRecord.enchant].effects
        local requiredLevels = {
            [1] = 25,
            [2] = 50,
            [3] = 75,
            [4] = 100
        }
        local effectsCount = #effects
        local maxEffects = 4
        return requiredLevels[math.min(effectsCount, maxEffects)]
    else
        return 0
    end
end
local function canDuplicate(bookid)
    local bookRecord = types.Book.record(bookid)

    if cmn.isGenBook(bookRecord.id) then
        return true
    end

    -- Проверяем базовые требования к мастерству
    if attributes.intelligence(player).modified < 40 then
        player:sendEvent('ShowMessage', {
            message = msg("noSoClever")
        })
        return false
    end

    -- Проверяем дополнительные требования для заклинаний
    if bookRecord.enchant then
        local currentEnchantLevel = skills.enchant(player).modified
        local requiredLevel = magicBookRequiredLevel(bookRecord.id)
        local effects = core.magic.enchantments.records[bookRecord.enchant].effects

        -- Проверяем уровень навыка
        if currentEnchantLevel < requiredLevel then
            player:sendEvent('ShowMessage', {
                message = msg("notEnoughEnchant")
            })
            return false
        end

        -- Проверка требований к уровню школы для каждого эффекта
        for _, effectId in ipairs(effects) do
            local effectRecord = core.magic.effects.records[effectId.id]
            local school = effectRecord.school
            local skillLevel = skills[school](player).modified
            local schoolName = core.stats.Skill.records[school].name

            if skillLevel < 25 then
                player:sendEvent('ShowMessage', {
                    message = msg("notEnoughSkill", {
                        school = schoolName
                    })
                })
                return false
            end
        end
    end
    -- Все проверки пройдены
    return true
end

local function playSuccess(isMagic)
    if isMagic then
        core.sound.playSoundFile3d('Sound/Fx/magic/restH.wav', player)
    else
        core.sound.playSoundFile3d('Sound/Scribo/snd_write.wav', player)
    end
end
local function playSuccessOrigami(isMagic)
    if isMagic then
        core.sound.playSoundFile3d('Sound/Fx/magic/restH.wav', player)
    else
        core.sound.playSoundFile3d('Sound/Fx/magic/BOOKPAG1.wav', player)
    end
end
local function playFail(isMagic)
    if isMagic then
        core.sound.playSoundFile3d('Sound/Fx/magic/enchantFAIL.wav', player)
    else
        core.sound.playSoundFile3d('Sound/Fx/magic/BOOKPAG1.wav', player)
    end
end

local function chanceCreateMagicOrigami()
    local chance = 0
    local level = attributes.personality(player).modified
    local luck = attributes.luck(player).modified

    if level < 50 then
        chance = 1 -- Защита от уровней ниже минимального диапазона
    elseif level <= 59 then
        chance = 2
    elseif level <= 69 then
        chance = 5
    elseif level <= 79 then
        chance = 8
    else
        chance = 11 -- Для уровней 90 и выше
    end
    if luck > 50 then
        chance = chance + (luck - 50) * 0.1
    end

    if dynamic.magicka(player).current > 100 then
        chance = chance + 5
    end

    return chance
end

local function makeOrigami(misc, origami)
    removeItem({
        item = misc
    })
    addNewItem(origami.id)
end
local function makeMagicOrigami(misc, origami)
    local scrolls = types.Book.records
    local magicScrolls = {}
    for _, scroll in pairs(scrolls) do
        if scroll.isScroll and scroll.enchant then
            table.insert(magicScrolls, scroll)
        end
    end

    local scroll = magicScrolls[math.random(1, #magicScrolls)]

    local template = {
        enchant = scroll.enchant,
        enchantCapacity = scroll.enchantCapacity,
        icon = origami.icon,
        isScroll = scroll.isScroll,
        model = origami.model,
        name = origami.name,
        skill = scroll.skill,
        text = scroll.text,
        value = scroll.value,
        weight = scroll.weight
    }

    local scrollid = createBook(template)

    removeItem({
        item = misc
    })
    addNewItem(scrollid)
end
local function bonusOrigami()
    local bonus = 6
    local duration = 5 * 60

    player:sendEvent('BoostAgility', {
        value = bonus
    })

    local callback = async:registerTimerCallback("endBonusOrigami", function()
        local unbonus = math.min(attributes.agility(self).modifier, bonus)
        player:sendEvent('BoostAgility', {
            value = -unbonus
        })
    end)

    async:newSimulationTimer(duration * core.getSimulationTimeScale(), callback)
end

local function chooseOrigamiModel()
    local inventory = types.Actor.inventory(player)
    local availableInks = {}

    -- Собираем доступные чернила по цветам
    for _, ink in pairs(global.inkwells) do
        availableInks[ink.colorName] = inventory:find(ink.id) ~= nil
    end
    -- Добавляем базовые черные чернила
    availableInks["black"] = inventory:find(cmn.inkwellID) ~= nil

    -- Фильтруем подходящие модели
    local validModels = {}
    for _, model in ipairs(global.origami) do
        local canUse = true
        -- Проверяем каждый цвет из availableInks
        for color, hasInk in pairs(availableInks) do
            -- Если чернила отсутствуют и модель требует этот цвет
            if not hasInk and string.find(model.model, color, 1, true) then
                canUse = false
                break
            end
        end
        if canUse then
            table.insert(validModels, model)
        end
    end

    -- Возвращаем случайную подходящую модель или nil
    if #validModels == 0 then
        return nil
    end
    local choose = math.random(1, #validModels)
    local model = validModels[choose]
    return model
end

local function tryMakeOrigami(data)
    if not data.needAction then
        return
    end

    local origami = chooseOrigamiModel()

    local chanse = chanceCreateMagicOrigami() -- если достаточный уровень можно сложить магическую оригами
    if math.random(1, 100) < chanse then

        local msgid = math.random(1, #cmn.magicOrigamiMessage)
        player:sendEvent('ShowMessage', {
            message = cmn.magicOrigamiMessage[msgid]
        })
        makeMagicOrigami(data.misc, origami)
        playSuccessOrigami(true)
    else
        player:sendEvent('ShowMessage', {
            message = msg("origamiComplete")
        })
        makeOrigami(data.misc, origami)
        playSuccessOrigami(false)
    end
    bonusOrigami()
    closeInterface(data)
end

local function removePageForScroll(bookid)
    local bookRecord = types.Book.record(bookid)
    local inventory = types.Actor.inventory(player)

    local cleanPage = inventory:find(cmn.cleanPageID)
    local emptyScroll = inventory:find(global.emptyScrollId)

    if bookRecord.enchant then -- магические книги и свитки требуют качественной страницы
        removeItem({
            item = emptyScroll
        })
    elseif cleanPage then -- если есть обычная страница используем ее
        removeItem({
            item = cleanPage
        })
    else -- иначе используем качественную
        removeItem({
            item = emptyScroll
        })
    end
end

local function removeMaterialForScroll(bookid)
    local bookRecord = types.Book.record(bookid)
    local requiredLevel = magicBookRequiredLevel(bookRecord.id)

    if bookRecord.enchant then
        if dynamic.magicka(player).current < dynamic.magicka(player).base / 100 * requiredLevel then
            player:sendEvent('ShowMessage', {
                message = msg("notEnoughMana")
            })
            return false
        else
            player:sendEvent("SpendMagika", {
                value = requiredLevel
            })
        end
    end

    removePageForScroll(bookid)

    return true
end

local function removeMaterialForBook(bookid)
    local inventory = types.Actor.inventory(player)
    local bookRecord = types.Book.record(bookid)

    if dynamic.fatigue(player).current >= dynamic.fatigue(player).base then
        player:sendEvent('SpendFatigue', {
            value = 100
        })
    else
        player:sendEvent('ShowMessage', {
            message = msg("notEnoughFatigue")
        })
        return false
    end

    local page = nil
    local pageCount = nil

    if inventory:countOf(cmn.cleanPageID) >= 2 then
        page = cmn.cleanPageID
        pageCount = 2
    else
        page = global.emptyScrollId
        pageCount = 1
    end

    -- Требуемые материалы
    local materials = {{
        id = page,
        count = pageCount,
        msg = "notEnoughPage"
    }, {
        id = cmn.inkwellID,
        count = 1,
        msg = "notEnoughInkwell"
    }, {
        id = cmn.quillID,
        count = 1,
        msg = "notEnoughQuill"
    }}

    -- Проверяем наличие материалов
    for _, material in ipairs(materials) do
        if inventory:countOf(material.id) < material.count then
            player:sendEvent('ShowMessage', {
                message = msg(material.msg)
            })
            return false
        end
    end

    -- Удаляем материалы
    for _, material in ipairs(materials) do
        local item = inventory:find(material.id)
        if item then
            item:remove(material.count)
        end
    end

    return true
end

local function chooseTemplate()
    local template
    local inventory = types.Actor.inventory(player)
    local hasRolled = inventory:find(cmn.cleanPageID)

    if hasRolled then
        template = cmn.scrollTemplates.rolled
    else
        template = cmn.scrollTemplates.fine
    end
    return template
end
local function duplicateScroll(bookid)
    local bookRecord = types.Book.record(bookid)

    if bookRecord.enchant then
        addNewItem(bookRecord.id)
    else
        local template = chooseTemplate()
        template.text = bookRecord.text
        template.name = msg("copy", {
            name = bookRecord.name
        })
        -- template.weight = bookRecord.weight
        template.value = bookRecord.value / 2
        template.isScroll = true
        local newbookid = createBook(template)
        addNewItem(newbookid)
    end
    updateInkwellsStatus()
end

local callback = async:registerTimerCallback("endSpeedUpTime", function()
    player:sendEvent('Unfade')
    world.setGameTimeScale(0)
end)

local function speedUpTime()
    core.sound.playSoundFile3d('Sound/Scribo/snd_write_long.wav', player)
    player:sendEvent('Fade')
    world.setGameTimeScale(60 * 60 * 24 / 2)
    closeInterface()
    async:newGameTimer(60 * 60 * 24, callback)
end
local function duplicateBook(bookid, allowDup)
    local bookRecord = types.Book.record(bookid)

    speedUpTime()

    local template = chooseTemplate()

    template.text = bookRecord.text
    template.name = msg("copy", {
        name = bookRecord.name
    })
    template.value = bookRecord.value / 2
    -- template.weight = bookRecord.weight
    template.weight = 2 -- bookRecord.weight
    template.isScroll = true

    local newbookid = createBook(template)
    addNewItem(newbookid)

    if allowDup then
        player:sendEvent('ShowMessage', {
            message = msg("spendForBook")
        })
    else
        player:sendEvent('ShowMessage', {
            message = msg("inCombatCompliteBook")
        })
    end
    updateInkwellsStatus()
end

local function maxLengthText(bookid)
    local bookRecord = types.Book.record(bookid)
    local maxLengthText = 0
    if bookRecord.isScroll then
        if bookRecord.id == cmn.dirtyPageID then -- or data.source.icon == "icons/scribo/ic_sc_drty_txt.dds" then
            maxLengthText = 200
        elseif bookRecord.id == cmn.cleanPageID then -- or data.source.icon == "icons/scribo/ic_sc_rlld_txt.dds" then
            maxLengthText = 660
        elseif bookRecord.id == global.emptyScrollId then -- data.source.icon == "icons/scribo/ic_sc_fine_blnk.dds" or data.source.icon == "icons/scribo/ic_sc_fine_txt.dds" then
            maxLengthText = 1320
        end
    end
    return maxLengthText
end

local function getModeSetup(bookid)
    local bookRecord = types.Book.record(bookid)
    local newBookID
    local mode
    if bookRecord.isScroll then
        newBookID = global.emptyScrollId
        mode = 'Scroll'
    else
        newBookID = global.emptyBookId
        mode = 'Book'
    end
    local book = world.createObject(newBookID, 1)

    return {
        mode = mode,
        target = book
    }
end
local function isGoodDisposition(actor)
    if actor == nil then
        return true
    elseif actor.recordId == player.recordId then
        return true
    elseif actor.class == "bookseller" then
        return false
    else -- if actor.class == "trader service" then
        local disp = types.NPC.getDisposition(actor, player)
        if disp < 80 then
            return false
        end
    end
    return true
end
local function actorById(aid)
    if aid == nil then
        return nil
    end

    for _, actor in ipairs(world.activeActors) do
        if actor.recordId == aid.recordId then
            return actor
        end
    end
    return nil
end

local function checkFail(chanceRuin, chanceDestroy, bookId, showMessage)
    -- Устанавливаем значение по умолчанию для showMessage
    showMessage = showMessage ~= false  -- true по умолчанию, если не передано false

    local chance = math.random(1, 100)

    -- Проверка на полное уничтожение
    if chance <= chanceDestroy then
        removePageForScroll(bookId)
        return false
    end

    -- Проверка на порчу (разрыв страницы)
    if chance <= chanceRuin then
        removePageForScroll(bookId)
        addNewItem(global.rippedPageId)
        if showMessage then
            player:sendEvent('ShowMessage', { message = msg("failPage") })
        end
        return false
    end

    -- Успех — ничего не произошло
    return true
end

local function writeBook(data)
    -- print("scribo: Writebook")

    if inCombat then
        return
    end

    asHTML = data.asHTML
    uncontrolEdit = data.uncontrolEdit

    local bookRecord = types.Book.record(data.book)

    if not data.needAction then
        return
    end

    if not data.disableEdit and isWritableBook(bookRecord.id) then -- если это книга или свиток для записи
        -- print("scribo: write book or scroll")
        if not hasWritingMaterials() then
            return
        end
        if bookRecord.isScroll and not hasPages(bookRecord.id) then
            return
        end

        local title
        local content
        if isEmptyScroll(bookRecord.id) then
            title = cmn.emptyTitleName
            content = cmn.emptyTextName
        elseif bookRecord.id == global.emptyBookId then
            title = cmn.emptyTitleName
            content = cmn.emptyTextName
        else
            title = bookRecord.name
            content = cmn.ripHTML(bookRecord.text, asHTML)
        end

        local mode = getModeSetup(bookRecord.id)
        player:sendEvent('AddUiMode', mode)

        player:sendEvent('EditBookPage', {
            source = data.book,
            empty = mode.target,
            title = title,
            content = content,
            maxLengthText = maxLengthText(bookRecord.id),
            inventory = data.inventory
        })
    else

        -- print("scribo: duplicate book or scroll")

        if not isCopyableBook(bookRecord.id) then -- свои книги и свитки не копируем
            return
        end

        if not hasWritingMaterials() or not hasPages(bookRecord.id) then -- проверяем наличие чернил и пера 
            closeInterface(data)
            return
        end

        if not canDuplicate(bookRecord.id) then -- пытаемся скопировать, если не хватает навыков
            if not checkFail(10, 0, bookRecord.id, false) then
                playFail(bookRecord.enchant)
            end
            closeInterface(data)
            return
        end

        local chanceFail = 5
        if bookRecord.isScroll and bookRecord.enchant then
            chanceFail = 10
        end

        local owner = actorById(data.book.owner)
        local allowDup = isGoodDisposition(owner)
        if not allowDup then
            crimes.commitCrime(player, {
                arg = data.cost,
                type = player.type.OFFENSE_TYPE.Theft,
                victim = owner,
                victimAware = false
            })
            chanceFail = 80
        end

        if bookRecord.isScroll then
            -- print("scribo: duplicate scroll")
            if removeMaterialForScroll(bookRecord.id) then
                if checkFail(chanceFail, 0, bookRecord.id) then
                    duplicateScroll(data.book)
                    playSuccess(bookRecord.enchant)
                else
                    playFail(bookRecord.enchant)
                end
            end
        else
            -- print("scribo: duplicate book")
            if removeMaterialForBook(bookRecord.id) then
                if checkFail(chanceFail, 0, bookRecord.id) then
                    duplicateBook(data.book, allowDup)
                    playSuccess(bookRecord.enchant)
                else
                    playFail(bookRecord.enchant)
                end
            end
        end

        closeInterface(data)
    end
end

local function checkPenState()
    -- 5% вероятность того, что перо сломается
    if math.random(1, 100) <= 5 then
        local inventory = types.Actor.inventory(player)
        local penItem = inventory:find(cmn.quillID)

        if penItem then
            local penCount = inventory:countOf(cmn.quillID)
            removeItem({
                item = penItem
            })
            --            if penCount == 0 then
            player:sendEvent('ShowMessage', {
                message = msg("penBroken")
            })
            --            end
        end
    end
end
local INKWELL_PER_SCROLL = 5
local function checkInkwellState(inkwellId, inkwellName)
    local usageCount = inkwellsUsed[inkwellId] or 0

    if usageCount > INKWELL_PER_SCROLL then
        inkwellsUsed[inkwellId] = 0

        local inventory = types.Actor.inventory(player)
        local inkwellItem = inventory:find(inkwellId)

        if inkwellItem then
            removeItem({
                item = inkwellItem
            })

            local inkwellCount = inventory:countOf(inkwellId)
            --            if inkwellCount == 0 then
            player:sendEvent('ShowMessage', {
                message = msg("inkGone", {
                    ink = inkwellName
                })
            })
            --            end
        end
    else
        inkwellsUsed[inkwellId] = usageCount + 1
    end
end
local function checkInksState(content)
    -- Таблица для отслеживания использованных чернил
    local usedInks = {}

    -- Проверяем все доступные чернила
    for _, ink in ipairs(global.inkwells) do
        -- Формируем шаблоны для полного и сокращённого названия цвета
        local fullPattern = "{" .. ink.colorName .. "}"
        local shortPattern = "{" .. ink.colorNameShort .. "}"

        -- Проверяем наличие шаблонов в контенте (без интерпретации спецсимволов)
        if string.find(content, fullPattern, 1, true) or string.find(content, shortPattern, 1, true) then
            usedInks[ink.id] = true -- Отмечаем, что чернила использованы
        end
    end

    for inkId in pairs(usedInks) do
        local inkRecord = types.Miscellaneous.record(inkId)
        checkInkwellState(inkId, inkRecord.name)
    end

    -- Проверяем стандартную чернильницу отдельно
    checkInkwellState(cmn.inkwellID, msg("inkwellBlack"))
end
local function isValidInkwell(inkwell, bookId)
    return (bookId == cmn.dirtyPageID and inkwell.colorName == "gray") or
               (bookId == cmn.cleanPageID and (inkwell.colorName == "gray" or inkwell.colorName == "black")) or
               (bookId == global.emptyScrollId) or cmn.isGenBook(bookId)
end
local function unpdateAvailableColors(bookid)
    local inventory = types.Actor.inventory(player)
    local hasInkwell = (inventory:find(cmn.inkwellID) ~= nil)

    availableColors = {}
    for _, inkwell in ipairs(global.inkwells) do
        if inventory:find(inkwell.id) then
            if isValidInkwell(inkwell, bookid) then
                table.insert(availableColors, inkwell.colorName)
                table.insert(availableColors, inkwell.colorNameShort)
            end
        end
    end
    if hasInkwell then
        table.insert(availableColors, "black")
    end

    if bookid == cmn.dirtyPageID and
        (cmn.table_contains(availableColors, "black") or cmn.table_contains(availableColors, "gray")) then
        availableColors = {}
        table.insert(availableColors, "gray")
    end
end

local function reCreateBook(data)
    -- print("scribo: recreate book")
    local icon
    local model
    local sourceRecord = types.Book.record(data.source)

    unpdateAvailableColors(sourceRecord.id)
    checkPenState()
    checkInksState(data.content)

    if sourceRecord.id == global.emptyScrollId then
        icon = cmn.scrollTemplates.fine.icon
        model = cmn.scrollTemplates.fine.model
    elseif sourceRecord.id == cmn.cleanPageID then
        icon = cmn.scrollTemplates.rolled.icon
        model = cmn.scrollTemplates.rolled.model
    elseif sourceRecord.id == cmn.dirtyPageID then
        icon = cmn.scrollTemplates.dirty.icon
        model = cmn.scrollTemplates.dirty.model
    elseif sourceRecord.id == global.rippedPageId then
        icon = cmn.scrollTemplates.ripped.icon
        model = cmn.scrollTemplates.ripped.model
    else
        icon = sourceRecord.icon
        model = sourceRecord.model
    end

    local newBookTemplate = types.Book.createRecordDraft({
        name = data.title,
        isScroll = sourceRecord.isScroll,
        model = model,
        text = cmn.genHTML(data.content, availableColors, asHTML),
        weight = sourceRecord.weight,
        value = sourceRecord.value,
        icon = icon
    })

    local newBookRecord = world.createRecord(newBookTemplate)
    local newBookWorld = world.createObject(newBookRecord.id, 1)

    if data.inventory then
        newBookWorld:moveInto(types.Actor.inventory(data.actor))
    else
        newBookWorld:teleport(data.actor.cell.name, data.actor.position)
    end

    local owner = actorById(data.source.owner)
    if not isGoodDisposition(owner) then
        crimes.commitCrime(player, {
            arg = data.cost,
            type = player.type.OFFENSE_TYPE.Theft,
            victim = owner,
            victimAware = false
        })
    end

    removeItem({
        item = data.source
    })
    removeItem({
        item = data.empty
    })
    updateInkwellsStatus()
end

local function addTestItems()
    ensureItemCount(cmn.inkwellID, 10)
    ensureItemCount(cmn.quillID, 10)
    ensureItemCount(cmn.cleanPageID, 10)
    ensureItemCount(global.emptyScrollId, 10)
    ensureItemCount(global.emptyBookId, 1)
    ensureItemCount(global.rippedPageId, 50)
    for _, inkwell in ipairs(global.inkwells) do
        ensureItemCount(inkwell.id, 10)
    end
    ensureItemCount("Gold_001", 20000)

    for _, origami in ipairs(global.origami) do
        ensureItemCount(origami.id, 1)
    end
end

local wasInit = false
local lastTraderUpdateTime = nil

local function onLoad(data)
    math.randomseed(os.time())
    initBooks()
    initMisc()

    --addTestItems()

    if data then
        -- Использование переданных данных
        inkwellsUsed = data.inkwellsUsed
        lastTraderUpdateTime = data.lastTraderUpdateTime
    else
        inkwellsUsed = {}
        lastTraderUpdateTime = nil
    end
    wasInit = true
end
local function onSave()
    return {
        inkwellsUsed = inkwellsUsed,
        lastTraderUpdateTime = lastTraderUpdateTime
    }
end
local function onUpdate()
    if not wasInit then
        onLoad(nil)
    end
end

local function updateTradersItems(data)
    if not wasInit then
        onLoad(nil)
    end

    local currentTime = world.getGameTime()

    local npcRecord = types.NPC.record(data.trader)
    local inventory = types.Container.inventory(data.container)

    local baseItems = {{
        id = global.emptyScrollId,
        count = 3,
        interval = 3,
        traders = {'jobasha', 'dorisa darvel', 'codus callonus', 'simine fralinie'},
        max_ingredients = 5
    }, -- Добротный лист
    {
        id = global.inkwells[3].id,
        count = 3,
        interval = 1,
        traders = {},
        max_misc_items = 5
    }, -- разбавленные чернила
    {
        id = global.inkwells[1].id,
        count = 2,
        interval = 3,
        traders = {},
        max_misc_items = 5,
        max_gold = 800
    }, -- красные чернила
    {
        id = global.inkwells[2].id,
        count = 2,
        interval = 3,
        traders = {},
        max_misc_items = 5,
        max_gold = 800
    }, -- зеленые чернила
    {
        id = global.emptyBookId,
        count = 1,
        interval = 12,
        traders = {'jobasha', 'scamp_creeper', 'mudcrab_unique'}
    }, -- журнал
    {
        id = cmn.inkwellID,
        count = 3,
        interval = 2,
        max_misc_items = 5,
        traders = {}
    }, -- чернила
    {
        id = cmn.cleanPageID,
        count = 4,
        interval = 3,
        traders = {'jobasha', 'dorisa darvel', 'codus callonus', 'simine fralinie'},
        max_ingredients = 5
    }, -- скрученные страницы
    {
        id = cmn.quillID,
        count = 5,
        interval = 1,
        traders = {},
        max_misc_items = 5
    }}

    local countIngredients = #inventory:getAll(types.Ingredient) + (data.ingredient or 0)
    local countMisc = #inventory:getAll(types.Miscellaneous) + (data.misc or 0)
    local npcGold = npcRecord.baseGold

    for _, item in ipairs(baseItems) do
        local traderForItem = false
        if item.traders then
            if cmn.table_contains(item.traders, npcRecord.id) and data.container.type == types.NPC then
                traderForItem = true
            end
        end
        if not traderForItem then
            if item.max_misc_items and countMisc >= item.max_misc_items and not item.max_gold then
                traderForItem = true
            end
            if item.max_misc_items and countMisc >= item.max_misc_items and item.max_gold and npcGold >= item.max_gold then
                traderForItem = true
            end
            if item.max_ingredients and countIngredients >= item.max_ingredients then
                traderForItem = true
            end
        end

        if traderForItem then
            local needUpdate = false
            if not lastTraderUpdateTime then
                lastTraderUpdateTime = {}
            end
            if not lastTraderUpdateTime[npcRecord.id] then
                lastTraderUpdateTime[npcRecord.id] = {}
            end
            if not lastTraderUpdateTime[npcRecord.id].items then
                lastTraderUpdateTime[npcRecord.id].items = {}
            end
            if lastTraderUpdateTime[npcRecord.id].items[item.id] then
                local lastTime = lastTraderUpdateTime[npcRecord.id].items[item.id]
                if currentTime - lastTime > item.interval * 24 * 60 * 60 then
                    needUpdate = true
                end
            else
                needUpdate = true
            end
            if needUpdate then
                ensureItemCount(item.id, item.count, inventory)
                lastTraderUpdateTime[npcRecord.id].items[item.id] = currentTime
            end
        end
    end
end

local function showInkwellRest(itemid)
    local inventory = types.Actor.inventory(player)
    local inkwellsCount = inventory:countOf(itemid) or 0
    local inkwellUsed = inkwellsUsed[itemid] or 0

    if inkwellUsed == 0 then
        player:sendEvent("ShowMessage", {
            message = msg("inkwellStatusFull")
        })
    else
        player:sendEvent("ShowMessage", {
            message = msg("inkwellStatusPart", {
                fill = (INKWELL_PER_SCROLL - inkwellUsed),
                total = INKWELL_PER_SCROLL
            })
        })
    end
end

I.ItemUsage.addHandlerForType(types.Book, function(item, actor)
    -- print('scribo: book activated from inventory')
    player:sendEvent("ProcessingItem", {
        book = item,
        inventory = true
    })
end)

I.ItemUsage.addHandlerForType(types.Miscellaneous, function(item, actor)
    -- print('scribo: misc activated from inventory')

    if item.recordId == global.rippedPageId then
        player:sendEvent("ProcessingItem", {
            misc = item,
            inventory = true
        })
    else
        if item.recordId == cmn.inkwellID then
            showInkwellRest(item.recordId)
        else
            for _, inkwell in ipairs(global.inkwells) do
                if item.recordId == inkwell.id then
                    showInkwellRest(item.recordId)
                end
            end
        end
    end
end)

-- I.Activation.addHandlerForType(types.NPC, function(object, actor)
--     local class = types.NPC.record(object).class
--     if (class == "trader service") or class == "bookseller" then
--         if not wasInit then
--             onLoad(nil)
--         end
--         addItemsToTrader(object)
--     end
-- end)
local nearActors = {}
local stopfn = time.runRepeatedly(function()

    -- Проверяем, есть ли активные акторы в бою
    local hasCombatActor = false
    for _, actor in ipairs(world.activeActors) do
        if nearActors[actor.recordId] then
            hasCombatActor = true
            break -- Прерываем цикл при первом найденном участнике
        end
    end

    -- Обновляем глобальный флаг состояния боя
    if hasCombatActor and not inCombat then
        inCombat = true
        -- print('scribo: NPC in combat')
    elseif not hasCombatActor and inCombat then
        inCombat = false
        -- print('scribo: NPC not in combat')
    end
end, time.second)

local function checkCombat(data)
    -- Обновляем статус боя для указанного NPC
    if data.type == "Combat" then
        nearActors[data.npc] = true -- Добавляем NPC в список участников боя
    else
        nearActors[data.npc] = nil -- Удаляем NPC из списка
    end
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onUpdate = onUpdate
    },
    eventHandlers = {
        WriteBook = writeBook,
        MakeOrigami = tryMakeOrigami,
        ReCreateBook = reCreateBook,
        UpdateTradersItems = updateTradersItems,
        CheckCombat = checkCombat
    }
}
