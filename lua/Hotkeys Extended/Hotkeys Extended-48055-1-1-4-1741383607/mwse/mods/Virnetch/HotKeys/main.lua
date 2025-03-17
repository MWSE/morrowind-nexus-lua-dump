local config = mwse.loadConfig("hotkeys_extended",{
	itemIconPosition = false,
	showAll = true,
	holdDelay = 4
})

local data
local lastButton

local keys

local quickMainid = tes3ui.registerID("vir_quickkeys:quickMain")
local quick_id = tes3ui.registerID("vir_quickkeys:quick_")

local quickAid = tes3ui.registerID("vir_quickkeys:quickA")
local quickA2id = tes3ui.registerID("vir_quickkeys:quickA2")
local quickAHid = tes3ui.registerID("vir_quickkeys:quickAH")

local quickBid = tes3ui.registerID("vir_quickkeys:quickB")
local quickB2id = tes3ui.registerID("vir_quickkeys:quickB2")
local quickBHid = tes3ui.registerID("vir_quickkeys:quickBH")

local magicSelectid = tes3ui.registerID("vir_quickkeys:magicMenu")

local lastWeaponEquipped

local currentQuickMenu = 1

local function stopEquipSound()
	tes3.removeSound{ reference = tes3.player, sound = "Item Weapon Axe Up" }
	tes3.removeSound{ reference = tes3.player, sound = "Item Weapon Blunt Up" }
	tes3.removeSound{ reference = tes3.player, sound = "Item Weapon Bow Up" }
	tes3.removeSound{ reference = tes3.player, sound = "Item Weapon Crossbow Up" }
	tes3.removeSound{ reference = tes3.player, sound = "Item Weapon Longblade Up" }
	tes3.removeSound{ reference = tes3.player, sound = "Item Weapon Shortblade Up" }
	tes3.removeSound{ reference = tes3.player, sound = "Item Weapon Spear Up" }
end

local function checkEquipped()		--This is to make sure that the weapon is equipped after ending an attack if the player is attacking with another weapon when pressing the hotkey
	if tes3.mobilePlayer then
		if tes3.mobilePlayer.readiedWeapon and tes3.mobilePlayer.readiedWeapon.object and tes3.mobilePlayer.readiedWeapon.object.id then
			if tes3.mobilePlayer.readiedWeapon.object.id ~= lastWeaponEquipped then
				if mwscript.getItemCount{ reference = tes3.player, item = lastWeaponEquipped } > 0 then
					tes3.mobilePlayer:equip{ item = lastWeaponEquipped }
					local object = tes3.getObject(lastWeaponEquipped)
					if object then
						if object.objectType == tes3.objectType.weapon then
							timer.delayOneFrame(checkEquipped)
							if tes3.mobilePlayer.weaponReady == false then
								tes3.mobilePlayer.weaponReady = true	--Ready the equipped weapon
								stopEquipSound()	--Stops second weapon equip sound
							end
							return
						end
					end
				end
			end
		end
	end
	lastWeaponEquipped = nil
end

local function quickEquip(type, num)
	if data[type][num].id ~= nil then
		if data[type][num].id == 0 then			--Hand to Hand
			tes3.mobilePlayer:unequip{ type = tes3.objectType.weapon }
		else
			local id = data[type][num].id
			if data[type][num].isMagic then 	--Magic
				local found = false
				if data[type][num].isItem then	--Enchanted Item
					if mwscript.getItemCount{ reference = tes3.player, item = id } > 0 then
						local object = tes3.getObject(id)
						local scroll
						if object and object.objectType == tes3.objectType.book then	--Scrolls can't be equipped but they stack so it shouldn't matter
							scroll = true
						else
							scroll = false
							tes3.mobilePlayer:equip{ item = id }
						end
						local menuMagic = tes3ui.findMenu(tes3ui.registerID("MenuMagic"))
						if menuMagic then
							local itemsList = menuMagic:findChild(tes3ui.registerID("MagicMenu_item_names"))
							if itemsList then
								timer.delayOneFrame(
									function()
										for _, item in pairs(itemsList.children) do
											if item.text then
												local normalColor = tes3ui.getPalette("normal_color") --Equipped but not readied
												local activeColor = tes3ui.getPalette("active_color") --Equipped and readied
												if scroll or (math.floor(normalColor[1]*1000)/1000 == math.floor(item.color[1]*1000)/1000
												and math.floor(normalColor[2]*1000)/1000 == math.floor(item.color[2]*1000)/1000
												and math.floor(normalColor[3]*1000)/1000 == math.floor(item.color[3]*1000)/1000)
												or (math.floor(activeColor[1]*1000)/1000 == math.floor(item.color[1]*1000)/1000
												and math.floor(activeColor[2]*1000)/1000 == math.floor(item.color[2]*1000)/1000
												and math.floor(activeColor[3]*1000)/1000 == math.floor(item.color[3]*1000)/1000) then	--Item is equipped
													if item.text == data[type][num].name then	--same name
														item:triggerEvent("mouseClick")
														if tes3.mobilePlayer.currentEnchantedItem.object.id == data[type][num].id then
														--	found = true
															if not tes3.hasCodePatchFeature(71) then	--Swift casting
																if tes3.mobilePlayer.castReady == false then
																	tes3.mobilePlayer.weaponReady = false
																	tes3.mobilePlayer.castReady = true	--Ready hands if not using swift casting
																end
															end
															break
														end
													end
												end
											end
										end
									end
								)
							end
						end
					else
						local object = tes3.getObject(id)
						if object then
							local name = object.name or "that item"
							tes3.messageBox(tes3.findGMST(tes3.gmst.sQuickMenu5).value.." "..name)
						end
					end
				else							--Spell or Power
					local menuMagic = tes3ui.findMenu(tes3ui.registerID("MenuMagic"))
					if menuMagic then
						local powersList = menuMagic:findChild(tes3ui.registerID("MagicMenu_power_names"))
						local spellsList = menuMagic:findChild(tes3ui.registerID("MagicMenu_spell_names"))
						if powersList then
							for _, power in pairs(powersList.children) do
								if power.text then
									power:triggerEvent("mouseClick")
									if tes3.mobilePlayer.currentSpell.id == data[type][num].id then
										found = true
										break
									end
								end
							end
						end
						if spellsList and not found then
							for _, spell in pairs(spellsList.children) do
								if spell.text then
									spell:triggerEvent("mouseClick")
									if tes3.mobilePlayer.currentSpell.id == data[type][num].id then
										found = true
										break
									end
								end
							end
						end
						if not found then
							local object = tes3.getObject(id)
							if object then
								local name = object.name or "that spell"
								tes3.messageBox(tes3.findGMST(tes3.gmst.sQuickMenu5).value.." "..name)
							end
						end
					end
				end
				if found then
					if not tes3.hasCodePatchFeature(71) then	--Swift casting
						if tes3.mobilePlayer.castReady == false then
							tes3.mobilePlayer.weaponReady = false
							tes3.mobilePlayer.castReady = true	--Ready hands if not using swift casting
						end
					end
				end
			else								--Item
				if mwscript.getItemCount{ reference = tes3.player, item = id } > 0 then
					local object = tes3.getObject(id)
					local equip = true
					if object.objectType == tes3.objectType.alchemy then
						local menuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
						if menuMulti then
							local icons = menuMulti:findChild(tes3ui.registerID("MenuMulti_weapon_layout")).parent.children
							for i=1, #icons do
								if icons[i].children and icons[i].children[1] then
									if icons[i].children[1].contentPath and icons[i].children[1].contentPath == "icons\\nc\\potions_blocked.tga" then
										if icons[i].visible == true then
											equip = false
										end
									end
								end
							end
						end
					end
					local eventData = { item = object, reference = tes3.player }
					event.trigger("equip", eventData, { filter = tes3.player })
					if equip then
						tes3.mobilePlayer:equip{ item = id }
						if object then
							if object.objectType == tes3.objectType.weapon then
								lastWeaponEquipped = id
								timer.delayOneFrame(checkEquipped)
								if tes3.mobilePlayer.weaponReady == false then
									tes3.mobilePlayer.castReady = false
									tes3.mobilePlayer.weaponReady = true	--Ready the equipped weapon
									stopEquipSound()	--Stops second weapon equip sound
								end
							end
						end
					end
				else
					local object = tes3.getObject(id)
					if object then
						local name = object.name or "that item"
						tes3.messageBox(tes3.findGMST(tes3.gmst.sQuickMenu5).value.." "..name)
					end
				end
			end
		end
	end
