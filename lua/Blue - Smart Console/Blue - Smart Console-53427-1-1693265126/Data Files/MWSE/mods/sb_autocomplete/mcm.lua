local mcm = { ["settings"] = mwse.loadConfig("sb_Blue") or { ["minChar"] = 1, ["sugType"] = 2 } }

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
        }
    }
    configCategory:createDropdown {
        label = "Full or partial suggestions",
        options = { { label = "Full", value = 1 }, { label = "Partial", value = 2 } },
        variable = mwse.mcm.createTableVariable {
            id = "sugType",
            table = mcm.settings
        }
    }

    local creditsCategory = settingsPage:createCategory("Credits")
    creditsCategory:createInfo { text =
    "- JosephMcKean for More Console Commands which worked as a starting point for this mod.\n- Greatness7 who suggested it as a feature for the aforementioned mod." }

    template:saveOnClose("sb_Blue", mcm.settings)
    mwse.mcm.register(template)
end

return mcm
