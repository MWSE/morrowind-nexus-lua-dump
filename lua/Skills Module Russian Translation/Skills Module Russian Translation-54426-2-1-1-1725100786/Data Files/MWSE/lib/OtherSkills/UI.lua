local Skill = require("OtherSkills.components.Skill")
local SkillModifier = require("OtherSkills.components.SkillModifier")
local util = require("OtherSkills.util")
local logger = util.createLogger("UI")

--Class for handling Skill UI elements
---@class SkillsModule.UI
local UI = {}

local iconPaths = {
    [tes3.specialization.combat] = "Icons/OtherSkills/combat_blank.dds",
    [tes3.specialization.magic] = "Icons/OtherSkills/magic_blank.dds",
    [tes3.specialization.stealth] = "Icons/OtherSkills/stealth_blank.dds"
}

local function createOuterBlock(parent)
    local outerBlock = parent:createBlock({ id = tes3ui.registerID("OtherSkills:outerBlock") })
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.paddingTop = 6
    outerBlock.paddingBottom = 12
    outerBlock.paddingLeft = 6
    outerBlock.paddingRight = 6
    outerBlock.autoWidth = true
    outerBlock.autoHeight = true
    return outerBlock
end

local function createTopBlock(parent)
    local topBlock = parent:createBlock({ id = tes3ui.registerID("OtherSkills:ttTopBlock") })
    topBlock.autoHeight = true
    topBlock.autoWidth = true
    return topBlock
end

local function createIcon(parent, skill)
    local iconBlock = parent:createBlock({})
    iconBlock.height = 32
    iconBlock.width = 32
    iconBlock.flowDirection = "left_to_right"
    iconBlock.borderTop = 2

    local iconBackgroundImagePath = iconPaths[skill.specialization] or "Icons/OtherSkills/default_blank.dds"
    local iconBackground = iconBlock:createImage({
        id = tes3ui.registerID("OtherSkills:ttIconBackground"),
        path = iconBackgroundImagePath
    })
    iconBackground.layoutOriginFractionX = 0
    local icon = iconBlock:createImage({ id = tes3ui.registerID("OtherSkills:ttIconImage"), path = skill.icon })
    icon.autoHeight = true
    icon.autoWidth = true
    icon.layoutOriginFractionX = 0
end


local function createTopRightBlock(parent)
    local topRightBlock = parent:createBlock({ id = tes3ui.registerID("OtherSkills:ttTopRightBlock") })
    topRightBlock.autoHeight = true
    topRightBlock.autoWidth = true
    topRightBlock.paddingLeft = 10
    topRightBlock.flowDirection = "top_to_bottom"
    return topRightBlock
end


local function createSkillLabel(parent, skill)
    local skillLabel = parent:createLabel({ id = tes3ui.registerID("OtherSkills:ttSkillLabel"), text = skill.name })
    skillLabel.autoHeight = true
    skillLabel.autoWidth = true
    skillLabel.color = tes3ui.getPalette("header_color")
    return skillLabel
end

local function createMidBlock(parent)
    local midBlock = parent:createBlock({ id = tes3ui.registerID("OtherSkills:ttMidBlock") })
    midBlock.paddingTop = 10
    midBlock.paddingBottom = 10
    midBlock.autoHeight = true
    midBlock.width = 430
    return midBlock
end

local function createDescriptionLabel(parent, skill)
    local descriptionLabel = parent:createLabel({
        id = tes3ui.registerID("OtherSkills:ttDescriptionLabel"),
        text = skill.description
    })
    descriptionLabel.wrapText = true
    descriptionLabel.width = 445
    descriptionLabel.autoHeight = true
    return descriptionLabel
end

local function createBottomBlock(parent)
    local bottomBlock = parent:createBlock({ id = tes3ui.registerID("OtherSkills:ttBottomBlock") })
    bottomBlock.autoHeight = true
    bottomBlock.widthProportional = 1.0
    bottomBlock.flowDirection = "top_to_bottom"
    bottomBlock.childAlignX = 0.5
    return bottomBlock
end

---comment
---@param parent tes3uiElement
---@param skill SkillsModule.Skill
local function createProgressBar(parent, skill)
    local progressLabel = parent:createLabel({
        id = tes3ui.registerID("OtherSkills:ttProgressLabel"),
        text = tes3.findGMST(tes3.gmst.sSkillProgress).value
    })
    progressLabel.color = tes3ui.getPalette("header_color")
    local progressBar = parent:createFillBar({
        id = tes3ui.registerID("OtherSkills:ttProgressFillBar"),
        current = skill:getProgressAsPercentage(),
        max = 100
    })
    progressBar.borderTop = 4
end

