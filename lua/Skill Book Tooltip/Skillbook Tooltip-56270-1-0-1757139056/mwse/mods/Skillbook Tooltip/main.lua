local config = { showSkillName = true }

local function isSkillBook(book)
    return book.skill and book.skill ~= -1
end

local function getSkillName(skillId)
    if skillId and skillId >= 0 and skillId <= 26 then
        return tes3.skillName[skillId]
    end
    return "Unknown Skill"
end

local function addTooltip(tooltip, book)
    local label = tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    if label then
        if config.showSkillName then
            local skillName = getSkillName(book.skill)
            label.text = label.text .. string.format(" (Skill Book - Teaches: %s)", skillName)
        else
            label.text = label.text .. " (Skill Book)"
        end
        mwse.log("[SkillBook Tooltip] Updated tooltip: %s", label.text)
    else
        mwse.log("[SkillBook Tooltip] Failed to find tooltip label.")
    end
end

local function onTooltip(e)
    local data = tes3.player.data
    if not data or not data.skillBookModInitialized then
        mwse.log("[SkillBook Tooltip] Mod not initialized, skipping tooltip.")
        return
    end

    if e.object.objectType == tes3.objectType.book then
        local book = e.object

        if isSkillBook(book) then
            mwse.log("[SkillBook Tooltip] Skill book detected: %s", book.id)
            addTooltip(e.tooltip, book)
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

-- MCM (Mod Configuration Menu)
local function registerModConfig()
    local template = mwse.mcm.createTemplate("Skill Book Tooltip")
    template:saveOnClose("SkillBookTooltip", config)

    local page = template:createSideBarPage({
        label = "Skill Book Tooltip Settings",
        description = "This mod adds an indicator to skill books in the tooltip.\n\nEnable 'Show Skill Name' to display the skill it teaches."
    })

    local category = page:createCategory("Tooltip Options")

    category:createOnOffButton({
        label = "Show Skill Name",
        description = "If enabled, tooltips will show the skill name a book teaches.\nOtherwise, it will just say 'Skill Book'.",
        variable = mwse.mcm.createTableVariable { id = "showSkillName", table = config }
    })

    mwse.mcm.register(template)
end

event.register(tes3.event.uiObjectTooltip, onTooltip)
event.register(tes3.event.loaded, onLoaded)
event.register(tes3.event.modConfigReady, registerModConfig)
