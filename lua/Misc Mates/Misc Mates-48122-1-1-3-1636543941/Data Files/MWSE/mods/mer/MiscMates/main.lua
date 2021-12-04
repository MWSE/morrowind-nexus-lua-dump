
local configPath = "MiscMates"
local config = mwse.loadConfig(configPath, {
    enabled = true,
    maxItemValue = 50,
    logLevel = "INFO"
})

local log = require("mer.MiscMates.logger").new({
    name = "Misc Mates",
    logLevel = config.logLevel
})

---METHODS-------------------------------------------------------------------------------------------------------------

---@param itemRef tes3reference
---@return number
local function getMinimumDispositionToTakeItem(itemRef)
    local defaultDisposition = 70
    local goldEffect = math.remap(itemRef.object.value, 1, 100, 1.0, 4.0 )
    local personalityEffect = math.remap(math.log(tes3.mobilePlayer.personality.current), 0, 4.6, 1.0, 0.70)
    local dispositionRequired = defaultDisposition * goldEffect * personalityEffect
    return dispositionRequired
end

---@param ownerRef tes3reference
---@param itemRef tes3reference
---@return boolean
local function dispositionIsHighEnough(ownerRef, itemRef)
    if ownerRef and ownerRef.object and ownerRef.object.disposition then
        return math.min(ownerRef.object.disposition, 100) > getMinimumDispositionToTakeItem(itemRef)
    else
        return false
    end
end

---@param itemRef tes3reference
---@return tes3reference|nil
local function getOwner(itemRef)
    local ownerObject = tes3.getOwner(itemRef)
    if ownerObject then
        return tes3.getReference(ownerObject.id)
    end
end

---@param ownerRef tes3reference|nil
---@return boolean
local function ownerIsValid(ownerRef)
    if not ownerRef then
        return false
    end
    if ownerRef.mobile and ownerRef.mobile.health.current <= 0 then
        return false
    end
    return true
end

---@param itemRef tes3reference
---@return boolean
local function itemIsCheapEnough(itemRef)
    if not itemRef.object.value then
        log:debug("%s has no value", itemRef)
    end
    return itemRef.object.value <= config.maxItemValue
end


---@param reference tes3reference
---@return boolean
local function itemRefIsValid(reference)
    return reference ~= nil
        and reference.object ~= nil
        and reference.object.value ~= nil
        and (not reference.object.isKey)
        and (not reference.object.isGold)
        and (not reference.object.script)
end

---@param itemRef tes3reference
---@param ownerRef tes3reference
local function removeItemOwnership(itemRef, ownerRef)
    if itemRef.itemData then
        itemRef.itemData.data.ownerPermitted = ownerRef.object.id
        itemRef.itemData.owner = nil
    end
end

---@param itemRef tes3reference
local function restoreItemOwnership(itemRef)
    if itemRef.itemData then
        log:debug("Previous owner data: %s", itemRef.itemData.data.ownerPermitted)
        tes3.setOwner{ reference = itemRef, owner = itemRef.itemData.data.ownerPermitted}
        itemRef.itemData.data.ownerPermitted = nil
    end
end

---@param itemRef tes3reference
---@param ownerRef tes3reference
local function ownerCanGiveItem(itemRef, ownerRef)
    if not ownerRef then return end
    if not itemRef then return end
    if not ownerIsValid(ownerRef) then return end
    if tes3.checkMerchantTradesItem{ item = itemRef.object, reference =  ownerRef} then return end
    return true
end

---@param itemRef tes3reference
local function itemRefHasPreviousOwner(itemRef)
    return itemRef
        and itemRef.data
        and itemRef.data.ownerPermitted
end

---EVENT FUNCTIONS--------------------------------------------------------------------------------------------------------------

--[[
    Called whenever the player looks at an item
    and checks if the owner allows them to take it
]]
---@param e uiObjectTooltipEventData
local function updateOwnership(e)
    if not config.enabled then return end
    local itemRef = e.reference
    if itemRefIsValid(itemRef) and itemIsCheapEnough(itemRef) then
        log:debug("Valid Item")
        local ownerRef = getOwner(itemRef)
        if ownerCanGiveItem(itemRef, ownerRef) then
            log:debug("Owner can give item")
            if dispositionIsHighEnough(ownerRef, itemRef) then
                log:debug("Allowed to take %s from %s, removing ownership", itemRef, ownerRef)
                removeItemOwnership(itemRef, ownerRef)
            end
        elseif itemRefHasPreviousOwner(itemRef) then
            log:debug("item has previous owner")
            local previousOwner = tes3.getReference(itemRef.data.ownerPermitted)
            if not dispositionIsHighEnough(previousOwner, itemRef) then
                log:debug("No longer allowed to take %s from %s, restoring ownership", itemRef, previousOwner)
                restoreItemOwnership(itemRef)
            end
        end
    end
end
event.register(tes3.event.uiObjectTooltip, updateOwnership)

--[[
    Remove data when picking up to prevent stack splitting
]]
---@param e activateEventData
local function removeDataOnActivate(e)
    if e.target.itemData and e.target.itemData.data.ownerPermitted then
        log:debug("Removing ownership data on pickup")
        e.target.itemData.data.ownerPermitted = nil
    end
end
event.register(tes3.event.activate, removeDataOnActivate)

---MCM--------------------------------------------------------------------------------------------------------------

local function registerMcm()
    local template = mwse.mcm.createTemplate{ name = "Misc Mates"}
    template:register()
    template:saveOnClose(configPath, config)

    local page = template:createSideBarPage{
        description = "This mod makes it so that NPCs will allow you to take small inexpensive items if their disposition towards you is high enough. The disposition required is based on the gold value of the item and the player's personality."
    }

    page:createOnOffButton{
        label = "Mod Enabled",
        description = "Turn the mod on or off.",
        variable = mwse.mcm.createTableVariable{ id = "enabled", table = config }
    }

    page:createDropdown{
        label = "Log Level",
        description = "Set the logging level for mwse.log: Keep on INFO unless you are debugging.",
        options = {
            { label = "TRACE", value = "TRACE"},
            { label = "DEBUG", value = "DEBUG"},
            { label = "INFO", value = "INFO"},
            { label = "ERROR", value = "ERROR"},
            { label = "NONE", value = "NONE"},
        },
        variable = mwse.mcm.createTableVariable{ id = "logLevel", table = config },
        callback = function(self)
            log:setLogLevel(self.variable.value)
        end
    }

    page:createTextField{
        label = "Max Item Value",
        description = "Set the max value of an item that an NPC can let you take.",
        variable = mwse.mcm.createTableVariable{ id = "maxItemValue", table = config, numbersOnly = true, converter = tonumber },
    }
end

event.register("modConfigReady", registerMcm)