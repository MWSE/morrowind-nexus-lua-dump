local async = require("openmw.async")
local ui = require("openmw.ui")
local util = require("openmw.util")
local core = require("openmw.core")
local vfs = require("openmw.vfs")

local uiUtils = require("scripts.quest_guider_lite.ui.utils")
local config = require("scripts.quest_guider_lite.configLib")
local stringLib = require("scripts.quest_guider_lite.utils.string")

local playerDataHandler = require("scripts.quest_guider_lite.storage.playerDataHandler")

local button = require("scripts.quest_guider_lite.ui.button")
local interval = require("scripts.quest_guider_lite.ui.interval")
local customTemplates = require("scripts.quest_guider_lite.ui.templates")
local mapWidget = require("scripts.quest_guider_lite.ui.mapWidget")
local borders = require("scripts.quest_guider_lite.ui.borders")

local commonData = require("scripts.quest_guider_lite.common")

local l10n = core.l10n(commonData.l10nKey)


local mapTexture


local this = {}


---@param positions questGuider.quest.getRequirementPositionData.positionData[]
---@return boolean
function this.isValidMapPositionsExist(positions)
    if not positions then return false end

    for _, posDt in pairs(positions) do
        if (posDt.exitPos and posDt.isExitEx) or (not posDt.id and posDt.position) then
            return true
        end
    end

    return false
end


---@class questGuider.mapMenu.meta
local mapMenuMeta = {}
mapMenuMeta.__index = mapMenuMeta


---@param positions questGuider.quest.getRequirementPositionData.positionData[]
---@return boolean
function mapMenuMeta:mark(positions)
    local count = 0
    local exits = {}

    for _, posDt in ipairs(positions) do
        local descr = stringLib.getPathToPosition(posDt)

        if (posDt.exitPos and posDt.isExitEx) or (not posDt.id and posDt.position) then
            count = count + 1
            local pos = posDt.exitPos or posDt.position
            exits[string.format("%d_%d_%d", pos.x, pos.y, pos.z)] = {pos, descr} ---@diagnostic disable-line: need-check-nil
            if count == 1 then
                self.mapWidget:focusOnWorldPosition(pos)
            end
        end
    end

    if count == 0 then return false end

    local screenSize = uiUtils.getScaledScreenSize()

    for hashId, dt in pairs(exits) do

        local positionElem
        if dt[2] then
            local height = uiUtils.getTextHeight(dt[2], self.params.fontSize, screenSize.x / 3, config.data.journal.textHeightMulRecord)
            positionElem = {
                type = ui.TYPE.Text,
                props = {
                    text = dt[2],
                    textColor = config.data.ui.defaultColor,
                    autoSize = false,
                    textSize = self.params.fontSize,
                    size = util.vector2(screenSize.x / 3, height),
                    multiline = true,
                    wordWrap = true,
                    textAlignH = ui.ALIGNMENT.Center,
                    textAlignV = ui.ALIGNMENT.Center,
                },
            }
        end

        self.mapWidget:createMarker(dt[1], config.data.ui.selectionColor, nil, positionElem and ui.content{
            positionElem
        })
    end

    return true
end



---@class questGuider.mapMenu.new.params
---@field menuId string?
---@field fontSize number?
---@field relativeSize {x : number, y : number}?
---@field size {x : number, y : number}?
---@field relativePosition {x : number, y : number}?
---@field onClose function?

