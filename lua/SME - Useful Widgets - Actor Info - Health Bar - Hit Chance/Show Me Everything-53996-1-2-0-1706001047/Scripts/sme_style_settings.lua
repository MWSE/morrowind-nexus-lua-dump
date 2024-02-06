local async = require("openmw.async")
local camera = require("openmw.camera")
local core = require("openmw.core")
local I = require("openmw.interfaces")
local nearby = require("openmw.nearby")
local self = require("openmw.self")
local types = require("openmw.types")
local ui = require("openmw.ui")
local util = require("openmw.util")
local storage = require('openmw.storage')

local settings = {
    behavior = storage.playerSection('SMESettingsBh'),
    style = storage.playerSection('SMESettingsSt'),
}

local healthBarSkyrimStyle = ui.content {
        {
            name = "hbBG",
            type = ui.TYPE.Image,
                props = {
                resource = ui.texture({ path = 'Textures/HbSkyrimBG.png' }),
                --color = util.color.rgb(8 / 255, 8 / 255, 8 / 255),
                size = util.vector2(250, 12),
                -- position in the top right corner
                relativePosition = util.vector2(0.50, 0.18),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                anchor = util.vector2(0.5, 0),
                --visible = false,
            },
        },
        {
            name = "hbBarAnim",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture({ path = 'Textures/HbSkyrimAnim.png' }),
                color = util.color.rgb(200 / 255, 200 / 255, 200 / 255),
                size = util.vector2(250, 12),
                -- position in the top right corner
                align = ui.ALIGNMENT.Center,
                relativePosition = util.vector2(0.5, 0.18),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                anchor = util.vector2(0.5, 0),
                --visible = false,
            },
        },
        {
            name = "hbBar",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture({ path = 'Textures/HbSkyrimHealth.png' }),
                color = util.color.rgb(135 / 255, 36 / 255, 32 / 255),
                size = util.vector2(250, 12),
                -- position in the top right corner
                align = ui.ALIGNMENT.Center,
                relativePosition = util.vector2(0.5, 0.18),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                anchor = util.vector2(0.5, 0),
                --visible = false,
            },
        },
        {
            name = "hbOL",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture({ path = 'Textures/HbSkyrimOverlay.png' }),
                size = util.vector2(290, 20),
                -- position in the top right corner
                relativePosition = util.vector2(0.5, 0.1115),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                anchor = util.vector2(0.5, 0),
            },
        },
}

local healthBarSkyNostalgic = ui.content {   
    {
        name = "hbBG",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/HbNostalgicBg.png' }),
            alpha = 0.8,
            color = util.color.rgb(8 / 255, 8 / 255, 8 / 255),
            size = util.vector2(307, 10),
            -- position in the top right corner
            relativePosition = util.vector2(0.50, 0.18),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbBarAnim",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture({ path = 'Textures/HbNostalgicAnim.png' }),
            --color = util.color.rgb(170 / 255, 170 / 255, 170 / 255),
            size = util.vector2(330, 12),
            -- position in the top right corner
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0.5, 0.18),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbBar",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture({ path = 'Textures/HbNostalgicHealth.png' }),
            --color = util.color.rgb(135 / 255, 36 / 255, 32 / 255),
            size = util.vector2(330, 12),
            -- position in the top right corner
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0.5, 0.18),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbOL",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture({ path = 'Textures/HbNostalgicOverlay.png' }),
            size = util.vector2(340, 20),
            -- position in the top right corner
            relativePosition = util.vector2(0.5, 0.1115),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
        },
    },
}

local healthBarMorrowindStyle = ui.content {
    {
        name = "hbBG",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/HbVanillaBg.png' }),
            --color = util.color.rgb(30 / 255, 30 / 255, 30 / 255),
            size = util.vector2(260, 20),
            -- position in the top right corner
            relativePosition = util.vector2(0.50, 0.1),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbBarAnim",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture({ path = 'Textures/HbVanillaAnim.png' }),
            color = util.color.rgb(200 / 255, 200 / 255, 200 / 255),
            size = util.vector2(260, 20),
            -- position in the top right corner
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0.5, 0.135),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbBar",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture({ path = 'Textures/HbVanillaHealth.png' }),
            color = util.color.rgb(135 / 255, 36 / 255, 32 / 255),
            size = util.vector2(260, 20),
            -- position in the top right corner
            --align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0.5, 0.135),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbOL",
        template = I.MWUI.templates.borders,
        props = {
            size = util.vector2(260, 20),
            -- position in the top right corner
            relativePosition = util.vector2(0.5, 0.1115),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
        },
    },
    
}

