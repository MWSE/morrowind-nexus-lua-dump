local mod = "No Taunting"
local version = "1.0"

-- Register this ID in outer scope so we only have to do it once.
local persuasionListID = tes3ui.registerID("MenuPersuasion_ServiceList")

-- Runs each time the persuasion menu is opened.
local function onPersuasionMenu(e)

    -- Find the list of persuasion options.
    local persuasionList = e.element:findChild(persuasionListID)

    -- Taunt is the third option down.
    local tauntButton = persuasionList.children[3]

    -- The button is still there, just hidden, so there shouldn't be conflicts.
    tauntButton.visible = false

    -- Refresh the layout of the persuasion menu so it will still display properly.
    -- Yes this has to be done twice.
    e.element:updateLayout()
    e.element:updateLayout()
end

local function onInitialized()
    event.register("uiActivated", onPersuasionMenu, { filter = "MenuPersuasion" })
    mwse.log("[%s %s] initialized.", mod, version)
end

event.register("initialized", onInitialized)