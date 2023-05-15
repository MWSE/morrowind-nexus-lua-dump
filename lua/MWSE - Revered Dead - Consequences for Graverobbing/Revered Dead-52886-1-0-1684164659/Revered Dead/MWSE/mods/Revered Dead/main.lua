local strings = require("Revered Dead.strings")
local common = require("Revered Dead.common")
local config = require("Revered Dead.config")

-- Tomb item tagging stuff

local function tagDroppedItems(item) -- Prevent items left behind in tombs from being flagged.
    if item.reference.supportsLuaData then
        if not item.reference.data.reveredDead then
            common.assignGraveGoodData(item.reference, false, item.reference.object)
            common.log:debug(item.reference.id .. " dropped in tomb was untagged. Marking as NOT a grave good.") -- debug
        end
    end
end

---@param e leveledItemPickedEventData
local function handleLeveledItem(e)
    if e.spawner and e.pick then
        timer.delayOneFrame(function()
            common.handleContainerItems(e.spawner, false)
        end)
    end
end

--- @param e containerClosedEventData
local function refreshClosedContainer(e) -- Prevent items left behind in tomb containers from being flagged.
    common.handleContainerItems(e.reference, true)
end

local function checkInTomb()
    local playerCell = tes3.player.cell
    if playerCell.isInterior and playerCell.displayName:find("Ancestral Tomb") then
        tes3.addTopic({ topic = "grave goods" })
        event.register(tes3.event.itemDropped, tagDroppedItems)
        event.register(tes3.event.leveledItemPicked, handleLeveledItem)
        event.register(tes3.event.containerClosed, refreshClosedContainer)
        return true
    else
        event.unregister(tes3.event.itemDropped, tagDroppedItems)
        event.unregister(tes3.event.leveledItemPicked, handleLeveledItem)
        event.unregister(tes3.event.containerClosed, refreshClosedContainer)
        return false
    end
end

local function scanTombItems()
    local playerCell = tes3.player.cell
    local booltostring = ""
    if checkInTomb() then
        if config.warnOnTombEntry then
            tes3.messageBox("I just entered " .. playerCell.displayName .. ", a revered place...")
        end
        for ref in playerCell:iterateReferences({ tes3.objectType.alchemy, tes3.objectType.apparatus, tes3.objectType.armor, tes3.objectType.clothing, tes3.objectType.container, tes3.objectType.ingredient, tes3.objectType.lockpick, tes3.objectType.miscItem, tes3.objectType.probe, tes3.objectType.repairItem, tes3.objectType.weapon }) do -- Iterate over anything which might be or contain grave goods
            if ref.object.objectType == tes3.objectType.container then
                common.handleContainerItems(ref, false)
            else -- handle world items
                if ref.supportsLuaData == true then
                    common.log:debug("Assigning data to " .. ref.id .. ", grave goods in " .. playerCell.displayName)
                    common.assignGraveGoodData(ref, true, ref.object)
                else --debug
                    common.log:debug("Skipped " .. ref.id .. ", due to not supporting item data.") -- debug
                end
            end
        end
    end
end

-- Merchant exchange stuff

local function evaluateMerchant(merchant) -- merchant is tes3mobilenpc
    local merchantTrust = 30 -- Higher = stronger negative reaction to grave goods
    local merchantActor = merchant.object
    if merchant.objectType ~= tes3.objectType.mobileNPC then
        merchantTrust = 10 -- Default edge-cases, e.g. mudcrab merchant
    elseif merchantActor.class.id == "Smuggler" or (merchantActor.faction and (merchantActor.faction.id == "Thieves Guild" or merchantActor.faction.id == "Camonna Tong")) then
        merchantTrust = 0 -- Smugglers and fences
    elseif merchantActor.class.id == "Ordinator" or (merchantActor.faction and (merchantActor.faction.id == "Temple")) then
        merchantTrust = 70 -- Temple-affiliated merchants
    elseif merchantActor.faction and (merchantActor.faction.id == "Telvanni" or merchantActor.faction.id == "Redoran" or merchantActor.faction.id == "Hlaalu" or merchantActor.faction.id == "Ashlanders") then
        merchantTrust = 60 -- Great House or Ashlander Tribe-affiliated merchants
    elseif common.checkIsEmpire(merchantActor) then
        merchantTrust = 40 -- Directly Empire-affiliated merchants, trying to keep a good reputation.
    elseif merchantActor.race.id == "Dark Elf" then
        merchantTrust = 50 -- General Dunmer merchants
    else
        merchantTrust = 30 -- General outlander merchants.
    end
    common.log:debug("Merchant " .. merchantActor.id .. " evaluated with a trust rating of: " .. merchantTrust) -- debug
    return merchantTrust
