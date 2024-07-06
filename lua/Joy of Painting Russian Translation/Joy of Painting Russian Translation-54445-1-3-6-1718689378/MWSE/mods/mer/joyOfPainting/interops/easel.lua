--Add canvases via the interop
local JoyOfPainting = require("mer.joyOfPainting")
local easel = {
    {
        id = "jop_easel_01",
    },
    {
        id = "jop_field_easel",
        miscItem = "jop_easel_pack",
        doesPack = true,
    },
    {
        id = "jop_easel_02",
        miscItem = "jop_easel_misc",
    }
}

event.register(tes3.event.initialized, function()
    for _, data in ipairs(easel) do
        JoyOfPainting.Easel.registerEasel(data)
    end
end)

