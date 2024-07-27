local itemLib = include("Morrowind_World_Randomizer.item")

local eventNameAdd = "mwr_itemWasAdded"
local eventNameRem = "mwr_itemWasRemoved"

--- It doesn't track itemData
local this = {}

this.lastItems = nil

---@class mwr_inventoryEventItemData
---@field id string
---@field count integer
---@field object any

---@return table<string, mwr_inventoryEventItemData>|nil
function this.getInventoryChanges()
    local player = tes3.mobilePlayer
    if not this.lastItems or not player then return end
    local newItemsData = this.getInventoryChangesData()
    local changed = {}
    for id, stack in pairs(newItemsData) do
        if this.lastItems[id] then
            local lastData = this.lastItems[id]
            if stack.count > lastData.count then
                local data = {id = id, count = stack.count - lastData.count, object = stack.object}
                changed[id] = data
                event.trigger(eventNameAdd, data)
            elseif stack.count < lastData.count then
                local data = {id = id, count = lastData.count - stack.count, object = stack.object}
                changed[id] = {id = id, count = -data.count, object = stack.object}
                event.trigger(eventNameRem, data)
            end
            this.lastItems[id] = nil
        else
            local data = {id = id, count = stack.count, object = stack.object}
            changed[id] = data
            event.trigger(eventNameAdd, data)
        end
    end
    for id, stack in pairs(this.lastItems) do
        local data = {id = id, count = stack.count, object = stack.object}
        changed[id] = {id = id, count = -stack.count, object = stack.object}
        event.trigger(eventNameRem, data)
    end
    this.lastItems = newItemsData
    return changed
end

function this.getInventoryChangesData()
    local player = tes3.mobilePlayer
    if not player then return {} end
    local newItemsData = {}
    for _, stack in pairs(player.inventory) do
        if not newItemsData[stack.object.id] then
            newItemsData[stack.object.id] = {count = 0, itData = {}, object = stack.object}
        end
        local newData = newItemsData[stack.object.id]
        newData.count = newData.count + stack.count
        -- if stack.variables then
        --     for _, var in pairs(stack.variables) do
        --         newData.itData[var] = true
        --     end
        -- end
    end
    return newItemsData
end

function this.saveInventoryChanges()
    this.lastItems = this.getInventoryChangesData()
end

function this.reset()
    this.lastItems = nil
end

function this.start()
    this.lastItems = {}
end

---@param id string
function this.makeItemUnadded(id)
    local player = tes3.mobilePlayer
    if not this.lastItems or not player then return end
    this.lastItems[id] = nil
end

return this