end

local function timerExpired(key, heldKey)
	local inputController = tes3.worldController.inputController
	local key1 = "quick"..key
	if keys[heldKey][key].hold == true then --Hold
		if inputController:isKeyDown(tes3.getInputBinding(tes3.keybind[key1]).code)
		or inputController:isMouseButtonDown(tes3.getInputBinding(tes3.keybind[key1]).code) then
		--	tes3.messageBox("held key "..key.." with "..heldKey.." held down")
			local type
			if heldKey == "_" then
				type = "quickH"
			else
				type = ("quick"..heldKey.."H")
			end
			quickEquip(type, key)
		--else
		--	tes3.messageBox("timer stopped "..heldKey.." "..key)
		end
	end
	keys[heldKey][key].double = false
	keys[heldKey][key].hold = false
end

local function getHeldKey()
	local inputController = tes3.worldController.inputController
	if data.keyA ~= "DISABLED" and inputController:isKeyDown(data.keyA) then
		return("A")
	elseif data.keyB ~= "DISABLED" and inputController:isKeyDown(data.keyB) then
		return("B")
	else
		return("_")
	end
end

local function getKeyUpType(key)
	if keys["_"][key].hold == true and keys["_"][key].double == true then	--Single tap
	--	tes3.messageBox("tapped key "..key.." with _ held down")
		quickEquip("quick_", key)
	elseif keys["A"][key].hold == true and keys["A"][key].double == true then	--Single tap
	--	tes3.messageBox("tapped key "..key.." with A held down")
		quickEquip("quickA", key)
	elseif keys["B"][key].hold == true and keys["B"][key].double == true then	--Single tap
	--	tes3.messageBox("tapped key "..key.." with B held down")
		quickEquip("quickB", key)
	end
	keys["_"][key].hold = false
	keys["A"][key].hold = false
	keys["B"][key].hold = false
end

local function getKeyDownType(key)
	local heldKey = getHeldKey()
	if keys[heldKey][key].double == true then	 --Double tap
		keys[heldKey][key].double = false
	--	tes3.messageBox("double tapped key "..key.." with "..heldKey.." held down")
		local type
		if heldKey == "_" then
			type = "quick2"
		else
			type = ("quick"..heldKey.."2")
		end
		quickEquip(type, key)
	elseif keys[heldKey][key].hold == false then
		keys[heldKey][key].double = true
		keys[heldKey][key].hold = true
		timer.start{
			type = timer.real,
			duration = config.holdDelay / 10,
			callback = function()
				timerExpired(key, heldKey)
			end
		}
	end
end

local function keyUp(e)
	if not tes3.menuMode() then
		for i=1, 10 do
			local key = "quick"..i
			if (e.keyCode == tes3.getInputBinding(tes3.keybind[key]).code) and (tes3.getInputBinding(tes3.keybind[key]).device ~= 1) then
				getKeyUpType(i)
			end
		end
	end
end
event.register("keyUp", keyUp)

