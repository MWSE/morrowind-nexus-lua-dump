local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local auxUi = require('openmw_aux.ui')

local helpers = require('scripts.InventoryExtender.util.helpers')
local constants = require('scripts.InventoryExtender.util.constants')

local windowManager = require('scripts.InventoryExtender.ui.windowManager')

local API = {}

API.VERSION = 1

API.Constants = constants
API.Helpers = helpers

API.Templates = {
    BASE = require('scripts.InventoryExtender.ui.templates.base'),
    MAGIC = require('scripts.InventoryExtender.ui.templates.magic'),
}

function API.show(windowName, arg)
    windowManager:show(windowName, arg)
end

function API.hide(windowName, arg, force)
    windowManager:hide(windowName, arg, force)
end

function API.getWindows()
    return windowManager.windows
end

function API.getWindow(windowName)
    return windowManager.windows[windowName]
end

function API.getContext()
    return windowManager.ctx
end

local lastCrimeLevel
local function checkCrimeLevel()
    local crimeLevel = types.Player.getCrimeLevel(self)
    if lastCrimeLevel and crimeLevel < lastCrimeLevel then
        core.sendGlobalEvent('IE_TryConfiscate', { player = self, stolenMap = windowManager.ctx.stolenItems })
    end
    
    lastCrimeLevel = crimeLevel
end

function API.onFrame()
    windowManager:onFrame()
    checkCrimeLevel()
end

function API.onMouseWheel(v, h)
    windowManager:onMouseWheel(v, h)
end

function API.reset()
    windowManager:reset()
end

function API.refresh()
    windowManager:refresh()
end

function API.update()
    windowManager:update()
end

function API.setConsoleState(state)
    windowManager.ctx.isConsoleOpen = state
    if windowManager.ctx.activeTooltip then
        auxUi.deepDestroy(windowManager.ctx.activeTooltip)
        windowManager.ctx.activeTooltip = nil
    end
    windowManager.ctx.dragAndDrop.lastHoveredObject = nil
end

function API.getConsoleState()
    return windowManager.ctx.isConsoleOpen
end

local categories = {}
local categoriesChanged = false
function API.getCategories()
    return categories
end

function API.getCategory(key)
    for _, category in ipairs(categories) do
        if category.key:lower() == key:lower() then
            return category
        end
    end
    return nil
end

function API.registerCategory(category)
    for i, existingCategory in ipairs(categories) do
        if existingCategory.key:lower() == category.key:lower() then
            table.remove(categories, i)
            break
        end
    end
    categoriesChanged = true

    if category.prepend then
        table.insert(categories, 1, category)
    else
        table.insert(categories, category)
    end
end

function API.unregisterCategory(key)
    for i, existingCategory in ipairs(categories) do
        if existingCategory.key:lower() == key:lower() then
            table.remove(categories, i)
            return
        end
    end
    categoriesChanged = true
end

--- Register a tooltip modifier function.
--- Modifiers are called in order of registration, and each modifier receives the current modified layout.
--- The passed layout is a direct reference and can be modified in-place.
--- Optionally, a modifier can return a new layout to replace the current one entirely.
--- @param id string A unique identifier for the modifier
--- @param modifier fun(item: GameObject, layout: Layout):Layout|nil The modifier function
function API.registerTooltipModifier(id, modifier)
    for _, existingModifier in ipairs(windowManager.ctx.modifiers.tooltip) do
        if existingModifier.id:lower() == id:lower() then
            existingModifier.modifier = modifier
            return
        end
    end
    table.insert(windowManager.ctx.modifiers.tooltip, { id = id, modifier = modifier })
end

--- Register a cell content modifier function for rows in the item table.
--- Modifiers are called in order of registration when a cell's content is updated, and each modifier receives the current cell layout.
--- The passed layout is a direct reference and can be modified in-place.
--- Optionally, a modifier can return new layout to replace the current one entirely.
--- WIP KINDA BROKEN :)
--- @param id string A unique identifier for the modifier
--- @param modifier fun(cell: Layout, row: table, ctx: table, windowType: string):Layout|nil The modifier function
function API.registerCellContentModifier(id, modifier)
    for _, existingModifier in ipairs(windowManager.ctx.modifiers.cellContent) do
        if existingModifier.id:lower() == id:lower() then
            existingModifier.modifier = modifier
            return
        end
    end
    table.insert(windowManager.ctx.modifiers.cellContent, { id = id, modifier = modifier })
end

--- Register a function to override the equipped status of items in the inventory.
--- Handlers are called in reverse order of registration until one returns a non-nil value, at which point that value is used as the result. 
--- If no handlers return a non-nil value, the default value is used.
--- @param id string A unique identifier for the override
--- @param handler fun(item: GameObject, actor: Actor):boolean|nil The override function
function API.registerEquippedOverride(id, handler)
    for _, existingHandler in ipairs(windowManager.ctx.overrides.equipped) do
        if existingHandler.id:lower() == id:lower() then
            existingHandler.handler = handler
            return
        end
    end
    table.insert(windowManager.ctx.overrides.equipped, { id = id, handler = handler })
end

