local camera = require 'openmw.camera'
local gameSelf = require 'openmw.self'
local ui = require 'openmw.ui'
local util = require 'openmw.util'

local I = require 'openmw.interfaces'

local ModInfo = require 'scripts.sw4.modinfo'

local SW4CrosshairDefaultOptions = {
    size = util.vector2(64, 64),
    path = 'textures/sw4/ogacrosshairs.dds',
    offset = util.vector2(0, 0),
}

local SW4Crosshair = ui.create {
    layer = 'HUD',
    type = ui.TYPE.Image,
    props = {
        size = util.vector2(64, 64),
        relativePosition = util.vector2(0.5, 0.5),
        anchor = util.vector2(0.5, 0.5),
        visible = false,
    },
}

---@class CrosshairManager
---@field CrosshairRow number 0-7 index of the crosshair to use from the atlas
---@field CrosshairColumn number 0-7 index of the crosshair to use from the atlas
---@field ReplaceCrosshair boolean whether to use the crosshairManager at all
---@field CrosshairColor util.color
local CrosshairManager = I.StarwindVersion4ProtectedTable.new {
    modName = ModInfo.name,
    logPrefix = ModInfo.logPrefix,
    inputGroupName = 'SettingsGlobal' .. ModInfo.name .. 'CrosshairGroup',

    ---@type ShadowTableSubscriptionHandler
    subscribeHandler = function(shadowTable, group, _, key)
        if not key or key == 'CrosshairRow' or key == 'CrosshairColumn' then
            local row = group:get('CrosshairRow')
            local column = group:get('CrosshairColumn')

            SW4CrosshairDefaultOptions.offset = util.vector2(
                row * 64,
                column * 64
            )

            shadowTable.CrosshairRow = row
            shadowTable.CrosshairColumn = column

            SW4Crosshair.layout.props.resource = ui.texture(SW4CrosshairDefaultOptions)
        end

        if not key or key == 'CrosshairColor' then
            local color = group:get('CrosshairColor')
            shadowTable.CrosshairColor = color
            SW4Crosshair.layout.props.color = color
        end

        if not key or key == 'CrosshairSize' then
            local size = group:get('CrosshairSize')
            shadowTable.CrosshairSize = size
            SW4Crosshair.layout.props.size = util.vector2(size, size)
        end

        local replaceCrosshair = group:get('ReplaceCrosshair')
        shadowTable.ReplaceCrosshair = replaceCrosshair

        if SW4Crosshair.layout.props.visible ~= replaceCrosshair then
            SW4Crosshair.layout.props.visible = replaceCrosshair
            camera.showCrosshair(not replaceCrosshair)
        end

        SW4Crosshair:update()
    end,
}

CrosshairManager.state = {

}

SW4CrosshairDefaultOptions.offset = util.vector2(
    CrosshairManager.CrosshairRow * 64,
    CrosshairManager.CrosshairColumn * 64
)

SW4CrosshairDefaultOptions.size = util.vector2(
    CrosshairManager.CrosshairSize,
    CrosshairManager.CrosshairSize
)

SW4Crosshair.layout.props.resource = ui.texture(SW4CrosshairDefaultOptions)
SW4Crosshair.layout.props.color = CrosshairManager.CrosshairColor

if CrosshairManager.ReplaceCrosshair then
    SW4Crosshair.layout.props.visible = true
    SW4Crosshair:update()
end


function CrosshairManager:onFrameLate(dt)
    if not self.ReplaceCrosshair then return end

    local show = not GlobalManagement.LockOn.getMarkerVisibility()
        and not GlobalManagement.Cursor:getCursorVisible()
        and not I.UI.getMode()
        and not gameSelf.controls.sneak

    local crosshairProps = SW4Crosshair.layout.props
    if show ~= crosshairProps.visible then
        crosshairProps.visible = show
        SW4Crosshair:update()
    end

    camera.showCrosshair(false)
end

---@param globalManagement ManagementStore
---@return CrosshairManager
return function(globalManagement)
    assert(globalManagement)
    GlobalManagement = globalManagement
    return CrosshairManager
end