local function keyDown(e)
	if not tes3.menuMode() then
		for i=1, 10 do
			local key = "quick"..i
			if (e.keyCode == tes3.getInputBinding(tes3.keybind[key]).code) and (tes3.getInputBinding(tes3.keybind[key]).device ~= 1) then
				getKeyDownType(i)
			end
		end
	end
end
event.register("keyDown", keyDown)

local function mouseUp(e)
	if not tes3.menuMode() then
		for i=1, 10 do
			local key = "quick"..i
			if (e.button == tes3.getInputBinding(tes3.keybind[key]).code) and (tes3.getInputBinding(tes3.keybind[key]).device == 1) then
				getKeyUpType(i)
			end
		end
	end
end
event.register("mouseButtonUp", mouseUp)

local function mouseDown(e)
	if not tes3.menuMode() then
		for i=1, 10 do
			local key = "quick"..i
			if (e.button == tes3.getInputBinding(tes3.keybind[key]).code) and (tes3.getInputBinding(tes3.keybind[key]).device == 1) then
				getKeyDownType(i)
			end
		end
	end
end
event.register("mouseButtonDown", mouseDown)

local function updateButtonLabels()
	local menu = tes3ui.findMenu(quickMainid)
	if not menu then return end

	local textA	--Left side
	if data.keyA == "DISABLED" then
		textA = "-Select Key-"
	else
		textA = tes3.findGMST(tes3.gmst.sKeyName_00 + data.keyA).value
	end

	local labelA = menu:findChild(quickAid)
	if labelA then
		labelA.text = textA
	end
	local labelA2 = menu:findChild(quickA2id)
	if labelA2 then
		if data.keyA == "DISABLED" then
			labelA2.text = ("DISABLED")
		else
			labelA2.text = ("Double Tap Quick Keys While Holding "..textA)
		end
	end
	local labelAH = menu:findChild(quickAHid)
	if labelAH then
		if data.keyA == "DISABLED" then
			labelAH.text = ("DISABLED")
		else
			labelAH.text = ("Hold Quick Keys While Holding "..textA)
		end
	end

	local textB	--Right side
	if data.keyB == "DISABLED" then
		textB = "-Select Key-"
	else
		textB = tes3.findGMST(tes3.gmst.sKeyName_00 + data.keyB).value
	end

	local labelB = menu:findChild(quickBid)
	if labelB then
		labelB.text = textB
	end
	local labelB2 = menu:findChild(quickB2id)
	if labelB2 then
		if data.keyB == "DISABLED" then
			labelB2.text = ("DISABLED")
		else
			labelB2.text = ("Double Tap Quick Keys While Holding "..textB)
		end
	end
	local labelBH = menu:findChild(quickBHid)
	if labelBH then
		if data.keyB == "DISABLED" then
			labelBH.text = ("DISABLED")
		else
			labelBH.text = ("Hold Quick Keys While Holding "..textB)
		end
	end
end

local function setKey(e)
	local quickMainMenu = tes3ui.findMenu(quickMainid)
	if not quickMainMenu
	or e.keyCode == 1														--Esc
	or e.keyCode == tes3.getInputBinding(tes3.keybind.quickMenu).code then	--Quick Menu key
		event.unregister("keyDown", setKey)
		return
	end

	if e.keyCode == 14 then	--Backspace
		if lastButton == "A" then
			data.keyA = "DISABLED"
		else
			data.keyB = "DISABLED"
		end
		tes3.messageBox("Disabled Hotkeys")
	elseif lastButton == "A" then
		data.keyA = e.keyCode
		tes3.messageBox(tes3.findGMST(tes3.gmst.sKeyName_00 + e.keyCode).value)
		if data.keyB == data.keyA then
			data.keyB = "DISABLED"
		end
	else
		data.keyB = e.keyCode
		tes3.messageBox(tes3.findGMST(tes3.gmst.sKeyName_00 + e.keyCode).value)
		if data.keyA == data.keyB then
			data.keyA = "DISABLED"
		end
	end

	event.unregister("keyDown", setKey)
	updateButtonLabels()
	quickMainMenu:updateLayout()
end

local function createKeyBinder(e)
	local menu = tes3ui.findMenu(tes3ui.registerID("MenuQuick"))
	if not menu then return end

	if e.source.id == quickAid then
		lastButton = "A"
	else
		lastButton = "B"
	end

	tes3.messageBox("Press a button that needs to be held when using these quick keys or press Backspace to disable them")
	event.unregister("keyDown", setKey)
	event.register("keyDown", setKey)
end

local function updateIcon(button, type, num)
	if data[type][num].id then
		local label
		if data[type][num].id == 0 then
			label = button:createImage{ path = "Icons\\k\\Stealth_HandToHand.tga" }
			label.borderAllSides = 4
			label.consumeMouseEvents = false
			button.paddingAllSides = 10
		else
			local object = tes3.getObject(data[type][num].id)
			local iconPath
			if data[type][num].isMagic and not data[type][num].isItem then
				iconPath = data[type][num].icon
			else
				iconPath = "Icons\\"..object.icon
			end
			if iconPath then
				button.borderAllSides = 4
				button.paddingAllSides = 8

				local borderPath
				if data[type][num].isMagic and not data[type][num].isItem then	--Spell or Power
					borderPath = "Textures\\menu_icon_select_magic.tga"
				elseif object.enchantment == nil then	--Non-enchanted item
					borderPath = "Textures\\menu_icon_barter.tga"
					if config.itemIconPosition == false then
						button.paddingAllSides = 6
					end
				else		--enchanted item
					borderPath = "Textures\\menu_icon_select_magic_magic.tga"
				end

				local barterIcon = button:createImage{ path = borderPath }
				barterIcon.widthProportional = 1
				barterIcon.heightProportional = 1
				barterIcon.childAlignX = 0.0
				barterIcon.childAlignY = 0.0
				barterIcon.consumeMouseEvents = false

				local shadowIcon
				if (not data[type][num].isMagic) or data[type][num].isItem then
					shadowIcon = barterIcon:createImage{ path = iconPath }
					shadowIcon.color = {0.0, 0.0, 0.0}
					shadowIcon.absolutePosAlignX = 0
					shadowIcon.absolutePosAlignY = 0
					shadowIcon.borderAllSides = 12
					shadowIcon.consumeMouseEvents = false
				end
				local icon = barterIcon:createImage{ path = iconPath }
				icon.borderAllSides = 6
				icon.consumeMouseEvents = false
			else
				label = button:createImage{ path = "Icons\\default icon.dds" }
				label.borderLeft = 4
				label.consumeMouseEvents = false
				button.paddingAllSides = 10
			end
		end
	else
		if num == 10 then num = 0 end
		num = tostring(num)
		local label = button:createLabel{ text = num }
		label.borderAllSides = 14
		label.borderLeft = 20
		label.consumeMouseEvents = false
	end
	local quickMainMenu = tes3ui.findMenu(quickMainid)
	quickMainMenu:updateLayout()
