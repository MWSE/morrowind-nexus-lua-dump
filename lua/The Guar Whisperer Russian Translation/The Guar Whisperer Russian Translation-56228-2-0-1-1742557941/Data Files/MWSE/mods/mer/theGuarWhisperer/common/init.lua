

---@class GuarWhisperer.Common.targetData
---@field reference tes3reference
---@field intersection tes3vector3
---@field playerTarget tes3reference

---@class GuarWhisperer.Common
---@field activeCompanion GuarWhisperer.GuarCompanion
---@field targetData GuarWhisperer.Common.targetData
local common = {}
common.config = require("mer.theGuarWhisperer.config")
common.util = require("mer.theGuarWhisperer.common.Util")

---TODO: access with getters, move to player.tempData
---This holds a list of references guars are currently taking an action towards
common.fetchItems = {}

---@type table<string, mwseLogger>
common.loggers = {}
local MWSELogger = require("logging.logger")
function common.createLogger(serviceName)
    local logger = MWSELogger.new{
        name = string.format("GuarWhisperer - %s", serviceName),
        logLevel = common.config.mcm.logLevel,
        includeTimestamp = true,
    }
    common.loggers[serviceName] = logger
    return logger
end
local logger = common.createLogger("common")

common.packId = "mer_tgw_guarpack"
common.balls = {
    mer_tgw_ball = true,
    mer_tgw_ball_02 = true,
}
common.fluteId = "mer_tgw_flute"
common.fluteSound = "mer_flutesound"

function common.getModEnabled()
    return (
        common.config.mcm.enabled and
        tes3.isModActive("TheGuarWhisperer.ESP")
    )
end


local function initialiseData()
    if not tes3.player.data.theGuarWhisperer then
        tes3.player.data.theGuarWhisperer = {}
    end

    common.data = tes3.player.data.theGuarWhisperer
    --in case you were stupid enough to save/load during a fadeout
    if common.config.isFading  then
        tes3.fadeIn()
    end
    event.trigger("GuarWhispererDataLoaded")
end
event.register("loaded", initialiseData)


function common.getIsDead(ref)
    if not ref.mobile then return false end
    local animState = ref.mobile.actionData.animationAttackState
    local isDead = (
        ref.mobile.health.current <= 0 or
        animState == tes3.animationState.dying or
        animState == tes3.animationState.dead
    )
    return isDead
end

local function onLoadInitialiseRefs(e)
    logger:debug("\n\nInitialising companion refs")
    for i, cell in ipairs(tes3.dataHandler.nonDynamicData.cells) do
        for reference in cell:iterateReferences() do
            event.trigger("GuarWhisperer:registerReference", { reference = reference })
        end
    end
end
event.register("loaded", onLoadInitialiseRefs)

function common.addToEasyEscortBlacklist(obj)
    local easyEscort = include("Easy Escort.interop")
    if easyEscort then
        logger:info("Adding %s to Easy Escort blacklist", obj.id)
        easyEscort.addToBlacklist(obj.id)
    end
end

---@param obj tes3creature
---@return tes3creature
function common.createCreatureCopy(obj)
    logger:debug("Creating copy of %s", obj.id)
    local newObj = obj:createCopy{}
    newObj.persistent = true
    newObj.modified = true
    common.addToEasyEscortBlacklist(newObj)
    return newObj
end

local function isLuaFile(file) return file:sub(-4, -1) == ".lua" end
local function isInitFile(file) return file == "init.lua" end
--Execute all lua files in the given directory
function common.initAll(path)
    for file in lfs.dir(path) do
        if isLuaFile(file) and not isInitFile(file) then
            logger:debug("Executing file: %s", file)
            dofile(path .. file)
        end
    end
end

return common