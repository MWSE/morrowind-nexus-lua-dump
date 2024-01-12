local GuarCompanion = require("mer.theGuarWhisperer.GuarCompanion")
local guarConfig = require("mer.theGuarWhisperer.guarConfig")
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("GuarConverter")

---@class GuarWhisperer.GuarConverter.convert.params
---@field reference tes3reference

---@class GuarWhisperer.GuarConverter
local GuarConverter = {}

---Override the base object stats
---@param baseObject tes3creature
---@param convertConfig GuarWhisperer.ConvertConfig
function GuarConverter.overrideStats(baseObject, convertConfig)
    local statOverrides = convertConfig.statOverrides
    if not statOverrides then return end
    logger:debug("Overriding stats")
    if statOverrides.attributes then
        logger:debug("Overriding attributes")
        for attribute, value in pairs(statOverrides.attributes) do
            logger:debug("Setting %s to %d", attribute, value)
            baseObject.attributes[tes3.attribute[attribute] + 1] = value
        end
    end
    if statOverrides.attackMin or statOverrides.attackMax then
        for _, attack in ipairs(baseObject.attacks) do
            if statOverrides.attackMin then
                logger:debug("Setting attack min to %d", statOverrides.attackMin)
                attack.min = statOverrides.attackMin
            end
            if statOverrides.attackMax then
                logger:debug("Setting attack max to %d", statOverrides.attackMax)
                attack.max = statOverrides.attackMax
            end
        end
    end
end


---@param reference tes3reference
---@param convertConfig GuarWhisperer.ConvertConfig
function GuarConverter.convert(reference, convertConfig)
    if reference.deleted then return end
    if reference.disabled then return end
    logger:debug("Converting %s into type '%s'", reference.object.id, convertConfig.type)
    local newObj = common.createCreatureCopy(reference.baseObject)
    if convertConfig.mesh then
        logger:debug("Replacing mesh with %s", convertConfig.mesh)
        newObj.mesh = convertConfig.mesh
    end
    GuarConverter.overrideStats(newObj, convertConfig)
    newObj.swims = true
    newObj.script = tes3.dataHandler.nonDynamicData:findScript("mer_tgw_guarscript")

    local guarData = GuarCompanion.getData(reference)
    local name = guarData and guarData.name or convertConfig.name
    if name then
        logger:debug("Replacing name with %s", name)
        newObj.name = name
    end

    reference.hasNoCollision = true
    local newRef = tes3.createReference{
        object = newObj,
        position = reference.position,
        orientation =  {
            reference.orientation.x,
            reference.orientation.y,
            reference.orientation.z,
        },
        cell = reference.cell,
    }
    if guarData then
        newRef.data.tgw = table.copy(guarData)
    end

    --clear inventory
    logger:debug("Clearing inventory")
    for _, stack in pairs(newRef.object.inventory) do
        newRef.object.inventory:removeItem{
            item = stack.object,
            playSound = false
        }
    end

    if convertConfig.transferInventory then
        logger:debug("Transfering existing inventory")
        for _, stack in pairs(reference.object.inventory) do
            tes3.transferItem{
                from = reference,
                to = newRef,
                item = stack.object,
                count = stack.count or 1,
                playSound=false
            }
        end
    end
    --Remove old ref
    reference:delete()

    GuarCompanion.initialiseRefData(newRef, convertConfig.type)
    table.copymissing(newRef.data.tgw, convertConfig.extra)
    local guar = GuarCompanion.get(newRef)
    if not guar then
        logger:error("Failed to create guar from reference %s", newRef)
        return
    end
    if guar.pack:hasPack() then
       guar.pack:setSwitch()
    end
    guar.genetics:randomiseGenes()

    logger:debug("Conversion done")
    return guar
end

---Get the guar type and extra data for a given vanilla
--- guar reference.
---@param reference tes3reference
---@return GuarWhisperer.ConvertConfig?
function GuarConverter.getConvertConfig(reference)
    logger:trace("Get convert data")
    if not reference then
        logger:trace("No reference")
        return nil
    end
    if not reference.mobile then
        logger:trace("No mobile")
        return nil
    end
    if not (reference.object.objectType == tes3.objectType.creature) then
        logger:trace("Not a creature")
        return nil
    end
    local crMesh = reference.object.mesh:lower()
    logger:trace("Finding type for mesh %s", crMesh)
    local typeData = guarConfig.meshToConvertConfig[crMesh]
    if typeData then
        return typeData
    else
        logger:trace("No type data")
        return nil
    end
end

---@param convertConfig GuarWhisperer.ConvertConfig
---@return GuarWhisperer.AnimalType
function GuarConverter.getTypeFromConfig(convertConfig)
    return guarConfig.animals[convertConfig.type]
end

return GuarConverter