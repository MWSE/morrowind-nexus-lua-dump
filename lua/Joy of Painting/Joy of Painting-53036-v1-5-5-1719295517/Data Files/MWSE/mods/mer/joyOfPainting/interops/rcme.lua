local common = include("mer.joyOfPainting.common")
local logger = common.createLogger("RightClickMenuExit Interop")

local rcmeButtons = {
    {
        menu = "JOP_SketchbookMenu",
        button = "JOP_SketchbookMenu_ExitButton"
    },
    -- {
    --     menu = "TJOP.PhotoMenu",
    --     button = "JOP.CloseButton"
    -- },
    {
        menu = "JOP.NamePaintingMenu",
        button = "JOP.CloseButton"
    }
}
event.register(tes3.event.initialized, function()
    local RightClickMenuExit = include("mer.RightClickMenuExit")
    if RightClickMenuExit and RightClickMenuExit.registerMenu then
        for _, data in ipairs(rcmeButtons) do
            logger:debug("Registering menu %s with close button  %s", data.menu, data.button)
            RightClickMenuExit.registerMenu{
                menuId = data.menu,
                buttonId = data.button
            }
        end
    end
end)