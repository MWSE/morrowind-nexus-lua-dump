local ui = require('openmw.ui')
local async = require('openmw.async')
local util = require('openmw.util')
local input = require('openmw.input')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local core = require('openmw.core')
local self = require('openmw.self')
local time = require('openmw_aux.time')
local storage = require('openmw.storage')
local section = storage.playerSection("Settings_SkillProgressRecord_CONTROLS_KINDI")
local getL = core.l10n("skill_progress_record")
require('scripts.skill_progress_record.settings')

if core.API_REVISION < 29 then
    error("[Skill Progress Record] requires the latest OpenMW version to function. Please update to enjoy this mod.")
end
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
local attributesSkills = {
    ["strength"] = {"Acrobatics", "Armorer", "Axe", "Blunt Weapon", "Long Blade"},
    ["intelligence"] = {"Alchemy", "Conjuration", "Enchant", "Security"},
    ["willpower"] = {"Alteration", "Destruction", "Mysticism", "Restoration"},
    ["agility"] = {"Block", "Light Armor", "Marksman", "Sneak"},
    ["speed"] = {"Athletics", "Handtohand", "Short Blade", "Unarmored"},
    ["endurance"] = {"Heavy Armor", "Medium Armor", "Spear"},
    ["personality"] = {"Illusion", "Mercantile", "Speechcraft"},
    ["luck"] = {},
    --["custom_skill_attribute"] = {"custom_skill_1", "custom_skill_2"}, --//remember to add custom attribute to attributes table as well
}

local attributes = {"strength", "intelligence", "willpower", "agility", "speed", "endurance", "personality", "luck"}

local skillsAttributes = {}

for attributeName, skills in pairs(attributesSkills) do
    for i, skill in pairs(skills) do
        local skillName = skill:lower():gsub("%s", "")
        skillsAttributes[skillName] = attributeName
    end
end

