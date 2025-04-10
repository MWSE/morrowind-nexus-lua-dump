local function isSkillBook(book)
    return book.skill and book.skill ~= -1
end

local function addTooltip(tooltip)
    local label = tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    if label then
        label.text = label.text .. " (Skill Book)"
        mwse.log("[SkillBook Tooltip] Added tooltip for a skill book: %s", label.text)
    else
        mwse.log("[SkillBook Tooltip] Failed to find tooltip label.")
    end
end

local function onTooltip(e)
    -- Check if the mod is initialized
    local data = tes3.player.data
    if not data or not data.skillBookModInitialized then
        mwse.log("[SkillBook Tooltip] Mod not initialized, skipping tooltip.")
        return
    end

    if e.object.objectType == tes3.objectType.book then
        local book = e.object

        if isSkillBook(book) then
            mwse.log("[SkillBook Tooltip] Detected a skill book: %s", book.id)
            addTooltip(e.tooltip)
        else
            mwse.log("[SkillBook Tooltip] Not a skill book: %s", book.id)
        end
    end
end

local function onLoaded()
    local data = tes3.player.data
    if not data.skillBookModInitialized then
        data.skillBookModInitialized = true
        mwse.log("[SkillBook Tooltip] Mod initialized successfully.")
    end
end

event.register(tes3.event.uiObjectTooltip, onTooltip)
event.register(tes3.event.loaded, onLoaded)