local healthBarFlatStyle = ui.content {   
        {
            name = "hbBG",
            type = ui.TYPE.Image,
                props = {
                alpha = 0.8,
                resource = ui.texture({ path = 'White' }),
                color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
                size = util.vector2(310, 25),
                -- position in the top right corner
                relativePosition = util.vector2(0.50, 0.2),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                anchor = util.vector2(0.5, 0),
                --visible = false,
            },
        },
        {
            name = "hbBarAnim",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture({ path = 'Textures/HbFlatHealth.png' }),
                color = util.color.rgb(135 / 255, 36 / 255, 32 / 255),
                size = util.vector2(280, 20),
                -- position in the top right corner
                align = ui.ALIGNMENT.Center,
                relativePosition = util.vector2(0.5, 0.28),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                anchor = util.vector2(0.5, 0),
                --visible = false,
            },
        },
        {
            name = "hbBar",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture({ path = 'Textures/HbFlatAnim.png' }),
                color = util.color.rgb(170 / 255, 170 / 255, 170 / 255),
                size = util.vector2(290, 20),
                -- position in the top right corner
                --align = ui.ALIGNMENT.Center,
                relativePosition = util.vector2(0.5, 0.28),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                anchor = util.vector2(0.5, 0),
                --visible = false,
            },
        },
        {
            name = "hbOL",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture({ path = 'Textures/HbFlatOverlay.png' }),
                color = util.color.rgb(135 / 255, 36 / 255, 32 / 255),
                size = util.vector2(300, 17.5),
                -- position in the top right corner
                --align = ui.ALIGNMENT.Center,
                relativePosition = util.vector2(0.5, 0.28),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                anchor = util.vector2(0.5, 0),
                --visible = false,
            },
        },
        {
            name = "healthBG",
            type = ui.TYPE.Image,
                props = {
                resource = ui.texture({ path = 'Textures/HbFlatHealthCounterBg.png' }),
                alpha = 0.8,
                color = util.color.rgb(8 / 255, 8 / 255, 8 / 255),
                size = util.vector2(100, 40),
                -- position in the top right corner
                relativePosition = util.vector2(0.50, 0.54),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                anchor = util.vector2(0.5, 0),
                visible = true,
            },
        },
}

local healthBarMinimalStyle = ui.content {
    {
        name = "hbBG",
        type = ui.TYPE.Image,
            props = {
            alpha = 0.8,
            resource = ui.texture({ path = 'White' }),
            color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
            size = util.vector2(180, 16),
            -- position in the top right corner
            relativePosition = util.vector2(0.50, 0.5),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbBarAnim",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture({ path = 'textures/menu_bar_gray.dds' }),
            color = util.color.rgb(50 / 255, 50 / 255, 50 / 255),
            size = util.vector2(280, 20),
            -- position in the top right corner
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0.5, 0.5),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbBar",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture({ path = 'textures/menu_bar_gray.dds' }),
            color = util.color.rgb(204 / 255, 153 / 255, 0 / 255),
            size = util.vector2(290, 20),
            -- position in the top right corner
            --align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0.5, 0.5),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbOL",
        template = I.MWUI.templates.borders,
        props = {
            size = util.vector2(180, 16),
            -- position in the top right corner
            relativePosition = util.vector2(0.5, 0.5),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
        },
    },
    
}

local healthBarSixthHouse = ui.content {
    {
        name = "hbBG",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/HbStoneBg.png' }),
            color = util.color.rgb(65 / 255, 65 / 255, 65 / 255),
            size = util.vector2(275, 16),
            -- position in the top right corner
            relativePosition = util.vector2(0.50, 0.44),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbBarAnim",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture({ path = 'Textures/HbStoneHealthbar.png' }),
            color = util.color.rgb(80 / 255, 80 / 255, 80 / 255),
            size = util.vector2(220, 16),
            -- position in the top right corner
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0.5, 0.44),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbBar",
        type = ui.TYPE.Image,
        props = {
            resource = ui.texture({ path = 'Textures/HbStoneAnim.png' }),
            color = util.color.rgb(50 / 255, 50 / 255, 50 / 255),
            size = util.vector2(220, 16),
            -- position in the top right corner
            align = ui.ALIGNMENT.Center,
            relativePosition = util.vector2(0.5, 0.44),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
            --visible = false,
        },
    },
    {
        name = "hbOL",
        template = I.MWUI.templates.borders,
        props = {
            size = util.vector2(275, 20),
            -- position in the top right corner
            relativePosition = util.vector2(0.5, 0.4),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0.5, 0),
        },
    },    
}

local function getStyleVanilla()
    return healthBarMorrowindStyle
end

local function getStyleSkyrim()
    return healthBarSkyrimStyle
end

local function getStyleNostalgy()
    return healthBarSkyNostalgic
end

local function getStyleFlat()
    return healthBarFlatStyle
end

local function getStyleMinimal()
    return healthBarMinimalStyle
end

local function getStyleSixthHouse()
    return healthBarSixthHouse
end


return { 
    engineHandlers = 
    { 
        onUpdate = onUpdate 
    },
    interfaceName = "SME_STYLE",
    interface = {
        getStyleVanilla = getStyleVanilla,
        getStyleSkyrim = getStyleSkyrim,
        getStyleNostalgy = getStyleNostalgy,
        getStyleFlat = getStyleFlat,
        getStyleMinimal = getStyleMinimal,
        getStyleSixthHouse = getStyleSixthHouse,
    },
}