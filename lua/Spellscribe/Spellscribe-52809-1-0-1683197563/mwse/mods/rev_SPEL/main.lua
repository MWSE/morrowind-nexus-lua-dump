local config = include("rev_SPEL.config")

local enscribeMenu = {}

local ids = {
	enscribeMenu = tes3ui.registerID("rev_SPEL_enscribe"),
	enscribeMenuClose = tes3ui.registerID("rev_SPEL_enscribe_close"),
	enscribeMenuScroll = tes3ui.registerID("rev_SPEL_enscribe_scroll"),
}

function enscribeMenu.closeMenu()
	local menu = tes3ui.findMenu(ids.enscribeMenu)
	if menu then 
		menu:destroy()
		tes3ui.leaveMenuMode()
	end
end

function enscribeMenu.createWindow(spellList, itemID)
    if (tes3ui.findMenu(ids.enscribeMenu) ~= nil) then
        return
    end
	
	local menu = tes3ui.createMenu{ id = ids.enscribeMenu, fixedFrame = true }
	menu.alpha = 1.0
	local width, height = tes3ui.getViewportSize() 
	menu.width = width/3
	menu.height = height/2
	menu.autoHeight = false
	menu.autoWidth = false
	
	local scrollPane = menu:createVerticalScrollPane({ id = ids.enscribeMenuScroll})
	scrollPane.autoHeight = true
	scrollPane.widthProportional = 0.9
	scrollPane.childAlignX = 0.0

	
	for index,spell in pairs(spellList) do
		if spell.castType == tes3.spellType.spell or spell.castType == tes3.spellType.power then
			local spellLabel = scrollPane:createLabel({id = spell.id, text = spell.name})
			spellLabel:register(tes3.uiEvent.mouseClick, function(e) 
			local itemData = tes3.addItemData({ to = tes3.player, item = itemID})
			itemData.data.enscriptionName = "Enscription of " .. spell.name 
			itemData.data.enscriptionID = spell.id
			enscribeMenu.closeMenu()
			end)
		end
	end

	local buttonBlock = menu:createBlock{}
	buttonBlock.widthProportional = 1.0
	buttonBlock.autoHeight = true
	buttonBlock.childAlignX = 1.0
	
	local buttonClose = buttonBlock:createButton{ id = ids.enscribeMenuClose, text = tes3.findGMST("sClose").value}
	
	buttonClose:register(tes3.uiEvent.mouseClick, enscribeMenu.closeMenu)
	
	menu:updateLayout()
	tes3ui.enterMenuMode(ids.enscribeMenu)
	
end


local function buttonPressed(e, item)
	if e.button == 1 then
		return
	else
		enscribeMenu.createWindow(tes3.player.object.spells, item)
	end
end



local function equipCallback(e)
	if e.itemData == nil or e.itemData.data.enscriptionID == nil then
			for _, id in ipairs(config.baseItems) do
				if id == e.item.id then 
					e.block = true
					local itemID = e.item.id
					tes3.messageBox({ message = "Enscribe a spell onto this material?", buttons = {"Yes", "No"}, callback = 
					function(g)
						buttonPressed(e, itemID)
					end})
				end
			end
	elseif e.itemData.data.enscriptionID ~= nil then
		e.block = true
		tes3.addSpell({ reference = tes3.player, spell = e.itemData.data.enscriptionID })
	end
end

event.register(tes3.event.equip, equipCallback)
event.register("uiObjectTooltip", function(e)
    local name = e.itemData and e.itemData.data.enscriptionName
    local label = e.tooltip:findChild("HelpMenu_name")
    if label and name then
        label.text = name
    end
end)