end

local function setQuickButton(button, type, num)
	button.width = 60
	button.height = 60
	button.borderAllSides = 4
	button.paddingAllSides = 6

	updateIcon(button, type, num)
end

local function quickItemSelected(e, button, type, num)
	if not e.item then return end
	data[type][num].id = e.item.id
	data[type][num].name = nil	--only the id is needed for regular items
	data[type][num].icon = nil
	data[type][num].isMagic = false
	data[type][num].isItem = false
	button:destroyChildren()
	updateIcon(button, type, num)
end

local function selectMagicToQuickKey(button, type, num, object, isItem, iconPath)
	if not object then return end
	if not object.id then return end
	data[type][num].id = object.id
	if isItem then	--name only needs to be saved for enchanted items
		data[type][num].name = object.name
	else
		data[type][num].name = nil
	end
	data[type][num].icon = iconPath	--icon path needs to be saved for spells
	data[type][num].isMagic = true
	data[type][num].isItem = isItem
	button:destroyChildren()
	updateIcon(button, type, num)
end

local function closeMagicMenu()
	local menu = tes3ui.findMenu(magicSelectid)
	if not menu then return end

	menu:destroy()
end

local function showMagicSelectMenu(button, type, num)
	local menuMagic = tes3ui.findMenu(tes3ui.registerID("MenuMagic"))
	if menuMagic then
		if (tes3ui.findMenu(magicSelectid) ~= nil) then return end

		local powersList = menuMagic:findChild(tes3ui.registerID("MagicMenu_power_names"))
		local spellsList = menuMagic:findChild(tes3ui.registerID("MagicMenu_spell_names"))
		local itemsList = menuMagic:findChild(tes3ui.registerID("MagicMenu_item_names"))

		local magicMenu = tes3ui.createMenu{ id = magicSelectid, fixedFrame = true }
		magicMenu.absolutePosAlignX = 0.5
		magicMenu.absolutePosAlignY = 0.5
		magicMenu.autoHeight = true
		magicMenu.autoWidth = true
		magicMenu.alpha = 1.0
		magicMenu.flowDirection = "top_to_bottom"

		magicMenu:createLabel{ text = tes3.findGMST(tes3.gmst.sMagicSelectTitle).value }
		local listBlock = magicMenu:createBlock()
		listBlock.width = 300
		listBlock.height = 520

		local spellList = listBlock:createVerticalScrollPane()
		local powerLabel = spellList:createLabel{ text = tes3.findGMST(tes3.gmst.sPowers).value }
		powerLabel.color = { 0.875, 0.788, 0.624 }
		if powersList then
			for _, power in pairs(powersList.children) do
				if power.text then
					local label = spellList:createTextSelect{ text = power.text }
					label.widget.idle = tes3ui.getPalette("normal_color")
					label.widget.over = tes3ui.getPalette("normal_over_color")
					label.widget.pressed = tes3ui.getPalette("normal_pressed_color")
					label:register("help", function()
						power:triggerEvent("help")
					end)
					label:register("mouseClick", function()
						power:triggerEvent("mouseClick")
						magicMenu:destroy()
						local menuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
						local iconPath
						if menuMulti then
							local icon = menuMulti:findChild(tes3ui.registerID("MenuMulti_magic_icon"))
							if icon then
								iconPath = icon.contentPath
							end
							selectMagicToQuickKey(button, type, num, tes3.mobilePlayer.currentSpell, false, iconPath)
						end
					end)
				end
			end
		end
		spellList:createDivider()
		local spellLabel = spellList:createLabel{ text = tes3.findGMST(tes3.gmst.sSpells).value }
		spellLabel.color = { 0.875, 0.788, 0.624 }
		if spellsList then
			for _, spell in pairs(spellsList.children) do
				if spell.text then
					local label = spellList:createTextSelect{ text = spell.text }
					label.widget.idle = tes3ui.getPalette("normal_color")
					label.widget.over = tes3ui.getPalette("normal_over_color")
					label.widget.pressed = tes3ui.getPalette("normal_pressed_color")
					label:register("help", function()
						spell:triggerEvent("help")
					end)
					label:register("mouseClick", function()
						spell:triggerEvent("mouseClick")
						magicMenu:destroy()
						local menuMulti = tes3ui.findMenu(tes3ui.registerID("MenuMulti"))
						local iconPath
						if menuMulti then
							local icon = menuMulti:findChild(tes3ui.registerID("MenuMulti_magic_icon"))
							if icon then
								iconPath = icon.contentPath
							end
							selectMagicToQuickKey(button, type, num, tes3.mobilePlayer.currentSpell, false, iconPath)
						end
					end)
				end
			end
		end
		spellList:createDivider()
		local itemLabel = spellList:createLabel{ text = tes3.findGMST(tes3.gmst.sMagicItem).value }
		itemLabel.color = { 0.875, 0.788, 0.624 }
		if itemsList then
			for _, item in pairs(itemsList.children) do
				if item.text then
					local label = spellList:createTextSelect{ text = item.text }
					label.widget.idle = tes3ui.getPalette("normal_color")
					label.widget.over = tes3ui.getPalette("normal_over_color")
					label.widget.pressed = tes3ui.getPalette("normal_pressed_color")
					label:register("help", function()
						item:triggerEvent("help")
					end)
					label:register("mouseClick", function()
						item:triggerEvent("mouseClick")
						magicMenu:destroy()
						selectMagicToQuickKey(button, type, num, tes3.mobilePlayer.currentEnchantedItem.object, true, nil)
					end)
				end
			end
		end


		local cancelBlock = magicMenu:createBlock()
		cancelBlock.widthProportional = 1
	--	cancelBlock.heightProportional = 1
		cancelBlock.height = 30
		cancelBlock.childAlignX = 1

		local cancelButton = cancelBlock:createButton{ text = tes3.findGMST(tes3.gmst.sCancel).value }
		cancelButton:register("mouseClick", closeMagicMenu)

		magicMenu:updateLayout()
		tes3ui.enterMenuMode(magicSelectid)
	end
