local ui = require("openmw.ui")
local util = require("openmw.util")

-- Create the health bar container widget on the HUD layer
local healthBar = ui.create {
    layer = "HUD",                 -- Place on HUD so it’s visible during gameplay
    type = ui.TYPE.Widget,
    props = {
        -- Place the widget in the top-right corner:
        -- relativePosition defines where the widget's anchor is placed in the screen (1,0) is the top right.
        relativePosition = util.vector2(1, 0),
        -- Anchor the widget's top-right corner to that point
        anchor = util.vector2(1, 0),
        -- Set the bar dimensions (width x height)
        size = util.vector2(200, 20),
    },
    content = ui.content {
        -- The main health bar graphic: a simple red rectangle.
        ui.create {
            type = ui.TYPE.Image,
            props = {
                resource = "black",      -- Use a blank/solid texture; adjust path as needed
                tileH = false,
                tileV = false,
                -- Overlay the black texture with red:
                color = util.color.rgb(1, 0, 0),  -- Red color
                relativeSize = util.vector2(1, 1),
                alpha = 1,
            }
        },
        -- Optional: Add a text label to show health value (can be updated in a game loop)
        ui.create {
            type = ui.TYPE.Text,
            props = {
                text = "Health: 100%",      -- Placeholder text; update during gameplay
                textColor = util.color.rgb(1, 1, 1),  -- White text on red bar
                textSize = 16,
                anchor = util.vector2(0.5, 0.5),   -- Center the text in the widget
                relativePosition = util.vector2(0.5, 0.5),
            }
        }
    }
}

-- A simple update function – add your game-logic here to update the health value and bar size.
local function update(dt)
    -- Example: Update health text or bar size based on your game logic.
    -- healthBar.layout.content[2].layout.props.text = "Health: " .. newHealthValue .. "%"
    -- healthBar:update()  -- Don’t forget to call update() if you change any properties.
end

-- Return the engine handler so OpenMW can run the update (or tie it to another event)
return {
    engineHandlers = {
        onFrame = function(dt)
            update(dt)
        end
    }
}
