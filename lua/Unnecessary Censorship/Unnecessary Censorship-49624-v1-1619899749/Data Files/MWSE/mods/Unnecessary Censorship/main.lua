local config = require("Unnecessary Censorship.config")
config.init()

--------------------------------------------------

local function kLoop(kList, child)
    for _, k in pairs(kList) do
        child.text = child.text:gsub(k[1], k[2])
    end
end

local function findAndReplace(child)
    if (child) then
        if (config.getSettings().dunmerEnabled) then
            kLoop(config.getDunmer(), child)
        end
        if (config.getSettings().argonianEnabled) then
            kLoop(config.getDunmer(), child)
        end
    end
end

local function childLoop(child)
    if (child.children) then
        for _, ch in pairs(child.children) do
            findAndReplace(ch)
            childLoop(ch)
        end
    end
end

--------------------------------------------------

local function replaceDialogue(e)
    local child = { text = e:loadOriginalText() }

    findAndReplace(child)
    e.text = child.text
end

local function replaceUI(e)
    local menuMap = tes3ui.findMenu(tes3ui.registerID("MenuMap"))
    if (menuMap) then
        findAndReplace(menuMap)
    end

    local menuPopup = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
    if (menuPopup) then
        local child = menuPopup:findChild(tes3ui.registerID("MenuMulti_map_notify"))
        findAndReplace(child)
    end

    local menuDialogue = tes3ui.findMenu(tes3ui.registerID("MenuDialog"))
    if (menuDialogue) then
        local child = menuDialogue:findChild(tes3ui.registerID("PartDragMenu_main"))
        childLoop(child)
    end

    local menuJournal = tes3ui.findMenu(tes3ui.registerID("MenuJournal"))
    if (menuJournal) then
        local children = {
            menuJournal:findChild(tes3ui.registerID("MenuBook_page_1")),
            menuJournal:findChild(tes3ui.registerID("MenuBook_page_2")),
            menuJournal:findChild(tes3ui.registerID("MenuJournal_topicscroll"))
        }
        for _, child in ipairs(children) do
            if (child) then
                childLoop(child)
            end
        end
    end

    local menuContents = tes3ui.findMenu(tes3ui.registerID("MenuContents"))
    if (menuContents) then
        findAndReplace(menuContents)
    end
end

--------------------------------------------------

local function init()
    event.register("infoGetText", replaceDialogue)
    event.register("uiEvent", replaceUI)
end

event.register("initialized", init, { priority = 10 })