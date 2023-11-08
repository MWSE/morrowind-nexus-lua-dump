local mcm = {
    ["settings"] = mwse.loadConfig("sb_blue") or
        { ["minChar"] = 1, ["sugType"] = 2, ["fillKey"] = {
            ["keyCode"] = tes3.scanCode["tab"],
            ["isShiftDown"] = false,
            ["isControlDown"] = false,
            ["isAltDown"] = false
        }
        }
}

function mcm.init()
    local template = mwse.mcm.createTemplate { name = "Blue - Smart Console", headerImagePath =
    "Textures\\sb_autocomplete\\Logo.tga" }
    local settingsPage = template:createPage { label = "", noScroll = true }
    local configCategory = settingsPage:createCategory("Config")
    configCategory:createSlider {
        label = "Minimum character requirement",
        description = "Increase this if you experience lag.\nRecommended: 1-3",
        min = 1,
        max = 5,
        step = 1,
        jump = 1,
        variable = mwse.mcm.createTableVariable {
            id = "minChar",
            table = mcm.settings
        },
        defaultSetting = 1
    }
    configCategory:createDropdown {
        label = "Full or partial suggestions",
        options = { { label = "Full", value = 1 }, { label = "Partial", value = 2 } },
        variable = mwse.mcm.createTableVariable {
            id = "sugType",
            table = mcm.settings
        },
        defaultSetting = 1
    }
    configCategory:createKeyBinder {
        label = "Autofill key binding",
        leftSide = false,
        allowCombinations = true,
        variable = mwse.mcm.createTableVariable {
            id = "fillKey",
            table = mcm.settings
        },
        defaultSetting = {
            ["keyCode"] = tes3.scanCode["tab"],
            ["isShiftDown"] = false,
            ["isControlDown"] = false,
            ["isAltDown"] = false
        }
    }

    local creditsCategory = settingsPage:createCategory("Credits")
    creditsCategory:createInfo { text =
    "- JosephMcKean for More Console Commands which worked as a starting point for this mod.\n- Greatness7 who suggested it as a feature for the aforementioned mod." }

    template:saveOnClose("sb_Blue", mcm.settings)
    mwse.mcm.register(template)
end

return mcm
