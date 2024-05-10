local common = require("mer.joyOfPainting.common")
local config = require("mer.joyOfPainting.config")
local logger = common.createLogger("artStyle")

local Spyglass = {}

function Spyglass.activate()
    if tes3ui.menuMode() then
        tes3ui.leaveMenuMode()
    end

    --Disable movement and controls

    --save current mge zoom

    --scrollwheel affects zoom level

    --right click leaves zoom mode
end

return Spyglass