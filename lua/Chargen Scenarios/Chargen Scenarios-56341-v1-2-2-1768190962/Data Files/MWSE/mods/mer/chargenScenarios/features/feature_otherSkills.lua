local common = require("mer.chargenScenarios.common")
local logger = common.createLogger("Feature:Curses")
local ExtraFeatures = require("mer.chargenScenarios.component.ExtraFeatures")

local SkillsModule = include("SkillsModule")

local OtherSkillsFeature = {
    id = "otherSkills",
    name = "Other Skills",
}

---@return table<string, number> selectedSkills
local function getSkillBonuses()
    return tes3.player.tempData.ChargenScenarios_selectedOtherSkills or {}
end

---Set or clear a skill bonus
---@param skillId string The SkillsModule skill ID
---@param bonus number|nil
local function setSkillBonus(skillId, bonus)
    tes3.player.tempData.ChargenScenarios_selectedOtherSkills = tes3.player.tempData.ChargenScenarios_selectedOtherSkills or {}
    tes3.player.tempData.ChargenScenarios_selectedOtherSkills[skillId] = (bonus ~= 0) and bonus or nil
end


function OtherSkillsFeature.getTooltip()
    local skillBonuses = getSkillBonuses()
    if not skillBonuses or next(skillBonuses) == nil then
        return ""
    end
    local message = "Other Skills: "
    for skillId, bonus in pairs(skillBonuses) do
        local skill = SkillsModule.skills[skillId]
        local skillName = skill.name or skillId
        message = message .. string.format("\n - %s: +%d", skillName, bonus)
    end
    return message
end

function OtherSkillsFeature.showFeature()
    --Show if Skills Module is installed and there are available skills
    return SkillsModule and table.size(SkillsModule.skills) > 0
end

---@param e ChargenScenarios.ExtraFeature.callbackParams
function OtherSkillsFeature.callback(e)
    --Create a list of available skills
    --Button callback: show [-10][-1][+1][+10] buttons to adjust skill bonus
    local skillBonuses = getSkillBonuses()
    local availableSkills = SkillsModule.skills

    local menu = tes3ui.createMenu{
        id = "ChargenScenarios:OtherSkillsMenu",
        fixedFrame = true,
    }
    menu.autoWidth = true
    menu:updateLayout()
    menu.flowDirection = "top_to_bottom"
    menu.childAlignX = 0.5

    local header = menu:createLabel{ text = "Select Other Skills Bonuses" }
    header.color = tes3ui.getPalette(tes3.palette.headerColor)
    header.borderBottom = 5

    local skillList = menu:createVerticalScrollPane()
    skillList.autoHeight = true
    skillList.widthProportional = 1.0
    skillList.minHeight = 400
    skillList.minWidth = 500

    local rows = {}
    for skillId, skill in pairs(availableSkills) do
        local skillName = skill.name
        local currentBonus = skillBonuses[skillId] or 0

        local skillBlock = skillList:createBlock()
        skillBlock.widthProportional = 1.0
        skillBlock.autoHeight = true
        skillBlock.flowDirection = "left_to_right"
        skillBlock.paddingAllSides = 5

        local function getSkillLabelText()
            local bonusValue = currentBonus >= 0 and "+" .. tostring(currentBonus) or tostring(currentBonus)
            return string.format("%s: %d (%s)", skillName, skill.current, bonusValue)
        end

        local skillLabel = skillBlock:createLabel{ text = getSkillLabelText() }
        skillLabel.autoHeight = true
        skillLabel.widthProportional = 1.0

        local function resetSkillBonus()
            currentBonus = 0
            setSkillBonus(skillId, 0)
            skillLabel.text = getSkillLabelText()
            menu:updateLayout()
        end

        local function createResetButton()
            local button = skillBlock:createButton{ text = "Reset" }
            button.autoHeight = true
            button.autoWidth = true
            button.borderLeft = 1
            button.borderRight = 1
            button:register("mouseClick", function()
                resetSkillBonus()
            end)
            return button
        end

        local function updateBonus(amount)
            currentBonus = currentBonus + amount
            SkillsModule.registerBaseModifier{
                id = "chargenScenarios_otherSkill_" .. skillId,
                skill = skillId,
                callback = function()
                    return getSkillBonuses()[skillId] or 0
                end
            }
            setSkillBonus(skillId, currentBonus)
            skillLabel.text = getSkillLabelText()
            menu:updateLayout()
        end

        local function createBonusButton(amount)
            local text = amount > 0 and "+" .. tostring(amount) or tostring(amount)
            local button = skillBlock:createButton{ text = text }
            button.autoHeight = true
            button.autoWidth = true
            button.borderLeft = 1
            button.borderRight = 1
            button:register("mouseClick", function()
                updateBonus(amount)
            end)
            return button
        end

        createBonusButton(-5)
        createBonusButton(-1)
        createResetButton()
        createBonusButton(1)
        createBonusButton(5)

        table.insert(rows, {
            reset = resetSkillBonus,
        })
    end

    local buttonsBlock = menu:createBlock()
    buttonsBlock.widthProportional = 1.0
    buttonsBlock.childAlignX = 1.0
    buttonsBlock.autoHeight = true


    --Reset button
    local resetButton = buttonsBlock:createButton{ text = "Reset All" }
    resetButton:register("mouseClick", function()
        for _, row in pairs(rows) do
            row.reset()
        end
    end)

    --Ok button
    local okButton = buttonsBlock:createButton{ text = tes3.findGMST(tes3.gmst.sOK).value }
    okButton:register("mouseClick", function()
        menu:destroy()
        e.goBack()
    end)

    menu:updateLayout()
    skillList.widget:contentsChanged()
end


function OtherSkillsFeature.onStart()

end

function OtherSkillsFeature.isActive()
    local skillBonuses = getSkillBonuses()
    return skillBonuses and table.size(skillBonuses) > 0
end

ExtraFeatures.registerFeature(OtherSkillsFeature)
