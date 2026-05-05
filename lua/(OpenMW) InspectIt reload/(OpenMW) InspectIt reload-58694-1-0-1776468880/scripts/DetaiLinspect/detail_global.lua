local world = require('openmw.world')
local util = require('openmw.util')

local _player = world.players[1]
local _previewItem = nil
local _itemRotation = { x = 0, y = 0, z = 0 }
local _itemPos = { x = 0, y = 50, z = 105 }
local _isTeleporting = false

local function createObjectToPreview(data)
    if not data or not data.referenceId then return end

    _previewItem = world.createObject(data.referenceId, 1)

    if _previewItem then
        local playerCell = _player and _player.cell
        if playerCell then
            _previewItem:teleport(
                playerCell,
                _player.position + util.vector3(_itemPos.x, _itemPos.y, _itemPos.z)
            )
        end
    end
end

local function destroyObjectToPreview()
    if _previewItem then
        _previewItem:remove(1)
        _previewItem = nil
        _itemRotation = { x = 0, y = 0, z = 0 }
        _itemPos = { x = 0, y = 50, z = 105 }
    end
end

local function zoomPreviewObject(data)
    if not data or not _previewItem or _isTeleporting then return end

    _isTeleporting = true

    _itemPos.y = _itemPos.y + (data.zoom * 4)

    local playerCell = _player and _player.cell
    if playerCell then
        pcall(function()
            _previewItem:teleport(
                playerCell,
                _player.position + util.vector3(_itemPos.x, _itemPos.y, _itemPos.z)
            )
        end)
    end

    _isTeleporting = false
end

local function rotatePreviewObject(data)
    if not data or not _previewItem then return end

    local dz = _itemRotation.z + data.movePos.x * 0.01
    local dx = _itemRotation.x + data.movePos.y * 0.005

    local playerCell = _player and _player.cell
    if playerCell then
        pcall(function()
            _previewItem:teleport(
                playerCell,
                _player.position + util.vector3(_itemPos.x, _itemPos.y, _itemPos.z),
                util.transform.rotateX(dx):__mul(util.transform.rotateZ(dz))
            )
        end)
        _itemRotation.z = dz
        _itemRotation.x = dx
    end
end

local function translatePreviewObject(data)
    if not data or not _previewItem or _isTeleporting then return end

    _isTeleporting = true

    local moveSpeed = 0.05

    _itemPos.x = _itemPos.x + (data.movePos.x * moveSpeed)

    _itemPos.z = _itemPos.z + (data.movePos.y * moveSpeed * -1) 

    local maxX = 40
    local minX = -40
    local maxZ = 130
    local minZ = 100

    _itemPos.x = math.max(minX, math.min(maxX, _itemPos.x))
    _itemPos.z = math.max(minZ, math.min(maxZ, _itemPos.z))

    local playerCell = _player and _player.cell
    if playerCell then
        pcall(function()
            _previewItem:teleport(
                playerCell,
                _player.position + util.vector3(_itemPos.x, _itemPos.y, _itemPos.z)
            )
        end)
    end

    _isTeleporting = false
end

local function onUpdate(dt)
    -- object position WIP
end

local function onLoad(data)
    print("Inspect Preview Global mod loaded")
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onInit = onLoad,
        onUpdate = onUpdate,
    },
    eventHandlers = {
        createObjectToPreview = createObjectToPreview,
        destroyObjectToPreview = destroyObjectToPreview,
        rotatePreviewObject = rotatePreviewObject,
        translatePreviewObject = translatePreviewObject,
        zoomPreviewObject = zoomPreviewObject
    }
}
