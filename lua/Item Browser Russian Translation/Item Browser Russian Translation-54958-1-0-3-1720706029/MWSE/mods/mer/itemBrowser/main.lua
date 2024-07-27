local Util = require("mer.itemBrowser.util")
local config = require("mer.itemBrowser.config")
local logger = Util.createLogger("main")
local mcm = require("mer.itemBrowser.mcm")

local CraftingFramework = include("CraftingFramework")
if not CraftingFramework then
    logger:error("CraftingFramework not installed! Go here to download: https://www.nexusmods.com/morrowind/mods/51009")
    return
end


---@param object tes3object|tes3armor|tes3clothing|tes3misc|tes3light|tes3weapon|tes3book|tes3probe|tes3lockpick
local function getDescription(object)
    local description = ""
    description = description .. string.format("ID: %s\n\n", object.id)
    description = description .. string.format("Источник предмета: %s\n\n", object.sourceMod)
    if object.armorRating then
        description = description .. string.format("Уровень защиты: %d\n", object.armorRating)
    end
    if object.slashMax then
        description = description .. string.format("Режущий: %d - %d\n", object.slashMin, object.slashMax)
    end
    if object.thrustMax then
        description = description .. string.format("Колющий: %d - %d\n", object.thrustMin, object.thrustMax)
    end
    if object.chopMax then
        description = description .. string.format("Рубящий: %d - %d\n", object.chopMin, object.chopMax)
    end
    if object.speed then
        description = description .. string.format("Скорость: %d\n", object.speed)
    end
    if object.enchantCapacity then
        description = description .. string.format("Емкость зачарования: %d\n", object.enchantCapacity)
    end
    description = description .. string.format("Вес: %.2f   Цена: %d", object.weight, object.value)
    return description
end

local function addRecipe(recipes, category, obj)
    ---@type craftingFrameworkRecipe
    local recipe = {
        id = "itemBrowser:" .. obj.id,
        craftableId = obj.id,
        category = obj.sourceMod,
        soundId = "Item Misc Up",
        description = getDescription(obj),
        persist = false,
        resultAmount = category.resultAmount
    }
    table.insert(recipes, recipe)
end

local function isValidObject(object, category)
    if category.slots then
        if not category.slots[object.slot] then
            return false
        end
    end
    if category.requiredFields then
        for k, v in pairs(category.requiredFields) do
            if object[k] ~= v then
                return false
            end
        end
    end
    if category.enchanted ~= nil then
        if object.enchantment and (category.enchanted == false) then
            return false
        end
        if (not object.enchantment) and (category.enchanted == true) then
            return false
        end
    end
    if object.name == "" then return false end
    if not object.sourceMod then return false end
    return true
end

local function registerObjectTypeForCategory(objectType, category, recipes)
    ---@param obj tes3object|tes3armor|tes3clothing|tes3misc|tes3light|tes3weapon|tes3book|tes3probe|tes3lockpick
    for object in tes3.iterateObjects(objectType) do
        if isValidObject(object, category) then
            addRecipe(recipes, category, object)
        end
    end
end

local showMenu
local function registerCategory(category)
    if not category.registered then
        category.registered = true
        logger:debug("Category: %s", category.name)
        local recipes = {}
        for objectType, _ in pairs(category.objectTypes) do
            registerObjectTypeForCategory(objectType, category, recipes)
        end
        logger:debug("Total %s registered: %d", category.name, #recipes)
        CraftingFramework.MenuActivator:new{
            name = "Каталог предметов: " .. category.name,
            id = "ItemBrowserActivate:" .. category.name,
            type = "event",
            recipes = recipes,
            defaultSort = "name",
            defaultFilter = "all",
            defaultShowCategories = true,
            closeCallback = showMenu,
            craftButtonText = "Добавить в инвентарь",
            showCollapseCategoriesButton = true,
            showCategoriesButton = true,
            showFilterButton = false,
            showSortButton = false,
        }
    end
end


local menusRegistered
local function registerMenus()
    logger:debug("Registering Item Menus")
    if not menusRegistered then
        for _, category in pairs(config.static.categories) do
            registerCategory(category)
        end
        menusRegistered = true
    end
end
event.register("ItemBrowser:RegisterMenus", registerMenus)


showMenu = function ()
    local buttons = {}
    for _, category in ipairs(config.static.categories) do
        table.insert(buttons, {
            text = category.name,
            callback = function()
                timer.delayOneFrame(function()
                    registerCategory(category)
                    event.trigger("ItemBrowserActivate:" .. category.name)
                end)
            end
        })
    end
    tes3ui.showMessageMenu{
        header = "Каталог предметов",
        message = "Выберите тип предмета:",
        buttons = buttons,
        cancels = true,
    }
end

---@param e keyDownEventData
local function onKeyDown(e)
    if tes3ui.menuMode() then return end
    if not config.mcm.enabled then return end
    if Util.isKeyPressed(e, config.mcm.hotKey) then
        showMenu()
    end
end

---@param e initializedEventData
local function onInitialised(e)
    event.register(tes3.event.keyDown, onKeyDown)
    if config.mcm.enabled then
        --registerMenus()
    else
        logger:debug("Mod disabled, skipping recipe registration.")
    end
    logger:info("Initialised: %s", Util.getVersion())
end
event.register(tes3.event.initialized, onInitialised)