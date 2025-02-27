-- MCM
local modName = "Character Goals"

local defaultConfig = {
    enabled = true,
}
local configFile = modName
local config = mwse.loadConfig(configFile, defaultConfig)

local goalsMenuId = tes3ui.registerID("goalsMenu")
local testheader = tes3ui.registerID("testheaderID")
local descriptionHeaderId = tes3ui.registerID("goalDescriptionHeaderText")
local descriptionTextId = tes3ui.registerID("goalDescriptionText")
local makeActiveButtonId = tes3ui.registerID("makeActiveButton")
local descriptionInputID = tes3ui.registerID("descriptionInputID")
local randomButtonResult = tes3ui.registerID("randomButtonResultID")

local goalData


local function registerModConfig()
    local template = mwse.mcm.createTemplate({ name = modName, config = config, defaultConfig = defaultConfig, showDefaultSetting = true })
    template:saveOnClose(configFile, config)

    local settings = template:createSideBarPage({ label = "Settings" })

    settings:createYesNoButton({ label = "Enable mod - requires restart", configKey = "enabled" })

    local goalInspirationPage = template:createSideBarPage({ label = "Goal Ideas"})

    for filePath, dir, fileName in lfs.walkdir("Data Files\\MWSE\\mods\\luce\\goals\\config\\") do
            local fileNameWithoutExtension = fileName:sub(1, -5)
            local goalList = require("luce.goals.config." .. fileNameWithoutExtension)
            for _, goal in ipairs(goalList) do
                goalInspirationPage:createActiveInfo({ label = goal.name, description = goal.description })
            end
    end 

    template:register()
end
event.register(tes3.event.modConfigReady, registerModConfig)

-- Create goals menu
local okayButton

local function clickedCancel(menu)
    if (tes3ui.findMenu(menu) ~= nil) then
        tes3ui.leaveMenuMode()
        tes3ui.findMenu(menu):destroy()
    end
end

