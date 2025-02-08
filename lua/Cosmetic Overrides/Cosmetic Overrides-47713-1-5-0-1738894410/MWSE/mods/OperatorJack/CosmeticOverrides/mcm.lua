local config = require("OperatorJack.CosmeticOverrides.config")
local log = require("OperatorJack.CosmeticOverrides.logger")
local data = require("OperatorJack.CosmeticOverrides.data")
local name = config.name

local options = {}
local function getOptions(objectTypeId, objectTypeName)
    objectTypeName = objectTypeName:lower()
    local labels = { { label = "-- None --", value = nil } }

    if (tes3.player == nil) then
        log:debug("Getting Options - player is nil, so returning default options.")
        return labels
    elseif (tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeId] == nil or
            tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeId][objectTypeName] == nil) then
        log:debug("Getting Options - player vardata is nil, so returning default options.")
        return labels
    end

    for id, text in pairs(
        tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeId][objectTypeName]) do
        table.insert(labels, { label = text .. " - " .. id, value = id })
    end

    log:debug("Getting Options - checks are passed, so returning valid options.")
    return labels
end

--- Updates MCM dropdown options for the given object type.
---@param objectTypeString string The stringified object type, found via ex `mwse.longToString(e.item.objectType)`.
---@param slotName string The stringified slot name, likely found with `getSlotNameFromObject`
local function updateOptions(objectTypeString, slotName)
    slotName = slotName:lower()

    for key in pairs(options[objectTypeString][slotName]) do
        options[objectTypeString][slotName][key] = nil
    end

    table.insert(options[objectTypeString][slotName], { label = "-- None --", value = nil })

    if (tes3.player ~= nil and tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString] ~= nil) then
        for id, text in pairs(tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString][slotName]) do
            log:debug("Updating dropdown options.")
            table.insert(
                options[objectTypeString][slotName],
                { label = text .. " - " .. id, value = id }
            )
        end
    end
end

local function sortedKeys(query, sortFunction)
    local keys, len = {}, 0
    for k, _ in pairs(query) do
        len = len + 1
        keys[len] = k
    end
    table.sort(keys, sortFunction)
    return keys
end

local function createDropDownsForCategory(category, typeId, typeObject)
    for _, slotName in pairs(sortedKeys(typeObject.types)) do
        if (not typeObject.blockedSlots[slotName]) then
            local slotNameLower = slotName:lower()
            if (options[typeId] == nil) then options[typeId] = {} end
            options[typeId][slotNameLower] = getOptions(typeId, slotNameLower)

            category:createDropdown({
                label = slotName,
                description = "Set the cosmetic override for the " .. slotName ..
                    " slot.",
                options = options[typeId][slotNameLower],
                variable = mwse.mcm.createPlayerData({
                    id = slotNameLower,
                    path = "OJ_CosmeticOverrides.Active." .. typeId
                })
            })
        end
    end
end

-- Handle mod config menu.
local function createCategory(template, typeId, typeObject)
    local page = template:createSideBarPage {
        label = typeObject.text,
        description = "Hover over a setting to learn more about it."
    }

    local category = page:createCategory {
        label = typeObject.text,
        description = "Manage the cosmetic overrides for " .. typeObject.text ..
            "."
    }

    createDropDownsForCategory(category, typeId, typeObject)
end

local function registerModConfig()
    local template = mwse.mcm.createTemplate(name)

    local page = template:createSideBarPage {
        label = "General",
        description = "Hover over a setting to learn more about it."
    }

    local general = page:createCategory { label = "General Settings" }

    -- Create option to capture debug mode.
    general:createOnOffButton {
        label = "Enable Unlock Messages",
        description = "Use this option to enable unlock messages. You will be notified when you unlock a new cosmetic with a message like, 'Unlocked Daedric Helm Cosmetic'.",
        variable = mwse.mcm.createTableVariable {
            id = "showMessages",
            table = config
        }
    }

    general:createDropdown {
        label = "Logging Level",
        description = "Set the log level.",
        options = {
            { label = "TRACE", value = "TRACE" },
            { label = "DEBUG", value = "DEBUG" },
            { label = "INFO",  value = "INFO" }, { label = "WARN", value = "WARN" },
            { label = "ERROR", value = "ERROR" }, { label = "NONE", value = "NONE" }
        },
        variable = mwse.mcm.createTableVariable {
            id = "logLevel",
            table = config
        },
        callback = function(self) log:setLogLevel(self.variable.value) end
    }

    for key, value in pairs(data.categories) do
        createCategory(template, mwse.longToString(key), value)
    end

    template:saveOnClose(name, config)
    mwse.mcm.register(template)
end

event.register(tes3.event.modConfigReady, registerModConfig)

local this = {}
this.updateOptions = updateOptions
return this
