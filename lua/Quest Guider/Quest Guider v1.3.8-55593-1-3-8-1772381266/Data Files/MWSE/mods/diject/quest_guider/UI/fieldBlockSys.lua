local log = include("diject.quest_guider.utils.log")
local tooltipMenu = {
    tooltipMainBlock = "qGuider_fb_mainBlock",
    tooltipBlock = "qGuider_fb_block",
}

local this = {}

---@class questGuider.fieldBlock
local fieldBlockClass = {}
fieldBlockClass.__index = fieldBlockClass

---@param parent tes3uiElement
local function createBlock(parent)
    local block = parent:createBlock{id = tooltipMenu.tooltipBlock}
    block.autoHeight = true
    block.widthProportional = 1
    block.borderAllSides = 0
    block.flowDirection = tes3.flowDirection.leftToRight

    return block
end

---@class questGuider.fieldBlock.add.dataBlockParam
---@field text string
---@field id string?
---@field isLabel boolean?

---@param params questGuider.fieldBlock.add.dataBlockParam
function fieldBlockClass:add(params)
    if #self.blocks == 0 then
        local block = createBlock(self.parent)
        block:setLuaData("_freeWidth_", self.width)
        table.insert(self.blocks, block)
    end
    local lastBlock = self.blocks[#self.blocks]
    local text = params.text
    local textWidth, textHeight = tes3ui.textLayout.getTextExtent{text = text}
    local delimiterWidth = 0
    if self.delimiter then
        local width = tes3ui.textLayout.getTextExtent{text = self.delimiter}
        delimiterWidth = width
    end

    local borderWidth = self.borderLeft + self.borderRight + self.delimiterBorderLeft + self.delimiterBorderRight
    local fullTextWidth = delimiterWidth + textWidth + borderWidth
    if fullTextWidth > self.width then return end

    local blockFreeWidth = lastBlock:getLuaData("_freeWidth_") or 0
    if blockFreeWidth < fullTextWidth then
        local block = createBlock(self.parent)
        block:setLuaData("_freeWidth_", self.width)
        table.insert(self.blocks, block)
        lastBlock = block
        blockFreeWidth = self.width
    end

    local isHasElements = lastBlock:getLuaData("_hasElements_")
    if isHasElements then
        local delimiter = lastBlock:createLabel{text = self.delimiter}
        delimiter.borderLeft = self.delimiterBorderLeft
        delimiter.borderRight = self.delimiterBorderRight
    end
    local label = lastBlock:createLabel{id = params.id, text = params.text}
    label.borderLeft = self.borderLeft
    label.borderRight = self.borderRight

    lastBlock:setLuaData("_freeWidth_", blockFreeWidth - fullTextWidth)
    if not params.isLabel then
        lastBlock:setLuaData("_hasElements_", true)
    end

    return label
end

function fieldBlockClass:destroyChildren()
    self.blocks = {}
    self.parent:destroyChildren()
end


---@class questGuider.fieldBlock.new.params
---@field parent tes3uiElement
---@field width integer?
---@field delimiter string?
---@field delimiterBorderLeft integer?
---@field delimiterBorderRight integer?
---@field borderLeft integer?
---@field borderRight integer?

---@param params questGuider.fieldBlock.new.params
---@return questGuider.fieldBlock
function this.new(params)
    local parent = params.parent
    do
        local class = parent:getLuaData("_fieldBlockClass_")
        if class then
            return class
        end
    end

    ---@class questGuider.fieldBlock
    local self = setmetatable({}, fieldBlockClass)

    self.width = params.width or parent.width
    self.delimiter = params.delimiter

    self.parent = parent
    self.blocks = {}

    self.delimiterBorderLeft = params.delimiterBorderLeft or 0
    self.delimiterBorderRight = params.delimiterBorderRight or 0
    self.borderLeft = params.borderLeft or 0
    self.borderRight = params.borderRight or 0

    parent:setLuaData("_fieldBlockClass_", self)

    return self
end

return this