---@class MidnightOil.common
local common = {}

---@class MidnightOil.LightToggleEventData
---@field reference tes3reference The reference being turned on or off

local conf = require("mer.midnightOil.config")
local config = conf.getConfig()

---@type mwseLogger[]
common.loggers = {}
--- Create a new logger
---@param name string
---@return table<string, mwseLogger>
common.createLogger = function(name)
    local MwseLogger = require("logging.logger")
    local logger = MwseLogger.new{
        name = string.format("Midnight Oil - %s", name),
        logLevel = conf.getConfig().logLevel,
        includeTimestamp = true,
    }
    common.loggers[name] = logger
    return logger
end
local logger = common.createLogger("Common")

common.merchantContainers = {
    ["ra'virr"] = "mer_lntrn_merch",
    ["arrille"] = "mer_lntrn_merch",
    ["mebestian ence"] = "mer_lntrn_merch",
    ["alveno andules"] = "mer_lntrn_merch",
    ["dralasa nithryon"] = "mer_lntrn_merch",
    ["galtis guvron"] = "mer_lntrn_merch",
    ["goldyn belaram"] = "mer_lntrn_merch",
    ["irgola"] = "mer_lntrn_merch",
    ["clagius clanler"] = "mer_lntrn_merch",
    ["fadase selvayn"] = "mer_lntrn_merch",
    ["naspis apinia"] = "mer_lntrn_merch",
    ["tiras sadus"] = "mer_lntrn_merch",
    ["thongar"] = "mer_lntrn_merch",
    ["heifnir"] = "mer_lntrn_merch",
    ["berwen"] = "mer_lntrn_merch",
}

common.merchantClassContainers = {
    t_sky_publican = "mer_lntrn_merch",
    t_cyr_publican = "mer_lntrn_merch",
    publican = "mer_lntrn_merch",
    pawnbroker = "mer_lntrn_merch",
}

common.oil = {
    ["mer_lntrn_flask"] = true
}

common.candle = {
    ["mer_lntrn_candle"] = true
}

common.oilSource = {
    ["terrain_ashmire_02"] = true
}

common.lightPatterns = {
    "candle",
    "lantern",
    "lamp",
    "chandelier",
    "sconce",
    "streetlight",
    "torch",
    "light_spear_skull",
    "t_de_var_swimlant",
    "ab_light_delant",
    "ab_light_cavelantern",
    "ab_light_comsconsilv",
}

common.candlePatterns = {
    "candle",
    "lantern"
}

common.oilLanterns = {
    --lamps
    ["light_com_redware_lamp"] = true,
    ["light_de_buglamp_01"] = true,
    ["light_de_buglamp_01_64"] = true,
    ["light_de_buglamp_01_off"] = true,
}

common.blacklist = {}
function common.isBlacklisted(obj)
    return common.blacklist[obj.id:lower()]
end

---@return boolean
function common.cellIsBlacklisted(cell)
    return config.cellBlacklist[cell.editorName]
end


function common.modActive()
    return conf.getConfig().enabled == true
end

function common.wasToggledToday(reference)
    return (
        reference.data and
        reference.data.dayLightManuallyToggled and
        reference.data.dayLightManuallyToggled >= tes3.worldController.daysPassed.value
    )
end

function common.setToggledDay(reference)
    reference.data.dayLightManuallyToggled = tes3.worldController.daysPassed.value
end

function common.isSwitchable(obj)
    if common.isBlacklisted(obj) then return end
    for _, pattern in ipairs(common.lightPatterns) do
        if string.find(obj.id:lower(), pattern) then
            return true
        end
    end
    return false
end

function common.isOilSource(obj)
    if common.isBlacklisted(obj) then return end
    obj = obj.baseObject or obj
    return common.oilSource[obj.id:lower()]
end

function common.isOil(obj)
    if common.isBlacklisted(obj) then return end
    obj = obj.baseObject or obj
    return common.oil[obj.id:lower()]
end

function common.isCandleLantern(obj)
    if common.isBlacklisted(obj) then return end
    if common.isCarryableLight(obj) then
        for _, pattern in ipairs(common.candlePatterns) do
            if string.find(obj.id:lower(), pattern) then
                return true
            end
        end
    end
    return false
end

function common.isCandle(obj)
    if common.isBlacklisted(obj) then return end
    obj = obj.baseObject or obj
    return common.candle[obj.id:lower()]
end

--Is an oil lantern
function common.isOilLantern(obj)
    if common.isBlacklisted(obj) then return end
    obj = obj.baseObject or obj

    local isOilLantern = (
        obj.objectType == tes3.objectType.light and
        common.oilLanterns[obj.id:lower()] == true
    )
    return isOilLantern
end

