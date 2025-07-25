local compat = require("SedrynTyros.ORLL.compat")
local config = require("SedrynTyros.ORLL.config")
local health = require("SedrynTyros.ORLL.health")
local log = require("SedrynTyros.ORLL.log")

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
    [3] = "wilpower", --this typo of 'wilpower' is intentional and matches the file name within morrowind.esm
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
end

---Builds and renders the custom level-up UI, replacing the vanilla one.
---@param element tes3uiElement UI element passed through the uiActivated event payload
---@param nextLevel number The new level achieved by the player
this.build = function (element, nextLevel)
    local mp = tes3.mobilePlayer
    local state = {
        virtues = config.virtuesPerLevel
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
            local baseHealth
            local data = tes3.player.data.ORLL or {}
            local initialStrength = data.initialStrength or tes3.mobilePlayer.strength.base
            if not data.initialStrength then
                log:warn("initialStrength missing in ORLL data during menu build. Health projection may be inaccurate.")
            end
            local endurance = tes3.mobilePlayer.endurance.base

            if config.retroHealth then
                baseHealth = health.previewRetroactive(nextLevel, initialStrength, endurance)
            else
                baseHealth = health.previewVanilla(tes3.mobilePlayer.health.base, endurance)
            end

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

            local healthValue
            local data = tes3.player.data.ORLL or {}
            local initialStrength = data.initialStrength or myAttributes[1]
            if not data.initialStrength then
                log:warn("initialStrength missing in ORLL data during updateBars. Health projection may be inaccurate.")
            end
            local endurance = myAttributes[6]

            if config.retroHealth then
                healthValue = health.previewRetroactive(nextLevel, initialStrength, endurance)
            else
                healthValue = health.previewVanilla(tes3.mobilePlayer.health.base, endurance)
            end

            log:debug("Preview health: %.1f | STR: %d | END: %d | Level: %d", healthValue, initialStrength, endurance, nextLevel)

            healthBar.widget.max = healthValue
            healthBar.widget.current = healthValue

            local magicValue = myAttributes[2] * tes3.mobilePlayer.magickaMultiplier.current
            magicBar.widget.max = magicValue
            magicBar.widget.current = magicValue

            local fatigueValue = myAttributes[1] + myAttributes[3] + myAttributes[4] + myAttributes[6]
            fatigueBar.widget.max = fatigueValue
            fatigueBar.widget.current = fatigueValue

            -- Force visual update for fillbars
            healthBar.parent:updateLayout()
            magicBar.parent:updateLayout()
            fatigueBar.parent:updateLayout()

            -- Debug log for development
            log:debug("Updated Health Bar: %.1f / %.1f", healthBar.widget.current, healthBar.widget.max)
            log:debug("Updated Magic Bar: %.1f / %.1f", magicBar.widget.current, magicBar.widget.max)
            log:debug("Updated Fatigue Bar: %.1f / %.1f", fatigueBar.widget.current, fatigueBar.widget.max)
        end

        -- Construct player attribute display
        pageLeft:createLabel{text = ""}  -- empty line for spacing
        local virtuesLabel = pageLeft:createLabel{text = "Virtues remaining: " .. state.virtues}
        virtuesLabel.color = tes3ui.getPalette("header_color")
        virtuesLabel.borderBottom = 4

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

        local function countAllocatedAttributes()
            local count = 0
            for i = 1, 8 do
                if atr[i].pointsSpent > 0 then
                     count = count + 1
                end
            end
           return count
        end

        local function updateColors(i)
            local spent = atr[i].pointsSpent
            local base = atr[i].base + spent
            local max = config.maxPointsPerAttribute
            local activeCount = countAllocatedAttributes()
            local isLuck = (i == 8)
            local luckRestricted = isLuck and config.restrictLuckToOne and spent >= 1

            if spent > 0 then
                if (max > 0 and spent >= max) or base >= config.attributeLvlCap or luckRestricted then
                    atr[i].label.color = tes3ui.getPalette("active_color")   -- Blue
                    atr[i].value.color = tes3ui.getPalette("active_color")
                else
                    atr[i].label.color = tes3ui.getPalette("fatigue_color") -- Green
                    atr[i].value.color = tes3ui.getPalette("fatigue_color")
                end
            else
                if activeCount >= 3 then
                    atr[i].label.color = tes3ui.getPalette("negative_color") -- Red
                    atr[i].value.color = tes3ui.getPalette("negative_color")
                else
                    atr[i].label.color = tes3ui.getPalette("normal_color")   -- Default
                    atr[i].value.color = tes3ui.getPalette("normal_color")
                end
            end
        end

        local function updateTableText(i)
            atr[i].value.text = tostring(atr[i].base + atr[i].pointsSpent)
            updateColors(i)
        end

        local function modButtonValue(i, delta)
            local cost = (i == 8) and 4 or 1
            state.virtues = state.virtues - delta * cost
            atr[i].pointsSpent = atr[i].pointsSpent + delta
        end

        local function disableButton(params)
            if params.index then
                local i = params.index
                atr[i][params.type].disabled = true
                atr[i][params.type].widget.state = tes3.uiState.disabled
            else
                for _, data in pairs(atr) do
                    data[params.type].disabled = true
                    data[params.type].widget.state = tes3.uiState.disabled
                end
            end
        end

        local function enableButton(params)
            if params.index then
                local i = params.index
                atr[i][params.type].disabled = false
                atr[i][params.type].widget.state = tes3.uiState.normal
            else
                for _, data in pairs(atr) do
                    data[params.type].disabled = false
                    data[params.type].widget.state = tes3.uiState.normal
                end
            end
        end

        local function updatePlusButtons()
            for i = 1, 8 do
                local isLuck = (i == 8)
                local spent = atr[i].pointsSpent
                local base = atr[i].base + spent
                local cost = isLuck and 4 or 1
                local canAfford = state.virtues >= cost
                local activeTotal = countAllocatedAttributes()

                local maxReached = config.maxPointsPerAttribute > 0 and spent >= config.maxPointsPerAttribute
                local atCap = base >= config.attributeLvlCap
                local limit3Reached = spent == 0 and activeTotal >= 3
                local outOfVirtues = state.virtues == 0

                local disable = maxReached or atCap

                --Special handling for Luck
                if isLuck then
                    if spent == 0 then
                        -- ❌ Lock if 3 others picked or no Virtues left
                        if activeTotal >= 3 or state.virtues == 0 then
                            disable = true
                        end

                        -- ✅ Keep Luck clickable for feedback when < 4 points
                        if activeTotal < 3 and state.virtues > 0 and state.virtues < 4 then
                            disable = false
                        end
                    end

                    -- Allow Luck to remain clickable when restriction is hit
                    if config.restrictLuckToOne and spent >= 1 then
                        disable = false
                    end
					
					-- 🔒 Final guard. Always disable Luck if Virtues Remaining is 0
                    if state.virtues == 0 then
                        disable = true
                    end
                else
                    -- Normal attributes: enforce 3-pick limit and affordability
                    disable = disable or limit3Reached or not canAfford
                end

                if disable then
                    disableButton{index = i, type = "button_plus"}
                else
                    enableButton{index = i, type = "button_plus"}
                end
            end
        end

        for i, a in pairs(tes3.mobilePlayer.attributes) do
            local name = tes3.getAttributeName(i - 1)
            local function onHoverAttribute()
                --  TODO: Add icon to tooltip (Morrowind.esm/icon/k) <-- comment left by chantox for future SAD mod work
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
                    local noVirtues = (state.virtues == 0)
                    modButtonValue(i, -1)
                    updateTableText(i)

                    if atr[i].pointsSpent == 0 then
                        disableButton{index = i, type = "button_minus"}
                    end

                    local max = config.maxPointsPerAttribute
                    local base = atr[i].base + atr[i].pointsSpent

                    if noVirtues then
                        for j, data in ipairs(atr) do
                            local cost = (j == 8) and 4 or 1
                            if (max == 0 or max > data.pointsSpent) and state.virtues >= cost then
                                enableButton{index = j, type = "button_plus"}
                            end
                        end
                    end
                    virtuesLabel.text = "Virtues remaining: " .. state.virtues
                    updateBars(atr)
                    attributeDisplay:updateLayout()
                    for j = 1, 8 do
                        updateColors(j)
                    end
                    updatePlusButtons()
                end
            )
            atr[i].button_plus:register("mouseClick",
                function ()
                    if countAllocatedAttributes() >= 3 and atr[i].pointsSpent == 0 then
                        return
                    end

                    if i == 8 and config.restrictLuckToOne and atr[i].pointsSpent >= 1 then
                        tes3.messageBox("You may only raise Luck by 1 point per level-up.")
                        return
                    end

                    local noVirtues = (atr[i].pointsSpent == 0)
                    local cost = (i == 8) and 4 or 1
                    if state.virtues < cost then
                        if i == 8 and state.virtues > 0 then
                            tes3.messageBox("Luck increases costs 4 Virtues per point.")
                        end
                        return
                    end
                    modButtonValue(i, 1)
                    updateTableText(i)

                    if noVirtues then
                        enableButton{index = i, type = "button_minus"}
                    end
                    virtuesLabel.text = "Virtues remaining: " .. state.virtues
                    updateBars(atr)
                    attributeDisplay:updateLayout()
                    for j = 1, 8 do
                        updateColors(j)
                    end
                    updatePlusButtons()
                end
            )
        end

        -- Second pass: update all colors after full setup
        for i = 1, 8 do
            updateColors(i)
        end
        updatePlusButtons()

    local pageRight = midsection:createBlock{}
    pageRight.flowDirection = "top_to_bottom"
    pageRight.autoHeight = true
    pageRight.autoWidth = true
    pageRight.childAlignX = 0.5
    pageRight.childAlignY = 0
    pageRight.paddingAllSides = 5
        local imageFrame = pageRight:createThinBorder{id = "ORLL_ImageBlock"}
        imageFrame.paddingAllSides = 4
        imageFrame.width = 0.85 * 256
        imageFrame.height = 0.85 * 128
        if not compat.classImages then
            local image = imageFrame:createImage{path = getPlayerClassImagePath()}
            image.width = 0.85 * 256
            image.height = 0.85 * 128
            image.scaleMode = true
        end

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
        local virtuesLeft = state.virtues
        if virtuesLeft == 0 then
           return true
        end

        local max = config.maxPointsPerAttribute
        local activeCount = 0
        for i = 1, 8 do
            if atr[i].pointsSpent > 0 then
                activeCount = activeCount + 1
            end
        end

        for i = 1, 8 do
            local cost = (i == 8) and 4 or 1
            local base = atr[i].base + atr[i].pointsSpent
            local atMax = max > 0 and atr[i].pointsSpent >= max
            local atCap = base >= config.attributeLvlCap
            local alreadyPicked = atr[i].pointsSpent > 0
            local newPickLockedOut = (not alreadyPicked) and (activeCount >= 3)
            local luckRestricted = (i == 8 and config.restrictLuckToOne and atr[i].pointsSpent >= 1)

            if not atMax and not atCap and not newPickLockedOut and cost <= virtuesLeft and not luckRestricted then
                return false -- a valid target exists
            end
        end

        return true -- no valid moves; allow level-up
    end

    local function onOk()
        if not levelUpDone() then
            tes3.messageBox("You have valid Virtue allocations available.")
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
        log:info("Level-up complete: Level %d applied", nextLevel)
        event.trigger(tes3.event.levelUp, {level = nextLevel})
        require("SedrynTyros.ORLL.display").update()
    end

    -- Set up 'Ok' button
    local buttonBlock = frame:createBlock{}
    buttonBlock.widthProportional = 1.0
    buttonBlock.autoHeight = true
    buttonBlock.childAlignX = 1.0

    local buttonOk = buttonBlock:createButton{
        id = tes3ui.registerID("ORLL:button_ok"),
        text = tostring(tes3.findGMST("sOK").value)
    }
    buttonOk:register(tes3.uiEvent.mouseClick, onOk)

    -- Display our menu
    frame:updateLayout()
end

return this