--- Create a tooltip for the given skill
---@param skill SkillsModule.Skill
local function createSkillTooltip(skill)
    --debugMessage("Creating skills list")
    local tooltip = tes3ui.createTooltipMenu()
    local outerBlock = createOuterBlock(tooltip)
    do
        local topBlock = createTopBlock(outerBlock)
        createIcon(topBlock, skill)
        local topRightBlock = createTopRightBlock(topBlock)
        createSkillLabel(topRightBlock, skill)
    end
    local midBlock = createMidBlock(outerBlock)
    createDescriptionLabel(midBlock, skill)
    local bottomBlock = createBottomBlock(outerBlock)
    createProgressBar(bottomBlock, skill)
end

--[[
    Create "Другие навыки" list and place into the stats menu
]]
local function createSkillsList(parentSkillBlock)
    local outerSkillsBlock = parentSkillBlock:createBlock({ id = "OtherSkills:outerSkillsBlock" })
    outerSkillsBlock.autoHeight = true
    outerSkillsBlock.layoutWidthFraction = 1.0
    outerSkillsBlock.flowDirection = "top_to_bottom"

    outerSkillsBlock:createDivider({ id = "OtherSkills:divider" })
    local headingBlock = outerSkillsBlock:createBlock({ id = "OtherSkills:headingBlock" })
    headingBlock.layoutWidthFraction = 1.0
    headingBlock.autoHeight = true

    local heading = headingBlock:createLabel({ id = "OtherSkills:headingLabel", text = "Другие навыки" })
    heading.color = tes3ui.getPalette("header_color")
    local skillsListBlock = outerSkillsBlock:createBlock({ id = "OtherSkills:skillsListBlock" })
    skillsListBlock.flowDirection = "top_to_bottom"
    skillsListBlock.layoutWidthFraction = 1.0
    skillsListBlock.autoHeight = true
    --move Другие навыки section to right after Misc Skills
    parentSkillBlock:reorderChildren(32, outerSkillsBlock, -1)
end


---Refreshes the skills list in the stats menu whenever values change
---E.g on skill increase or adding new skills
---@param e uiActivatedEventData
UI.updateSkillList = function(e)
    local mainMenu = tes3ui.findMenu(tes3ui.registerID("MenuStatReview"))
        or tes3ui.findMenu(tes3ui.registerID("MenuStat"))
    if not (mainMenu and mainMenu.visible) then return end
    logger:debug("Updating skill list")
    local skillsListBlock = mainMenu:findChild("OtherSkills:skillsListBlock")
    local outerSkillsBlock = mainMenu:findChild("OtherSkills:outerSkillsBlock")
    if not (skillsListBlock and outerSkillsBlock) then
        local scrollPane = mainMenu:findChild("MenuStat_scroll_pane")
            or mainMenu:findChild("MenuStatReview_scroll_pane")
        local miscBlock = scrollPane:findChild("MenuStat_misc_layout")
            or scrollPane:findChild("MenuStatReview_misc_layout")
        local parent = miscBlock.parent
        createSkillsList(parent)
        skillsListBlock = mainMenu:findChild("OtherSkills:skillsListBlock")
        outerSkillsBlock = mainMenu:findChild("OtherSkills:outerSkillsBlock")
    end
    ---@type SkillsModule.Skill[]
    local skills = Skill.getSorted()
    if #skills == 0 then
        logger:warn("No skills registered")
        outerSkillsBlock.autoHeight = false
        outerSkillsBlock.height = 0
        return
    end
    --skills found, recreating skill list
    skillsListBlock:destroyChildren()
    for _, skill in ipairs(skills) do
        if not skill:isActive() then
            logger:debug("- skill %s not active", skill.id)
        else
            logger:debug("- skill %s", skill.id)
            outerSkillsBlock.autoHeight = true
            local skillsBlockID = "OtherSkills:skillBlock_" .. skill.id
            local skillBlock = skillsListBlock:createBlock({ id = skillsBlockID })
            skillBlock.widthProportional = 1.0
            skillBlock.flowDirection = "left_to_right"
            skillBlock.borderLeft = 10
            skillBlock.borderRight = 5
            skillBlock.autoHeight = true

            local skillLabel = skillBlock:createLabel({ id = "OtherSkills:skillLabel", text = skill.name })
            skillLabel.absolutePosAlignX = 0.0

            local current = string.format("%G", skill.current)
            local skillValueLabel = skillBlock:createLabel({ id = "OtherSkills:skillValue", text = current })

            --Change color based on fortify or drain
            local fortifyEffect = SkillModifier.calculateFortifyEffect(skill)
            if fortifyEffect then
                if fortifyEffect > 0 then
                    skillValueLabel.color = tes3ui.getPalette("positive_color")
                elseif fortifyEffect < 0 then
                    skillValueLabel.color = tes3ui.getPalette("negative_color")
                end
            end

            skillValueLabel.absolutePosAlignX = 1.0

            --Create skill Tooltip
            skillBlock:register("help", function() createSkillTooltip(skill) end)
        end
    end
    mainMenu:updateLayout()