end

local function evaluatePlayer(merchant)
    local responseSeverity = 0
    local playerActor = tes3.player.object
    local merchantActor = merchant.object

    if merchant.objectType == tes3.objectType.mobileNPC then
        if merchantActor.race.id == "Dark Elf" then
            if playerActor.race.id ~= "Dark Elf" then
                responseSeverity = responseSeverity + 10 -- Outlanders don't get benefit of the doubt with locals.
                common.log:debug("Player eval: +10 dunmer distrusts outlander")
            end
            if tes3.getFaction("Temple").playerRank >= 3 then
                if merchantActor.faction and (merchantActor.faction.id == "Ashlanders") then
                    responseSeverity = responseSeverity + 10 -- Ashlanders suspicious of temple officials.
                    common.log:debug("Player eval: +10 temple official trading with ashlander")
                else
                    responseSeverity = responseSeverity - 10 -- Otherwise, temple officials generally get the benefit of the doubt.
                    common.log:debug("Player eval: -10 temple official trading with dunmer")
                end
            end
            if not common.checkIsEmpire(merchantActor) then
                if tes3.getFaction("Imperial Cult").playerRank > 1 then
                    responseSeverity = responseSeverity + 10 -- Non-imperial-aligned Dunmer suspicious of Empire religious officials.
                    common.log:debug("Player eval: +10 imperial cultist trading with non-imperial dunmer")
                end
                if tes3.getFaction("Imperial Legion").playerRank > 1 then
                    responseSeverity = responseSeverity + 5 -- Non-imperial-aligned Dunmer slightly suspicious of Legion officials.
                    common.log:debug("Player eval: +5 imperial legion trading with non-imperial dunmer")
                end
            end
        end
        if playerActor.race.isBeast and not merchantActor.race.isBeast then
            responseSeverity = responseSeverity + 10 -- Beast races get some prejudice from everyone else.
            common.log:debug("Player eval: +10 general beast racism")
            if merchantActor.faction and (merchantActor.faction.id == "Twin Lamps") then
                responseSeverity = responseSeverity - 10 -- Negate that for dedicated abolitionists.
                common.log:debug("Player eval: -10 ...but was an abolitionist trader")
            end
        end
        if merchantActor.disposition < 40 then
            responseSeverity = responseSeverity + 5 -- Wary of somebody they don't like much.
            common.log:debug("Player eval: +5 cold relations")
            if merchantActor.disposition < 20 then
                responseSeverity = responseSeverity + 10 -- They hate you and you're up to something.
                common.log:debug("Player eval: +10 terrible relations")
            end
        end
        if merchantActor.disposition > 75 then
            responseSeverity = responseSeverity - 5 -- Making some exceptions for a friend.
            common.log:debug("Player eval: -5 good relations")
            if merchantActor.disposition > 95 then
                responseSeverity = responseSeverity - 10 -- Making even more exceptions for a close friend.
                common.log:debug("Player eval: -10 excellent relations")
            end
        end
        if playerActor.reputation > 50 then
            responseSeverity = responseSeverity - 10 -- Turning a blind eye for a public figure.
            common.log:debug("Player eval: -10 well-known person")
        elseif playerActor.reputation < 5 then
            responseSeverity = responseSeverity + 10 -- Suspicious of total unknown quantities.
            common.log:debug("Player eval: +10 total stranger")
        end
        if merchantActor.faction and tes3.getFaction(merchantActor.faction.id).playerRank >= 0 then
            responseSeverity = responseSeverity - 5 -- Mild benefit of the doubt for same faction.
            common.log:debug("Player eval: -5 same faction member")
        end
        if merchantActor.faction and (merchantActor.faction.id == "Redoran") and tes3.getJournalIndex{id="B5_RedoranHort"} >= 50  then
            responseSeverity = responseSeverity - 10 -- Redoran turning a blind eye for their hortator.
            common.log:debug("Player eval: -10 red hort")
        end
        if merchantActor.faction and (merchantActor.faction.id == "Hlaalu") and tes3.getJournalIndex{id="B6_HlaaluHort"} >= 50  then
                responseSeverity = responseSeverity - 10 -- Hlaalu turning a blind eye for their hortator.
                common.log:debug("Player eval: -10 hla hort")
        end
        if merchantActor.faction and (merchantActor.faction.id == "Telvanni") and tes3.getJournalIndex{id="B7_TelvanniHort"} >= 50  then
            responseSeverity = responseSeverity - 10 -- Telvanni turning a blind eye for their hortator.
            common.log:debug("Player eval: -10 tel hort")
        end
        if merchantActor.faction and (merchantActor.faction.playerRank == 9) then
            responseSeverity = responseSeverity - 10 -- General blind eye for own faction leaders.
            common.log:debug("Player eval: -10 merchant's faction leader")
        end
    else
        common.log:debug("Merchant is not a mobile actor, skipping advanced evaluation.")
    end
    common.log:debug("Player trustworthiness was evaluated with a final rating of: " .. responseSeverity)
    return responseSeverity
