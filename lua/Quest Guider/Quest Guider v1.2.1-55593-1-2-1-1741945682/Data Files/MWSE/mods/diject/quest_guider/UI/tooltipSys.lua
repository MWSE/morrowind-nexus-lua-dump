local tooltipMenu = {
    tooltipBlock = "qGuider_ts_block",
    tooltipName = "qGuider_ts_name",
    tooltipDescription = "qGuider_ts_description",
}

local this = {}

---@class questGuider.tooltipSys.tooltip
local tooltipClass = {}
tooltipClass.__index = tooltipClass

---@class questGuider.tooltipSys.tooltip.dataBlock
---@field name string?
---@field description string?
---@field nameColor number[]?
---@field descrColor number[]?

---@param params questGuider.tooltipSys.tooltip.dataBlock
function tooltipClass:add(params)
    table.insert(self.tooltipData.items, params)
end

function tooltipClass:destroy()
    self.parent:unregister(tes3.uiEvent.help)
end


---@class questGuider.tooltipSys.new.params
---@field parent tes3uiElement
---@field maxWidth integer?

---@param params questGuider.tooltipSys.new.params
---@return questGuider.tooltipSys.tooltip
function this.new(params)
    local parent = params.parent
    do
        local class = parent:getLuaData("_tooltipClass_")
        if class then
            return class
        end
    end

    ---@class questGuider.tooltipSys.tooltip
    local self = setmetatable({}, tooltipClass)

    ---@class questGuider.tooltipSys.tooltipData
    local tooltipData = {items = {}}

    tooltipData.maxWidth = params.maxWidth

    self.parent = parent
    self.tooltipData = tooltipData

    parent:setLuaData("_tooltipData_", tooltipData)
    parent:setLuaData("_tooltipClass_", self)

    local function tooltipFunc(e)
        if not e.source then return end
        ---@type questGuider.tooltipSys.tooltipData
        local luaData = e.source:getLuaData("_tooltipData_")
        if not luaData then return end
        if #luaData.items == 0 then return end

        local tooltip = tes3ui.createTooltipMenu()
        tooltip.childAlignX = 0

        local block
        local createDivider = false
        for i, rec in ipairs(luaData.items) do

            if createDivider and rec.name then
                local divider = tooltip:createDivider{}
                divider.borderAllSides = 4
            end

            block = tooltip:createBlock{id = tooltipMenu.tooltipBlock}
            block.flowDirection = tes3.flowDirection.topToBottom
            block.autoHeight = true
            block.autoWidth = true
            block.maxWidth = luaData.maxWidth or 350

            if rec.name then
                local label = block:createLabel{id = tooltipMenu.tooltipName, text = rec.name}
                label.autoHeight = true
                label.widthProportional = 1
                label.maxWidth = luaData.maxWidth or 350
                label.wrapText = true
                label.justifyText = tes3.justifyText.center
                if rec.nameColor then
                    label.color = rec.nameColor
                end
                createDivider = true
            end

            if rec.description then
                local label = block:createLabel{id = tooltipMenu.tooltipDescription, text = rec.description}
                label.autoHeight = true
                label.autoWidth = true
                label.maxWidth = luaData.maxWidth or 350
                label.wrapText = true
                label.justifyText = tes3.justifyText.left
                if rec.descrColor then
                    label.color = rec.descrColor
                end
            end

            ::continue::
        end

        if block then
            block.borderBottom = 3
        end

        tooltip:getTopLevelMenu():updateLayout()
    end

    tooltipData.func = tooltipFunc
    parent:register(tes3.uiEvent.help, tooltipFunc)

    return self
end

return this