end

---@param menu tes3uiElement
function UI.updateClassMenuCustomSkills(menu)

    local customSkillsBlock = menu:findChild("SkillsModule_OtherSkillsBlock")
    --First clear any existing content
    if customSkillsBlock then
        customSkillsBlock:destroyChildren()
    else
        customSkillsBlock = menu:createBlock{ id = "SkillsModule_OtherSkillsBlock"}
    end
    customSkillsBlock.widthProportional = 1
    customSkillsBlock.autoHeight = true
    customSkillsBlock.flowDirection = "top_to_bottom"
    customSkillsBlock.paddingAllSides = 4
    customSkillsBlock.minHeight = 80
    --Don't repopulate if nothing to add
    local class = tes3.player.object.class
    local classModifiers = SkillModifier.getClassModifiers(class.id)
    local header = customSkillsBlock:createLabel{
        id = "SkillsModule_OtherSkillsHeader",
        text = "Другие навыки"
    }
    header.color = tes3ui.getPalette("header_color")

    --Sort skills into 3 columns
    local columnBlock = customSkillsBlock:createBlock{ id = "SkillsModule_OtherSkillsColumnBlock" }
    columnBlock.flowDirection = "left_to_right"
    columnBlock.widthProportional = 1.0
    columnBlock.autoHeight = true
    local columns = {}
    for i = 1, 3 do
        local column = columnBlock:createBlock{ id = "SkillsModule_OtherSkillsColumn_" .. i }
        column.widthProportional = 1.0
        column.autoHeight = true
        column.flowDirection = "top_to_bottom"
        table.insert(columns, column)
    end

    local colIndex = 1
    table.sort(classModifiers, function(a, b) return a.name < b.name end)
    for skillId, amount in pairs(classModifiers) do
        local skill = Skill.get(skillId)
        if skill then
            --get one of the 3 columns
            logger:debug("Adding custom skill %s to column %d", skill.id, colIndex)
            local column = columns[colIndex]
            colIndex = (colIndex % 3) + 1
            local plusOrMinus = amount > 0 and "+" or "-"
            local text = string.format("%s %s %d", skill.name, plusOrMinus, math.abs(amount))
            column:createLabel{ text = text }
            logger:debug("Adding custom skill %s to class menu", skill.id)
        end
    end

    local placeBeforeBlock = menu:findChild("MenuChooseClass_Backbutton").parent
    menu:getContentElement():reorderChildren(placeBeforeBlock, customSkillsBlock, 1)
    menu:updateLayout()
end

---@param e uiRefreshedEventData
function UI.addSkillsToClassMenu(e)
    local menu = e.element
    if not menu.id == "MenuChooseClass" then return end
    local classList = e.element:findChild("MenuChooseClass_ClassScroll")
    if not classList then
        logger:warn("Class list not found")
        return
    end

    if not Skill.hasActiveClassModifiers() then
        logger:debug("No active class modifiers")
        return
    end

    logger:debug("Initialising custom skills in class menu")
    classList = classList:getContentElement()
    for _, button in ipairs(classList.children) do
        button:registerAfter("mouseClick", function()
            UI.updateClassMenuCustomSkills(menu)
        end)
    end
    UI.updateClassMenuCustomSkills(menu)
end


---@TODO Finish NPC skills and training
---@private Unfinished
---@param newSkill SkillsModule.Skill
function UI.replaceTrainingSkill(newSkill)
    local trainingMenu = tes3ui.findMenu("MenuServiceTraining")
    if not trainingMenu then
        logger:warn("Training Menu not found")
        return
    end
    local serviceList = trainingMenu:findChild("MenuServiceTraining_ServiceList")
    if not serviceList then
        logger:warn("Service List not found")
        return
    end

    --insert new skill according to NPC skill level
    local insertindex = (function()
        local trainer = trainingMenu:getTopLevelMenu():getPropertyObject("MenuServiceTraining_Actor")
        for i, button in ipairs(serviceList.children) do
            local thisSkill = tes3.getSkill(button:getPropertyInt("MenuServiceTraining_ListNumber"))
            local trainerSkill = trainer.skills[thisSkill + 1]
            if newSkill.base > trainerSkill.base then
                return i
            end
        end
    end)()
    if insertindex then
        logger:debug("Inserting new skill at index %d", insertindex)
        local buttonText = string.format("%s - %dgp", newSkill.name, 100)
        serviceList:createTextSelect{ text = buttonText}
        serviceList:reorderChildren(insertindex, -1, 1)
        serviceList.widget:contentsChanged()
    end
end

return UI
