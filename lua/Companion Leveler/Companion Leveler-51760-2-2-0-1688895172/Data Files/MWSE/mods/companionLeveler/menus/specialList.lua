local logger = require("logging.logger")
local log = logger.getLogger("Companion Leveler")
local func = require("companionLeveler.functions.common")

local specList = {}

function specList.createWindow(reference)
    specList.id_menu = tes3ui.registerID("kl_specList_menu")
    specList.id_label = tes3ui.registerID("kl_specList_label")
    specList.id_title = tes3ui.registerID("kl_specList_ok")
    specList.id_pane = tes3ui.registerID("kl_specList_pane")


    log = logger.getLogger("Companion Leveler")
    log:debug("Special List menu initialized.")


    local menu = tes3ui.createMenu { id = specList.id_menu, fixedFrame = true }

    local modData = func.getModData(reference)

    --Create layout
    local label = menu:createLabel { text = "" .. reference.object.name .. "'s Special Information:", id = specList.id_label }
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

        for i = 1, #modData.contracts do
			local npc = tes3.getObject(modData.contracts[i])
            local listItem = pane:createLabel({ text = "#" .. i .. ": " .. npc.name .. "" })
        end

        --Bounty Hunter Bounties
		local bountyLabel = pane:createLabel({ text = "Bounty Locations:" })
		bountyLabel.borderBottom = 12
		bountyLabel.borderTop = 12
		bountyLabel.color = { 1.0, 1.0, 1.0 }

        --Remove text after comma
        for i = 1, #modData.bounties do
            local cellName = modData.bounties[i]
            local unused
            if string.match(cellName, ",") then
                cellName, unused = modData.bounties[i]:match("([^,]+),([^,]+)")
            end
            local listItem = pane:createLabel({ text = "#" .. i .. ": " .. cellName .. "" })
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

    local button_ok = button_block:createButton { id = specList.id_ok, text = tes3.findGMST("sOK").value }

    --Events
    menu:register(tes3.uiEvent.keyEnter, specList.onOK)
    button_ok:register(tes3.uiEvent.mouseClick, specList.onOK)
end

function specList.onOK()
    local menu = tes3ui.findMenu(specList.id_menu)

    if menu then
        menu:destroy()
    end
end

return specList
