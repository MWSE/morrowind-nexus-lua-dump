local ui = require 'openmw.ui'
local util = require 'openmw.util'
local Constants = require 'scripts.omw.mwui.constants'

local I = require 'openmw.interfaces'

local DarkFactor = 0.8
local LightFactor = 1.25

local DarkColor = util.color.rgb(
    Constants.normalColor.r * DarkFactor,
    Constants.normalColor.g * DarkFactor,
    Constants.normalColor.b * DarkFactor
)

local LightColor = util.color.rgb(
    Constants.normalColor.r * LightFactor,
    Constants.normalColor.g * LightFactor,
    Constants.normalColor.b * LightFactor
)

local BannerSize = ui.layers[1].size:emul(util.vector2(0.15, 0.08))
local SongBanner = ui.create {
    layer = 'HUD',
    name = 'S3maphore_TrackBanner',
    template = I.MWUI.templates.boxTransparent,
    props = {
        relativePosition = util.vector2(0.5, 0),
        anchor = util.vector2(0.5, 0),
        visible = false,
    },
    content = ui.content {
        {
            name = 'SW4_CursorBannerText',
            template = I.MWUI.textHeader,
            type = ui.TYPE.Text,
            props = {
                autoSize = false,
                size = BannerSize,
                text = '',
                textColor = Constants.normalColor,
                textSize = 18,
                textAlignH = ui.ALIGNMENT.Center,
                textAlignV = ui.ALIGNMENT.Center,
                wordWrap = true,
                multiline = true,
            }
        },
    }
}

return SongBanner
