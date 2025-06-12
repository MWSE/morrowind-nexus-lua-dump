local ui = require("openmw.ui")
local util = require("openmw.util")

-- Reference resolution values (for 1920x1080)
local refWidth = 1920
local refHeight = 1080
local refAspectRatio = refWidth / refHeight

-- Get current screen dimensions
local screenSize = ui.screenSize()
local currentAspectRatio = screenSize.x / screenSize.y

-- Calculate scale factors
local scaleX = screenSize.x / refWidth
local scaleY = screenSize.y / refHeight
local uiScale = math.min(scaleX, scaleY)  -- Use the smaller scale to prevent stretching

-- Function to scale sizes based on screen resolution
local function scaleSize(width, height)
    return util.vector2(width * uiScale, height * uiScale)
end

-- Function to scale portrait element sizes with consistent aspect ratio
local function scalePortrait(width, height, modifier)
    modifier = modifier or 1.0
    return util.vector2(width * uiScale * modifier, height * uiScale * modifier)
end

local bg3FocusHealthBar = ui.content {   
        {
            name = "hbBG",
            type = ui.TYPE.Image,
                props = {
                resource = ui.texture({ path = 'Textures/BG3HealthBarBG.png' }),
                --color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
                size = scaleSize(423.5, 26.775),
                align = ui.ALIGNMENT.Center,
                -- position in the top right corner
                --relativePosition = util.vector2(0.50, 0.28),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                --anchor = util.vector2(0.5, 0),
            },
        },
        {
            name = "hbBarAnim",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture({ path = 'Textures/BG3HealthBarAnim.png' }),
                --color = util.color.rgb(1 / 255, 1 / 255, 1 / 255),
                size = scaleSize(423.5, 26.775),
                -- position in the top right corner
                align = ui.ALIGNMENT.Center,
                --relativePosition = util.vector2(0.5, 0.28),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                --anchor = util.vector2(0.5, 0),
                visible = false,
            },
        },
        {
            name = "hbBar",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture({ path = 'Textures/BG3HealthBarFull.png' }),
                color = util.color.rgb(255, 255, 255),
                size = scaleSize(423.5, 26.775),
                -- position in the top right corner
                align = ui.ALIGNMENT.Center,
                --relativePosition = util.vector2(0.167, 0.28),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                --anchor = util.vector2(0, 0),
                --visible = false,
            },
        },
        {
            name = "hbOL",
            type = ui.TYPE.Image,
            props = {
                resource = ui.texture({ path = 'Textures/BG3HealthBar.png' }),
                color = util.color.rgb(0, 0, 0),
                size = scaleSize(423.5, 26.775),
                -- position in the top right corner
                align = ui.ALIGNMENT.Center,
                --relativePosition = util.vector2(0.5, 0.28),
                -- position is for the top left corner of the widget by default
                -- change it to align exactly to the top right corner of the screen
                --anchor = util.vector2(0.5, 0),
                --visible = false,
            },
        },
}


local bg3Focus = ui.content {
    {
        name = "abBG",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abBGSmoke.png' }),
            color = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
            size = scalePortrait(71.75, 117.25),
            -- position in the top right corner
            relativePosition = util.vector2(0, 0.0),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0, 0),
        },
    },
    {
        name = "abPortrait",
        type = ui.TYPE.Image,
            props = {
            --resource = ,
            size = scalePortrait(71.75, 117.25),
            -- position in the top right corner
            relativePosition = util.vector2(0, 0.0),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0, 0),
            },
    },
    
    {
        name = "abDamage",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abDamage.png'}),
            color = util.color.rgb(120 / 255, 120 / 255, 120 / 255),
            size = scalePortrait(71.75, 117.25),
            -- position in the top right corner
            relativePosition = util.vector2(0, 1),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0, 0),
            alpha = 0.7
            },
    },
    {
        name = "abFocus",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abFocus.png' }),
            --color = util.color.rgb(65 / 255, 65 / 255, 65 / 255),
            size = scalePortrait(71.75, 133),
            -- position in the top right corner
            relativePosition = util.vector2(0, 0.0),
            -- position is for the top left corner of the widget by default
            -- change it to align exactly to the top right corner of the screen
            anchor = util.vector2(0, 0),
        },
    },
}