end

local function checkSellingGraveGoods(e)
    local merchant = tes3ui.getServiceActor()
    local graveGoods = common.checkIsGraveGoods(e.selling)
    local extremeGraveGoods = common.checkIsExtremeGraveGoods(e.selling)
    local merchantRating = evaluateMerchant(merchant)
    local playerTrust = evaluatePlayer(merchant)
    local offendingGood = "item"

    if graveGoods then
        common.log:debug("Detected grave goods in current sales offer with" .. merchant.object.id)
        local reactionSeverity = merchantRating + playerTrust
        local messageString
        local turnOverResponse

        if extremeGraveGoods and merchantRating > 10 then
            if config.mortalRemainsForbidden and checkBlacklisted(extremeGraveGoods) then
                e.success = false
                messageString = table.choice(strings.saleReactionMortalRemains)
            else
                reactionSeverity = reactionSeverity + 20
            end
            offendingGood = extremeGraveGoods.name
            common.log:debug("Barter offer contained extremely offensive goods. Increasing reaction severity.")
        else
            offendingGood = graveGoods.name
        end
        common.log:debug("Final reaction rating for this merchant is:" .. reactionSeverity)

        if reactionSeverity >= 30 then -- Refuse sale
            e.success = false
            messageString = table.choice(strings.saleReactionMild)
        end

        if reactionSeverity >= 50 then -- + disposition hit
            if merchant.object.race.id == "Dark Elf" then
                messageString = table.choice(strings.saleReactionModerateDunmer)
                turnOverResponse = strings.turnOverResponseDunmer

            elseif common.checkIsEmpire(merchant.object) then
                messageString = strings.saleReactionModerateEmpire
                turnOverResponse = strings.turnOverResponseEmpire
            else
                messageString = table.choice(strings.saleReactionModerate)
                turnOverResponse = strings.turnOverResponseMerchant
            end
            merchant.object.baseDisposition = merchant.object.baseDisposition - 25
        end

        if reactionSeverity >= 60 then -- + end trade, report to guards
            if reactionSeverity < 75 then
                common.triggerTradeMenuClose()
                timer.start{ -- Give trade menu a moment to close
                    duration = 0.0000001,
                    type = timer.real,
                    callback = function()
                        tes3ui.showDialogueMessage({ text = turnOverResponse })
                        tes3.runLegacyScript{ command = 'Goodbye' }
                    end}
            end
            dofile("Revered Dead.confiscation")
            tes3.mobilePlayer.bounty = tes3.mobilePlayer.bounty + (graveGoods.value)
        end

        if reactionSeverity >= 75 then -- + React as if personally robbed (May be violent)
            if merchant.object.race.id == "Dark Elf" then
                messageString = strings.saleReactionSevereDunmer
            else
                messageString = strings.saleReactionSevere
            end
            if merchant.alarm > 0 then
                timer.start{ -- Give trade menu a moment to close
                    duration = 0.0000001,
                    type = timer.real,
                    callback = function()
                        common.triggerDialogueMenuClose()
                        tes3.triggerCrime({
                            value = 0,
                            type = tes3.crimeType.theft,
                            victim = merchant,
                            criminal = tes3.player
                        })
                        tes3.messageBox(messageString, offendingGood)
                end}
            end
            common.triggerTradeMenuClose()
        end

        if reactionSeverity >= 100 then -- Kill you where you stand.
            messageString = strings.saleReactionExtreme
            merchant.object.baseDisposition = 0
            merchant.fight = 100
        end
        if messageString then
            tes3.messageBox(messageString, offendingGood)
        end
    end
