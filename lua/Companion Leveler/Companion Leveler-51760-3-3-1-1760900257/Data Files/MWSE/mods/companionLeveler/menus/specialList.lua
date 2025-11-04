local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")
local tables = require("companionLeveler.tables")

local specList = {}

-- Helpers ------------------------------------------------------------------
local function registerHelp(item, getTextFn)
    item:register("help", function()
        local tooltip = tes3ui.createTooltipMenu()
        local contentElement = tooltip:getContentElement()
        contentElement.paddingAllSides = 12
        contentElement.childAlignX = 0.5
        contentElement.childAlignY = 0.5

        tooltip:createLabel({ text = getTextFn() })
    end)
end

local function getLocationHint(source)
    source = source or ""
    if source == "Morrowind.esm" then
        return "Likely somewhere in Vvardenfell..."
    elseif source == "Tamriel_Data.esm" or source == "Tribunal.esm" or source == "TR_Mainland.esm" then
        return "Could be somewhere on the mainland..."
    elseif string.startswith(source, "Wares") then
        return "In Vvardenfell, or somewhere just outside of it..."
    else
        return "Located somewhere outside of Morrowind..?"
    end
end

local function createTextItem(block, text, id, opts)
    local item = block:createTextSelect({ text = text, id = id })
    if opts then
        if opts.borderBottom then item.borderBottom = opts.borderBottom end
        if opts.absolutePosAlignX then item.absolutePosAlignX = opts.absolutePosAlignX end
        if opts.color then item.widget.idle = opts.color end
        if opts.helpFn then registerHelp(item, opts.helpFn) end
        if opts.clickFn then item:register("mouseClick", opts.clickFn) end
    end
    return item
end
-- End helpers --------------------------------------------------------------