local tableOverflowControl = {
    __index = function(_T, _K)
        if _K >= #_T then
            return _T[1]
        elseif _K < 1 then
            return _T[#_T]
        end
    end
}

local lastSkillValues = setmetatable({}, {
    __index = function()
        return 0
    end
})
local trainedSkillValues = setmetatable({}, {
    __index = function()
        return 0
    end
})
setmetatable(attributes, tableOverflowControl)
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

local SPC = {}
local SPCMenu
local SPCMenu_ResetMenu
local SPCMenu_InfoMenu
local skillData = types.NPC.stats.skills
local currentAttributeShown = next(attributesSkills)
local currentLevel = 0
local controlSwitched = false
local SPCMenu_isClosing


SPC.find = function(t, value)
    for key, v in pairs(t) do
        if v == value then
            return key
        end
    end
end

SPC.findGoverningAttribute = function(skillName)
    return skillsAttributes[skillName]
end

SPC.getTotalTrainedSkillsForCurrentLevel = function()
    local total = 0
    SPC.updateTrainedSkillValues()
    for skillName in pairs(skillsAttributes) do
        total = total + trainedSkillValues[skillName]
    end
    return tostring(total)
end

SPC.getTrainedValueForThisSkill = function(skillName)
    return math.max(0, skillData[skillName](self).base - lastSkillValues[skillName])
end

SPC.getTotalTrainedSkillsForThisAttribute = function(attributeName)
    local total = 0
    for skillName, value in pairs(trainedSkillValues) do
        if SPC.findGoverningAttribute(skillName) == attributeName then
            total = total + value
        end
    end
    return tostring(total)
end

SPC.updateTrainedSkillValues = function()
    for skillName in pairs(skillsAttributes) do
        trainedSkillValues[skillName] = SPC.getTrainedValueForThisSkill(skillName)
    end
end

SPC.resetTrainedSkillValues = function()
    for skillName in pairs(skillsAttributes) do
        lastSkillValues[skillName] = types.NPC.stats.skills[skillName](self).base
        trainedSkillValues[skillName] = 0
    end
end

SPC.createNewBlock = function(name, isHorizontal)
    return {
        name = name,
        type = ui.TYPE.Flex,
        props = {
            horizontal = isHorizontal == nil and true or isHorizontal,
            align = ui.ALIGNMENT.Center,
            arrange = ui.ALIGNMENT.Center,
            alpha = 1,
        },
        content = ui.content {}
    }
end

SPC.createNewText = function(name, text, template)
    return {
        name = name,
        type = ui.TYPE.Text,
        template = template or I.MWUI.templates.textNormal,
        props = {
            text = tostring(text),
            textSize = 20,
            textAlignH = ui.ALIGNMENT.Center,
            textAlignV = ui.ALIGNMENT.Center
        }
    }
end

SPC.createNewImage = function(name, texture, visible)
    local block = SPC.createNewBlock(name, nil)
    block.content = ui.content {{
        name = name,
        type = ui.TYPE.Image,
        props = {
            resource = texture,
            size = util.vector2(16, 16),
            visible = visible
        }
    }}
    return block
end

SPC.createNewButton = function(name, text, callback)
    local block = SPC.createNewBlock(name, nil)
    local cont = SPC.createNewText(name, text)
    cont.events = {
        mouseClick = async:callback(callback)
    }
    block.content = ui.content {cont}
    block.props.size = util.vector2(0, 50)

    return block
end

SPC.createNewMenu = function(name, layer, template)
    return ui.create {
        name = name,
        template = template or I.MWUI.templates.boxTransparent,
        layer = layer or 'Windows',
        props = {
            relativePosition = util.vector2(.5, .5),
            anchor = util.vector2(.5, .5),
            alpha = 1
        },
        content = ui.content {}
    }
end

SPC.refreshSPCMenu = function(attributeName)

    if not attributeName then
        attributeName = currentAttributeShown
    else
        currentAttributeShown = attributeName
    end

    SPC.destroySPCMenu()

    SPCMenu = SPC.createNewMenu("SPCMenu")

    local mainBlock = SPC.createNewBlock("mainBlock")
    SPCMenu.layout.content:add(mainBlock)
    mainBlock.props.horizontal = false
    mainBlock.props.align = ui.ALIGNMENT.Center
    mainBlock.props.arrange = ui.ALIGNMENT.Center

    mainBlock.content:add(SPC.createNewBlock("totalSkillIncreaseBlock"))
    local totalSkillIncreaseBlock = mainBlock.content.totalSkillIncreaseBlock
    totalSkillIncreaseBlock.props.size = util.vector2(100, 25)
    totalSkillIncreaseBlock.content:add(SPC.createNewText("descText", string.format(getL("game_descText"),
        currentLevel, SPC.getTotalTrainedSkillsForCurrentLevel())))

    mainBlock.content:add(SPC.createNewBlock("attributeNameBlock"))
    local attributeNameBlock = mainBlock.content.attributeNameBlock
    attributeNameBlock.props.size = util.vector2(100, 25)
    attributeNameBlock.content:add(SPC.createNewText("attributeNameText", getL(attributeName):upper()))

    mainBlock.content:add(SPC.createNewBlock("attributeIncreaseBlock"))
    local attributeIncreaseBlock = mainBlock.content.attributeIncreaseBlock
    attributeIncreaseBlock.content:add(SPC.createNewText("attributeDescText",
        string.format(getL("game_attributeDescText"), getL(attributeName),
            SPC.getTotalTrainedSkillsForThisAttribute(attributeName))))

    mainBlock.content:add(SPC.createNewBlock("skillsListBlock"))
    local skillsListBlock = mainBlock.content.skillsListBlock
    skillsListBlock.content:add(SPC.createNewText("divider1", "------------"))


    for i, skill in pairs(attributesSkills[attributeName]) do
        local skillName = getL(skill:lower())

        mainBlock.content:add(SPC.createNewBlock("headerBlockSkillName_" .. skillName))
        local headerBlockSkillName = mainBlock.content["headerBlockSkillName_" .. skillName]
        headerBlockSkillName.content:add(SPC.createNewText("skillName_" .. skillName, skillName .. ": "))
        headerBlockSkillName.content:add(SPC.createNewText("skillLevelsTrained", SPC.getTrainedValueForThisSkill(
            skill:gsub("%s", ""):lower())))

        if attributesSkills[attributeName][i+1] then
            mainBlock.content:add(SPC.createNewBlock("skillsListBlock"))
            local skillsListBlock = mainBlock.content.skillsListBlock
            skillsListBlock.content:add(SPC.createNewText(nil, ""))
        end

    end

    local divider = SPC.createNewBlock()
    mainBlock.content:add(divider)
    divider.content:add(SPC.createNewText(nil, string.rep(" ", 4) .. string.rep("_", 120) .. string.rep(" ", 4)))

    local buttonsBlock1 = SPC.createNewBlock("buttonsBlock1")
    mainBlock.content:add(buttonsBlock1)

    local arrowRightTexture = ui.texture {
        path = 'textures/menu_scroll_right.dds',
        size = util.vector2(64, 64),
        offset = util.vector2(-8, -8)
    }

    for i, attributeName in pairs(attributes) do
        local newImage = SPC.createNewImage("pointerArrow_image", arrowRightTexture, false)
        newImage.autoSize = false
        newImage.props.size = util.vector2(30, 0)
        local newButton = SPC.createNewButton("attributeName_button", getL(attributeName),
            function()
                SPC.onButtonPressed(attributeName)
            end)
        buttonsBlock1.content:add(newImage)
        buttonsBlock1.content:add(newButton)
        if attributeName == currentAttributeShown then
            newImage.content["pointerArrow_image"].props.visible = true
            newButton.content["attributeName_button"].template = I.MWUI.templates.textHeader
            -- newButton.content["attributeName_button"].props.textColor = util.color.rgba(0, 1, 0.5, 1) --// highlight the text
        end
        if attributes[i + 1] then
            -- buttonsBlock1.content:add(SPC.createNewText("attributeName_space", string.rep(" ", 6))) --// hax for padding. temporary solution until proper API is available
        end
    end

    local buttonsBlock2 = SPC.createNewBlock("buttonsBlock2")
    mainBlock.content:add(buttonsBlock2)

    local newImage = SPC.createNewImage("pointerArrow_image", arrowRightTexture, false)
    newImage.autoSize = false
    newImage.props.size = util.vector2(30, 0)
    local infoButton = SPC.createNewButton("info_button", string.format("%s [%s]", getL("info"), section:get("Open Info")),
        SPC.onInfoButtonPressed)
    buttonsBlock2.content:add(newImage)
    buttonsBlock2.content:add(infoButton)

    local newImage = SPC.createNewImage("pointerArrow_image", arrowRightTexture, false)
    newImage.autoSize = false
    newImage.props.size = util.vector2(30, 0)
    local resetButton = SPC.createNewButton("reset_button", string.format("%s [%s]", getL("reset"), section:get("Open Reset")), SPC.onResetButtonPressed)
    buttonsBlock2.content:add(newImage)
    buttonsBlock2.content:add(resetButton)

    SPCMenu:update()
    ui.updateAll()

end

SPC.onButtonPressed = function(attributeName)
    currentAttributeShown = attributeName:lower()
    SPC.refreshSPCMenu(currentAttributeShown)
end

SPC.closeSPCMenu = function(dt)
    if SPCMenu_isClosing and SPCMenu then
        SPCMenu.layout.props.alpha = SPCMenu.layout.props.alpha - 0.05
        SPCMenu:update()

        if SPCMenu.layout.props.alpha <= 0 then
            SPCMenu_isClosing = nil
            SPCMenu:destroy()
            SPCMenu = nil
        end
    end
end

SPC.destroySPCMenu = function(closeButtonPressed)
    if SPCMenu then
        if closeButtonPressed and not SPCMenu_isClosing then
            SPCMenu_isClosing = true
            input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
        else
            SPCMenu:destroy()
            SPCMenu = nil
        end
    end
end

SPC.destroySPC_ResetMenu = function()
    if SPCMenu_ResetMenu then
        SPCMenu_ResetMenu:destroy()
        SPCMenu_ResetMenu = nil
    end
end

SPC.destroySPC_InfoMenu = function()
    if SPCMenu_InfoMenu then
        SPCMenu_InfoMenu:destroy()
        SPCMenu_InfoMenu = nil
        SPC.refreshSPCMenu()
    end
end

SPC.onInfoButtonPressed = function()

    if SPCMenu_InfoMenu then
        SPC.destroySPC_InfoMenu()
        return
    end

    SPCMenu_InfoMenu = SPC.createNewMenu("SPCMenu_InfoMenu")
    local mainBlock = SPC.createNewBlock("mainBlock")
    SPCMenu_InfoMenu.layout.content:add(mainBlock)
    mainBlock.props.horizontal = false
    mainBlock.props.align = ui.ALIGNMENT.Center
    mainBlock.props.arrange = ui.ALIGNMENT.Center

    SPCMenu.layout.template = I.MWUI.templates.disabled

    local padding = SPC.createNewBlock("SPCMenu_InfoMenu_paddingTop")
    padding.autoSize = false
    padding.props.size = util.vector2(512, 16)
    padding.props.anchor = util.vector2(0.5, 0.5)
    local textBlock = SPC.createNewBlock("SPCMenu_InfoMenu_textBlock")

    local text = SPC.createNewText("infoDescription", getL("game_infoDesc"))
    text.props.wordWrap = true
    text.props.multiline = true

    mainBlock.content:add(padding)
    mainBlock.content:add(textBlock)
    textBlock.content:add(text)
    mainBlock.content:add(padding)

    SPCMenu_InfoMenu:update()
    SPCMenu:update()
end

SPC.onResetButtonPressed = function()
    SPCMenu_ResetMenu = SPC.createNewMenu("SPCMenu_ResetMenu")
    local mainBlock = SPC.createNewBlock("mainBlock")
    SPCMenu_ResetMenu.layout.content:add(mainBlock)
    mainBlock.props.horizontal = false
    mainBlock.props.align = ui.ALIGNMENT.Center
    mainBlock.props.arrange = ui.ALIGNMENT.Center

    SPCMenu.layout.template = I.MWUI.templates.disabled

    local paddingTop = SPC.createNewBlock("SPCMenu_ResetMenu_paddingTop")
    paddingTop.autoSize = false
    paddingTop.props.size = util.vector2(512, 16)
    local textBlock = SPC.createNewBlock("SPCMenu_ResetMenu_textBlock")

    local text = SPC.createNewText("resetPrompt", getL("game_resetPrompt"))
    text.props.wordWrap = true
    text.props.multiline = true

    mainBlock.content:add(paddingTop)
    mainBlock.content:add(textBlock)
    textBlock.content:add(text)

    local yesButton = SPC.createNewButton("yes_button", core.getGMST("sYes") .. " [Y]", function()
        SPC.resetTrainedSkillValues()
        SPC.refreshSPCMenu()
        SPCMenu_ResetMenu:destroy()
        SPCMenu_ResetMenu = nil
        SPCMenu.layout.template = I.MWUI.templates.boxTransparent
        SPCMenu:update()
    end)
    local noButton = SPC.createNewButton("no_button", core.getGMST("sNo") .. " [N]", function()
        SPCMenu_ResetMenu:destroy()
        SPCMenu_ResetMenu = nil
        SPCMenu.layout.template = I.MWUI.templates.boxTransparent
        SPCMenu:update()
    end)

    local buttonBlock = SPC.createNewBlock("SPCMenu_ResetMenu_buttonBlock")
    buttonBlock.props.autoSize = false
    buttonBlock.props.size = util.vector2(512, 64)
    mainBlock.content:add(buttonBlock)
    buttonBlock.content:add(yesButton)
    buttonBlock.content:add(SPC.createNewText("SPCMenu_ResetMenu_emptySpace", string.rep(" ", 12)))
    buttonBlock.content:add(noButton)

    SPCMenu_ResetMenu:update()
    SPCMenu:update()

end

--//shake effect of UI
SPC.shakeMenu = function(menu)
    local timer
    local iteration = 0
    local dt = 0.005
    timer = time.runRepeatedly(function()
        iteration = iteration + 1
        dt = dt * -1

        if not menu then
            timer()
            return
        end

        menu.layout.props.relativePosition = util.vector2(.5 + dt, .5)

        if iteration > 5 then
            timer()
            menu.layout.props.relativePosition = util.vector2(.5, .5)
        end

        menu:update()
    end, 0.01)
end


--//checks changes in player level periodically
time.runRepeatedly(function()
    if currentLevel ~= types.Actor.stats.level(self).current then
        currentLevel = types.Actor.stats.level(self).current
        SPC.resetTrainedSkillValues()
    end

    if SPCMenu and controlSwitched == false then
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, false)
        controlSwitched = true
    elseif not SPCMenu and controlSwitched == true then
        input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
        controlSwitched = false
    end
end, 0.1)


