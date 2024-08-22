local localStorage = {}

local storageName = "tooltipChanger_by_diject"

localStorage.data = nil

function localStorage.isReady()
    return localStorage.data ~= nil
end

---@param reference tes3reference
function localStorage.getStorage(reference)
    local data = reference.data[storageName]
    if not data then
        reference.data[storageName] = {}
        data = reference.data[storageName]
    end
    reference.modified = true
    return data
end

---@param reference tes3reference
function localStorage.isExists(reference)
    return reference.data[storageName]
end


local this = {}

---@param reference tes3reference
---@param tooltip string
function this.saveTooltip(reference, tooltip)
    local storageData = localStorage.getStorage(reference)
    storageData["tooltip"] = tooltip
end

---@param reference tes3reference
function this.getTooltip(reference)
    local storageData = localStorage.getStorage(reference)
    return storageData["tooltip"]
end


--- @param e uiObjectTooltipEventData
local function uiObjectTooltipCallback(e)
    if not e.reference or not e.reference.data then return end
    local tooltip = this.getTooltip(e.reference)
    if tooltip and e.tooltip then
        local nameContainer = e.tooltip:findChild("PartHelpMenu_main")
        if not nameContainer then return end
        local nameLabel = nameContainer:findChild("HelpMenu_name")
        if not nameLabel then return end
        nameLabel.text = tooltip
        e.tooltip:getTopLevelMenu():updateLayout()
    end
end

event.register(tes3.event.uiObjectTooltip, uiObjectTooltipCallback)


return this