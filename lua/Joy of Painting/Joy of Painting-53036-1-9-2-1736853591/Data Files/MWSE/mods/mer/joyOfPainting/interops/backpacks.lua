local BackpackService = require("mer.joyOfPainting.items.Backpack")

local backpacks = {
    {
        id = "jop_easel_pack",
        offset = {
            translation = { x = 8, y = -10, z = 0 },
            rotation = { x = 270, y = 0, z = 90 },
            scale = 0.76
        }
    },
    {
        id = "jop_easel_pack_02",
        offset = {
            translation = { x = 8, y = -10, z = 0 },
            rotation = { x = 270, y = 0, z = 90 },
            scale = 0.76
        }
    }
}

event.register(tes3.event.initialized, function()
    for _, backpack in ipairs(backpacks) do
        BackpackService.registerBackpack(backpack)
    end
end)

