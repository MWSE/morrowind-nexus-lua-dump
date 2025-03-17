local common = {}

common.config = require("mer.joyOfPainting.config")
local MWSELogger = require("logging.logger")
local CraftingFramework = require("CraftingFramework")

local inspect = include("inspect")
common.inspect = function(root, any)

    if inspect then
        return inspect.inspect(root, any)
    end
    return "[inspect not installed]"
end

---@type table<string, mwseLogger>
common.loggers = {}

function common.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("JoyOfPainting - %s", serviceName),
        logLevel = common.config.mcm.logLevel,
        includeTimestamp = true,
    }
    common.loggers[serviceName] = logger
    return logger
end
local logger = common.createLogger("common")

function common.getVersion()
    return common.config.metadata.package.version
end

---@param reference tes3reference
---@return boolean
function common.isStack(reference)
    return (
        reference.attachments and
        reference.attachments.variables and
        reference.attachments.variables.count > 1
    )
end

function common.isShiftDown()
    return tes3.worldController.inputController:isKeyDown(tes3.scanCode.lShift)
end

---@param target tes3reference
function common.pickUp(target)
    tes3.addItem({
        reference = tes3.player,
        item = target.object --[[@as JOP.tes3itemChildren]],
        count = 1,
        itemData = target.itemData,
    })
    target.itemData = nil
    target:delete()
end

function common.closeEnough(reference)
    return reference.position:distance(tes3.player.position) < tes3.getPlayerActivationDistance()
end

function common.disablePlayerControls()
    logger:debug("Disabling player controls")
    --disable everything except vanity
    tes3.setPlayerControlState{ enabled = false}
    tes3.player.data.jopDisablePlayerControls = true
end

function common.enablePlayerControls()
    logger:debug("Enabling player controls")
    tes3.setPlayerControlState{ enabled = true}
    tes3.player.data.jopDisablePlayerControls = true
end

--On load, enable controls if they are disabled
--This covers case where you auto-saved while painting
event.register("loaded", function()
    if tes3.player.data.jopDisablePlayerControls then
        common.enablePlayerControls()
    end
end)

function common.isLuaFile(file) return file:sub(-4, -1) == ".lua" end
function common.isInitFile(file) return file == "init.lua" end


local function blockActivate()
    if not tes3.player.tempData.jopBlockActivate then
        event.unregister("activate", blockActivate, { priority = 5})
        return
    end
    return true
end

function common.blockActivate()
    tes3.player.tempData.jopBlockActivate = true
    event.register("activate", blockActivate, { priority = 5})
end

function common.unblockActivate()
    tes3.player.tempData.jopBlockActivate = nil
    event.unregister("activate", blockActivate, { priority = 5})
end

---@param e CraftingFramework.interop.activatePositionerParams
function common.positioner(e)
    timer.delayOneFrame(function()
        if not CraftingFramework.interop.activatePositioner then
            tes3.messageBox{
                message = "Пожалуйста, обновите Модуль ремесла, чтобы использовать эту функцию.",
                buttons = {"OK"}
            }
            return
        end
        CraftingFramework.interop.activatePositioner(e)
    end)
end

function common.getCanvasTexture(texture)
    if (lfs.fileexists(tes3.installDirectory .. "\\Data Files\\Textures\\" .. texture)) then
        return "Data Files\\Textures\\" .. texture
    else
        return "Data Files\\Textures\\jop\\" .. texture
    end
end

---@class JOP.ItemInstanceParams
---@field reference? tes3reference
---@field item? tes3item
---@field itemData? tes3itemData
---@field ownerRef? tes3reference

---@class JOP.ItemInstance
---@field reference tes3reference
---@field item tes3item
---@field itemData tes3itemData
---@field paletteItem JOP.PaletteItem
---@field data table --access to the joyOfPainting data table

---comment
---@param e JOP.ItemInstanceParams
---@param class table The class object to create an instance of
---@param thisLogger mwseLogger
---@return JOP.ItemInstance
function common.createItemInstance(e, class, thisLogger)
    thisLogger = thisLogger or logger
    thisLogger:assert((e.reference or e.item) ~= nil, "requires either a reference or an item")
    local instance = setmetatable({}, class)

    instance.ownerRef = e.ownerRef or tes3.player
    instance.reference = e.reference
    instance.item = e.item
    instance.itemData = e.itemData
    if e.reference and not e.item then
        instance.item = e.reference.object --[[@as JOP.tes3itemChildren]]
    end

    instance.dataHolder = (e.itemData ~= nil) and e.itemData or e.reference
    instance.data = setmetatable({}, {
        __index = function(_, k)
            if not (
                instance.dataHolder
                and instance.dataHolder.data
                and instance.dataHolder.data.joyOfPainting
            ) then
                return nil
            end
            return instance.dataHolder.data.joyOfPainting[k]
        end,
        __newindex = function(_, k, v)
            if instance.dataHolder == nil then
                thisLogger:debug("Setting value %s and dataHolder doesn't exist yet", k)
                if not instance.reference then
                    thisLogger:debug("instance.item: %s", instance.item)
                    --create itemData
                    instance.dataHolder = tes3.addItemData{
                        to = instance.ownerRef,
                        item = instance.item.id,
                    }
                    if instance.dataHolder == nil then
                        thisLogger:error("Failed to create itemData for instance")
                        return
                    end
                end
            end
            if not ( instance.dataHolder.data and instance.dataHolder.data.joyOfPainting) then
                instance.dataHolder.data.joyOfPainting = {}
            end
            instance.dataHolder.data.joyOfPainting[k] = v
        end
    })
    return instance
