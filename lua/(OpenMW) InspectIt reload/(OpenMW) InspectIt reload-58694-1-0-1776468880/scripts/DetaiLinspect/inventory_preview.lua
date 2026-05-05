local world = require('openmw.world')
local util = require('openmw.util')

local _player = world.players[1]
local _inventoryPreviewItem = nil
local _invItemRotation = { x = 0, y = 0, z = 0 }
local _invItemPos = { x = 0, y = 50, z = 105 }
local _isInvTeleporting = false

local function createInventoryPreviewObject(data)
    if not data or not data.referenceId then return end

    _inventoryPreviewItem = world.createObject(data.referenceId, 1)

    if _inventoryPreviewItem then
        local playerCell = _player and _player.cell
        if playerCell then
            _inventoryPreviewItem:teleport(
                playerCell,
                _player.position + util.vector3(_invItemPos.x, _invItemPos.y, _invItemPos.z)
            )
        end
    end
end

local function destroyInventoryPreviewObject()
    if _inventoryPreviewItem then
        _inventoryPreviewItem:remove(1)
        _inventoryPreviewItem = nil
        _invItemRotation = { x = 0, y = 0, z = 0 }
        _invItemPos = { x = 0, y = 50, z = 105 }
    end
end

local function zoomInventoryPreviewObject(data)
    if not data or not _inventoryPreviewItem or _isInvTeleporting then return end

    _isInvTeleporting = true

    _invItemPos.y = _invItemPos.y + (data.zoom * 4)

    local playerCell = _player and _player.cell
    if playerCell then
        pcall(function()
            _inventoryPreviewItem:teleport(
                playerCell,
                _player.position + util.vector3(_invItemPos.x, _invItemPos.y, _invItemPos.z)
            )
        end)
    end

    _isInvTeleporting = false
end

local function rotateInventoryPreviewObject(data)
    if not data or not _inventoryPreviewItem then return end

    local dz = _invItemRotation.z + data.movePos.x * 0.01
    local dx = _invItemRotation.x + data.movePos.y * 0.005

    local playerCell = _player and _player.cell
    if playerCell then
        pcall(function()
            _inventoryPreviewItem:teleport(
                playerCell,
                _player.position + util.vector3(_invItemPos.x, _invItemPos.y, _invItemPos.z),
                util.transform.rotateX(dx):__mul(util.transform.rotateZ(dz))
            )
        end)
        _invItemRotation.z = dz
        _invItemRotation.x = dx
    end
end

local function translateInventoryPreviewObject(data)
    if not data or not _inventoryPreviewItem or _isInvTeleporting then return end

    _isInvTeleporting = true

    local moveSpeed = 0.05
    _invItemPos.x = _invItemPos.x + (data.movePos.x * moveSpeed)
    _invItemPos.z = _invItemPos.z + (data.movePos.y * moveSpeed * -1)

    local maxX = 40
    local minX = -40
    local maxZ = 130
    local minZ = 100

    _invItemPos.x = math.max(minX, math.min(maxX, _invItemPos.x))
    _invItemPos.z = math.max(minZ, math.min(maxZ, _invItemPos.z))

    local playerCell = _player and _player.cell
    if playerCell then
        pcall(function()
            _inventoryPreviewItem:teleport(
                playerCell,
                _player.position + util.vector3(_invItemPos.x, _invItemPos.y, _invItemPos.z)
            )
        end)
    end

    _isInvTeleporting = false
end

local function onLoad(data)
    print("Inventory Inspect Preview Global mod loaded")
end

return {
    engineHandlers = {
        onLoad = onLoad,
    },
    eventHandlers = {
        createInventoryPreviewObject = createInventoryPreviewObject,
        destroyInventoryPreviewObject = destroyInventoryPreviewObject,
        rotateInventoryPreviewObject = rotateInventoryPreviewObject,
        translateInventoryPreviewObject = translateInventoryPreviewObject,
        zoomInventoryPreviewObject = zoomInventoryPreviewObject
    }
}
