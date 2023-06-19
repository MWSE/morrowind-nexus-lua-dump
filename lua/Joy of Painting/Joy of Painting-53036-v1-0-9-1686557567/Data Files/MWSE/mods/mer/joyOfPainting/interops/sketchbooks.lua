local JoyOfPainting = require("mer.joyOfPainting")
local sketchbooks = {
    {
        id = "jop_sketchbook_01"
    }
}
event.register(tes3.event.initialized, function()
    for _, sketchbook in ipairs(sketchbooks) do
        JoyOfPainting.Sketchbook.registerSketchbook(sketchbook)
    end
end)