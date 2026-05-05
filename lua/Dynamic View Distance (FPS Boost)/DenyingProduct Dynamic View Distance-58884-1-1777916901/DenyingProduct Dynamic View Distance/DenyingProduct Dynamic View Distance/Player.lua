local camera = require('openmw.camera')
local self = require('openmw.self')
local async = require("openmw.async")
local storage = require("openmw.storage")
local I = require("openmw.interfaces")
local core = require('openmw.core')

I.Settings.registerPage{
    key = "DynamicViewDistance",
    l10n = "DynamicViewDistance",
    name = "Dynamic View Distance",
    description = "Automatically adjusts view distance based on city size."
}

I.Settings.registerGroup{
    key = "dvdSettings",
    page = "DynamicViewDistance",
    l10n = "DynamicViewDistance",
    name = "Settings",
    description = "Controls how city size affects view distance.",
    permanentStorage = true,
    settings = {
        {
            key = "mediumMult",
            renderer = "number",
            name = "View Distance Medium Cities",
            description = "Multiplier for cities with 3+ cells. (like Balmora or Old Ebonheart)",
            default = 0.75,
            argument = { min = 0.1, max = 2.0 }
        },
        {
            key = "largeMult",
            renderer = "number",
            name = "View Distance Large Cities",
            description = "Multiplier for cities with 6+ cells. (like Vivec or Narsis)",
            default = 0.5,
            argument = { min = 0.1, max = 2.0 }
        },
        {
            key = "printVD",
            renderer = "checkbox",
            name = "Debug Print",
            description = "Print current view distance info to console.",
            default = false
        }
    }
}

-- ===== SETTINGS STORAGE =====
local playerSettings = storage.playerSection("dvdSettings")

local mediumMult = 0.75
local largeMult = 0.5
local DEBUGPRINT = false

-- ===== STATE =====
local citySizes = {}
local lastCellName = nil
local baseViewDistance = nil
local lastAppliedDistance = baseViewDistance
local timeSinceLastCheck = 0
local timeBetweenChecks = 2

-- ===== GROUPING =====
local function getGroupName(name)
    return name:match("^(.-),")
        or name:match("^(.-)%s+[Nn]orth$")
        or name:match("^(.-)%s+[Ss]outh$")
        or name:match("^(.-)%s+[Ee]ast$")
        or name:match("^(.-)%s+[Ww]est$")
        or name
end

-- ===== BUILD SIZE TABLE =====
local function buildCitySizes(rawCells)
    local groups = {}

    for _, cell in ipairs(rawCells) do
        local groupName = getGroupName(cell.name)
        groups[groupName] = (groups[groupName] or 0) + 1
    end

    citySizes = groups
end

-- ===== LOOKUP =====
local function getCitySize(cellName)
    local groupName = getGroupName(cellName)
    return citySizes[groupName] or 1
end

-- ===== COMPUTE VIEW DISTANCE =====
local function computeViewDistance(size)
    if size >= 6 then
        return baseViewDistance * largeMult
    elseif size >= 3 then
        return baseViewDistance * mediumMult
    else
        return baseViewDistance
    end
end

-- ===== RECEIVE FROM GLOBAL =====
local function DP_DVD_fromGlobal(data)
    if not data or not data.value then return end
    buildCitySizes(data.value)
end

-- ===== SETTINGS UPDATE =====
local function updateSettings()
    mediumMult = playerSettings:get("mediumMult") or 0.75
    largeMult = playerSettings:get("largeMult") or 0.5
    DEBUGPRINT = playerSettings:get("printVD") or false
    lastCellName = nil
    lastAppliedDistance = nil
end

-- ===== MAIN LOOP =====
local function onUpdate(dt)
    timeSinceLastCheck = timeSinceLastCheck + dt
    if(timeSinceLastCheck < timeBetweenChecks) then return end
    timeSinceLastCheck = 0

    if not baseViewDistance then return end

    local cellName = self.cell.name
    if cellName ~= lastCellName then
        lastCellName = cellName

        local targetDistance
        if not self.cell.isExterior then 
            targetDistance = baseViewDistance
            if DEBUGPRINT then
                print("[DynamicViewDistance] New Cell: Inside Size: 1")
            end
        else 
            local size = getCitySize(cellName)
            targetDistance = computeViewDistance(size)
            if DEBUGPRINT then
                print("[DynamicViewDistance] New Cell: " .. cellName .. " Size: " .. size)
            end
        end

        if targetDistance ~= lastAppliedDistance then
            camera.setViewDistance(targetDistance)
            lastAppliedDistance = targetDistance
            if DEBUGPRINT then
                print("[DynamicViewDistance] Applied VD: " .. targetDistance)
                print("[DynamicViewDistance] You can disable this message in the settings")
            end
        else
            if DEBUGPRINT then
                print("[DynamicViewDistance] Skipped (no change) VD: " .. targetDistance)
                print("[DynamicViewDistance] You can disable this message in the settings")
            end
        end
    end  
end

-- ===== INIT =====
baseViewDistance = camera.getViewDistance()
core.sendGlobalEvent('DP_DVD_sendPlayerCells', {
    actor = self.object
})
playerSettings:subscribe(async:callback(function()
    updateSettings()
end))
updateSettings()

return {
    engineHandlers = {
        onUpdate = onUpdate
    },
    eventHandlers = {
        DP_DVD_fromGlobal = DP_DVD_fromGlobal
    }
}