local common = {}

local config = require("mer.joyOfPainting.config")

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
        logLevel = config.mcm.logLevel,
        includeTimestamp = true,
    }
    common.loggers[serviceName] = logger
    return logger
end
local logger = common.createLogger("common")

function common.getVersion()
    return config.metadata.package.version
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
                        to = tes3.player,
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

return common