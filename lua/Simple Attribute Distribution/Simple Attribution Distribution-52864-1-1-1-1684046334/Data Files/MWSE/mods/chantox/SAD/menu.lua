local config = require("chantox.SAD.config")
local health = require("chantox.SAD.health")

local this = {}

---Set default table value
---@param t table
---@param d any
local function setDefault (t, d)
	local mt = {__index = function () return d end}
	setmetatable(t, mt)
end

local levelUpMessage
if (config.altLevelMsgs) then
    levelUpMessage = {
        [2] = "You realize that all your life you have been coasting along as if you were in a dream. Suddenly, facing the trials of the last few days, you have come alive.",
        [3] = "You realize that you are catching on to the secret of success. It's just a matter of concentration.",
        [4] = "It's all suddenly obvious to you. You just have to concentrate. All the energy and time you've wasted -- it's a sin. But without the experience you've gained, taking risks, taking responsibility for failure, how could you have understood?",
        [5] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
        [6] = "You sense yourself more aware, more open to new ideas. You've learned a lot about Morrowind. It's hard to believe how ignorant you were -- but now you have so much more to learn.",
        [7] = "You resolve to continue pushing yourself. Perhaps there's more to you than you thought.",
        [8] = "The secret does seem to be hard work, yes, but it's also a kind of blind passion, an inspiration.",
        [9] = "So that's how it works. You plod along, putting one foot before the other, look up, and suddenly, there you are. Right where you wanted to be all along.",
        [10] = "You woke today with a new sense of purpose. You're no longer afraid of failure. Failure is just an opportunity to learn something new.",
        [11] = "Being smart doesn't hurt. And a little luck now and then is nice. But the key is patience and hard work. And when it pays off, it's SWEET!",
        [12] = "You can't believe how easy it is. You just have to go... a little crazy. And then, suddenly, it all makes sense, and everything you do turns to gold.",
        [13] = "It's the most amazing thing. Yesterday it was hard, and today it is easy. Just a good night's sleep, and yesterday's mysteries are today's masteries.",
        [14] = "Today you wake up, full of energy and ideas, and you know, somehow, that overnight everything has changed. What a difference a day makes.",
        [15] = "Today you suddenly realized the life you've been living, the punishment your body has taken -- there are limits to what the body can do, and perhaps you have reached them. You've wondered what it's like to grow old. Well, now you know.",
        [16] = "You've been trying too hard, thinking too much. Relax. Trust your instincts. Just be yourself. Do the little things, and the big things take care of themselves.",
        [17] = "Life isn't over. You can still get smarter, or cleverer, or more experienced, or meaner -- but your body and soul just aren't going to get any younger.",
        [18] = "The challenge now is to stay at the peak as long as you can. You may be as strong today as any mortal who has ever walked the earth, but there's always someone younger, a new challenger.",
        [19] = "You're really good. Maybe the best. And that's why it's so hard to get better. But you just keep trying, because that's the way you are.",
        [20] = "You'll never be better than you are today. If you are lucky, by superhuman effort, you can avoid slipping backwards for a while. But sooner or later, you're going to lose a step, or drop a beat, or miss a detail -- and you'll be gone forever.",
    }
