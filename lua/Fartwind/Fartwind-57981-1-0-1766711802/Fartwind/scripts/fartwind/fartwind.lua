local ambient = require("openmw.ambient")

-- Seed RNG once
math.randomseed(os.time())

-- Build fart sound list
local fartSounds = {}
for i = 1, 30 do
    fartSounds[i] = string.format("Sound\\fart%d.mp3", i)
end

-- Track pressed keys / mouse buttons
local pressed = {}

local function playRandomFart()
    -- Pick random sound
    local index = math.random(1, #fartSounds)

    -- Random pitch between 0.5 and 1.5
    local pitch = 0.5 + math.random() * 1.0

    -- Random volume between 0.5 and 1.5
    local volume = 0.5 + math.random() * 1.0

    ambient.playSoundFile(fartSounds[index], {
        volume = volume,
        pitch = pitch,
    })
end

return {
    engineHandlers = {

        onKeyPress = function(key)
            if not pressed[key] then
                pressed[key] = true
                playRandomFart()
            end
        end,

        onKeyRelease = function(key)
            pressed[key] = nil
        end,

        onMouseButtonPress = function(button)
            if not pressed[button] then
                pressed[button] = true
                playRandomFart()
            end
        end,

        onMouseButtonRelease = function(button)
            pressed[button] = nil
        end,
    }
}