end

local function inventoryFilter(e)	--item types that can be hot-keyed
	return (e.item.objectType ~= tes3.objectType.miscItem or e.item.isSoulGem)
end

local function onButton(e, button, type, num)
	if e.button == 0 then		--Inventory Menu Item
		tes3ui.showInventorySelectMenu{
			title = tes3.findGMST(tes3.gmst.sQuickMenu6).value,
			noResultsText = tes3.findGMST(tes3.gmst.sInventorySelectNoItems).value,
			filter = inventoryFilter,
			callback = function(e)
				quickItemSelected(e, button, type, num)
			end
		}
	elseif e.button == 1 then	--Magic Menu Item
		showMagicSelectMenu(button, type, num)
	elseif e.button == 2 then	--Delete QuickKey Item
		data[type][num].id = nil
		data[type][num].name = nil
		data[type][num].icon = nil
		data[type][num].isMagic = false
		data[type][num].isItem = false
		button:destroyChildren()
		updateIcon(button, type, num)
	end
end

local function openQuickKeySelect(button, type, num)
	if data[type][num].id == 0 then	--Hand to Hand
	else
		tes3.messageBox{
			message = tes3.findGMST(tes3.gmst.sQuickMenu1).value,
			buttons = {
				tes3.findGMST(tes3.gmst.sQuickMenu2).value,	--Inventory Menu Item
				tes3.findGMST(tes3.gmst.sQuickMenu3).value,	--Magic Menu Item
				tes3.findGMST(tes3.gmst.sQuickMenu4).value	--Delete QuickKey Item
			},
			callback = function(e)
				onButton(e, button, type, num)
			end
		}
	end
end

local lastId
local lastRow
local lastKey
local lastType
local function checkTooltip(e)
	if lastId then
		if lastRow then		--Items
			if e.object and e.object.id == lastId then
				lastId = nil
				event.unregister("uiObjectTooltip", checkTooltip)

				local menuInventory = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
				if menuInventory then
					local scrollPane = menuInventory:findChild(tes3ui.registerID("MenuInventory_scrollpane"))
					if scrollPane then
						local pane = scrollPane:findChild(tes3ui.registerID("PartScrollPane_pane"))
						if pane then
							pane.children[lastRow].children[lastKey]:triggerEvent("help")
							lastKey = nil
							lastType = nil
							lastRow = nil
						end
					end
				end
			end
		else				--Spells
			if e.spell and e.spell.id == lastId then
				lastId = nil
				event.unregister("uiSpellTooltip", checkTooltip)

				local menuMagic = tes3ui.findMenu(tes3ui.registerID("MenuMagic"))
				if menuMagic then
					local powersList = menuMagic:findChild(tes3ui.registerID("MagicMenu_power_names"))
					local spellsList = menuMagic:findChild(tes3ui.registerID("MagicMenu_spell_names"))
					if powersList and lastType == "power" then
						powersList.children[lastKey]:triggerEvent("help")
						lastKey = nil
						lastType = nil
						lastRow = nil
					elseif spellsList and lastType == "spell" then
						spellsList.children[lastKey]:triggerEvent("help")
						lastKey = nil
						lastType = nil
						lastRow = nil
					end
				end
			end
		end
	end
end