function specList.createWindow(reference)
    specList.id_menu = tes3ui.registerID("kl_specList_menu")

    log = logger.getLogger("Companion Leveler")
    log:debug("Special List menu initialized.")


    local menu = tes3ui.createMenu { id = specList.id_menu, fixedFrame = true }
    menu.alpha = 1.0

    specList.reference = reference
    specList.modData = func.getModData(reference)

    --Create layout
    local label = menu:createLabel { text = "Special Information:" }
    label.wrapText = true
    label.justifyText = "center"
    label.borderBottom = 16


    local specList_block = menu:createBlock { id = "kl_specList_block" }
    specList_block.autoWidth = true
    specList_block.autoHeight = true

    local border = specList_block:createThinBorder {}
    border.width = 380
    border.height = 566
    border.flowDirection = "top_to_bottom"

    --Create Pane
    local pane = border:createVerticalScrollPane()
    pane.width = 380
    pane.height = 566
    pane.widget.scrollbarVisible = true

    --Pane Block
    local pBlock = pane:createBlock { id = "kl_specList_pane_block" }
    pBlock.autoHeight = true
    pBlock.width = 358
    pBlock.flowDirection = tes3.flowDirection.topToBottom
    pBlock.childAlignX = 0.5

    --Populate Pane
    if reference.object.objectType ~= tes3.objectType.creature then
        --Assassin Contracts
		local contractLabel = pBlock:createLabel({ text = "Contracts:" })
		contractLabel.borderBottom = 12
		contractLabel.color = { 1.0, 1.0, 1.0 }

        for i = 1, #specList.modData.contracts do
            local idx = i
            local npc = tes3.getObject(specList.modData.contracts[idx][1])
            local msg = getLocationHint(npc.sourceMod)
            createTextItem(pBlock,
                "#" .. idx .. ": " .. npc.name .. "\n " .. msg,
                "kl_contract_listItem_" .. idx,
                {
                    borderBottom = 12,
                    absolutePosAlignX = 0.0,
                    helpFn = function()
                        return tes3.findGMST(tes3.gmst.sValue).value .. ": " .. specList.modData.contracts[idx][2] .. " " .. tes3.findGMST(tes3.gmst.sGold).value
                    end,
                    clickFn = function() specList.onSelect(idx, 1) end
                }
            )
        end


        --Bounty Hunter Bounties
		local bountyLabel = pBlock:createLabel({ text = "Bounty Locations:" })
		bountyLabel.borderBottom = 12
		bountyLabel.borderTop = 24
		bountyLabel.color = { 1.0, 1.0, 1.0 }

        --Remove text after comma
        for i = 1, #specList.modData.bounties do
            local idx = i
            local cellName = specList.modData.bounties[idx]
            local unused
            if string.match(cellName, ",") then
                cellName, unused = specList.modData.bounties[idx]:match("([^,]+),([^,]+)")
            end
            createTextItem(pBlock, "#" .. idx .. ": " .. cellName, "kl_bounty_listItem_" .. idx, { clickFn = function() specList.onSelect(idx, 2) end })
        end


        --Courier Deliveries
        local deliveryLabel = pBlock:createLabel({ text = "Deliveries:" })
        deliveryLabel.borderBottom = 12
        deliveryLabel.borderTop = 24
        deliveryLabel.color = { 1.0, 1.0, 1.0 }
        
        for i = 1, #specList.modData.deliveries do
            local idx = i
            local npc = tes3.getObject(specList.modData.deliveries[idx][1])
            local msg = getLocationHint(npc.sourceMod)
            createTextItem(pBlock,
                "#" .. idx .. ": " .. tes3.getObject(specList.modData.deliveries[idx][3]).name .. "\n " .. msg,
                "kl_delivery_listItem_" .. idx,
                {
                    borderBottom = 4,
                    absolutePosAlignX = 0.0,
                    helpFn = function()
                        return tes3.findGMST(tes3.gmst.sValue).value .. ": " .. specList.modData.deliveries[idx][2] .. " " .. tes3.findGMST(tes3.gmst.sGold).value
                    end,
                    clickFn = function() specList.onSelect(idx, 3) end
                }
            )
        end


        --Friendly Relations
        local diploLabel = pBlock:createLabel ({ text = "Friendly Relations:" })
        diploLabel.borderBottom = 12
        diploLabel.borderTop = 24
        diploLabel.color = { 1.0, 1.0, 1.0 }

        --Diplomat
        if specList.modData.consulate ~= nil then
            local faction = tes3.getFaction(specList.modData.consulate)
            local speech = reference.mobile:getSkillStatistic(25)
            local mod = math.round(speech.current * 0.1)
            if mod > 15 then
                mod = 15
            end
            if mod < 0 then
                mod = 0
            end
            local listItem = pBlock:createTextSelect({ text = "" .. faction.name .. "", id = "kl_relation_label" })
            listItem.widget.idle = tables.colors["pink"]
            listItem.borderBottom = 4
            listItem:register("help", function(e)
                local tooltip = tes3ui.createTooltipMenu()

                local contentElement = tooltip:getContentElement()
                contentElement.paddingAllSides = 12
                contentElement.childAlignX = 0.5
                contentElement.childAlignY = 0.5

                tooltip:createLabel({ text = "Diplomatic Negotiations\n\n+ " .. mod .. " disposition bonus to members of this faction. (" .. tes3.findGMST(tes3.gmst.sSkillSpeechcraft).value .. ")" })
            end)
        end

        --Retainer
        if specList.modData.allegiances ~= nil then
            for i = 1, #specList.modData.allegiances[2] do
                if specList.modData.allegiances[2][i][2] > 0 then
                    local faction = tes3.getFaction(specList.modData.allegiances[2][i][1])
                    local msg = "Friendly"
                    local color = tables.colors["default_font"]
                    if specList.modData.allegiances[2][i][2] == 2 then
                        msg = "Allied"
                        color = { 0.773, 0.91, 0.718 }
                    elseif specList.modData.allegiances[2][i][2] == 3 then
                        msg = "Beholden"
                        color = { 0.48, 0.82, 0.49 }
                    elseif specList.modData.allegiances[2][i][2] == 4 then
                        msg = "Honored"
                        color = { 0.34, 0.78, 0.3 }
                    elseif specList.modData.allegiances[2][i][2] >= 5 then
                        msg = "Exalted"
                        color = { .18, 0.713, 0.172 }
                    end
                    local listItem = pBlock:createTextSelect({ text = "" .. faction.name .. "", id = "kl_relation_good_label_" .. i .. "" })
                    listItem.borderBottom = 4
                    listItem.widget.idle = color
                    listItem:register("help", function(e)
                        local tooltip = tes3ui.createTooltipMenu()
        
                        local contentElement = tooltip:getContentElement()
                        contentElement.paddingAllSides = 12
                        contentElement.childAlignX = 0.5
                        contentElement.childAlignY = 0.5


                        local amount = specList.modData.allegiances[2][i][2] * 3
                        if amount > 12 then
                            amount = 12
                        end
        
                        tooltip:createLabel({ text = "" .. msg .. "\n\n+" .. amount .. " disposition bonus to members of this faction. (" .. tes3.getFaction(specList.modData.allegiances[1]).name .. " Affiliation)" })
                    end)
                end
            end
        end


        --Unfriendly Relations
        local hateLabel = pBlock:createLabel({ text = "Unfriendly Relations:" })
        hateLabel.borderBottom = 12
        hateLabel.borderTop = 24
        hateLabel.color = { 1.0, 1.0, 1.0 }

        --Retainer
        if specList.modData.allegiances ~= nil then
            for i = 1, #specList.modData.allegiances[2] do
                if specList.modData.allegiances[2][i][2] < 0 then
                    local faction = tes3.getFaction(specList.modData.allegiances[2][i][1])
                    local msg = "Unfriendly"
                    local color = tables.colors["default_font"]
                    if specList.modData.allegiances[2][i][2] == -2 then
                        msg = "Hostile"
                        color = { 0.85, 0.6, 0.6 }
                    elseif specList.modData.allegiances[2][i][2] == -3 then
                        msg = "Enemy"
                        color = { 0.9, 0.4, 0.4 }
                    elseif specList.modData.allegiances[2][i][2] == -4 then
                        msg = "Sworn Enemy"
                        color = { 0.85, 0.3, 0.3 }
                    elseif specList.modData.allegiances[2][i][2] <= -5 then
                        msg = "Blind Rage"
                        color = { .75, 0.05, 0.05 }
                    end
                    local listItem = pBlock:createTextSelect({ text = "" .. faction.name .. "", id = "kl_relation_bad_label_" .. i .. "" })
                    listItem.borderBottom = 4
                    listItem.widget.idle = color
                    listItem:register("help", function(e)
                        local tooltip = tes3ui.createTooltipMenu()
        
                        local contentElement = tooltip:getContentElement()
                        contentElement.paddingAllSides = 12
                        contentElement.childAlignX = 0.5
                        contentElement.childAlignY = 0.5


                        local amount = specList.modData.allegiances[2][i][2] * 3
                        if amount < -20 then
                            amount = -20
                        end
        
                        tooltip:createLabel({ text = "" .. msg .. "\n\n" .. amount .. " disposition penalty to members of this faction. (" .. tes3.getFaction(specList.modData.allegiances[1]).name .. " Affiliation)" })
                    end)
                end
            end
        end


        --Hostile Relations
        local enemyLabel = pBlock:createLabel({ text = "Hostile Relations:" })
        enemyLabel.borderBottom = 12
        enemyLabel.borderTop = 24
        enemyLabel.color = { 1.0, 1.0, 1.0 }
        --Infiltrator
        if specList.modData.infiltrated ~= nil then
            local faction = tes3.getFaction(specList.modData.infiltrated)
            local listItem = pBlock:createTextSelect({ text = "" .. faction.name .. "", id = "kl_relation_host_label_infil" })
            listItem.borderBottom = 4
            listItem.widget.idle = tables.colors["pink"]
            listItem:register("help", function(e)
                local tooltip = tes3ui.createTooltipMenu()

                local contentElement = tooltip:getContentElement()
                contentElement.paddingAllSides = 12
                contentElement.childAlignX = 0.5
                contentElement.childAlignY = 0.5

                local security = reference.mobile:getSkillStatistic(18)
                local mod = (security.base * 0.0012)
                if mod > 0.20 then
                    mod = 0.20
                end

                tooltip:createLabel({ text = "Infiltrated\n\n" .. mod * 100 .. "% damage bonus against members of this faction. (" .. tes3.findGMST(tes3.gmst.sSkillSecurity).value .. ")" })
            end)
        end

        --Exile
        if specList.modData.fEnemies ~= nil then
            for i = 1, #specList.modData.fEnemies do
                local faction = tes3.getFaction(specList.modData.fEnemies[i][1])
                local msg = "Hostile"
                local color = tables.colors["default_font"]
                if specList.modData.fEnemies[i][2] == -2 then
                    msg = "Enemy"
                    color = { 0.85, 0.6, 0.6 }
                elseif specList.modData.fEnemies[i][2] == -3 then
                    msg = "Hated Enemy"
                    color = { 0.9, 0.4, 0.4 }
                elseif specList.modData.fEnemies[i][2] == -4 then
                    msg = "Sworn Enemy"
                    color = { 0.85, 0.3, 0.3 }
                elseif specList.modData.fEnemies[i][2] == -5 then
                    msg = "Grudge"
                    color = { 0.8, 0.2, 0.2 }
                elseif specList.modData.fEnemies[i][2] < -5 then
                    msg = "Blind Rage"
                    color = { .75, 0.05, 0.05 }
                end
                local listItem = pBlock:createTextSelect({ text = "" .. faction.name .. "", id = "kl_relation_host_label_" .. i .. "" })
                listItem.borderBottom = 4
                listItem.widget.idle = color
                listItem:register("help", function(e)
                    local tooltip = tes3ui.createTooltipMenu()
    
                    local contentElement = tooltip:getContentElement()
                    contentElement.paddingAllSides = 12
                    contentElement.childAlignX = 0.5
                    contentElement.childAlignY = 0.5

                    local amount = (specList.modData.fEnemies[i][2] * -4)
                    if reference.mobile.willpower.base < 100 then
                        amount = amount / 2
                    elseif reference.mobile.willpower.base >= 150 then
                        amount = amount * 1.25
                    end
    
                    tooltip:createLabel({ text = "" .. msg .. "\n\n" .. amount .. "% damage bonus against members of this faction. (" .. tes3.findGMST(tes3.gmst.sAttributeWillpower).value .. ")" })
                end)
            end
        end

        --Patron Information
        local patronLabel = pBlock:createLabel({ text = "Patron Information:" })
        patronLabel.borderBottom = 12
        patronLabel.borderTop = 24
        patronLabel.color = tables.colors["white"]

        if specList.modData.patron then
            local patron = tables.patrons[specList.modData.patron]
			local lbl = pBlock:createLabel({ text = "" .. patron .. "", id = "kl_patron_label_spec" })
            lbl.borderBottom = 12
			if specList.modData.patron < 10 then
				lbl.color = tables.colors["blue"]
			else
				lbl.color = tables.colors["red"]
			end
			func.patronTooltip(lbl, specList.modData.patron)
            --gifts
            local gift = pBlock:createLabel({ text = "" .. tables.patronGifts[specList.modData.patron] .. "", id = "kl_patron_gift_spec" })
            gift.borderBottom = 12
            gift.wrapText = true
            gift.widthProportional = 1.0
            --tribute/duty
            local duty = pBlock:createLabel({ text = "" .. tables.patronDuties[specList.modData.patron] .. "", id = "kl_patron_duty_spec" })
            duty.wrapText = true
            duty.widthProportional = 1.0
        end
    else
		--Creature special information

        --Guild Training Information
        local trainLabel = pBlock:createLabel({ text = "Guild Training:" })
        trainLabel.borderBottom = 12
        trainLabel.borderTop = 24
        trainLabel.color = tables.colors["white"]

        if specList.modData.guildTraining then
            local key = 1
            for i = 1, #tables.factions do
                if specList.modData.guildTraining[1] == tables.factions[i] then
                    key = i
                    break
                end
            end
            local abil = tes3.getObject("kl_ability_gTrained_" .. key .. "")
			local lbl = pBlock:createLabel({ text = "" .. abil.name .. "", id = "kl_guild_label_spec" })
            lbl.borderBottom = 12
			func.guildTooltip(lbl, key)

            if specList.modData.guildTraining[2] then
                local key2 = 1
                for i = 1, #tables.factions do
                    if specList.modData.guildTraining[2] == tables.factions[i] then
                        key2 = i
                        break
                    end
                end
                local abil2 = tes3.getObject("kl_ability_gTrained_" .. key2 .. "")
                local lbl2 = pBlock:createLabel({ text = "" .. abil2.name .. "", id = "kl_guild2_label_spec" })
                lbl2.borderBottom = 12
                func.guildTooltip(lbl2, key2)
            end
        end
    end

    --Button Block
    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0
    button_block.autoHeight = true
    button_block.childAlignX = 0.5
    button_block.borderTop = 24

    local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }

    --Events
    menu:updateLayout()
    menu:register(tes3.uiEvent.keyEnter, specList.onOK)
    button_ok:register(tes3.uiEvent.mouseClick, specList.onOK)