end

--- @param e uiObjectTooltipEventData
local function graveGoodTooltip(e)
    if e.itemData and e.itemData.data and e.itemData.data.reveredDead and e.itemData.data.reveredDead.isGraveGoods == true then
        local tooltip = e.tooltip
        local displayText = strings.toolTipGraveGood
        if e.itemData.data.reveredDead.isExtremeGraveGoods == true then
            displayText = strings.toolTipGraveGoodExtreme
        end
        local label = tooltip:createLabel( { id = tes3ui.registerID("reveredDeadToolTipStolen"), text = displayText })
        label.wrapText = true
    end
end

-- Worn reactions

--- @param e equippedEventData
local function checkEquippedGraveGood(e)
    if e.reference ~= tes3.player then
        return
    end
    if e.itemData and e.itemData.data and e.itemData.data.reveredDead and e.itemData.data.reveredDead.isExtremeGraveGoods then
        local currentWornGraveGoods = tes3.getGlobal("RDWearingGravegoods")
        tes3.setGlobal("RDWearingGravegoods", (currentWornGraveGoods + 1))
        common.log:debug("Player is now wearing " .. tes3.getGlobal("RDWearingGravegoods") .. "obviously plundered items.")
    end
end

--- @param e unequippedEventData
local function checkUnequippedGraveGood(e)
    if e.reference ~= tes3.player then
        return
    end
    if e.itemData and e.itemData.data and e.itemData.data.reveredDead and e.itemData.data.reveredDead.isExtremeGraveGoods then
        local currentWornGraveGoods = tes3.getGlobal("RDWearingGravegoods")
        tes3.setGlobal("RDWearingGravegoods", (currentWornGraveGoods - 1))
        common.log:debug("Player is now wearing " .. tes3.getGlobal("RDWearingGravegoods") .. "obviously plundered items.")
    end
end

-- discussing grave goods

local function checkHoldingGraveGoods()
    local currentGraveGoodCount = 0
    for _, stack in pairs(tes3.player.object.inventory) do
        if stack.object.supportsLuaData == true and stack.variables then
            for _, vars in pairs(stack.variables) do
                if vars.data and vars.data.reveredDead and (vars.data.reveredDead.isGraveGoods == true) then
                    currentGraveGoodCount = currentGraveGoodCount + 1
                end
            end
        end
    end
    if currentGraveGoodCount > 0 then
        tes3.setGlobal("RDHasGravegoods", 1)
    else
        tes3.setGlobal("RDHasGravegoods", 0)
    end
end

-- Init

local function onInitialize()
    if config.enabled == true then
        event.register(tes3.event.uiObjectTooltip, graveGoodTooltip)
        event.register(tes3.event.uiActivated, checkHoldingGraveGoods, {filter = "MenuDialog"})
        event.register(tes3.event.equipped, checkEquippedGraveGood)
        event.register(tes3.event.unequipped, checkUnequippedGraveGood)
        event.register(tes3.event.cellChanged, scanTombItems)
        event.register(tes3.event.barterOffer, checkSellingGraveGoods)
        print("[Revered Dead] Revered Dead Initialized.")
    end
end

event.register(tes3.event.initialized, onInitialize)
dofile("Revered Dead.mcm")
