local configPath = "character_beliefs"

local config = mwse.loadConfig(configPath)
if (config == nil) then
	config = { 
        enableBeliefs = true,
    }
    mwse.saveConfig(configPath, config)
end 


local beliefsList = require("mtrByTheDivines.beliefsList")

local perksMenuID = tes3ui.registerID("perksMenu")
local descriptionID = tes3ui.registerID("perkDescriptionText")
local descriptionHeaderID = tes3ui.registerID("perkDescriptionHeaderText")

local data

local function modReady()
    return (
        config.enableBeliefs and
        not tes3.menuMode() and
        tes3.player and
        data
    ) 
end


-------------------------------------------------------------
--UI functions
-------------------------------------------------------------

local bfUID = tes3ui.registerID("BeliefNameUI")

local function updateBFStat()
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuStat"))
    if menu then 
        local belief = menu:findChild(bfUID)
       
        if data and data.currentBelief then
            belief.text =  beliefsList[data.currentBelief].name
        else
            belief.text = "None"
        end
        menu:updateLayout()
    end
end

local function getDescription(belief)
    if type(belief.description) == "function" then
        return belief.description()
    else
        return belief.description
    end
end

local function createBFTooltip()
    if data.currentBelief then
        local belief = beliefsList[data.currentBelief]

        local tooltip = tes3ui:createTooltipMenu()
        local outerBlock = tooltip:createBlock()
        outerBlock.flowDirection = "top_to_bottom"
        outerBlock.paddingTop = 6
        outerBlock.paddingBottom = 12
        outerBlock.paddingLeft = 6
        outerBlock.paddingRight = 6
        outerBlock.width = 450
        outerBlock.autoHeight = true   

        local header = outerBlock:createLabel{
            text = belief.name 
        }
        header.absolutePosAlignX = 0.5
        header.color = tes3ui.getPalette("header_color")

         
        local description = outerBlock:createLabel{
            text = getDescription(belief)
        }
        description.autoHeight = true
        description.width = 285
        description.wrapText = true  

        tooltip:updateLayout()
    end
end


local function createBFStat(e)
    
    local menu = e.element
    local charBlock = menu:findChild(tes3ui.registerID("MenuStat_level_layout")).parent
    local bfBlock = charBlock:createBlock()
    bfBlock.widthProportional = 1.0
    bfBlock.autoHeight = true


    local label = bfBlock:createLabel{ text = "Belief"}
    label.color = tes3ui.getPalette("header_color")


    local beliefBlock = bfBlock:createBlock()
    beliefBlock.paddingLeft = 5
    beliefBlock.autoHeight = true
    beliefBlock.widthProportional = 1.0

    local beliefLabel = beliefBlock:createLabel{ id = bfUID,  text = "None" }
    if data and data.currentBelief then
        beliefLabel.text = beliefsList[data.currentBelief].name
    end
    beliefLabel.wrapText = true
    beliefLabel.widthProportional = 1
    --belief.absolutePosAlignX = 1.0
    beliefLabel.justifyText = "right"
    

    label:register("help", createBFTooltip )
    beliefBlock:register("help", createBFTooltip )
    beliefLabel:register("help", createBFTooltip )

    menu:updateLayout()
end
event.register("uiActivated", createBFStat, { filter = "MenuStat", priority = 1})

-----------------------------------------------------------------
local okayButton

local function clickedPerk(belief)
    data.currentBelief = belief.id
    
    local header = tes3ui.findMenu(perksMenuID):findChild(descriptionHeaderID)
    header.text = belief.name

    local description = tes3ui.findMenu(perksMenuID):findChild(descriptionID)
    description.text = getDescription(belief)
    description:updateLayout()
    
    if beliefsList[data.currentBelief].checkDisabled and beliefsList[data.currentBelief].checkDisabled() then 
        header.color = tes3ui.getPalette("disabled_color")
        okayButton.widget.state = 2
        okayButton.disabled = true
    else
        header.color = tes3ui.getPalette("header_color")
        okayButton.widget.state = 1
        okayButton.disabled = false
    end

end

