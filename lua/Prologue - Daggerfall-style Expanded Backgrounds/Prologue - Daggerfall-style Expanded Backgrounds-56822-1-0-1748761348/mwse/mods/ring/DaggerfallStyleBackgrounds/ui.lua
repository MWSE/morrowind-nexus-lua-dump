local upbringing = require("ring.DaggerfallStyleBackgrounds.upbringing")

local data

local ui = {}

local function randomize(trait, button)
    local list = data[trait].options
    local randomValue,randomName = table.choice(list)
    local name = randomName
    local value = randomValue
    local id = value.id or name

    if value.objectType == tes3.objectType.skill then
        name = tes3.getSkillName(value.id)
    end
    if value.objectType == tes3.objectType.race then
        name = value.name
    end

    upbringing.current[trait].name = name
    upbringing.current[trait].value = value.startingGold or id
    button.text = name
    button:updateLayout()
end

---@param e tes3uiEventData
local function createPickList(e,trait, button)
    local list = data[trait].options
    local menu = tes3ui.createMenu{id = "chargenUpbringing_"..trait, fixedFrame = true}
        local block = menu:createBlock()
            block.width = 300
            block.height = 400
            block.flowDirection = tes3.flowDirection.topToBottom
        local pickHeader = block:createLabel{ text = "Choose your " .. trait }
            pickHeader.justifyText = tes3.justifyText.center
            pickHeader.color = tes3ui.getPalette("header_color")
        local scrollpane = block:createVerticalScrollPane()
            scrollpane.height = 300
            scrollpane.autoWidth = true
            scrollpane.paddingAllSides = 10
            block:createDivider()
            block:createButton{ text = "Randomize" }:register(tes3.uiEvent.mouseClick, function (e)
                randomize(trait,button)
                menu:destroy()
            end)
    for name, value in pairs(list) do
        local id = value.startingGold or value.id or name
        name = value.name or name
        if trait == "majorSkill" then
            name = tes3.getSkillName(value.id)
        end
        local thisTextSelect = scrollpane:createTextSelect{ text = name }
            thisTextSelect.autoHeight = true
            thisTextSelect.autoWidth = true
            thisTextSelect.paddingAllSides = 2
            thisTextSelect:register(tes3.uiEvent.mouseClick, function ()
                upbringing.current[trait].name = name
                upbringing.current[trait].value = id
                button.text = name
                button:updateLayout()
                menu:destroy()
            end)

        if trait == "province" and name == "None" then
            local morrowindOption = scrollpane:createTextSelect{ text = "Morrowind" }
            morrowindOption.disabled = true
            morrowindOption.color = tes3ui.getPalette("disabled_color")
            morrowindOption:register(tes3.uiEvent.help, function ()
                local tooltip = tes3ui.createTooltipMenu()
                tooltip:createLabel{ text = "You are an Outlander, so you don't get to choose this, n'wah." }
            end)
        end

        -- Tooltips
        if trait == "environment" then
            thisTextSelect:register(tes3.uiEvent.help, function (e)
                local tooltip = tes3ui.createTooltipMenu()
                tooltip.flowDirection = tes3.flowDirection.topToBottom
                tooltip.autoHeight = true
                tooltip.autoWidth = true
                tooltip:createLabel{ text = name }.absolutePosAlignX = 0.5
                local description = tooltip:createLabel{ text = value.description }
                description.wrapText = true
                tooltip:createDivider()
                for _, bonus in ipairs(value.bonuses) do
                    local prefix = ""
                    if bonus.value > 0 then
                        prefix = "+"
                    end
                    tooltip:createLabel{ text = prefix .. bonus.value .. " " .. tes3.attributeName[bonus.attribute] }
                end
            end)
        end
        if trait == "socialClass" then
            thisTextSelect:register(tes3.uiEvent.help, function (e)
                local tooltip = tes3ui.createTooltipMenu()
                tooltip.flowDirection = tes3.flowDirection.topToBottom
                tooltip.autoHeight = true
                tooltip.autoWidth = true
                tooltip:createLabel{ text = name }.absolutePosAlignX = 0.5
                local description = tooltip:createLabel{ text = value.description }
                description.wrapText = true
                tooltip:createDivider()
                tooltip:createLabel{ text = "Starting Gold: " .. value.startingGold }
            end)
        end
        if trait == "fatherRace" then
            local raceObject = tes3.findRace(value.id)
            thisTextSelect:register(tes3.uiEvent.help, function (e)
                local tooltip = tes3ui.createTooltipMenu()
                tooltip.flowDirection = tes3.flowDirection.topToBottom
                tooltip.autoHeight = true
                tooltip.autoWidth = true
                tooltip:createLabel{ text = name }.absolutePosAlignX = 0.5
                local description = tooltip:createLabel{ text = value.description }
                description.wrapText = true

                if raceObject then
                    tooltip:createDivider()
                    tooltip:createLabel{ text = "You will receive a random skill and attribute bonus from the following list after chargen, and a +5 disposition bonus with the chosen race" }
                    if raceObject.skillBonuses then
                        tooltip:createLabel{ text = "Skills" }.absolutePosAlignX = 0.5
                        for _, skill in ipairs(raceObject.skillBonuses) do
                            tooltip:createLabel{ text = tes3.getSkillName(skill.skill)..": "..skill.bonus }
                        end
                    end
                    if raceObject.baseAttributes then
                        tooltip:createLabel{ text = "Attributes" }.absolutePosAlignX = 0.5
                        for i, attribute in ipairs(raceObject.baseAttributes) do
                            if attribute.male >= 50 then
                                tooltip:createLabel{ text = tes3.attributeName[i].. ": +5"}
                            end
                        end
                    end
                end
            end)
        end
        if trait == "majorSkill" then
            ---@cast value tes3skill
            thisTextSelect:register(tes3.uiEvent.help, function (e)
                local tooltip = tes3ui.createTooltipMenu({ skill = tes3.getSkill(value.id) })
                tooltip:createLabel{ text = "You will receive a +5 bonus to this skill after chargen." }.absolutePosAlignX = 0.5
            end)
        end
        if trait == "province" then
            thisTextSelect:register(tes3.uiEvent.help, function (e)
                local tooltip = tes3ui.createTooltipMenu()
                tooltip.flowDirection = tes3.flowDirection.topToBottom
                tooltip.autoHeight = true
                tooltip.autoWidth = true
                tooltip:createLabel{ text = name }.absolutePosAlignX = 0.5
                tooltip:createLabel{ text = value.description }.wrapText = true
                tooltip:createDivider()
                tooltip:createLabel{ text = "You will receive a +5 disposition bonus with the chosen province." }
            end)
        end
    end
    menu:updateLayout()
