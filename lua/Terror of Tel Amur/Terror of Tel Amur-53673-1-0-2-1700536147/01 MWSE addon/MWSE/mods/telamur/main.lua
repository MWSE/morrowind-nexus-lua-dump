if tes3.isModActive("Terror of Tel Amur.esp") then

    event.register(tes3.event.initialized, function()
            -- Loads our lua modules
            require("telamur.shaders.fogInterior")
            require("telamur.music.controller")
            require("telamur.sounds.controller")
    end)

    -- Registers MCM menu
    event.register(tes3.event.modConfigReady, function()
        dofile("Data Files\\MWSE\\mods\\telamur\\mcm.lua")
    end)

end