end

function specList.onSelect(id, type)
    local menu = tes3ui.findMenu(specList.id_menu)
    if menu then
        specList.id = id
        specList.type = type

        if type == 1 then
            specList.obj = tes3.getObject(specList.modData.contracts[id][1])
            tes3.messageBox({ message = "Abandon the contract on \"" .. specList.obj.name .. "\"?",
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = specList.abandon })
        elseif type == 2 then
            tes3.messageBox({ message = "Give up on the \"" .. specList.modData.bounties[id] .. "\" bounty?",
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = specList.abandon })
        else
            specList.obj = tes3.getObject(specList.modData.deliveries[id][3])
            tes3.messageBox({ message = "Forsake the " .. specList.obj.name .. "?",
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = specList.abandon })
        end
    end
end

function specList.abandon(e)
    local menu = tes3ui.findMenu(specList.id_menu)
    if menu then
        if e.button == 0 then
            if specList.type == 1 then
                table.remove(specList.modData.contracts, specList.id)
                func.clMessageBox("" .. specList.reference.object.name .. " abandoned the " .. specList.obj.name .. " contract.")
            elseif specList.type == 2 then
                func.clMessageBox("" .. specList.reference.object.name .. " abandoned the " .. specList.modData.bounties[specList.id] .. " bounty.")
                table.remove(specList.modData.bounties, specList.id)
            else
                tes3.removeItem({ reference = specList.reference, item = specList.modData.deliveries[specList.id][3], count = 1, playSound = true })
                table.remove(specList.modData.deliveries, specList.id)
                func.clMessageBox("" .. specList.reference.object.name .. " abandoned the " .. specList.obj.name .. " delivery.")
            end
            menu:destroy()
            specList.createWindow(specList.reference)
        end
    end
end

function specList.onOK()
    local menu = tes3ui.findMenu(specList.id_menu)

    if menu then
        menu:destroy()
    end
end


return specList