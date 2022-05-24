local common = require("celediel.DoorRandomizer.common")
local config = require("celediel.DoorRandomizer.config").getConfig()

local this = {}

-- {{{ randomize specific doors
this.randomizeDoor = function(door, chance)
    if not door.object or door.object.objectType ~= tes3.objectType.door then
        common.log("[Interop] Only doors can be randomized, ya goof.")
        return
    end

    if not chance then
        common.log("[Interop] No randomize chance given, defaulting to 100%")
        chance = 100
    end

    if not door.data.doorRandomizer then door.data.doorRandomizer = {} end

    door.data.doorRandomizer.randomizeChance = chance
end

this.unRandomizeDoor = function(door)
    if not door.object or door.object.objectType ~= tes3.objectType.door then
        common.log("[Interop] Only doors can be unrandomized, ya goof.")
        return
    end

    door.data.doorRandomizer = nil
end
-- }}}

-- {{{ global randomize chance
this.setRandomizeChance = function(chance)
    if not chance or type(chance) ~= "number" then
        common.log("[Interop] Randomize chance must be a number, ya goof.")
        return
    end

    config.randomizeChance = chance
end

this.getRandomizeChance = function()
    return config.randomizeChance
end
-- }}}

return this
