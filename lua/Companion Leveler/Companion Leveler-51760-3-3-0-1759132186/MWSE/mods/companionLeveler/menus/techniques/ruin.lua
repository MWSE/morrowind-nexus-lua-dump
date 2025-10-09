local ruin = {}


function ruin.createWindow(ref)
	--Initialize
	local menu = tes3ui.createMenu { id = "kl_simple_list", fixedFrame = true }
    menu.alpha = 1.0

	local label = menu:createLabel { text = "Ruin-Sense" }
    label.wrapText = true
    label.justifyText = "center"
    label.borderBottom = 16

	local border = menu:createThinBorder {}
    border.width = 221
    border.height = 211
	border.paddingAllSides = 5
    border.flowDirection = "top_to_bottom"

	--Check for ruins
	local result, result2, result3 = ruin.check()

	--Container Block
	local contBlock = border:createBlock({})
	contBlock.flowDirection = "left_to_right"
	contBlock.width = 210
	contBlock.height = 210
	contBlock.borderLeft = 2
	contBlock.borderRight = 2
	contBlock.borderTop = 53

	--Label Block
	local labelBlock = contBlock:createBlock({})
	labelBlock.flowDirection = "top_to_bottom"
	labelBlock.width = 90
	labelBlock.height = 210
	labelBlock.borderRight = 20

	--Result Block
	local resultBlock = contBlock:createBlock({})
	resultBlock.flowDirection = "top_to_bottom"
	resultBlock.width = 90
	resultBlock.height = 210
    resultBlock.widthProportional = 1.0
	resultBlock.childAlignX = 0.5

	--Labels
	local dwemer = labelBlock:createLabel({ text = "Dwemer:"})
	dwemer.borderBottom = 15
	local daedric = labelBlock:createLabel({ text = "Daedric:"})
	daedric.borderBottom = 15
	local wreck = labelBlock:createLabel({ text = "Shipwrecks:"})

	--Results
	local resultLabel = resultBlock:createLabel({ text = result })
	resultLabel.borderBottom = 15
	local resultLabel2 = resultBlock:createLabel({ text = result2 })
	resultLabel2.borderBottom = 15
	local resultLabel3 = resultBlock:createLabel({ text = result3 })



	----Bottom Button Block------------------------------------------------------------------------------------------
	local button_block = menu:createBlock {}
	button_block.widthProportional = 1.0
	button_block.autoHeight = true
	button_block.childAlignX = 0.5
	button_block.borderTop = 10

	local button_ok = button_block:createButton { text = tes3.findGMST("sOK").value }
	button_ok:register("mouseClick", function() menu:destroy() end)

	-- Final setup
	menu:updateLayout()
	tes3ui.enterMenuMode("kl_simple_list")
end

function ruin.check()
	local active = tes3.getActiveCells()
	local near, far, near2, far2, near3, far3 = 0, 0, 0, 0, 0, 0
	local result, result2, result3 = "--", "--", "--"
	--Each active cell
	for i = 1, #active do
		--All door references in each active cell
		for refe in active[i]:iterateReferences({ tes3.objectType.door }) do
			if refe.disabled == false then
				if string.find(refe.object.id, "door_dwrv") then
					if refe.cell == tes3.getPlayerCell() then
						near = 1
					else
						far = 1
					end
				end
				if string.find(refe.object.id, "ex_dae_door") then
					if refe.cell == tes3.getPlayerCell() then
						near2 = 1
					else
						far2 = 1
					end
				end
				if refe.destination then
					if string.find(refe.destination.cell.id, "Shipwreck") then
						if refe.cell == tes3.getPlayerCell() then
							near3 = 1
						else
							far3 = 1
						end
					end
				end
			end
		end
	end

	if near > 0 then
		result = "Near"
	elseif far > 0 then
		result = "Far"
	end

	if near2 > 0 then
		result2 = "Near"
	elseif far2 > 0 then
		result2 = "Far"
	end

	if near3 > 0 then
		result3 = "Near"
	elseif far3 > 0 then
		result3 = "Far"
	end

	return result, result2, result3
end

return ruin