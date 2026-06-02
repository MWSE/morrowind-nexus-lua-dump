local ui = require("openmw.ui")
local util = require("openmw.util")
local async = require("openmw.async")

local configData = require("scripts.quest_guider_lite.config")
local consts = require("scripts.quest_guider_lite.common")
local tableLib = require("scripts.quest_guider_lite.utils.table")
local stringLib = require("scripts.quest_guider_lite.utils.string")
local config = require("scripts.quest_guider_lite.config")
local uiUtils = require("scripts.quest_guider_lite.ui.utils")

local interval = require("scripts.quest_guider_lite.ui.interval")
local newButton = require("scripts.quest_guider_lite.ui.button")


local this = {}

---@class questGuider.ui.buttonBlockMeta
local buttonBlock = {}
buttonBlock.__index = buttonBlock


local function getBtnWidth(btnMeta, widthMul)
    local buttonWidth = 0
    if btnMeta.params.size then
        buttonWidth = btnMeta.params.size.x + 8
    else
        if btnMeta.params.text then
            buttonWidth = buttonWidth + stringLib.length(btnMeta.params.text) * (widthMul or config.data.journal.textHeightMulRecord) *
                config.data.ui.fontSize + 8
        end
        if btnMeta.params.icon and btnMeta.params.iconSize then
            buttonWidth = buttonWidth + btnMeta.params.iconSize.x
        end
    end

    return buttonWidth
end


---@param params questGuider.ui.buttonBlock.params
function buttonBlock:add(params)
    params.updateFunc = params.updateFunc or self.params.updateFunc
    params.anchor = util.vector2(0.5, 0.5)
    local button = newButton(params)
    if not button then return end

    local btnMeta = button.userData.meta

    local buttonWidth = getBtnWidth(btnMeta, self.widthMul)

    local function addNewFlex()
        local newFlex = {
            type = ui.TYPE.Flex,
            props = {
                horizontal = true,
                arrange = ui.ALIGNMENT.Center,
                align = ui.ALIGNMENT.Center,
            },
            userData = {
                width = 0
            },
            content = ui.content{},
        }
        self.layout.content:add(newFlex)

        return newFlex
    end

    local lastFlex
    if #self.layout.content == 0 then
        lastFlex = addNewFlex()
    else
        lastFlex = self.layout.content[#self.layout.content]
    end

    local padding = config.data.ui.fontSize

    if lastFlex.userData.width + buttonWidth + padding > self.width then
        lastFlex = addNewFlex()
    end

    padding = lastFlex.userData.width == 0 and 0 or config.data.ui.fontSize

    lastFlex.userData.width = lastFlex.userData.width + buttonWidth + padding
    if padding > 0 then
        lastFlex.content:add(interval(padding, 0))
    end
    lastFlex.content:add(button)

    table.insert(self.buttons, button)

    return button
end


function buttonBlock:clear()
    self.buttons = {}
    uiUtils.clearContent(self.layout.content)
end


---@class questGuider.ui.buttonBlock.params
---@field width number? util.vector2
---@field relativePosition any? util.vector2
---@field position any? util.vector2
---@field anchor any? util.vector2
---@field customWidthMul number?
---@field updateFunc function?


---@param params questGuider.ui.buttonBlock.params
function this.new(params)
    if not params then params = {} end

    ---@class questGuider.ui.buttonBlockMeta
    local meta = setmetatable({}, buttonBlock)

    meta.params = params
    meta.width = params.width or 100
    meta.widthMul = params.customWidthMul or config.data.journal.textHeightMulRecord
    meta.buttons = {}

    local layout = {
        type = ui.TYPE.Flex,
        props = {
            horizontal = false,
            arrange = ui.ALIGNMENT.Center,
            align = ui.ALIGNMENT.Center,
            position = params.position,
            relativePosition = params.relativePosition,
            anchor = params.anchor,
        },
        userData = {
            meta = meta,
        },
        content = ui.content{

        },
    }

    meta.layout = layout

    return layout
end


return this