local function getTooltip(type, num)
	lastId = data[type][num].id
	if data[type][num].id == 0 then --Hand to Hand
	elseif data[type][num].isMagic and not data[type][num].isItem then	--spells
		lastRow = nil
		local menuMagic = tes3ui.findMenu(tes3ui.registerID("MenuMagic"))
		if menuMagic then
			local powersList = menuMagic:findChild(tes3ui.registerID("MagicMenu_power_names"))
			local spellsList = menuMagic:findChild(tes3ui.registerID("MagicMenu_spell_names"))
			if powersList or spellsList then
				event.unregister("uiSpellTooltip", checkTooltip)
				event.register("uiSpellTooltip", checkTooltip)
			end
			local found = false
			if powersList then
				for key, power in pairs(powersList.children) do
					if power.text then
						if lastId ~= data[type][num].id then
							found = true
							break
						else
							lastKey = key
							lastType = "power"
							power:triggerEvent("help")
						end
					end
				end
			end
			if spellsList and not found then
				for key, spell in pairs(spellsList.children) do
					if spell.text then
						if lastId ~= data[type][num].id then
							found = true
							break
						else
							lastKey = key
							lastType = "spell"
							spell:triggerEvent("help")
						end
					end
				end
				if lastId ~= data[type][num].id then
					found = true
				end
			end
			if not found then
				local toolTip = tes3ui.createTooltipMenu()
				toolTip:createLabel{ text = "You no longer have this spell" }
			end
		end
	elseif data[type][num].id ~= nil then		--Any Items
		if mwscript.getItemCount{ reference = tes3.player, item = data[type][num].id } > 0 then
			local menuInventory = tes3ui.findMenu(tes3ui.registerID("MenuInventory"))
			if menuInventory then
				local scrollPane = menuInventory:findChild(tes3ui.registerID("MenuInventory_scrollpane"))
				if scrollPane then
					local pane = scrollPane:findChild(tes3ui.registerID("PartScrollPane_pane"))
					if pane then
						event.unregister("uiObjectTooltip", checkTooltip)
						event.register("uiObjectTooltip", checkTooltip)
					end
					if pane then
						local object = tes3.getObject(data[type][num].id)
						local icon = "Icons\\"..object.icon
						for key1, row in pairs(pane.children) do
							for key2, item in pairs(row.children) do
								if lastId ~= data[type][num].id then
									break
								elseif item.children[1].contentPath == icon then
									lastRow = key1
									lastKey = key2
									lastType = "item"
									item:triggerEvent("help")
								end
							end
						end
					end
				end
			end
		else
			local toolTip = tes3ui.createTooltipMenu()
			local object = tes3.getObject(data[type][num].id)
			local name = "this item"
			if object and object.name then
				name = object.name
			end
			local text = tes3.findGMST(tes3.gmst.sQuickMenu5).value.." "..name
			toolTip:createLabel{ text = text }
		end
	end
end

local function closeQuickMenu()
	local vanillaMenu = tes3ui.findMenu(tes3ui.registerID("MenuQuick"))
	if not vanillaMenu then return end

	tes3ui.leaveMenuMode()
	vanillaMenu:destroy()
end

local function previousQuickMenu(quickMenu)
	currentQuickMenu = currentQuickMenu - 1
	if currentQuickMenu < 1 then
		currentQuickMenu = 9
	end

	for i = 1, 9 do
		quickMenu.children[i].visible = false
	end
	quickMenu.children[currentQuickMenu].visible = true
end

local function nextQuickMenu(quickMenu)
	currentQuickMenu = currentQuickMenu + 1
	if currentQuickMenu > 9 then
		currentQuickMenu = 1
	end

	for i = 1, 9 do
		quickMenu.children[i].visible = false
	end
	quickMenu.children[currentQuickMenu].visible = true
end

local function createQuickMenu(mainBlock, type)
	mainBlock.flowDirection = "top_to_bottom"
	mainBlock.autoHeight = true
	mainBlock.autoWidth = true
	mainBlock.maxWidth = 400
	mainBlock.childAlignX = 0.5

	local textBlock = mainBlock:createBlock()
	textBlock.flowDirection = "top_to_bottom"
	textBlock.childAlignX = 0.5
	textBlock.width = 400