--- Register a function to handle use actions (left-click, unless swapped) on item rows in the inventory.
--- By default, this equips or uses the item. In barter, it adds/removes the item from the current barter offer.
--- Handlers are called in reverse order of registration until one returns false, at which point the click is not processed further. If all handlers return true, the default click behavior is executed.
--- @param id string A unique identifier for the handler
--- @param handler fun(row: table, ctx: table, windowType: string):boolean? The handler function
function API.registerRowUseHandler(id, handler)
    for _, existingHandler in ipairs(windowManager.ctx.handlers.onRowUse) do
        if existingHandler.id:lower() == id:lower() then
            existingHandler.handler = handler
            return
        end
    end
    table.insert(windowManager.ctx.handlers.onRowUse, { id = id, handler = handler })
end
--- @deprecated Use registerRowUseHandler instead
API.registerRowClickHandler = API.registerRowUseHandler

--- Register a function to handle pick-up actions (default: R, or left-click if swapped) on item rows in the inventory.
--- By default, this picks up the item or drops/transfers it if Alt is held. In barter, it is routed to the "use" handler.
--- Handlers are called in reverse order of registration until one returns false, at which point the activation is not processed further. If all handlers return true, the default activation behavior is executed.
--- @param id string A unique identifier for the handler
--- @param handler fun(row: table, ctx: table, windowType: string):boolean? The handler function
function API.registerRowPickupHandler(id, handler)
    for _, existingHandler in ipairs(windowManager.ctx.handlers.onRowPickup) do
        if existingHandler.id:lower() == id:lower() then
            existingHandler.handler = handler
            return
        end
    end
    table.insert(windowManager.ctx.handlers.onRowPickup, { id = id, handler = handler })
end
--- @deprecated Use registerRowPickupHandler instead
API.registerRowActivateHandler = API.registerRowPickupHandler

local eventHandlers = {
    UiModeChanged = function(data)
        windowManager:onUiModeChanged(data.oldMode, data.newMode, data.arg)
        core.sendGlobalEvent('IE_UIModeChanged', { actor = self, oldMode = data.oldMode, newMode = data.newMode, arg = data.arg })
    end,
    IE_StoleItem = function(props)
        windowManager.ctx.stolenItems[props.recordId] = windowManager.ctx.stolenItems[props.recordId] or {}
        local id = props.victim.recordId or props.victim.factionId
        if id then
            windowManager.ctx.stolenItems[props.recordId][id] = (windowManager.ctx.stolenItems[props.recordId][id] or 0) + props.count 
        end
    end,
    IE_ItemsConfiscated = function(props)
        --print(helpers.deepPrint(props.stolenMap))
        windowManager.ctx.stolenItems = props.stolenMap or windowManager.ctx.stolenItems
    end,
    IE_Update = function()
        windowManager:update()
    end,
    IE_CompanionProfit = function(props)
        windowManager.ctx.companionProfit[props.companion.id] = props.profit
    end,
    IE_SetDraggingObject = function(props)
        local obj = props.obj
        if helpers.isGold(props.obj) then
            local targetInv = props.target.type.inventory(props.target)
            local foundGold = targetInv:find('gold_001')
            if foundGold then
                obj = foundGold
            end
        end

        windowManager.ctx.dragAndDrop:setDraggingObject(obj, props.resetMode)
    end,
    IE_BarterFinalized = function(props)
        I.SkillProgression.skillUsed('mercantile', {
            skillGain = props.skillGain,
            useType = I.SkillProgression.SKILL_USE_TYPES.Mercantile_Success
        })
    end,
}
-- deprecated event names
eventHandlers.MI_StoleItem = eventHandlers.IE_StoleItem
eventHandlers.MI_ItemsConfiscated = eventHandlers.IE_ItemsConfiscated
eventHandlers.MI_Update = eventHandlers.IE_Update
eventHandlers.MI_CompanionProfit = eventHandlers.IE_CompanionProfit
eventHandlers.MI_SetDraggingObject = eventHandlers.IE_SetDraggingObject
eventHandlers.MI_BarterFinalized = eventHandlers.IE_BarterFinalized

return {
    interfaceName = 'InventoryExtender',
    interface = API,
    engineHandlers = {
        onSave = function()
            return {
                stolenItems = windowManager.ctx.stolenItems,
                favoriteItems = windowManager.ctx.favoriteItems,
                favoriteRevision = windowManager.ctx.favoriteRevision,
                companionProfit = windowManager.ctx.companionProfit,
            }
        end,
        onLoad = function(data)
            if data then
                windowManager.ctx.stolenItems = data.stolenItems or {}
                windowManager.ctx.favoriteItems = data.favoriteItems or {}
                windowManager.ctx.favoriteRevision = data.favoriteRevision or 0
                windowManager.ctx.companionProfit = data.companionProfit or {}
            end
            windowManager:init()
        end,
        onInit = function()
            windowManager:init()
        end,
        onUpdate = function()
            if categoriesChanged then
                for _, window in pairs(windowManager.windows) do
                    if window.categoryFilter then
                        window.categoryFilter.layout.userData.updateCategories()
                    end
                    if window.itemTable then
                        window.itemTable.layout.userData.refresh()
                    end
                end
                categoriesChanged = false
            end
        end,
        onControllerButtonPress = function(id)
            windowManager:onControllerButtonPress(id)
        end,
        onControllerButtonRelease = function(id)
            windowManager:onControllerButtonRelease(id)
        end,
        onMouseButtonPress = function(button)
            windowManager:onMouseButtonPress(button)
        end,
        onMouseButtonRelease = function(button)
            windowManager:onMouseButtonRelease(button)
        end,
        onKeyPress = function(key)
            windowManager:onKeyPress(key)
        end,
    },
    eventHandlers = eventHandlers,
}