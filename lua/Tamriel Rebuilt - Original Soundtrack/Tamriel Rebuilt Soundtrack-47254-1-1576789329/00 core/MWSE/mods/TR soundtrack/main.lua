local MUSE = require("music.MUSE")

local function OnGameStart()

    if (MUSE == nil) then
        tes3.messageBox({message = "MUSE not installed! Download Morrowind Music System Extended 2.01 for Tamriel Rebuilt soundtrack to work!"})
        return
    end

    local text = "Update MUSE to version 2.01! Tamriel Rebuilt soundtrack requires 2.01 or newer version of Morrowind Music System Extended."

    if(MUSE.systemVersion == nil) then
        tes3.messageBox({message = text})
    end

    if(MUSE.systemVersion < 2.01) then
        tes3.messageBox({message = text})
    end
end
event.register("initialized", OnGameStart)