--	textBlock.autoHeight = true
	textBlock.height = 73
	textBlock.paddingAllSides = 10
	textBlock.wrapText = true

	local mainLabel
	local quickButtonSelect
	if type == "quick_" or type == "quick2" or type == "quickH" then
		if type == "quick_" then mainLabel = "Quick Keys"			 		--Regular
		elseif type == "quick2" then mainLabel = "Double Tap Quick Keys"	--Double tap
		else mainLabel = "Hold Quick Keys" end			 					--Hold

		local mainLabelBlock = textBlock:createBlock()
		mainLabelBlock.height = 21
		mainLabelBlock.autoWidth = true
		mainLabelBlock:createLabel{ text = mainLabel }
	elseif type == "quickA" or type == "quickA2" or type == "quickAH" then
		if config.showAll then
			mainBlock.borderRight = 700
		end
		local mainLabelBlock = textBlock:createBlock()
		mainLabelBlock.flowDirection = "left_to_right"
	--	mainLabelBlock.autoHeight = false
		mainLabelBlock.height = 21
		mainLabelBlock.autoWidth = true

		if type == "quickA" then		 --Holding A
			mainLabel = "Quick Keys While Holding "
			mainLabelBlock:createLabel{ text = mainLabel }

			local buttonText
			if data.keyA == "DISABLED" then
				buttonText = "-Select Key-"
			else
				buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + data.keyA).value
			end
			quickButtonSelect = mainLabelBlock:createButton{ id = quickAid, text = buttonText }
			quickButtonSelect.borderAllSides = 0
			quickButtonSelect.borderLeft = 4
			quickButtonSelect.borderBottom = 4
		--	quickButtonSelect.autoHeight = false
		--	quickButtonSelect.height = 21
			quickButtonSelect:register("mouseClick", createKeyBinder)
		elseif type == "quickA2" then	--Holding A, Double tap
			if data.keyA == "DISABLED" then
				mainLabel = ("DISABLED")
			else
				mainLabel = ("Double Tap Quick Keys While Holding "..tes3.findGMST(tes3.gmst.sKeyName_00 + data.keyA).value)
			end
			mainLabelBlock:createLabel{ id = quickA2id, text = mainLabel }
		else						--Holding A, Hold
			if data.keyA == "DISABLED" then
				mainLabel = ("DISABLED")
			else
				mainLabel = ("Hold Quick Keys While Holding "..tes3.findGMST(tes3.gmst.sKeyName_00 + data.keyA).value)
			end
			mainLabelBlock:createLabel{ id = quickAHid, text = mainLabel }
		end
	else
		if config.showAll then
			mainBlock.borderLeft = 700
		end
		local mainLabelBlock = textBlock:createBlock()
		mainLabelBlock.flowDirection = "left_to_right"
	--	mainLabelBlock.autoHeight = false
		mainLabelBlock.height = 21
		mainLabelBlock.autoWidth = true

		if type == "quickB" then		 --Holding B
			mainLabel = "Quick Keys While Holding "
			mainLabelBlock:createLabel{ text = mainLabel }

			local buttonText
			if data.keyB == "DISABLED" then
				buttonText = "-Select Key-"
			else
				buttonText = tes3.findGMST(tes3.gmst.sKeyName_00 + data.keyB).value
			end
			quickButtonSelect = mainLabelBlock:createButton{ id = quickBid, text = buttonText }
			quickButtonSelect.borderAllSides = 0
			quickButtonSelect.borderLeft = 4
			quickButtonSelect.borderBottom = 4
		--	quickButtonSelect.autoHeight = false
		--	quickButtonSelect.height = 21
			quickButtonSelect:register("mouseClick", createKeyBinder)
		elseif type == "quickB2" then	--Holding B, Double tap
			if data.keyB == "DISABLED" then
				mainLabel = ("DISABLED")
			else
				mainLabel = ("Double Tap Quick Keys While Holding "..tes3.findGMST(tes3.gmst.sKeyName_00 + data.keyB).value)
			end
			mainLabelBlock:createLabel{ id = quickB2id, text = mainLabel }
		else						--Holding B, Hold
			if data.keyB == "DISABLED" then
				mainLabel = ("DISABLED")
			else
				mainLabel = ("Hold Quick Keys While Holding "..tes3.findGMST(tes3.gmst.sKeyName_00 + data.keyB).value)
			end
			mainLabelBlock:createLabel{ id = quickBHid, text = mainLabel }
		end
	end

	if type == "quick_" or config.showAll == false then
		local descriptionLabel = textBlock:createLabel{ text = tes3.findGMST(tes3.gmst.sQuickMenuInstruc).value }
		descriptionLabel.wrapText = true
	end

	local row1 = mainBlock:createBlock()
	row1.flowDirection = "left_to_right"
	row1.widthProportional = 1
	row1.childAlignX = 0.5
	row1.autoHeight = true

	for i=1, 5 do
		local button = row1:createThinBorder()
		setQuickButton(button, type, i)
		button:register("mouseOver", function() getTooltip(type, i) end)
		button:register("mouseClick", function() openQuickKeySelect(button, type, i) end)
	end

	local row2 = mainBlock:createBlock()
	row2.flowDirection = "left_to_right"
	row2.widthProportional = 1
	row2.childAlignX = 0.5
	row2.autoHeight = true
	row2.paddingBottom = 10


	for i=6, 9 do
		local button = row2:createThinBorder()
		setQuickButton(button, type, i)
		button:register("mouseOver", function() getTooltip(type, i) end)
		button:register("mouseClick", function() openQuickKeySelect(button, type, i) end)
	end

	if type == "quick_" then	--Hand to Hand and Ok button for top middle menu
		local button = row2:createThinBorder()
		setQuickButton(button, type, 10)
		button:register("mouseOver", function() getTooltip(type, 10) end)
		button:register("mouseClick", function() openQuickKeySelect(button, type, 10) end)
	end

	if type == "quick_" or config.showAll == false then
		local cancelBlock = mainBlock:createBlock()
		cancelBlock.widthProportional = 1
	--	cancelBlock.heightProportional = 1
		cancelBlock.height = 30
		cancelBlock.childAlignX = 1

		if config.showAll == false then
			local prevButton = cancelBlock:createButton{ text = "<<" }
			prevButton.borderAllSides = 0
			prevButton.height = 21
			prevButton.absolutePosAlignX = 0.1
			prevButton:register("mouseClick", function()
				previousQuickMenu(mainBlock.parent)
			end)
		end

		local cancelButton = cancelBlock:createButton{ text = tes3.findGMST(tes3.gmst.sOK).value }
		cancelButton.borderAllSides = 0
		cancelButton.borderRight = 35
		cancelButton:register("mouseClick", closeQuickMenu)

		if config.showAll == false then
			local nextButton = cancelBlock:createButton{ text = ">>" }
			nextButton.borderAllSides = 0
			nextButton.height = 21
			nextButton.absolutePosAlignX = 0.9
			nextButton:register("mouseClick", function()
				nextQuickMenu(mainBlock.parent)
			end)
		end
	end
end

local function quickMenuExit()
	local vanillaMenu = tes3ui.findMenu(tes3ui.registerID("MenuQuick"))
	if vanillaMenu then return end
	if (tes3ui.findMenu(quickMainid) ~= nil) then
		tes3ui.leaveMenuMode()	--Exit the new quick menu
		local quickMainMenu = tes3ui.findMenu(quickMainid)
		quickMainMenu:destroy()

		event.unregister("enterFrame", quickMenuExit)
	end
end