local function clickedOkay()
    if data.currentBelief then 
        --if beliefsList[data.currentBelief].checkDisabled and beliefsList[data.currentBelief].checkDisabled() then return end
        local belief = beliefsList[data.currentBelief]
        if belief.doOnce then
            belief.doOnce(data)
        end

        if belief.callback then
            belief.callback(data)
        end

        
    end
    tes3ui.findMenu(perksMenuID):destroy()
    tes3ui.leaveMenuMode()
    updateBFStat()
end


local function createPerkMenu()
    if not modReady() then return end
    local perksMenu = tes3ui.createMenu{id = perksMenuID, fixedFrame = true}
    local outerBlock = perksMenu:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.autoHeight = true
    outerBlock.autoWidth = true

    --HEADING
    local title = outerBlock:createLabel{ id = tes3ui.registerID("perksheading"), text = "Select your belief:" }
    title.absolutePosAlignX = 0.5
    title.borderTop = 4
    title.borderBottom = 4

    local innerBlock = outerBlock:createBlock()
    innerBlock.height = 500
    innerBlock.autoWidth = true
    innerBlock.flowDirection = "left_to_right"

    --PERKS
    local perkListBlock = innerBlock:createVerticalScrollPane{ id = tes3ui.registerID("perkListBlock") }
    perkListBlock.layoutHeightFraction = 1.0
    perkListBlock.minWidth = 250
    perkListBlock.autoWidth = true
    perkListBlock.paddingAllSides = 4
    perkListBlock.borderRight = 6

    local sort_func = function(a, b)
        return string.lower(a.name) < string.lower(b.name)
    end
    
    local sortedList = {}
    for _, belief in pairs(beliefsList) do
        table.insert(sortedList, belief)
    end
    table.sort(sortedList, sort_func)

    --Default "No belief" button
    
    local noBFButton = perkListBlock:createTextSelect{ text = "-Select Belief-" }
    do
        noBFButton.color = tes3ui.getPalette("disabled_color")
        noBFButton.widget.idle = tes3ui.getPalette("disabled_color")
        noBFButton.autoHeight = true
        noBFButton.layoutWidthFraction = 1.0
        noBFButton.paddingAllSides = 2
        noBFButton.borderAllSides = 2

        noBFButton:register("mouseClick", function()
            data.currentBelief = nil
            local header = tes3ui.findMenu(perksMenuID):findChild(descriptionHeaderID)
            header.text = "No Belief Selected"
        
            local description = tes3ui.findMenu(perksMenuID):findChild(descriptionID)
            description.text = "Select a Belief from the list."
            description:updateLayout()
        end)
    end

    --Rest of the buttons
    for _, belief in pairs(sortedList) do
        local perkButton = perkListBlock:createTextSelect{ id = tes3ui.registerID("perkBlock"), text = belief.name }
        perkButton.autoHeight = true
        perkButton.layoutWidthFraction = 1.0
        perkButton.paddingAllSides = 2
        perkButton.borderAllSides = 2
        if belief.checkDisabled and belief.checkDisabled() then
            perkButton.color = tes3ui.getPalette("disabled_color")
            perkButton.widget.idle = tes3ui.getPalette("disabled_color")
        end
        perkButton:register("mouseClick", function() clickedPerk(belief) end )
        
        

    end
    --DESCRIPTION
    do
        local descriptionBlock = innerBlock:createThinBorder()
        descriptionBlock.layoutHeightFraction = 1.0
        descriptionBlock.width = 400
        descriptionBlock.borderRight = 10
        descriptionBlock.flowDirection = "top_to_bottom"
        descriptionBlock.paddingAllSides = 10

        local descriptionHeader = descriptionBlock:createLabel{ id = descriptionHeaderID, text = ""}
        descriptionHeader.color = tes3ui.getPalette("header_color")

        local descriptionText = descriptionBlock:createLabel{id = descriptionID, text = ""}
        descriptionText.wrapText = true
    end

    local buttonBlock = outerBlock:createBlock()
    buttonBlock.flowDirection = "left_to_right"
    buttonBlock.widthProportional = 1.0
    buttonBlock.autoHeight = true
    buttonBlock.childAlignX = 1.0


    --Randomise
    local randomButton = buttonBlock:createButton{ text = "Random"}
    randomButton.alignX = 1.0
    randomButton:register("mouseClick", function()
        local list = perkListBlock:getContentElement().children
        list[ math.random(#list) ]:triggerEvent("mouseClick")
    end)


    --OKAY
    okayButton = buttonBlock:createButton{ id = tes3ui.registerID("perkOkayButton"), text = tes3.findGMST(tes3.gmst.sOK).value }
    okayButton.alignX = 1.0
    okayButton:register("mouseClick", clickedOkay)

    perksMenu:updateLayout()

    tes3ui.enterMenuMode(perksMenuID)
    noBFButton:triggerEvent("mouseClick")
end



local charGen
local newGame
local function checkCharGen()
    if charGen.value == 10 then
        newGame = true
    elseif newGame and charGen.value == -1 then
        event.unregister("simulate", checkCharGen)
        timer.start{
            type = timer.simulate,
            duration = 0.4,
            callback = createPerkMenu
        }
    end
end



local function loaded()
    newGame = false

    --prepare data
    tes3.player.data.mtrBeliefs = tes3.player.data.mtrBeliefs or {}
    data = tes3.player.data.mtrBeliefs
    --initialise existing belief
    local belief = beliefsList[data.currentBelief]
    if belief and belief.callback then
        belief.callback(data)
    end

    --Check for chargen
    charGen = tes3.findGlobal("CharGenState")
    event.unregister("simulate", checkCharGen)
    event.register("simulate", checkCharGen)
    updateBFStat()
    
end

event.register("loaded", loaded )

---------------------------------------
---MCM
---------------------------------------


local function registerMCM()
    local sideBarDefault = (
        "Welcome to MTR-ByTheDivines! This mod adds many character beliefs that can be selected after character generation. Unfortunately it's very lacklustre since I lack ability to create some interesting effect like Azura giving buffs only during Dawn and Dusk or Arkay preventing player from casting conjuration spells. At least it can be used for role-playing purpose. Role-playing is also the reason why there are little restrictions in worship. You can be Hist worshipping Orc for what it's worth.\n\nPS. Getting effects from Dagoth Ur requires extra steps and the item you got to be dropped first."
    )

    local function addSideBar(component)
        component.sidebar:createInfo{ text = sideBarDefault}
        component.sidebar:createHyperLink{
            text = "Made by MTR",
            exec = "start https://www.nexusmods.com/users/88247468?tab=user+files",
            postCreate = (
                function(self)
                    self.elements.outerContainer.borderAllSides = self.indent
                    self.elements.outerContainer.alignY = 1.0
                    self.elements.outerContainer.layoutHeightFraction = 1.0
                    self.elements.info.layoutOriginFractionX = 0.5
                end
            ),
        }
		
		component.sidebar:createHyperLink{
            text = "Thanks to Merlord for Merlord's Character Backgrounds from which I have borrowed 95% of the code :)",
            exec = "start https://www.nexusmods.com/morrowind/mods/46795",
            postCreate = (
                function(self)
                    self.elements.outerContainer.borderAllSides = self.indent
                    self.elements.outerContainer.alignY = 1.0
                    self.elements.outerContainer.layoutHeightFraction = 1.0
                    self.elements.info.layoutOriginFractionX = 0.5
                end
            ),
        }

    end
	


    local template = mwse.mcm.createTemplate("MTR-ByTheDivines")
    template:saveOnClose(configPath, config)

    local page = template:createSideBarPage()
    addSideBar(page)

    page:createOnOffButton{
        label = "Enable Character Beliefs",
        variable = mwse.mcm.createTableVariable{
            id = "enableBeliefs", 
            table = config
        },
        description = "Turn this mod on or off."
    }

    page:createButton {
        buttonText = "Activate Beliefs Menu",
        description = "Manually trigger the Character Beliefs menu. Be warned, activating this on an existing character may have unintended side effects!",
        inGameOnly = true,
        callback = function()
            timer.delayOneFrame(function()
                createPerkMenu()
            end)
        end
    }

    template:register()
end

event.register("modConfigReady", registerMCM)
