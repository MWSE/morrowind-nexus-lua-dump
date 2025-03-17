local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("PaperMold")
local NodeManager = require("mer.joyOfPainting.services.NodeManager")
local CraftingFramework = require("CraftingFramework")
---@class JOP.PaperMold.data
---@field id string The id of the paper mold
---@field hoursToDry number The number of hours it takes for the paper to dry
---@field paperId string The id of the paper that is created
---@field paperPerPulp number The number of papers that can be created from one pulp

---@class JOP.PaperMold
local PaperMold = {
    data = nil,
    dataHolder = nil,
    item = nil,
    itemData = nil,
    reference = nil,
}
PaperMold.__index = PaperMold

---@param e JOP.PaperMold.data
function PaperMold.registerPaperMold(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:debug("Registering paper mold %s", e.id)
    e.id = e.id:lower()
    config.paperMolds[e.id] = table.copy(e, {})
    CraftingFramework.Indicator.register{
        objectId = e.id,
        additionalUI = function(indicator, parent)
            local paperMold = PaperMold:new{
                reference = indicator.reference,
                item = indicator.item,
                itemData = indicator.dataHolder,
            }
            if paperMold then
                paperMold:doTooltip(parent)
            end
        end,
    }
end

function PaperMold.registerPaperPulp(e)
    logger:assert(type(e.id) == "string", "id must be a string")
    logger:debug("Registering paper pulp %s", e.id)
    e.id = e.id:lower()
    config.paperPulps[e.id] = table.copy(e, {})
end

function PaperMold.isPaperMold(object)
    return config.paperMolds[object.id:lower()] ~= nil
end

---@return JOP.PaperMold|nil
function PaperMold:new(e)
    logger:assert(e.reference or e.item, "PaperMold requires either a reference or an item")
    local item = e.item or e.reference.object
    if not PaperMold.isPaperMold(item) then
        logger:trace("%s is not a paper mold", item.id)
        return nil
    end

    local paperMold = setmetatable({}, self)

    paperMold.reference = e.reference
    paperMold.item = item
    paperMold.itemData = e.itemData

    paperMold.dataHolder = (e.itemData ~= nil) and e.itemData or e.reference
    paperMold.data = setmetatable({}, {
        __index = function(_, k)
            if not (
                paperMold.dataHolder
                and paperMold.dataHolder.data
                and paperMold.dataHolder.data.joyOfPainting
            ) then
                return nil
            end
            return paperMold.dataHolder.data.joyOfPainting[k]
        end,
        __newindex = function(_, k, v)
            if paperMold.dataHolder == nil then
                logger:debug("Setting value %s and dataHolder doesn't exist yet", k)
                if not paperMold.reference then
                    logger:debug("paperMold.item: %s", paperMold.item)
                    --create itemData
                    paperMold.dataHolder = tes3.addItemData{
                        to = tes3.player,
                        item = paperMold.item.id,
                    }
                    if paperMold.dataHolder == nil then
                        logger:error("Failed to create itemData for paperMold")
                        return
                    end
                end
            end
            if not ( paperMold.dataHolder.data and paperMold.dataHolder.data.joyOfPainting) then
                paperMold.dataHolder.data.joyOfPainting = {}
            end
            paperMold.dataHolder.data.joyOfPainting[k] = v
        end
    })
    return paperMold
end

function PaperMold:hasPulp()
    return self.data.timeAddedPulp ~= nil
end

function PaperMold:hasPaper()
    return self.data.hasPaper
end

function PaperMold:playerHasPulp()
    for id, _ in pairs(config.paperPulps) do
        if CraftingFramework.CarryableContainer.findItemStack{ item = id } then
            return true
        end
    end
    return false
end

function PaperMold:getHoursToDry()
    local moldData = config.paperMolds[self.item.id:lower()]
    if moldData == nil then
        logger:warn("Paper mold %s not registered", self.item.id)
        return 0
    end
    return moldData.hoursToDry
end

function PaperMold:getTimeAddedPulp()
    return self.data.timeAddedPulp
end

function PaperMold:doAddPulp()
    if not self:playerHasPulp() then
        logger:warn("Player doesn't have pulp")
        return
    end

    if self:hasPulp() then
        logger:warn("Paper mold already has pulp")
        return
    end

    --remove pulp from player inventory
    for id, _ in pairs(config.paperPulps) do
        if CraftingFramework.CarryableContainer.findItemStack{ item = id } then
            CraftingFramework.CarryableContainer.removeItem{
                reference = tes3.player,
                item = id,
            }
            break
        end
    end
    self.data.timeAddedPulp = tes3.getSimulationTimestamp()
    NodeManager.updateSwitch("paper_mold")
end

function PaperMold:processMold(timestamp)
    local now = timestamp or tes3.getSimulationTimestamp()
    if self:hasPulp() then
        if now - self:getTimeAddedPulp() > self:getHoursToDry() then
            self:dryPaper()
        end
    end
end

function PaperMold:dryPaper()
    self.data.hasPaper = true
    self.data.timeAddedPulp = nil
    NodeManager.updateSwitch("paper_mold")
end

function PaperMold:takePaper()
    if not self:hasPaper() then
        logger:warn("Paper mold doesn't have paper")
        return
    end
    local paperConfig = config.paperMolds[self.item.id:lower()]
    local paperId = paperConfig.paperId
    if paperId == nil then
        logger:warn("Paper mold %s doesn't have a paperId", self.item.id)
        return
    end
    tes3.addItem{
        reference = tes3.player,
        item = paperId,
        count = paperConfig.paperPerPulp
    }
    self.data.hasPaper = false
    NodeManager.updateSwitch("paper_mold")
end

function PaperMold:getDryness()
    if not self:hasPulp() then
        return 0
    end
    local now = tes3.getSimulationTimestamp()
    local timeAddedPulp = self:getTimeAddedPulp()
    local hoursToDry = self:getHoursToDry()
    local dryness = (now - timeAddedPulp) / hoursToDry
    return dryness
end

---@param parent tes3uiElement
function PaperMold:doTooltip(parent)
    self:processMold()
    logger:debug("Creating tooltip")
    local text
    if self:hasPulp() then
        logger:debug("Has pulp")
        text = string.format("Pulp Drying: %d%%", self:getDryness() * 100)
    elseif self:hasPaper() then
        logger:debug("Has paper")
        text = "Paper Ready"
    end
    if text then
        logger:debug("Creating label")
        parent:createLabel{text = text}
    end
end

return PaperMold
