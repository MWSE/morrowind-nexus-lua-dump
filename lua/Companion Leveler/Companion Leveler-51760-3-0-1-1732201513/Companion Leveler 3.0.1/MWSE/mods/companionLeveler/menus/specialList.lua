local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")

local specList = {}


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
    label.borderBottom = 12


    local specList_block = menu:createBlock { id = "kl_specList_block" }
    specList_block.autoWidth = true
    specList_block.autoHeight = true

    local border = specList_block:createThinBorder {}
    border.width = 270
    border.height = 566
    border.flowDirection = "top_to_bottom"

    --Create Pane
    local pane = border:createVerticalScrollPane()
    pane.width = 270
    pane.height = 566
    pane.widget.scrollbarVisible = true

    --Populate Pane
    if reference.object.objectType ~= tes3.objectType.creature then
        --Assassin Contracts
		local contractLabel = pane:createLabel({ text = "Contracts:" })
		contractLabel.borderBottom = 12
		contractLabel.color = { 1.0, 1.0, 1.0 }

        for i = 1, #specList.modData.contracts do
			local npc = tes3.getObject(specList.modData.contracts[i])
            local reward = npc.level * 100
            if reward > 4000 then
                reward = 4000
            end
            local listItem = pane:createTextSelect({ text = "#" .. i .. ": " .. npc.name .. "", id = "kl_contract_listItem_" .. i .. "" })
            listItem:register("help", function(e)
                local tooltip = tes3ui.createTooltipMenu()

                local contentElement = tooltip:getContentElement()
                contentElement.paddingAllSides = 12
                contentElement.childAlignX = 0.5
                contentElement.childAlignY = 0.5

                tooltip:createLabel({ text = "" .. tes3.findGMST(tes3.gmst.sValue).value .. ": " .. reward .. " " .. tes3.findGMST(tes3.gmst.sGold).value .. "" })
            end)
            listItem:register("mouseClick", function() specList.onSelect(i, 1) end)
        end

        --Bounty Hunter Bounties
		local bountyLabel = pane:createLabel({ text = "Bounty Locations:" })
		bountyLabel.borderBottom = 12
		bountyLabel.borderTop = 12
		bountyLabel.color = { 1.0, 1.0, 1.0 }

        --Remove text after comma
        for i = 1, #specList.modData.bounties do
            local cellName = specList.modData.bounties[i]
            local unused
            if string.match(cellName, ",") then
                cellName, unused = specList.modData.bounties[i]:match("([^,]+),([^,]+)")
            end
            local listItem = pane:createTextSelect({ text = "#" .. i .. ": " .. cellName .. "", id = "kl_bounty_listItem_" .. i .."" })
            listItem:register("mouseClick", function() specList.onSelect(i, 2) end)
        end
    else
		--Creature special information
    end

    --Button Block
    local button_block = menu:createBlock {}
    button_block.widthProportional = 1.0
    button_block.autoHeight = true
    button_block.childAlignX = 0.5
    button_block.borderTop = 12

    local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }

    --Events
    menu:register(tes3.uiEvent.keyEnter, specList.onOK)
    button_ok:register(tes3.uiEvent.mouseClick, specList.onOK)
end

function specList.onSelect(id, type)
    local menu = tes3ui.findMenu(specList.id_menu)
    if menu then
        specList.id = id
        specList.type = type

        if type == 1 then
            specList.obj = tes3.getObject(specList.modData.contracts[id])
            tes3.messageBox({ message = "Abandon the contract on \"" .. specList.obj.name .. "\"?",
            buttons = { tes3.findGMST("sYes").value, tes3.findGMST("sNo").value },
            callback = specList.abandon })
        else
            tes3.messageBox({ message = "Give up on the \"" .. specList.modData.bounties[id] .. "\" bounty?",
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
                tes3.messageBox("" .. specList.reference.object.name .. " abandoned the " .. specList.obj.name .. " contract.")
            else
                tes3.messageBox("" .. specList.reference.object.name .. " abandoned the " .. specList.modData.bounties[specList.id] .. " bounty.")
                table.remove(specList.modData.bounties, specList.id)
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