--//unifies inputAction and keyPress handler
SPC.menuKeyPressBehaviour = function(action)
    pcall(function()
        --//coming from inputAction
        if type(action) == 'number' then 
            action = SPC.find(input.ACTION, action)
        end

        --//coming from onKeyPress 
        if type(action) == 'userdata' then
            action = SPC.find(input.KEY, action.code)
        end
    end)

    if action == section:get("Close Record") then
        if SPCMenu_ResetMenu then
            SPC.shakeMenu(SPCMenu_ResetMenu)
            return
        elseif SPCMenu_InfoMenu then
            SPC.shakeMenu(SPCMenu_InfoMenu)
            return
        elseif SPCMenu and not SPCMenu_isClosing then
            SPCMenu_isClosing = true
            input.setControlSwitch(input.CONTROL_SWITCH.Controls, true)
        end
    end

    if not SPCMenu_ResetMenu and not SPCMenu_InfoMenu then
        if action == section:get("Navigate Left") then
            local previousAtt = attributes[SPC.find(attributes, currentAttributeShown) - 1]
            SPC.refreshSPCMenu(previousAtt)
        elseif action == section:get("Navigate Right") then
            local nextAtt = attributes[SPC.find(attributes, currentAttributeShown) + 1]
            SPC.refreshSPCMenu(nextAtt)
        elseif action == section:get("Open Info") then
            SPC.onInfoButtonPressed()
        elseif action == section:get("Open Reset") then
            SPC.onResetButtonPressed()
            -- input.setControlSwitch(input.CONTROL_SWITCH.Looking, false) --//broken behavior, apparently imitates morrowind
        end
    elseif SPCMenu_ResetMenu then
        SPC.shakeMenu(SPCMenu_ResetMenu)
    elseif SPCMenu_InfoMenu then
        if action == section:get("Open Info") then
            SPC.destroySPC_InfoMenu()
        else
            SPC.shakeMenu(SPCMenu_InfoMenu)
            return
        end
    end

    if SPCMenu_isClosing then
        return
    end

    if SPCMenu_ResetMenu then
        if action == section:get("No") then
            SPC.destroySPC_ResetMenu()
            SPC.refreshSPCMenu()
            -- input.setControlSwitch(input.CONTROL_SWITCH.Looking, true)
        elseif action == section:get("Yes") then
            SPC.resetTrainedSkillValues()
            SPC.destroySPC_ResetMenu()
            SPC.refreshSPCMenu()
            ui.showMessage("Succesfully reset progress")
        end
        return
    end

    if action == section:get("Open Record") then
        SPC.refreshSPCMenu()
    end
end

return {
    engineHandlers = {
        onKeyPress = SPC.menuKeyPressBehaviour,
        onSave = function()
            return {currentLevel, lastSkillValues, trainedSkillValues}
        end,
        onLoad = function(data)
            if data then
                currentLevel, lastSkillValues, trainedSkillValues = unpack(data)
            end
        end,
        onInit = function()
            SPC.resetTrainedSkillValues()
        end,
        onFrame = function(dt)
            SPC.closeSPCMenu(dt)
        end,
        onInputAction = function(action)
            if not SPCMenu then
                return
            end

            SPC.menuKeyPressBehaviour(action)
        end
    },
}
