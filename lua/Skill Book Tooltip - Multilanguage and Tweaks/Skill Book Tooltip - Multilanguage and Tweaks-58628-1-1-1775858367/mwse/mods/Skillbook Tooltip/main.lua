local config = { showSkillName = true }
local i18n = mwse.loadTranslations("Skillbook Tooltip")

local function isSkillBook(book)
    return book.skill and book.skill ~= -1
end

local function getSkillName(skillId)
    if skillId and skillId >= 0 and skillId <= 26 then
        return tes3.getSkillName(skillId)
    end
    return "Unknown Skill"
end

local function addTooltip(tooltip, book)
    local label = tooltip:findChild(tes3ui.registerID("HelpMenu_name"))
    if label then
        if config.showSkillName then
            local skillName = getSkillName(book.skill)
            label.text = label.text .. i18n("skillbook_teaches", { skillName = skillName})
        else
            label.text = label.text .. i18n("skillbook")
        end
    end
end

local function onTooltip(e)
    if e.object.objectType == tes3.objectType.book then
        local book = e.object

        if isSkillBook(book) then
            addTooltip(e.tooltip, book)
        end
    end
end

-- MCM (Mod Configuration Menu)
local function registerModConfig()
    local template = mwse.mcm.createTemplate("Skill Book Tooltip")
    template:saveOnClose("SkillBookTooltip", config)

    local page = template:createSideBarPage({
        label = "Skill Book Tooltip Settings",
        description = i18n("page_description")
    })

    local category = page:createCategory(i18n("tooltip_options"))

    category:createOnOffButton({
        label = i18n("show_skill_name_label"),
        description = i18n("show_skill_name_description"),
        variable = mwse.mcm.createTableVariable { id = "showSkillName", table = config }
    })

    mwse.mcm.register(template)
end

event.register(tes3.event.uiObjectTooltip, onTooltip)
event.register(tes3.event.modConfigReady, registerModConfig)