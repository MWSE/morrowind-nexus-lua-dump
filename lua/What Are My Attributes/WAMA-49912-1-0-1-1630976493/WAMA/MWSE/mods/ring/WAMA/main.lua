local function displayAttributes(e)
    local MenuRaceSex = e.element
    local raceID = "Dark Elf"
    local raceList = MenuRaceSex:findChild(
        tes3ui.registerID("MenuRaceSex_RaceList")
    ):getContentElement().children
    local attributes = {
        tes3.findGMST(tes3.gmst.sAttributeStrength).value,
        tes3.findGMST(tes3.gmst.sAttributeIntelligence).value,
        tes3.findGMST(tes3.gmst.sAttributeWillpower).value,
        tes3.findGMST(tes3.gmst.sAttributeAgility).value,
        tes3.findGMST(tes3.gmst.sAttributeSpeed).value,
        tes3.findGMST(tes3.gmst.sAttributeEndurance).value,
        tes3.findGMST(tes3.gmst.sAttributePersonality).value,
        tes3.findGMST(tes3.gmst.sAttributeLuck).value
    }
    local attributeIcons = {
        "Attribute_Strength.dds",
        "Attribute_Int.dds",
        "Attribute_Wilpower.dds",
        "Attribute_Agility.dds",
        "Attribute_Speed.dds",
        "Attribute_Endurance.dds",
        "Attribute_Personality.dds",
        "Attribute_Luck.dds"
    }
    local attributeValueBlocks = {}
    local isFemale = false
    local races = tes3.dataHandler.nonDynamicData.races

    MenuRaceSex.absolutePosAlignX = 0.577
    MenuRaceSex.absolutePosAlignY = 0.474
    MenuRaceSex:findChild("MenuRaceSex_Skills").parent.autoWidth = true

    local attributesBlock = MenuRaceSex:findChild(
        "MenuRaceSex_Skills"
    ).parent:createBlock({
        id = tes3ui.registerID("WAMA:attributesBlock"),
        width = 184
    })
        attributesBlock.flowDirection = "top_to_bottom"
        attributesBlock.autoHeight = true
        attributesBlock.width = 160
        attributesBlock.paddingLeft = 8
        local attributesLabel = attributesBlock:createLabel(
            {
                id = tes3ui.registerID("WAMA:labelAttributes"),
                text = "Attributes"
            }
        )
            attributesLabel.color = {1,1,1,1}
        for i=1, 8, 1 do

            local attributeBlock = attributesBlock:createBlock()
                attributeBlock.autoHeight = true
                attributeBlock.autoWidth = true
                attributeBlock.widthProportional = 1
                attributeBlock:createLabel(
                    {
                        text = attributes[i]
                    }
                ):register("help", function (attributeHelpEvent)
                    local tooltip = tes3ui.createTooltipMenu()
                    tooltip.width = 400
                    tooltip.autoHeight = true
                    tooltip.flowDirection = "top_to_bottom"
                    tooltip.childAlignX = 0.0
                    local tooltipTitle = tooltip:createBlock()
                    tooltipTitle.widthProportional = 1.0
                    tooltipTitle.autoHeight = true
                    tooltipTitle.justifyText = "left"
                    tooltipTitle.wrapText = true
                    tooltipTitle.flowDirection = "left_to_right"
                    local tooltipIcon = tooltipTitle:createImage({path="Icons\\k\\" .. attributeIcons[i]})
                    tooltipIcon.justifyText = "left"
                    local tooltipTitleLabel = tooltipTitle:createLabel({text=attributes[i]})
                    tooltipTitleLabel.justifyText = "left"
                    local tooltipDesc = tooltip:createBlock()
                    tooltipDesc.width = 400
                    tooltipDesc.autoHeight = true
                    tooltipDesc.wrapText = true
                    tooltipDesc.justifyText = "left"
                    tooltipDesc:createLabel({text=tes3.findGMST(939 + i).value})
                end)
                attributeValueBlocks[i] = attributeBlock:createLabel({
                    text = "50"
                })
                attributeValueBlocks[i].absolutePosAlignX = 1
        end

    -- Race flavor text code goes here vvvvv
    MenuRaceSex:findChild(tes3ui.registerID("MenuRaceSex_text")).visible = false
    local secondRow = MenuRaceSex:findChild("MenuRaceSex_Skills").parent.parent:createBlock()
    secondRow.height = 156
    secondRow.autoWidth = true
    local specialsBlock = secondRow:createBlock({})
    specialsBlock.autoHeight = true
    specialsBlock.flowDirection = "top_to_bottom"
    specialsBlock.borderAllSides = 4
    specialsBlock.width = 486
    specialsBlock.height = 156
    local specialsLabel = specialsBlock:createLabel({
        text = "Specials"
    })
    specialsLabel.color = {1,1,1,1}
    local specialsList = {}
    for i=1, 8, 1 do
        specialsList[i] = specialsBlock:createTextSelect({})
        specialsList[i].wrapText = true
        specialsList[i].autoWidth = true
        specialsList[i].autoHeight = true
        specialsList[i].visible = false
        specialsList[i]:register("help", function (e2)
            MenuRaceSex:findChild(tes3ui.registerID("MenuRaceSex_text")).children[i+1]:triggerEvent("help")
        end)
    end
    for i, ability in pairs(tes3.dataHandler.nonDynamicData.races[2].abilities.iterator) do
        specialsList[i].text = ability.name
        specialsList[i].visible = true
    end
    local descriptionBlock = secondRow:createThinBorder({})
    descriptionBlock.autoHeight = true
    descriptionBlock.width = 320
    descriptionBlock.borderLeft = 5
    descriptionBlock.flowDirection = "top_to_bottom"
    descriptionBlock.absolutePosAlignX = 0.97
    local descriptionLabel = descriptionBlock:createLabel({
        text = "Description"
    })
    descriptionLabel.color = {1,1,1,1}
    descriptionLabel.autoHeight = true
    descriptionLabel.autoWidth = true
    descriptionLabel.absolutePosAlignX = 0.46
    local descriptionSlider = descriptionBlock:createVerticalScrollPane({
        id = tes3ui.registerID("WAMA:descriptionSlider")
    })
    descriptionSlider.widthProportional = 0
    descriptionSlider.heightProportional = 0
    descriptionSlider.width = 321
    descriptionSlider.height = 134
    local descriptionValue = descriptionSlider:createLabel({
        text = tes3.dataHandler.nonDynamicData.races[2].description
    })
    descriptionValue.widthProportional = 1
    descriptionValue.wrapText = true

    -- Data handling
    local currentRaceName=tes3.dataHandler.nonDynamicData.races[2].name
    local function updateAttributes(e2)
        if e2.source.text ~= "" then currentRaceName = e2.source.text end
        for id, raceObject in pairs(races) do
            if raceObject.name == currentRaceName then
                if isFemale then
                    for i,v in pairs(raceObject.baseAttributes) do
                        attributeValueBlocks[i].text = v.female
                    end
                else
                    for i,v in pairs(raceObject.baseAttributes) do
                        attributeValueBlocks[i].text = v.male
                    end
                end
                for i=1,8,1 do
                    specialsList[i].visible = false
                end
                for i, ability in pairs(raceObject.abilities.iterator) do
                    specialsList[i].visible = true
                    specialsList[i].text = ability.name
                end
                if descriptionValue.text ~= raceObject.description then
                    descriptionSlider.widget.positionY = 0
                    descriptionValue.text = raceObject.description
                end
            end
        end
        if e2.source.color ~= "init" then e2.source:forwardEvent(e2) end
    end

    local function updateSex(e2)
        isFemale = not isFemale
        updateAttributes(e2)
    end

    MenuRaceSex:findChild(
        "MenuRaceSex_ChangeSexbuttonBack"
    ):register("mouseClick", updateSex)
    MenuRaceSex:findChild(
        "MenuRaceSex_ChangeSexbuttonForward"
    ):register("mouseClick", updateSex)
    for k in pairs(raceList) do
        for x in pairs(raceList[k].children) do
            raceList[k].children[x]:register("mouseClick", updateAttributes)
        end
    end
    updateAttributes({ source = { text = currentRaceName, color = "init" }})
end
event.register("uiActivated", displayAttributes, {filter = "MenuRaceSex"})
event.register("initialized", function () mwse.log("[WAMA] Initialized") end)