local function clickedRandom(goalsList)
    return goalsList[ math.random(#goalsList) ] 
end

local function clickedOkay(newName, newDescription)
    goalData.currentGoalName = newName
    goalData.currentGoalDescription = newDescription
    if (tes3ui.findMenu(goalsMenuId) ~= nil) then
        tes3ui.findMenu(goalsMenuId):destroy()
        tes3ui.leaveMenuMode()
    end
end

local function createGoalsMenu()
    mwse.log("Creating goals menu")
    if (tes3ui.findMenu(goalsMenuId) ~= nil) then
        mwse.log("Already open")
        return
    end

    local goalsMenu = tes3ui.createMenu{ id = goalsMenuId, fixedFrame = true }
    local outerBlock = goalsMenu:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.autoHeight = true
    outerBlock.minWidth = 320

    local nameLabel = goalsMenu:createLabel{ text = "Set a goal name: \n" }
    nameLabel.color = tes3ui.getPalette("header_color")

    local thinBorder = goalsMenu:createThinBorder()
    thinBorder.height = 30
    thinBorder.width = 300
    thinBorder.paddingAllSides = 3

    local nameInput = thinBorder:createTextInput{ id = nameInputID }
    nameInput.text = goalData.currentGoalName  -- initial text
    nameInput.borderAllSides = 1
    nameInput.widget.lengthLimit = 28  -- TextInput custom properties

    local descriptionLabel = goalsMenu:createLabel{ text = "\nSet a goal description: \n" }
    descriptionLabel.color = tes3ui.getPalette("header_color")

    local descriptionInput = goalsMenu:createParagraphInput{ id = descriptionInputID }
    descriptionInput.text = goalData.currentGoalDescription
    descriptionInput.borderAllSides = 1
    descriptionInput.wrapText = true
    descriptionInput:register("mouseClick", function() tes3ui.acquireTextInput(descriptionInput) end)


    -- local buttonBlock = goalsMenu:createBlock()
    -- buttonBlock.flowDirection = "left_to_right"
    -- buttonBlock.widthProportional = 1

    local okayButton = goalsMenu:createButton{ text = tes3.findGMST("sOK").value }
    okayButton.autoHeight = true
    okayButton.paddingAllSides = 2
    okayButton.borderAllSides = 2
    local randomButton = goalsMenu:createButton{ text = "Random Goal" }
    local cancelButton = goalsMenu:createButton{ text = tes3.findGMST("sCancel").value }

    local goalList = {}
    for filePath, dir, fileName in lfs.walkdir("Data Files\\MWSE\\mods\\luce\\goals\\config\\") do
        local fileNameWithoutExtension = fileName:sub(1, -5)
        local tempGoalList = require("luce.goals.config." .. fileNameWithoutExtension)
        for _, goal in ipairs(tempGoalList) do
            table.insert(goalList, goal)
        end
    end 

    randomButton:register("mouseClick", function() 
        local randomGoal = clickedRandom(goalList) 
        nameInput.text = randomGoal.name
        descriptionInput.text = randomGoal.description
        if (randomGoal.replacerOptions ~= nil) then
            local replacement = randomGoal.replacerOptions[ math.random(#randomGoal.replacerOptions) ]
            nameInput.text = nameInput.text:gsub("REPLACE", replacement)
            descriptionInput.text =  descriptionInput.text:gsub("REPLACE", replacement)
        end

        end )
    cancelButton:register("mouseClick", function() clickedCancel(goalsMenuId) end )
    okayButton:register("mouseClick", function() clickedOkay(nameInput.text, descriptionInput.text) end )

    goalsMenu:updateLayout()
    tes3ui.enterMenuMode(goalsMenuId)
end
event.register("Goals:OpenGoalsMenu", function() createGoalsMenu() end)

-- Add Goals section to character sheet
-- Get and display goal summary
local goalStatUID = tes3ui.registerID("GoalNameStatUI")

local function updateGoalStat()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))

    if menu then
        local goalLabel = menu:findChild(goalStatUID)
        if goalData and goalData.currentGoalName then
          goalLabel.text = goalData.currentGoalName
        else
            goalLabel.text = "None"
        end
        menu:updateLayout()
    end
end
event.register("menuEnter", updateGoalStat)

-- Create the tooltip when hovering over the active goal
local function createGoalTooltip()
    if goalData.currentGoalName then
        local tooltip = tes3ui.createTooltipMenu()
        local outerBlock = tooltip:createBlock()
        outerBlock.flowDirection = "top_to_bottom"
        outerBlock.paddingTop = 6
        outerBlock.paddingBottom = 12
        outerBlock.paddingLeft = 6
        outerBlock.paddingRight = 6
        outerBlock.width = 400
        outerBlock.autoHeight = true

        local header = outerBlock:createLabel{
            text = goalData.currentGoalName
        }
        header.absolutePosAlignX = 0.5
        header.color = tes3ui.getPalette("header_color")


        local description = outerBlock:createLabel{
                text = goalData.currentGoalDescription
        }
        description.autoHeight = true
        description.width = 285
        description.wrapText = true

        tooltip:updateLayout()
    end
end

local function loaded()
    tes3.player.data.luceGoals = tes3.player.data.luceGoals or {}
    goalData = tes3.player.data.luceGoals
    goalData.currentGoalName = goalData.currentGoalName or "Explore"
    goalData.currentGoalDescription = goalData.currentGoalDescription or "Look for trouble."
end

event.register("loaded", loaded )

-- Create the goal block on the stats menu ui
local function createGoalStat(e)
    if not (config.enabled == true) then
        return
    end

    local goalHeadingText = "Goal"

    local GUI_Goal_Stat = tes3ui.registerID(GUI_MenuStat_Goal_Stat)

    local menu = e.element
    local charBlock = menu:findChild(tes3ui.registerID("MenuStat_level_layout")).parent

    local goalBlock = charBlock:findChild(GUI_Goal_Stat)
    if goalBlock then goalBlock:destroy() end

    goalBlock = charBlock:createBlock({ id = GUI_Goal_Stat })
    goalBlock.widthProportional = 1.0
    goalBlock.autoHeight = true
    
    local goalHeadingLabel = goalBlock:createLabel{ text = goalHeadingText }
    goalHeadingLabel.color = tes3ui.getPalette("header_color")

    local nameBlock = goalBlock:createBlock()
    nameBlock.paddingLeft = 5
    nameBlock.autoHeight = true
    nameBlock.widthProportional = 1.0

    local nameLabel = nameBlock:createLabel{ id = goalStatUID, text = "None" }
    nameLabel.wrapText = true
    nameLabel.widthProportional = 1.0
    nameLabel.justifyText = "right"

    goalHeadingLabel:register("help", createGoalTooltip )
    nameBlock:register("help", createGoalTooltip )
    nameLabel:register("help", createGoalTooltip )
    nameBlock:register("mouseClick", createGoalsMenu )
    nameLabel:register("mouseClick", createGoalsMenu )

    menu:updateLayout()

end
event.register("uiActivated", createGoalStat, { filter = "MenuStat" })