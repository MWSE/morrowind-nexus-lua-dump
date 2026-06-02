local types = require'openmw.types'
local util = require'openmw.util'

local M = {}

M.fn = {}
M.meta = {
    __index = M.fn
}

function M.propsFromGameObject(object)
    -- Cell object is not serializable,
    -- so it must be represented by its name, if present.
    local cellName = ''

    if object.cell then
        cellName = object.cell.name
    end

    local itemData = types.Item.itemData(object)

    return {
        cell = cellName,
        count = object.count,
        position = object.position,
        recordId = object.recordId,
        rotation = object.rotation,
        itemData = {
            condition = itemData.condition,
            enchantmentCharge = itemData.enchantmentCharge,
            soul = itemData.soul
        }
    }
end

function M.new(props)
    return setmetatable(
        {
            _cell = assert(props.cell),
            _count = assert(props.count),
            _position = assert(props.position),
            _recordId = assert(props.recordId),
            _rotation = assert(props.rotation),
            _itemData = assert(props.itemData)
        },
        M.meta
    )
end

function M.fn:findInInventory(inventory)
    for _, stack in ipairs(inventory:findAll(self._recordId)) do
        local itemData = types.Item.itemData(stack)

        if itemData.condition == self._itemData.condition
            and itemData.enchantmentCharge == self._itemData.enchantmentCharge
            and itemData.soul == self._itemData.soul
        then
            return stack
        end
    end

    return nil
end

function M.fn:teleportToStackPosition(inventoryStack, keepOne)
    local returnedStack

    if keepOne then
        local count = util.clamp(self._count - 1, 0, inventoryStack.count)

        if count == 0 then
            return
        end

        returnedStack = inventoryStack:split(count)
    else
        returnedStack = inventoryStack
    end

    returnedStack:teleport(
        self._cell,
        self._position,
        {rotation = self._rotation}
    )
end

return M
