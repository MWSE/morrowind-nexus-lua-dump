local tables=require('DS.DnDSeries.Class.Base.Tables')
local featsMenuId = tes3ui.registerID("featMenu")
local descriptionId = tes3ui.registerID("featDescriptionText")
local descriptionHeaderId = tes3ui.registerID("featDescriptionHeaderText")
local data = {}
local okayButton
local function clickedFeat(feats)
    data.currentFeat = feats.id
    local header = tes3ui.findMenu(featsMenuId):findChild(descriptionHeaderId)
    header.text = feats.name
    local description = tes3ui.findMenu(featsMenuId):findChild(descriptionId)
    description.text = feats.description
    description:updateLayout()
    if feats then
        okayButton.widget.state = 1
        okayButton.disabled = false
    end
end
local function clickedOkay()
local learnedFeats = tes3.player.data.DnDSeries.LearnedFeats or {}
    if data.currentFeat then
     for _, data1 in ipairs(tables.LearnableFeats) do
         if data.currentFeat == data1.id then
          table.insert(learnedFeats, data1.id)
          if data1.doOnce then
            data1.doOnce(data1)
          end
          if data1.callback then
            data1.callback(data1)
          end
          tes3.player.data.DnDSeries.LearnedFeats = learnedFeats
          tables.removeFromTables(data.currentFeat)
         end
     end
    end
    tes3ui.findMenu(featsMenuId):destroy()
    tes3ui.leaveMenuMode()
end
local this = {}
function this.createFeatsMenu()
    local LearnableFeats = tables.LearnableFeats
    local featsMenu = tes3ui.createMenu{id = featsMenuId, fixedFrame = true}
    local outerBlock = featsMenu:createBlock()
    outerBlock.flowDirection = "top_to_bottom"
    outerBlock.autoHeight = true
    outerBlock.autoWidth = true
    --HEADING
    local title = outerBlock:createLabel{ id = tes3ui.registerID("featsheading"), text = "Select your feat:" }
    title.absolutePosAlignX = 0.5
    title.borderTop = 4
    title.borderBottom = 4
    local innerBlock = outerBlock:createBlock()
    innerBlock.height = 500
    innerBlock.autoWidth = true
    innerBlock.flowDirection = "left_to_right"
    --feats
    local featListBlock = innerBlock:createVerticalScrollPane{ id = tes3ui.registerID("featListBlock") }
    featListBlock.layoutHeightFraction = 1.0
    featListBlock.minWidth = 250
    featListBlock.autoWidth = true
    featListBlock.paddingAllSides = 4
    featListBlock.borderRight = 6
    --Default "No belief" button
    local noFTButton = featListBlock:createTextSelect{ text = "-Select Feat-" }
    do
        noFTButton.color = tes3ui.getPalette("disabled_color")
        noFTButton.widget.idle = tes3ui.getPalette("disabled_color")
        noFTButton.autoHeight = true
        noFTButton.layoutWidthFraction = 1.0
        noFTButton.paddingAllSides = 2
        noFTButton.borderAllSides = 2
        noFTButton:register("mouseClick", function()
            data.currentFeat = nil
            local header = tes3ui.findMenu(featsMenuId):findChild(descriptionHeaderId)
            header.text = "No feat Selected"
            local description = tes3ui.findMenu(featsMenuId):findChild(descriptionId)
            description.text = "Select a feat from the list."
            okayButton.widget.state = 2
            okayButton.disabled = true
            description:updateLayout()
        end)
    end
    --Rest of the buttons
    for _, feats in pairs(LearnableFeats) do
        local featButton = featListBlock:createTextSelect{ id = tes3ui.registerID("featBlock"), text = feats.name }
        featButton.autoHeight = true
        featButton.layoutWidthFraction = 1.0
        featButton.paddingAllSides = 2
        featButton.borderAllSides = 2
        featButton:register("mouseClick", function() clickedFeat(feats) end )
    end
    --DESCRIPTION
    do
        local descriptionBlock = innerBlock:createThinBorder()
        descriptionBlock.layoutHeightFraction = 1.0
        descriptionBlock.width = 400
        descriptionBlock.borderRight = 10
        descriptionBlock.flowDirection = "top_to_bottom"
        descriptionBlock.paddingAllSides = 10

        local descriptionHeader = descriptionBlock:createLabel{ id = descriptionHeaderId, text = ""}
        descriptionHeader.color = tes3ui.getPalette("header_color")

        local descriptionText = descriptionBlock:createLabel{id = descriptionId, text = ""}
        descriptionText.wrapText = true
    end
    local buttonBlock = outerBlock:createBlock()
    buttonBlock.flowDirection = "left_to_right"
    buttonBlock.widthProportional = 1.0
    buttonBlock.autoHeight = true
    buttonBlock.childAlignX = 1.0
    --OKAY
    okayButton = buttonBlock:createButton{ id = tes3ui.registerID("featOkayButton"), 
                                           text = tes3.findGMST(tes3.gmst.sOK).value }
    okayButton.alignX = 1.0
    okayButton:register("mouseClick", clickedOkay)
    featsMenu:updateLayout()
    tes3ui.enterMenuMode(featsMenuId)
    noFTButton:triggerEvent("mouseClick")
end
return this