local function quickMenuOpen()
	if (tes3ui.findMenu(quick_id) ~= nil) then return end

	local vanillaMenu = tes3ui.findMenu(tes3ui.registerID("MenuQuick"))

	local isEmpty = true
	local slots = {"MenuQuick_Quick_One", "MenuQuick_Quick_Two", "MenuQuick_Quick_Three", "MenuQuick_Quick_Four", "MenuQuick_Quick_Five", "MenuQuick_Quick_Six", "MenuQuick_Quick_Seven", "MenuQuick_Quick_Eight", "MenuQuick_Quick_Nine"}
	for i=1, 9 do		--checks that the vanilla menu is empty
		local slot = vanillaMenu:findChild(tes3ui.registerID(slots[i]))
		if slot.children then
			if #slot.children >= 1 then
				if #slot.children[1].children >= 1 then
					print(i.." is not empty")
					isEmpty = false
					break
				end
			end
		end
	end

	if isEmpty == false then
		tes3.messageBox("Delete all Quick Keys from the vanilla Quick Key Menu before using Hotkeys Extended")
	else
		vanillaMenu.visible = false	--Hide the vanilla quick menu

		local quickMainMenu = tes3ui.createMenu{ id = quickMainid, fixedFrame = true }
		quickMainMenu.autoHeight = false
		quickMainMenu.autoWidth = false
		quickMainMenu.height = ( config.showAll and 840 ) or 250
		quickMainMenu.width = ( config.showAll and 1420 ) or 410

		local types = { "quick_", "quickH", "quick2", "quickA", "quickAH", "quickA2", "quickB", "quickBH", "quickB2" }
		local menuPositions = {
			{ 0.1, 0.5 },	-- quick_
			{ 0.5, 0.5 },	-- quickH
			{ 0.9, 0.5 },	-- quick2

			{ 0.1, 0.1 },	-- quickA
			{ 0.5, 0.1 },	-- quickAH
			{ 0.9, 0.1 },	-- quickA2

			{ 0.1, 0.9 },	-- quickB
			{ 0.5, 0.9 },	-- quickBH
			{ 0.9, 0.9 },	-- quickB2
		}
		for k, type in ipairs(types) do
			local quickBlock = quickMainMenu:createThinBorder()
			quickBlock.absolutePosAlignY = ( config.showAll and menuPositions[k][1] ) or 0.5
			quickBlock.absolutePosAlignX = ( config.showAll and menuPositions[k][2] ) or 0.5
			createQuickMenu(quickBlock, type)
			if not config.showAll and k ~= currentQuickMenu then
				quickBlock.visible = false
			end
		end

		quickMainMenu:updateLayout()
		tes3ui.enterMenuMode(quickMainid)
		event.register("enterFrame", quickMenuExit)
	end
end
event.register("uiActivated", quickMenuOpen, { filter = "MenuQuick" })

local function clearData(keybind)
	keybind.id = nil
	keybind.name = nil
	keybind.icon = nil
	keybind.isMagic = false
	keybind.isItem = false
end

local function validateData(keybind)
	keybind.id = keybind.id or nil
	keybind.name = keybind.name or nil	--for enchanted items
	keybind.icon = keybind.icon or nil
	keybind.isMagic = keybind.isMagic or false
	keybind.isItem = keybind.isItem or false

	if (type(keybind.id) == "string") then
		-- Clear the keybind if the data was removed.
		local object = tes3.getObject(keybind.id)
		if (object == nil) then
			mwse.log("Hotkey for object '%s' was removed; the object no longer exists.", keybind.id)
			clearData(keybind)
			return
		end
	end
end

local function loaded()
	lastWeaponEquipped = nil

	tes3.player.data.quickKeys = tes3.player.data.quickKeys or {}
	data = tes3.player.data.quickKeys

	data.quick_ = data.quick_ or {}		--Regular
	data.quick2 = data.quick2 or {}		--Double tap
	data.quickH = data.quickH or {}		--Hold

	data.keyA = data.keyA or tes3.scanCode.lShift
	data.quickA = data.quickA or {}		--Holding A
	data.quickA2 = data.quickA2 or {}	--Holding A, Double tap
	data.quickAH = data.quickAH or {}	--Holding A, Hold

	data.keyB = data.keyB or tes3.scanCode.lAlt
	data.quickB = data.quickB or {}		--Holding B
	data.quickB2 = data.quickB2 or {}	--Holding B, Double tap
	data.quickBH = data.quickBH or {}	--Holding B, Hold

	local types = { "quick_", "quick2", "quickH", "quickA", "quickA2", "quickAH", "quickB", "quickB2", "quickBH" }

	keys = {
		_ = {},
		A = {},
		B = {}
	}
	for i=1, 10 do
		keys["_"][i] = { double = false, hold = false }
		keys["A"][i] = { double = false, hold = false }
		keys["B"][i] = { double = false, hold = false }

		for _, type in ipairs(types) do
			data[type][i] = data[type][i] or {}
			validateData(data[type][i])
		end
	end
	data.quick_[10].id = 0
	print("[Quick Keys] Loaded")
end
event.register("loaded", loaded)

---------------------------------------------------------------------
-----------MCM-------------------------------------------------------
---------------------------------------------------------------------

local function setSliderLabelAsTenth(self)
	local newValue = ""

	if self.elements.slider then
		newValue = tostring( tonumber( self.elements.slider.widget.current + self.min ) / 10 )
	end
	self.elements.label.text = self.label .. ": " .. newValue
end

local function registerModConfig()
	local template = mwse.mcm.createTemplate("Hotkeys Extended")
	template:saveOnClose("hotkeys_extended", config)

	local page = template:createSideBarPage{
		label = "Settings",
		description = "Expands the vanilla Quick Menu by adding different hotkeys for holding or double tapping a button and when holding a specific button. All hotkeys use the same keys as in vanilla."
	}

	page:createSlider{
		label = "Hold/Double Tap Delay",
		description = "The time in seconds between key presses for it to be considered a double tap. Also changes the time that you need to hold a key down for the hold hotkey to be activated. Default: 0.4",
		max = 20,
		min = 1,
		step = 1,
		jump = 2,
		variable = mwse.mcm.createTableVariable{
			id = "holdDelay",
			table = config
		},
		postCreate = setSliderLabelAsTenth,
		updateValueLabel = setSliderLabelAsTenth
	}

	page:createOnOffButton{
		label = "Show All Menus",
		description = "Disabling this will show all menus on different pages/tabs that you can browse through. This should be disabled with lower resolutions or when using MGE XE UI scaling if the menus are not shown correctly.",
		variable = mwse.mcm.createTableVariable{
			id = "showAll",
			table = config
		}
	}

	page:createOnOffButton{
		label = "Alternative Item Icon Position in Quick Menu",
		description = "Changes the position of the regular item icons in the Quick Menu. If you are using a UI mod and some of the icons are not in the middle of the buttons, enable this option.",
		variable = mwse.mcm.createTableVariable{
			id = "itemIconPosition",
			table = config
		}
	}
	mwse.mcm.register(template)
end
event.register("modConfigReady", registerModConfig)