else
    levelUpMessage = {
        [2] = "You realize that all your life you have been coasting along as if you were in a dream. Suddenly, facing the trials of the last few days, you have come alive.",
        [3] = "You realize that you are catching on to the secret of success. It's just a matter of concentration.",
        [4] = "It's all suddenly obvious to you. You just have to concentrate. All the energy and time you've wasted -- it's a sin. But without the experience you've gained, taking risks, taking responsibility for failure, how could you have understood?",
        [5] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
        [6] = "You sense yourself more aware, more open to new ideas. You've learned a lot about Morrowind. It's hard to believe how ignorant you were -- but now you have so much more to learn.",
        [7] = "You resolve to continue pushing yourself. Perhaps there's more to you than you thought.",
        [8] = "The secret does seem to be hard work, yes, but it's also a kind of blind passion, an inspiration.",
        [9] = "Everything you do is just a bit easier, more instinctive, more satisfying. It is as though you had suddenly developed keen senses and instincts.",
        [10] = "You woke today with a new sense of purpose. You're no longer afraid of failure. Failure is just an opportunity to learn something new.",
        [11] = "Being smart doesn't hurt. And a little luck now and then is nice. But the key is patience and hard work. And when it pays off, it's SWEET!",
        [12] = "You can't believe how easy it is. You just have to go... a little crazy. And then, suddenly, it all makes sense, and everything you do turns to gold.",
        [13] = "It's the most amazing thing. Yesterday it was hard, and today it is easy. Just a good night's sleep, and yesterday's mysteries are today's masteries.",
        [14] = "Today you wake up, full of energy and ideas, and you know, somehow, that overnight everything has changed. What a difference a day makes.",
        [15] = "Today you suddenly realized the life you've been living, the punishment your body has taken -- there are limits to what the body can do, and perhaps you have reached them. You've wondered what it's like to grow old. Well, now you know.",
        [16] = "You've been trying too hard, thinking too much. Relax. Trust your instincts. Just be yourself. Do the little things, and the big things take care of themselves.",
        [17] = "Life isn't over. You can still get smarter, or cleverer, or more experienced, or meaner -- but your body and soul just aren't going to get any younger.",
        [18] = "The challenge now is to stay at the peak as long as you can. You may be as strong today as any mortal who has ever walked the earth, but there's always someone younger, a new challenger.",
        [19] = "You're really good. Maybe the best. And that's why it's so hard to get better. But you just keep trying, because that's the way you are.",
        [20] = "You'll never be better than you are today. If you are lucky, by superhuman effort, you can avoid slipping backwards for a while. But sooner or later, you're going to lose a step, or drop a beat, or miss a detail -- and you'll be gone forever.",
    }
end
setDefault(levelUpMessage, "The results of hard work and dedication always look like luck to saps. But you know you've earned every ounce of your success.")

---Gets the player's class image path.
---For custom classes, return the specialization's image instead.
local function getPlayerClassImagePath()
	local playerClass = tes3.player.object.class
	if tes3.getFileExists("textures\\levelup\\" .. string.lower(playerClass.name .. ".dds")) then
		return ("textures\\levelup\\" .. string.lower(playerClass.name .. ".dds"))
	elseif playerClass.specialization == tes3.specialization.magic then
		return "textures\\levelup\\mage.dds"
	elseif playerClass.specialization == tes3.specialization.stealth then
		return "textures\\levelup\\thief.dds"
	else
        return "textures\\levelup\\warrior.dds" 
	end
end

local attributeIconPathName = {
    [1] = "strength",
    [2] = "int",
    [3] = "wilpower",
    [4] = "agility",
    [5] = "speed",
    [6] = "endurance",
    [7] = "personality",
    [8] = "luck"
}

---Creates an abstract data table and a tes3uiElement to represent one of the player's statistics.
---@param table table The table where the data will be placed
---@param name string The display name of the attribute
---@param value number Base attribute value
---@param columns table Table of tes3uiElement; contains labelBlock, minusBlock, valueBlock, plusBlock columns
---@param onHover function Function invoked when hovering over the attribute name
this.createStat = function (table, name, value, columns, onHover)
    -- Initialize data
    table.base = value
    table.pointsSpent = 0

    -- Create stat label
    local labelBlock = columns.labelBlock:createBlock()
    labelBlock.autoWidth = true
    labelBlock.heightProportional = 1
    labelBlock.paddingRight = 10

    table.label = labelBlock:createLabel{text = name}
    table.label.absolutePosAlignY = 0.5
    table.label:register("help", onHover)

    -- Create "-" button
    local minusBlock = columns.minusBlock:createBlock()
    minusBlock.autoWidth = true
    minusBlock.heightProportional = 1

    table.button_minus = minusBlock:createButton()
    table.button_minus.text = "<"
    table.button_minus.disabled = true
    table.button_minus.widget.state = tes3.uiState.disabled

    -- Create current value label
    local valueBlock = columns.valueBlock:createBlock()
    valueBlock.autoWidth = true
    valueBlock.heightProportional = 1

    table.value = valueBlock:createLabel({text = tostring(table.base + table.pointsSpent)})
    table.value.absolutePosAlignY = 0.5

    -- Create "+" button
    local plusBlock = columns.plusBlock:createBlock()
    plusBlock.autoWidth = true
    plusBlock.heightProportional = 1

    table.button_plus = plusBlock:createButton()
    table.button_plus.text = ">"
    if table.base == config.attributeLvlCap then
        table.button_minus.disabled = true
        table.button_minus.widget.state = tes3.uiState.disabled
    end
end