---@param params questGuider.mapMenu.new.params
---@return questGuider.mapMenu.meta?
function this.new(params)

    if not mapTexture then
        local mapImagePath = "questData/"..playerDataHandler.data.mapInfo.file

        if not vfs.fileExists(mapImagePath) then return end

        mapTexture = ui.texture{ path = mapImagePath }
    end

    if not params then params = {} end

    local screenSize = uiUtils.getScaledScreenSize()

    params.fontSize = params.fontSize or config.data.ui.fontSize

    if params.relativeSize then
        params.size = params.size or util.vector2(screenSize.x * params.relativeSize.x, screenSize.y * params.relativeSize.y)
    end
    params.size = params.size or util.vector2(screenSize.y * 0.6, screenSize.y * 0.6)

    if not params.relativePosition then
        params.relativePosition = util.vector2((screenSize.x - params.size.x) / 2 / screenSize.x, (screenSize.y - params.size.y) / 2 / screenSize.y)
    end

    params.menuId = params.menuId or commonData.simpleMapMenuId


    ---@class questGuider.mapMenu.meta
    local meta = setmetatable({}, mapMenuMeta)

    meta.params = params
    meta.update = function ()
        meta.menu:update()
    end

    function meta:close()
        if not self.menu then return end
        if params.onClose then params.onClose() end
        self.menu:destroy()
    end

    local headerSize = util.vector2(params.size.x, params.fontSize * 1.3)

    local mainSize = util.vector2(params.size.x, params.size.y - headerSize.y)


    local mapElement, mapMeta = mapWidget.new{
        updateFunc = meta.update,
        fontSize = params.fontSize,
        size = mainSize,
    }
    meta.mapWidget = mapMeta


    local headerLayout = {
        type = ui.TYPE.Widget,
        props = {
            size = headerSize,
        },
        userData = {

        },
        events = {
            mousePress = async:callback(function(coord, layout)
                layout.userData.lastMousePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)
            end),

            mouseRelease = async:callback(function(_, layout)
                layout.userData.lastMousePos = nil
                meta:update()
            end),

            mouseMove = async:callback(function(coord, layout)
                if not layout.userData.lastMousePos then return end

                local props = meta.menu.layout.props
                local relativePos = util.vector2(coord.position.x / screenSize.x, coord.position.y / screenSize.y)

                props.relativePosition = props.relativePosition - (layout.userData.lastMousePos - relativePos)
                meta:update()

                layout.userData.lastMousePos = relativePos
            end),
        },
        content = ui.content {
            {
                type = ui.TYPE.Image,
                props = {
                    resource = uiUtils.whiteTexture,
                    relativeSize = util.vector2(1, 1),
                    color = config.data.ui.backgroundColor,
                    alpha = config.data.ui.headerBackgroundAlpha / 100,
                }
            },
            {
                type = ui.TYPE.Text,
                props = {
                    text = l10n("Close"),
                    textSize = params.fontSize * 1.25,
                    autoSize = true,
                    anchor = util.vector2(1, 0.5),
                    relativePosition = util.vector2(1, 0.5),
                    textColor = config.data.ui.defaultColor,
                    textShadow = true,
                    textShadowColor = config.data.ui.shadowColor,
                    propagateEvents = false,
                },
                userData = {},
                events = {
                    mouseRelease = async:callback(function(_, layout)
                        if params.onClose then params.onClose() end
                        meta.menu:destroy()
                    end),
                }
            }
        }
    }


    local mainLayout
    mainLayout = {
        type = ui.TYPE.Widget,
        props = {
            size = mainSize,
            position = util.vector2(0, headerSize.y),
        },
        userData = {

        },
        content = ui.content {
            mapElement,
            borders.thick()
        },
    }


    local layout = {
        type = ui.TYPE.Widget,
        layer = "Windows",
        props = {
            size = params.size,
            relativePosition = params.relativePosition,
        },
        userData = {
            meta = meta,
        },
        content = ui.content {
            headerLayout,
            mainLayout,
        }
    }


    meta.menu = ui.create(layout)

    local function onMouseWheelCallback(content, value)
        for _, dt in pairs(content) do
            if not type(dt) == "table" then goto continue end
            if dt.userData and dt.userData.onMouseWheel then
                dt.userData.onMouseWheel(value)
            end

            if dt.content then
                onMouseWheelCallback(dt.content, value)
            end

            ::continue::
        end
    end

    meta.onMouseWheel = function (self, vertical)
        local layout = meta.menu.layout
        onMouseWheelCallback(layout.content, vertical)
    end

    return meta
end


return this