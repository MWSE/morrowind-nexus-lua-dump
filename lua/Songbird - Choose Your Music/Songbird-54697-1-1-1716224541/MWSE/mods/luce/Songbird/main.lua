local modName = "Songbird"
local version = "v1.0"

local mcm = require("luce.songbird.mcm")
local config = mwse.loadConfig("Songbird", { 
    enabled = true,
    exploreFavourites = {},
    battleFavourites = {},
    customFavourites = {},
    accessMenuKey = { 
        keyCode = 83, 
        isShiftDown = false, 
        isAltDown = false, 
        isControlDown = false, 
        isSuperDown = false }
    })
mcm.config = config

-- thank you herbert
local function openSongbirdMenu(menu)
    if menu then
        local mcm = menu:findChild("MenuOptions_MCM_container")
        if mcm then
            mcm:triggerEvent("mouseClick")
            -- return true
        end
        local mcmModList = tes3ui.findMenu("MWSE:ModConfigMenu").children
        for child in table.traverse(mcmModList) do
            if child.text == modName then
                child:triggerEvent("mouseClick")
            end
        end
    end
    return false
end

-- thank you herbert
local function songbirdShortcut(e)
    if not tes3.isKeyEqual({ expected = config.accessMenuKey, actual = e }) then
        return
    end
    -- if we couldn't open the menu
    if tes3.onMainMenu() then
        return
    end
    if not openSongbirdMenu(tes3ui.findMenu("MenuOptions")) then
        -- get the key that opens the options menu, and then press it
        local inputConfig = tes3.getInputBinding(tes3.keybind.menuMode) 
        if inputConfig.device == 1 then -- device == 1 means it's a keyboard key. idk how to make this work on mouse buttons
            tes3.tapKey(inputConfig.code)
            -- as soon as the menu opens, click the mcm button
            event.register("uiActivated", function(e)
                openSongbirdMenu(e.element)
            end, { filter = "MenuOptions", priority=-1, doOnce=true })
        end
    end
end

local function registerModConfig()
	mwse.registerModConfig(modName, mcm)
end
event.register(tes3.event.modConfigReady, registerModConfig)
event.register(tes3.event.keyDown, songbirdShortcut)

local function onInitialized()
    mwse.log("[" .. modName .. " " .. version .. "] initialised")
end
event.register(tes3.event.initialized, onInitialized)