local bg3EnemyBar = ui.content {
 -- enemy #1
    {
        name = "ebBG2",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abBGSmoke.png' }),
            color = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.335, 0.0), 
            anchor = util.vector2(0, 0),
            visible = false
        },
    },
    {
        name = "ebPortrait2",
        type = ui.TYPE.Image,
            props = {
            --resource = ,
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.335, 0.0),
            anchor = util.vector2(0, 0),
            visible = false,
            },
    },
    
    {
        name = "ebDamage2",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abDamage.png'}),
            color = util.color.rgb(120 / 255, 120 / 255, 120 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.335, 0.0),
            anchor = util.vector2(0, 0),
            alpha = 0.7,
            visible = false
            },
    },
    {
        name = "ebFrame2",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abFrame.png' }),
            color = util.color.rgb(229 / 255, 38 / 255, 91 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.335, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    -- enemy #2
    {
        name = "ebBG3",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abBGSmoke.png' }),
            color = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.2655, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
        },
    },
    {
        name = "ebPortrait3",
        type = ui.TYPE.Image,
            props = {
            --resource = ,
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.2655, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    
    {
        name = "ebDamage3",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abDamage.png'}),
            color = util.color.rgb(120 / 255, 120 / 255, 120 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.2655, 0.0),
            anchor = util.vector2(0, 0),
            alpha = 0.7,
            visible = false
            },
    },
    {
        name = "ebFrame3",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abFrame.png' }),
            color = util.color.rgb(229 / 255, 38 / 255, 91 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.2655, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    -- enemy #3
    {
        name = "ebBG4",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abBGSmoke.png' }),
            color = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.37, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
        },
    },
    {
        name = "ebPortrait4",
        type = ui.TYPE.Image,
            props = {
            --resource = ,
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.37, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    
    {
        name = "ebDamage4",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abDamage.png'}),
            color = util.color.rgb(120 / 255, 120 / 255, 120 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.37, 0.0),
            anchor = util.vector2(0, 0),
            alpha = 0.7,
            visible = false
            },
    },
    {
        name = "ebFrame4",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abFrame.png' }),
            color = util.color.rgb(229 / 255, 38 / 255, 91 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.37, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    -- enemy #4
    {
        name = "ebBG5",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abBGSmoke.png' }),
            color = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.23, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
        },
    },
    {
        name = "ebPortrait5",
        type = ui.TYPE.Image,
            props = {
            --resource = ,
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.23, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    
    {
        name = "ebDamage5",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abDamage.png'}),
            color = util.color.rgb(120 / 255, 120 / 255, 120 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.23, 0.0),
            anchor = util.vector2(0, 0),
            alpha = 0.7,
            visible = false
            },
    },
    {
        name = "ebFrame5",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abFrame.png' }),
            color = util.color.rgb(229 / 255, 38 / 255, 91 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.23, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    -- enemy #5
    {
        name = "ebBG6",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abBGSmoke.png' }),
            color = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.4055, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
        },
    },
    {
        name = "ebPortrait6",
        type = ui.TYPE.Image,
            props = {
            --resource = ,
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.4055, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    
    {
        name = "ebDamage6",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abDamage.png'}),
            color = util.color.rgb(120 / 255, 120 / 255, 120 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.4055, 0),
            anchor = util.vector2(0, 0),
            alpha = 0.7,
            visible = false
            },
    },
    {
        name = "ebFrame6",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abFrame.png' }),
            color = util.color.rgb(229 / 255, 38 / 255, 91 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.4055, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    -- enemy #6
    {
        name = "ebBG7",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abBGSmoke.png' }),
            color = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.1955, 0),
            anchor = util.vector2(0, 0),
            visible = false
        },
    },
    {
        name = "ebPortrait7",
        type = ui.TYPE.Image,
            props = {
            --resource = ,
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.1955, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    
    {
        name = "ebDamage7",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abDamage.png'}),
            color = util.color.rgb(120 / 255, 120 / 255, 120 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.1955, 0),
            anchor = util.vector2(0, 0),
            alpha = 0.7,
            visible = false
            },
    },
    {
        name = "ebFrame7",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abFrame.png' }),
            color = util.color.rgb(229 / 255, 38 / 255, 91 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.1955, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    -- enemy #7
    {
        name = "ebBG8",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abBGSmoke.png' }),
            color = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.44, 0),
            anchor = util.vector2(0, 0),
            visible = false
        },
    },
    {
        name = "ebPortrait8",
        type = ui.TYPE.Image,
            props = {
            --resource = ,
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.44, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    
    {
        name = "ebDamage8",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abDamage.png'}),
            color = util.color.rgb(120 / 255, 120 / 255, 120 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.44, 0),
            anchor = util.vector2(0, 0),
            alpha = 0.7,
            visible = false
            },
    },
    {
        name = "ebFrame8",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abFrame.png' }),
            color = util.color.rgb(229 / 255, 38 / 255, 91 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.44, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    -- enemy #8
    {
        name = "ebBG9",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abBGSmoke.png' }),
            color = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.16, 0),
            anchor = util.vector2(0, 0),
            visible = false
        },
    },
    {
        name = "ebPortrait9",
        type = ui.TYPE.Image,
            props = {
            --resource = ,
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.16, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    
    {
        name = "ebDamage9",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abDamage.png'}),
            color = util.color.rgb(120 / 255, 120 / 255, 120 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.16, 0),
            anchor = util.vector2(0, 0),
            alpha = 0.7,
            visible = false
            },
    },
    {
        name = "ebFrame9",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abFrame.png' }),
            color = util.color.rgb(229 / 255, 38 / 255, 91 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.16, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    -- enemy #9
    {
        name = "ebBG1",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abBGSmoke.png' }),
            color = util.color.rgb(255 / 255, 255 / 255, 255 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.3, 0),
            anchor = util.vector2(0, 0),
            visible = false
        },
    },
    {
        name = "ebPortrait1",
        type = ui.TYPE.Image,
            props = {
            --resource = ,
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.3, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    
    {
        name = "ebDamage1",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abDamage.png'}),
            color = util.color.rgb(120 / 255, 120 / 255, 120 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.3, 0),
            anchor = util.vector2(0, 0),
            alpha = 0.7,
            visible = false
            },
    },
    {
        name = "ebFrame1",
        type = ui.TYPE.Image,
            props = {
            resource = ui.texture({ path = 'Textures/abFrame.png' }),
            color = util.color.rgb(229 / 255, 38 / 255, 91 / 255),
            size = scalePortrait(71.75, 117.25),
            relativePosition = util.vector2(0.3, 0.0),
            anchor = util.vector2(0, 0),
            visible = false
            },
    },
    -- Enemy Bar
}

local function getFocusHealthBar()
    return bg3FocusHealthBar
end

local function getBG3Focus()
    return bg3Focus
end

local function getBG3EnemyBar()
    return bg3EnemyBar
end

local function onUpdate(dt)
    -- Empty function placeholder for the interface
end

return { 
    engineHandlers = 
    { 
        onUpdate = onUpdate 
    },
    
    interfaceName = "MM_UI",
    interface = {
        getFocusHealthBar = getFocusHealthBar,
        getBG3Focus = getBG3Focus,
        getBG3EnemyBar = getBG3EnemyBar,
    },
}