--is a carryable light
function common.isCarryableLight(obj)
    if common.isBlacklisted(obj) then
        return false
    end
    if common.blacklist[obj.id:lower()] then
        return false
    end
    return obj.objectType == tes3.objectType.light and obj.canCarry
end

function common.isLight(obj)
    if common.isBlacklisted(obj) then return end
    return  common.isCandleLantern(obj)
end

local function traverse(roots)
    local function iter(nodes)
        for _, node in ipairs(nodes or roots) do
            if node then
                coroutine.yield(node)
                if node.children then
                    iter(node.children)
                end
            end
        end
    end
    return coroutine.wrap(iter)
end

function common.canProcessLight(reference)
    logger:trace("Processing light %s", reference.object.id)
    if not reference.supportsLuaData then
        logger:trace("Reference %s does not support lua data", reference.object.id)
        --Can't support lua data
        return false
    end
    if not reference.sceneNode then
        logger:trace("Reference %s has no scene node", reference.object.id)
        --No scene node
        return false
    end
    if (config.staticLightsOnly and reference.object.canCarry) then
        logger:trace("Reference %s is a carryable light", reference.object.id)
        --Carryable light when staticLightsOnly is set
        return false
    end
    if not common.isSwitchable(reference.object) then
        logger:trace("Reference %s is not a switchable light", reference.object.id)
        --Not a switchable light
        return false
    end
    return true
end

---Removes the light by
---traversing the scene node and
---deleting lights, particles and emissives
function common.removeLight(ref)
    event.trigger("MidnightOil:RemoveLight", {reference = ref})
    logger:debug("Removing light %s", ref.object.id)
    ref:deleteDynamicLightAttachment()
    tes3.removeSound{reference=ref}
    local lightNode = ref.sceneNode
    for node in traverse{lightNode} do
        --Kill particles
        if node.RTTI.name == "NiBSParticleNode" then
            node.appCulled = true
        end
        --Kill Melchior's Lantern glow effect
        if node.name == "LightEffectSwitch" or node.name == "Glow" then
            node.appCulled = true
        end

        -- Kill materialProperty
        local materialProperty = node:getProperty(0x2)
        if materialProperty then
            if (materialProperty.emissive.r > 1e-5 or materialProperty.emissive.g > 1e-5 or materialProperty.emissive.b > 1e-5 or materialProperty.controller) then
                materialProperty = node:detachProperty(0x2):clone()
                node:attachProperty(materialProperty)

                -- Kill controllers
                materialProperty:removeAllControllers()

                -- Kill emissives
                local emissive = materialProperty.emissive
                emissive.r, emissive.g, emissive.b = 0,0,0
                materialProperty.emissive = emissive

                node:updateProperties()
            end
        end
     -- Kill glowmaps
        local texturingProperty = node:getProperty(0x4)
        local newTextureFilepath = "Textures\\tx_black_01.dds"
        if (texturingProperty and texturingProperty.maps[4]) then
        texturingProperty.maps[4].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
        if (texturingProperty and texturingProperty.maps[5]) then
            texturingProperty.maps[5].texture = niSourceTexture.createFromPath(newTextureFilepath)
        end
    end
    ref.sceneNode:update()
    ref.sceneNode:updateNodeEffects()
    ref.data.lightTurnedOff = true
    ref.modified = true
    event.trigger("MidnightOil:RemovedLight", {reference = ref})
end

---Turns the light back on by creating a new
---reference with the same data as the old one
---@param lightRef tes3reference
function common.onLight(lightRef)
    if not lightRef.supportsLuaData then return end
    event.trigger("MidnightOil:TurnLightOn", {reference = lightRef})
    logger:debug("Turning light %s on", lightRef.object.id)
    local data = lightRef.data
    data.lightTurnedOff = false


    local object = lightRef.object
    if lightRef.object.isOffByDefault then
        local onId = lightRef.object.id:lower():gsub("_off$", "")
        local onObject = tes3.getObject(onId)
        if onObject then
            logger:debug("Found on version of %s", lightRef.object.id)
            object = onObject
        else
            logger:debug("No on version of %s", lightRef.object.id)
        end
    end

    local newRef = tes3.createReference{
        object = object,
        position = lightRef.position:copy(),
        orientation = lightRef.orientation:copy(),
        cell = lightRef.cell
    }
    newRef.scale = lightRef.scale

    for k, v in pairs(data) do
        newRef.data[k] = v
    end

    if lightRef.itemData then
        newRef.itemData = lightRef.itemData
        lightRef.itemData = nil
    end
    newRef.modified = true
    lightRef:delete()
    logger:debug("Light %s turned on, old ref deleted", newRef.object.id)

    event.trigger("MidnightOil:TurnedLightOn", {reference = newRef})
end

return common