local JoyOfPainting = require("mer.joyOfPainting")

local frameSizes = {
    {
        id = "square",
        width = 100,
        height = 100,
    },
    {
        id = "tall",
        width = 9,
        height = 16,
    },
    {
        id = "wide",
        width = 16,
        height = 9,
    },

    {
        id = "paper_portrait",
        width = 80,
        height = 100
    },

    {
        id = "paper_landscape",
        width = 100,
        height = 80
    },
}
local frames = {
    {
        id = "jop_frame_sq_01",
        frameSize = "square"
    },
    {
        id = "jop_frame_w_01",
        frameSize = "wide"
    },
    {
        id = "jop_frame_t_01",
        frameSize = "tall"
    },
    {
        id = "jop_frame_sq_02",
        frameSize = "square"
    },
    {
        id = "jop_frame_w_02",
        frameSize = "wide"
    },
    {
        id = "jop_frame_t_02",
        frameSize = "tall"
    },
    {
        id = "jop_frame_sq_03",
        frameSize = "square"
    },
    {
        id = "jop_frame_w_03",
        frameSize = "wide"
    },
    {
        id = "jop_frame_t_03",
        frameSize = "tall"
    },
}
event.register(tes3.event.initialized, function()
    for _, frameSize in ipairs(frameSizes) do
        JoyOfPainting.Frame.registerFrameSize(frameSize)
    end
    for _, frame in ipairs(frames) do
        JoyOfPainting.Frame.registerFrame(frame)
    end
end)