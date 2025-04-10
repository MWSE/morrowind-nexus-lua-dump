if tes3.isModActive("Terror of Tel Amur.esp") then

    event.register(tes3.event.initialized, function()
            -- Loads our lua modules
            require("telamur.shaders.fogInterior")
            if not tes3.isLuaModActive("music") then require("telamur.music.controller") end
            require("telamur.sounds.controller")
    end)

    -- Registers MCM menu
    event.register(tes3.event.modConfigReady, function()
        dofile("Data Files\\MWSE\\mods\\telamur\\mcm.lua")
    end)

end