---Builds the level up menu.
---@param element tes3uiElement UI element passed through the uiActivated event payload
---@param nextLevel number The new level achieved by the player
this.build = function (element, nextLevel)
    local mp = tes3.mobilePlayer
    local state = {
        points = config.pointsPerLevel
    }

    local iLevelupTotal = tes3.findGMST(tes3.gmst.iLevelupTotal).value

    element.text = "Level Up"
    local frame = element.children[2] --grabs the content section of the levelup menu
	frame:destroyChildren() --destroys the vanilla ui elements so that we can replace them with our own

    -- Set up frame settings
	frame.flowDirection = "top_to_bottom"
	frame.autoHeight = true
	frame.autoWidth = true
	frame.childAlignX = -1
	frame.paddingAllSides = 5

    local page = frame:createBlock{}
    page.flowDirection = "top_to_bottom"
    page.autoHeight = true
    page.autoWidth = true
    page.childAlignX = 0.5
    page.childAlignY = 0
    page.paddingAllSides = 5

    local caption = page:createLabel{text = tes3.findGMST("sLevelUpMenu1").value .. nextLevel}
    caption.color = tes3ui.getPalette("big_header_color")
    caption.widthProportional = 1
    caption.autoHeight = true
    caption.wrapText = true
    caption.justifyText = "center"

    local midsection = page:createBlock{}
    midsection.flowDirection = "left_to_right"
    midsection.autoWidth = true
    midsection.autoHeight = true

    local pageLeft = midsection:createBlock{}
    pageLeft.flowDirection = "top_to_bottom"
    pageLeft.autoHeight = true
    pageLeft.autoWidth = true
    pageLeft.childAlignX = 0
    pageLeft.childAlignY = 0
    pageLeft.paddingAllSides = 5
        -- Construct player statistic display
        local statBlock = pageLeft:createBlock()
        statBlock.autoWidth = true
        statBlock.autoHeight = true
        statBlock.flowDirection = "top_to_bottom"

        local healthBlock = statBlock:createBlock()
        healthBlock.autoWidth = true
        healthBlock.autoHeight = true
        healthBlock.flowDirection = "left_to_right"
        healthBlock.paddingBottom = 4
        healthBlock.childAlignX = -1
            local baseHealth = health.calcBase(tes3.mobilePlayer.strength.base,
                                               tes3.mobilePlayer.endurance.base,
                                               nextLevel)
            local healthBar = healthBlock:createFillBar{max = baseHealth, current = baseHealth}
            healthBar.widget.fillColor = tes3ui.getPalette("health_color")

        local magicBlock = statBlock:createBlock()
        magicBlock.autoWidth = true
        magicBlock.autoHeight = true
        magicBlock.flowDirection = "left_to_right"
        magicBlock.paddingBottom = 4
        magicBlock.childAlignX = -1
            local baseMagic = tes3.mobilePlayer.intelligence.base * tes3.mobilePlayer.magickaMultiplier.current
            local magicBar = magicBlock:createFillBar{max = baseMagic, current = baseMagic}
            magicBar.widget.fillColor = tes3ui.getPalette("magic_color")

        local fatigueBlock = statBlock:createBlock()
        fatigueBlock.autoWidth = true
        fatigueBlock.autoHeight = true
        fatigueBlock.flowDirection = "left_to_right"
        fatigueBlock.paddingBottom = 4
        fatigueBlock.childAlignX = -1
            local fatigueBar = fatigueBlock:createFillBar{max = tes3.mobilePlayer.fatigue.base,
                                                          current = tes3.mobilePlayer.fatigue.base}
            fatigueBar.widget.fillColor = tes3ui.getPalette("fatigue_color")

        local function updateBars(atr)
            local myAttributes = {}
            for i = 1, 8 do
                myAttributes[i] = atr[i].base + atr[i].pointsSpent
            end

            local healthValue = health.calcBase(myAttributes[1], myAttributes[6], nextLevel)
            healthBar.widget.max = healthValue
            healthBar.widget.current = healthValue

            local magicValue = myAttributes[2] * tes3.mobilePlayer.magickaMultiplier.current
            magicBar.widget.max = magicValue
            magicBar.widget.current = magicValue

            local fatigueValue = myAttributes[1] + myAttributes[3] + myAttributes[4] + myAttributes[6]
            fatigueBar.widget.max = fatigueValue
            fatigueBar.widget.current = fatigueValue
        end

        -- Construct player attribute display
        local attributeHeader = pageLeft:createLabel{text = "Attributes"}
        attributeHeader.color = tes3ui.getPalette("header_color")
        local pointsLabel = pageLeft:createLabel{text = "Points remaining: " .. state.points}
        pointsLabel.color = tes3ui.getPalette("header_color")
        pointsLabel.borderBottom = 4

        local attributeDisplay = pageLeft:createBlock{}
        attributeDisplay.flowDirection = "left_to_right"
        attributeDisplay.autoWidth = true
        attributeDisplay.height = 210
        attributeDisplay.paddingLeft = 20

        -- Create columns as separate blocks
        local attributeBlocks = {}
        attributeBlocks.labelBlock = attributeDisplay:createBlock{}
        attributeBlocks.labelBlock.flowDirection = "top_to_bottom"
        attributeBlocks.labelBlock.autoWidth = true
        attributeBlocks.labelBlock.heightProportional = 1

        attributeBlocks.minusBlock = attributeDisplay:createBlock{}
        attributeBlocks.minusBlock.flowDirection = "top_to_bottom"
        attributeBlocks.minusBlock.autoWidth = true
        attributeBlocks.minusBlock.heightProportional = 1

        attributeBlocks.valueBlock = attributeDisplay:createBlock{}
        attributeBlocks.valueBlock.flowDirection = "top_to_bottom"
        attributeBlocks.valueBlock.autoWidth = true
        attributeBlocks.valueBlock.heightProportional = 1

        attributeBlocks.plusBlock = attributeDisplay:createBlock{}
        attributeBlocks.plusBlock.flowDirection = "top_to_bottom"
        attributeBlocks.plusBlock.autoWidth = true
        attributeBlocks.plusBlock.heightProportional = 1

        local attributeDescriptions = {
            [1] = tes3.findGMST(tes3.gmst.sStrDesc).value,
            [2] = tes3.findGMST(tes3.gmst.sIntDesc).value,
            [3] = tes3.findGMST(tes3.gmst.sWilDesc).value,
            [4] = tes3.findGMST(tes3.gmst.sAgiDesc).value,
            [5] = tes3.findGMST(tes3.gmst.sSpdDesc).value,
            [6] = tes3.findGMST(tes3.gmst.sEndDesc).value,
            [7] = tes3.findGMST(tes3.gmst.sPerDesc).value,
            [8] = tes3.findGMST(tes3.gmst.sLucDesc).value
        }

        local atr = {}
        local function updateTableText(i)
            atr[i].value.text = tostring(atr[i].base + atr[i].pointsSpent)
            if (atr[i].pointsSpent > 0) then
                atr[i].value.color = tes3ui.getPalette('active_color')
            else
                atr[i].value.color = tes3ui.getPalette('normal_color')
            end
        end

        local function modButtonValue(i, delta)
            state.points = state.points - delta
            atr[i].pointsSpent = atr[i].pointsSpent + delta
        end

        local function disableMinus(i)
            atr[i].button_minus.disabled = true
            atr[i].button_minus.widget.state = tes3.uiState.disabled
        end

        local function enableMinus(i)
            atr[i].button_minus.disabled = false
            atr[i].button_minus.widget.state = tes3.uiState.normal
        end

        local function disablePlus()
            for _, data in pairs(atr) do
                data.button_plus.disabled = true
                data.button_plus.widget.state = tes3.uiState.disabled
            end
        end

        local function enablePlus()
            for _, data in pairs(atr) do
                data.button_plus.disabled = false
                data.button_plus.widget.state = tes3.uiState.normal
            end
        end

        for i, a in pairs(tes3.mobilePlayer.attributes) do
            local name = tes3.getAttributeName(i - 1)
            local function onHoverAttribute()
                --  TODO: Add icon to tooltip (Morrowind.esm/icon/k)
                local tooltip = tes3ui.createTooltipMenu()
                local ttipblock = tooltip:createBlock()
                ttipblock.flowDirection = "top_to_bottom"
                ttipblock.width = 440
                ttipblock.autoHeight = true
                ttipblock.paddingAllSides = 4

                local ttipLabelBlock = ttipblock:createBlock()
                ttipLabelBlock.flowDirection = "left_to_right"
                ttipLabelBlock.widthProportional = 1
                ttipLabelBlock.autoHeight = true
                ttipLabelBlock.borderBottom = 4
                ttipLabelBlock.childAlignY = 0.5

                local ttipImage = ttipLabelBlock:createImage{path = "icons\\k\\attribute_" .. attributeIconPathName[i] .. ".dds"}
                ttipImage.borderRight = 10

                local header = ttipLabelBlock:createLabel{text = name}
                header.color = tes3ui.getPalette("header_color")

                local descText = attributeDescriptions[i]
                local description = ttipblock:createLabel{text = tostring(descText)}
                description.wrapText = true
                description.autoHeight = true
            end

            atr[i] = {}
            this.createStat(atr[i], name, a.base, attributeBlocks, onHoverAttribute)

            --set up events for the '+' and '-' buttons
            atr[i].button_minus:register("mouseClick",
                function ()
                    local noPoints = (state.points == 0)
                    modButtonValue(i, -1)
                    updateTableText(i)
                    if (atr[i].pointsSpent == 0) then
                        disableMinus(i)
                    end
                    if noPoints then
                        enablePlus()
                    end
                    pointsLabel.text = "Points remaining: " .. state.points
                    updateBars(atr)
                    attributeDisplay:updateLayout()
                end
            )
            atr[i].button_plus:register("mouseClick",
                function ()
                    local noPoints = (atr[i].pointsSpent == 0)
                    modButtonValue(i, 1)
                    updateTableText(i)
                    if (state.points == 0) then
                        disablePlus()
                    end
                    if noPoints then
                        enableMinus(i)
                    end
                    pointsLabel.text = "Points remaining: " .. state.points
                    updateBars(atr)
                    attributeDisplay:updateLayout()
                end
            )
        end

    local pageRight = midsection:createBlock{}
    pageRight.flowDirection = "top_to_bottom"
    pageRight.autoHeight = true
    pageRight.autoWidth = true
    pageRight.childAlignX = 0.5
    pageRight.childAlignY = 0
    pageRight.paddingAllSides = 5
        local imageFrame = pageRight:createThinBorder{}
        imageFrame.paddingAllSides = 4
        imageFrame.autoWidth = true
        imageFrame.autoHeight = true

        local image = imageFrame:createImage{path = getPlayerClassImagePath()}
        image.imageScaleX = 0.8
        image.imageScaleY = 0.8

        local flavorTextBlock = pageRight:createBlock{}
        flavorTextBlock.widthProportional = 1
        flavorTextBlock.borderTop = 10
        flavorTextBlock.autoHeight = true

        local flavorText = flavorTextBlock:createLabel{text = levelUpMessage[nextLevel]}
        flavorText.widthProportional = 1
        flavorText.wrapText = true
        flavorText.autoHeight = true
        flavorText.justifyText = "center"

    local function levelUpDone()
        if state.points == 0 then
            return true
        end

        for i = 1, 8 do
            local base = atr[i].base + atr[i].pointsSpent
            if base < config.attributeLvlCap then
                return false
            end
        end
        return true
    end

    local function onOk()
        if not levelUpDone() then
            tes3.messageBox("You have attribute points pending allocation.")
            return
        end

        frame.visible = false
        tes3ui.leaveMenuMode()
        frame:getTopLevelMenu():destroy()

        tes3.player.baseObject.level = nextLevel

        tes3.mobilePlayer.levelUpProgress = math.max(0, tes3.mobilePlayer.levelUpProgress - iLevelupTotal)
        for i = 1, 8 do
            if atr[i].pointsSpent > 0 then
                local base = atr[i].base + atr[i].pointsSpent
                local dif = tes3.mobilePlayer.attributes[i].current - tes3.mobilePlayer.attributes[i].base

                tes3.setStatistic{
                    attribute = i - 1,
                    reference = tes3.player,
                    base = base
                }

                tes3.setStatistic{
                    attribute = i - 1,
                    reference = tes3.player,
                    current = base + dif
                }
            end
        end
        event.trigger(tes3.event.levelUp, {level = nextLevel})
    end

    -- Set up 'Ok' button
    local buttonBlock = frame:createBlock{}
    buttonBlock.widthProportional = 1.0
    buttonBlock.autoHeight = true
    buttonBlock.childAlignX = 1.0

    local buttonOk = buttonBlock:createButton{
        id = tes3ui.registerID("SAD:button_ok"),
        text = tostring(tes3.findGMST("sOK").value)
    }
    buttonOk:register(tes3.uiEvent.mouseClick, onOk)

    -- Display our menu
    frame:updateLayout()
end

return this
