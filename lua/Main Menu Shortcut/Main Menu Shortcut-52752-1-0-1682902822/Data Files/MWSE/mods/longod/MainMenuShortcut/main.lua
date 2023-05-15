local defaultConfig = {
    mainMenu = true,
    gameMenu = true,
    new = true,
    save = true,
    load = true,
    options = true,
    modConfig = true,
    exit = true,
    exitEsc = true,
    continue = true,
}
local configPath = "longod.MainMenuShortcut"
local config = mwse.loadConfig(configPath, defaultConfig)

local bindings = {
    [tes3.scanCode.n] = {
        ids = {
            tes3ui.registerID("MenuOptions_New_container")
        },
        main = false, key = "new"
    },
    [tes3.scanCode.s] = {
        ids = {
            tes3ui.registerID("MenuOptions_Save_container")
        },
        main = false, key = "save"
    },
    [tes3.scanCode.l] = {
        ids = {
            tes3ui.registerID("MenuOptions_Load_container")
        },
        main = false, key = "load"
    },
    [tes3.scanCode.o] = {
        ids = {
            tes3ui.registerID("MenuOptions_Options_container")
        },
        main = false, key = "options"
    },
    [tes3.scanCode.m] = {
        ids = {
            tes3ui.registerID("MenuOptions_MCM_container")
        },
        main = false, key = "modConfig"
    },
    [tes3.scanCode.e] = {
        ids = {
            tes3ui.registerID("MenuOptions_Exit_container")
        },
        main = false, key = "exit"
    },
    [tes3.scanCode.escape] = {
        ids = {
            tes3ui.registerID("MenuOptions_Exit_container")
        },
        main = true, key = "exitEsc"
    },
    [tes3.scanCode.c] = {
        ids = {
            tes3ui.registerID("Pete_ContinueButton"),
            tes3ui.registerID("ImprovedMainMenu:ContinueButton"),
        },
        main = false, key = "continue" },
}

local blocked = false

--- @param e keyDownEventData
local function OnKeyDown(e)
    local mod = e.isAltDown or e.isControlDown or e.isShiftDown or e.isSuperDown
    if mod then
        return
    end
    -- focus message box?
    if tes3ui.findMenu(tes3ui.registerID("MenuMessage")) then
        return
    end

    -- on main menu
    local mainMenu = tes3.onMainMenu()
    if (mainMenu and config.mainMenu) or ((not mainMenu) and config.gameMenu) then
        local main = tes3ui.findMenu(tes3ui.registerID("MenuOptions"))
        if main and main.visible and not main.disabled then
            -- per button
            local bind = bindings[e.keyCode]
            if bind and config[bind.key] and (mainMenu or not bind.main) then
                for _, id in ipairs(bind.ids) do
                    local button = main:findChild(id)
                    if button and button.visible and not button.disabled then
                        -- If there are duplicate keys, like Mod Config, they have priority.
                        if blocked then
                            blocked = false -- fail-safe
                            return
                        end
                        button:triggerEvent("mouseClick")
                        break
                    end
                end
            end
        end
    end
end

event.register(tes3.event.keyDown, OnKeyDown)

local function OnDestroyModConfig()
    blocked = true      -- lock for duplicate keys
    timer.frame.delayOneFrame(function()
        blocked = false -- unlock after one frame
    end)
end

local function OnMouseClickModConfig()
    -- insert destory detection
    local modConfigMenu = tes3ui.findMenu(tes3ui.registerID("MWSE:ModConfigMenu"))
    if modConfigMenu then
        modConfigMenu:register(tes3.uiEvent.destroy, OnDestroyModConfig)
    end
end

--- MCM is closed with esc key, but the main menu is also restored at the same time.
--- Therefore, closing MCM is treated as pressing exit at the same time.
--- To avoid this, handle the destroying of MCM and do not accept pressing esc key on this mod at that one frame.
---@param e uiActivatedEventData
local function OnUiActivated(e)
    if not e.newlyCreated then
        return
    end
    local main = tes3ui.findMenu(tes3ui.registerID("MenuOptions"))
    if main then
        local modConfig = main:findChild(tes3ui.registerID("MenuOptions_MCM_container"))
        if modConfig then
            -- after mcm window created
            modConfig:registerAfter(tes3.uiEvent.mouseClick, OnMouseClickModConfig)
        end
    end
end
event.register(tes3.event.uiActivated, OnUiActivated, { filter = "MenuOptions", priority = -100 })

local function OnModConfigReady()
    local template = mwse.mcm.createTemplate("Main Menu Shortcut")
    template:saveOnClose(configPath, config)
    template:register()

    local page = template:createSideBarPage {
        label = "Settings",
        description = (
            "This mod allows to press each button on Main Menu with a shortcut key for the initial letter (excluding Credit).\nSo you can quickly access the desired item."
            )
    }

    ---@param value boolean
    ---@return string
    local function GetYesNo(value)
        return value and "Yes" or "No"
    end

    local names = {
        "mainMenu",
        "gameMenu",
        "new",
        "save",
        "load",
        "options",
        "modConfig",
        "exit",
        "exitEsc",
        "continue",
    }
    local labels = {
        "Main Menu",
        "In-Game Menu",
        "New [N]",
        "Save [S]",
        "Load [L]",
        "Options [O]",
        "Mod Config [M]",
        "Exit [E]",
        "Exit [Esc]",
        "Continue [C]",
    }
    local descs = {
        "Allow on Main Menu.",
        "Allow on In-Game Menu.",
        "Allow N key to press 'New' button.",
        "Allow S key to press 'Save' button.",
        "Allow L key to press 'Load' button.",
        "Allow O key to press 'Options' button.",
        "Allow M key to press 'Mod Config' button.",
        "Allow E key to press 'Exit' button.",
        "Allow Esc key to press 'Exit' button. Excluding In-Game Menu.",
        "Allow C key to press 'Continue' button by Petethegoat and Wisp.\nhttps://www.nexusmods.com/morrowind/mods/45952\nhttps://www.nexusmods.com/morrowind/mods/50856",
    }

    -- menus
    for i = 1, 2 do
        page:createYesNoButton {
            label = labels[i],
            description = (
                descs[i] ..
                "\n\nDefault: " .. GetYesNo(defaultConfig[names[i]])
                ),
            variable = mwse.mcm.createTableVariable {
                id = names[i],
                table = config,
            }
        }
    end

    -- buttons
    local category = page:createCategory("Buttons")
    for i = 3, #names do
        category:createYesNoButton {
            label = labels[i],
            description = (
                descs[i] ..
                "\n\nDefault: " .. GetYesNo(defaultConfig[names[i]])
                ),
            variable = mwse.mcm.createTableVariable {
                id = names[i],
                table = config,
            }
        }
    end
end

event.register(tes3.event.modConfigReady, OnModConfigReady)