end



function common.getZoomedCursorPosition()
    local position = tes3.getCursorPosition()
    local zoom = mge.camera.zoomEnable and mge.camera.zoom or 1
    --scale to zoom from center
    position.x = position.x / zoom
    position.y = position.y / zoom

    return position
end

function common.clickedUIElement()
    local cursorPosition = tes3.getCursorPosition()
    local uiRoot = tes3.worldController.menuController.mainRoot.sceneNode
    local cursorPos, cursorDir = tes3.worldController.menuCamera.camera:windowPointToRay{cursorPosition.x, cursorPosition.y}
    local checkUiResult = tes3.rayTest{
        position = cursorPos,
        direction = cursorDir,
        root = uiRoot,
        ignore = { tes3ui.findMenu("MenuMulti").sceneNode }
    }
    return checkUiResult ~= nil
end

function common.getCursorTarget()
    if not tes3ui.menuMode() then return end

    local cursorPosition = common.getZoomedCursorPosition()
    ---@diagnostic disable-next-line: undefined-field
    local camera = tes3.worldController.worldCamera.camera
    local pos, dir = camera:windowPointToRay{cursorPosition.x, cursorPosition.y}

    local result = tes3.rayTest{
        position = pos,
        direction = dir,
        accurateSkinned = true,
        ignore = { tes3.player },
    }
    return result
end

local bit = require("bit") -- For LuaJIT bitwise shifts
local band = bit.band
local rshift = bit.rshift

---Writes a TGA file (uncompressed, type 2) by reading pixel data from a PixelMap.
---@param pixelMap JOP.PixelMap  The PixelMap object.
---@param filePath string        The output file path for the TGA.
---@param hasAlpha boolean?      If true, write 32-bit TGA (B, G, R, A). Otherwise 24-bit (B, G, R).
function common.writeTGAFromPixelMap(pixelMap, filePath, hasAlpha)
    -- 1) Gather basic info from the PixelMap
    local width  = pixelMap.width
    local height = pixelMap.height
    hasAlpha = (hasAlpha == true)
    local bitsPerPixel = hasAlpha and 32 or 24

    -- 2) Open the output file in binary mode
    local f = assert(io.open(filePath, "wb"), "Failed to open TGA file for writing.")

    ----------------------------------------------------------------------------
    -- 3) Write 18-byte TGA header for an uncompressed (type-2) true-color image
    ----------------------------------------------------------------------------
    --
    -- Byte-by-byte:
    --   0:  ID length         = 0
    --   1:  Color map type    = 0 (no color map)
    --   2:  Image type        = 2 (uncompressed, true-color)
    --   3-7:  Color map spec  = 5 bytes of 0
    --   8-9:  X origin        = 0
    --   10-11: Y origin       = 0
    --   12-13: width          (low byte, high byte)
    --   14-15: height         (low byte, high byte)
    --   16: bits per pixel    (24 or 32)
    --   17: descriptor        (0: origin at lower-left, 0 attribute bits)
    ----------------------------------------------------------------------------

    -- (0) ID length
    f:write(string.char(0))
    -- (1) Color map type
    f:write(string.char(0))
    -- (2) Image type = 2 (uncompressed, true-color)
    f:write(string.char(2))
    -- (3..7) Color map spec (5 zero bytes)
    f:write(string.char(0,0,0,0,0))
    -- (8..9) X origin = 0
    f:write(string.char(0,0))
    -- (10..11) Y origin = 0
    f:write(string.char(0,0))

    -- (12..13) Width
    local wLo = band(width, 0xFF)
    local wHi = band(rshift(width, 8), 0xFF)
    f:write(string.char(wLo, wHi))

    -- (14..15) Height
    local hLo = band(height, 0xFF)
    local hHi = band(rshift(height, 8), 0xFF)
    f:write(string.char(hLo, hHi))

    -- (16) Bits per pixel
    f:write(string.char(bitsPerPixel))

    -- (17) Descriptor = 0 => origin at lower-left, 0 attribute bits
    f:write(string.char(0))

    ----------------------------------------------------------------------------
    -- 4) Write pixel data:
    --    TGA is bottom-up, so row = 0 is the lowest. We'll flip the Y loop.
    --    Each pixel is B, G, R, (A) in the file. Our Pixel struct is also b,g,r,a.
    ----------------------------------------------------------------------------
    for row = 0, height - 1 do
        -- TGA row 0 is the bottom row. So if PixelMap row 0 is top, we invert it:
        local flippedRow = (height - 1) - row
        for col = 0, width - 1 do
            local i = flippedRow * width + col  -- no offset
            local pixel = pixelMap.pixels[i]
            -- TGA wants B, G, R, [A].
            if hasAlpha then
                f:write(string.char(pixel.b, pixel.g, pixel.r, pixel.a))
            else
                f:write(string.char(pixel.b, pixel.g, pixel.r))
            end
        end
    end

    -- 5) Done. Close file.
    f:close()
end

return common