end
---comment
---@param okCallback function
function ui.createMenu(okCallback)
    upbringing.currentClass = tes3.player.object.class
    upbringing.currentRace = tes3.player.object.race
    data = upbringing.initData()
    local menu = tes3ui.createMenu{id = "chargenUpbringing", fixedFrame = true}
        menu.height = 600
        menu.width = 800
        local outerBlock = menu:createBlock()
            outerBlock.flowDirection = tes3.flowDirection.topToBottom
            outerBlock.autoHeight = true
            outerBlock.autoWidth = true
            local header = outerBlock:createLabel{ text = "Upbringing" }
                header.color = tes3ui.getPalette("header_color")
                header.justifyText = tes3.justifyText.center
            local description = outerBlock:createLabel{ text = "Who are you?" }
                description.absolutePosAlignX = 0.5
            outerBlock:createDivider()
    ---@type table<string, tes3uiElement>
    local buttons = {}
    for trait, value in pairs(data) do
        local traitBlock = outerBlock:createBlock()
            traitBlock.autoHeight = true
            traitBlock.autoWidth = true
            traitBlock.flowDirection = tes3.flowDirection.topToBottom
            local traitLabel = traitBlock:createLabel{ text = value.description }
            local traitListButton = traitBlock:createButton{ text = upbringing.current[trait].name }
                buttons[trait] = traitListButton
                traitListButton.autoWidth = true
                traitListButton.autoHeight = true
                traitListButton:register(tes3.uiEvent.mouseClick, function (e)
                    createPickList(e,trait,traitListButton)
                end)
                traitListButton:register(tes3.uiEvent.help, function (e)
                    local tooltip = tes3ui.createTooltipMenu()
                    tooltip.flowDirection = tes3.flowDirection.topToBottom
                    tooltip:createLabel{ text = value.tooltip.header }.color = tes3ui.getPalette("header_color")
                    tooltip:createLabel{ text = value.tooltip.description }.wrapText = true
                end)
    end

    local footer = outerBlock:createBlock()
        footer.flowDirection = tes3.flowDirection.leftToRight
        footer.absolutePosAlignX = 0.90
        footer.height = 30
        footer.autoWidth = true
        footer:createButton{ text = "Confirm" }:register(tes3.uiEvent.mouseClick, function (e)
            local confirmMenu = tes3ui.createMenu{id = "chargenUpbringingConfirm", fixedFrame = true}
            confirmMenu.autoHeight = true
            confirmMenu.autoWidth = true
            confirmMenu.flowDirection = tes3.flowDirection.topToBottom
            confirmMenu.alpha = 1
            local confirmBlock = confirmMenu:createBlock()
                confirmBlock.width = 450
                confirmBlock.height = 250
                confirmBlock.flowDirection = tes3.flowDirection.topToBottom
                local headerBlock = confirmBlock:createBlock()
                    headerBlock.autoHeight = true
                    headerBlock.autoWidth = true
                    local header = headerBlock:createLabel{ text = "Confirm Upbringing" }
                        header.color = tes3ui.getPalette("header_color")
                        header.justifyText = tes3.justifyText.center
                confirmBlock:createDivider()
                confirmBlock:createLabel{ text = upbringing.flavorText() }.wrapText = true
                confirmBlock:createLabel{ text = "\nAre you sure you want this to be your upbringing?" }
                local buttonsBlock = confirmMenu:createBlock()
                    buttonsBlock.autoHeight = true
                    buttonsBlock.autoWidth = true
                    buttonsBlock.flowDirection = tes3.flowDirection.leftToRight
                    buttonsBlock:createButton{ text = "No" }:register(tes3.uiEvent.mouseClick, function (e)
                        confirmMenu:destroy()
                    end)
                    buttonsBlock:createButton{ text = "Yes" }:register(tes3.uiEvent.mouseClick, function (e)
                        confirmMenu:destroy()
                        menu:destroy()
                        okCallback()
                    end)
        end)
        footer:createButton{ text = "Randomize All" }:register(tes3.uiEvent.mouseClick, function (e)
            for trait, button in pairs(buttons) do
                randomize(trait, button)
            end
        end)
    menu:updateLayout()
end

return ui