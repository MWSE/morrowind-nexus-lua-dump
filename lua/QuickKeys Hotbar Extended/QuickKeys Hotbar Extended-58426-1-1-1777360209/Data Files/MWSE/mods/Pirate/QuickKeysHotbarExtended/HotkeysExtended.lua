local i18n = mwse.loadTranslations("Pirate.QuickKeysHotbarExtended")
local config = require("Pirate.QuickKeysHotbarExtended.config")
local common = require("Pirate.QuickKeysHotbarExtended.common")
local types = config.panelNames
local log = mwse.Logger.new()
local data
local quickMainid = tes3ui.registerID("vir_quickkeys:quickMain")
local lastWeaponEquipped

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
									common.isProgrammaticClick = true -- флаг программного клика мыши
									power:triggerEvent("mouseClick")
									common.isProgrammaticClick = false
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
									common.isProgrammaticClick = true -- флаг программного клика мыши
									spell:triggerEvent("mouseClick")
									common.isProgrammaticClick = false
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

local function keyDown(e)
	if not tes3.menuMode() then
		local modifierKey2 = tes3.worldController.inputController:isKeyDown(config.mcm.modifierKey2.keyCode)
		local modifierKey3 = tes3.worldController.inputController:isKeyDown(config.mcm.modifierKey3.keyCode)
		for i=1, 10 do
			local key = "quick"..i
			if (e.keyCode == tes3.getInputBinding(tes3.keybind[key]).code) and (tes3.getInputBinding(tes3.keybind[key]).device ~= 1) then
				if modifierKey2 and not modifierKey3 then
					quickEquip("quick2", i)
				elseif modifierKey3 and not modifierKey2 then
					quickEquip("quickH", i)
				else
					quickEquip("quick_", i)
				end
			end
		end
	end
end
event.register("keyDown", keyDown)

local function mouseDown(e)
	if not tes3.menuMode() then
		local modifierKey2 = tes3.worldController.inputController:isKeyDown(config.mcm.modifierKey2.keyCode)
		local modifierKey3 = tes3.worldController.inputController:isKeyDown(config.mcm.modifierKey3.keyCode)
		for i=1, 10 do
			local key = "quick"..i
			if (e.button == tes3.getInputBinding(tes3.keybind[key]).code) and (tes3.getInputBinding(tes3.keybind[key]).device == 1) then
				if modifierKey2 and not modifierKey3 then
					quickEquip("quick2", i)
				elseif modifierKey3 and not modifierKey2 then
					quickEquip("quickH", i)
				else
					quickEquip("quick_", i)
				end
			end
		end
	end
end
event.register("mouseButtonDown", mouseDown)

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
				iconPath = "Icons\\" .. data[type][num].icon
			else
				iconPath = "Icons\\"..object.icon
			end
			if iconPath then
				button.borderAllSides = 4
				button.paddingAllSides = 8

				local borderPath
				if data[type][num].isMagic and not data[type][num].isItem then
					-- Чистое заклинание/способность
					borderPath = "Textures\\menu_icon_select_magic.tga"
				elseif not data[type][num].isMagic and not data[type][num].isItem and object.enchantment ~= nil then
					-- Зачарованный предмет, назначенный как предмет
					borderPath = "Textures\\menu_icon_magic_barter.tga"
				elseif object.enchantment == nil then
					-- Обычный предмет без зачарования
					borderPath = "Textures\\menu_icon_barter.tga"
					button.paddingAllSides = 6
				else
					-- Зачарованный предмет, назначенный как магия
					borderPath = "Textures\\menu_icon_select_magic_magic.tga"
				end

				local barterIcon = button:createImage{ path = borderPath }
				barterIcon.widthProportional = 1
				barterIcon.heightProportional = 1
				barterIcon.childAlignX = 0.0
				barterIcon.childAlignY = 0.0
				barterIcon.consumeMouseEvents = false

				if (not data[type][num].isMagic) or data[type][num].isItem then
					local shadowIcon = barterIcon:createImage{ path = iconPath }
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
    if e.itemData then
        data[type][num].savedItemData = {
            charge = e.itemData.charge,
            condition = e.itemData.condition,
            count = e.itemData.count,
            timeLeft = e.itemData.timeLeft,
            --soul = e.itemData.soul and e.itemData.soul.id,
        }
    end
	data[type][num].name = nil
	data[type][num].icon = nil
	data[type][num].isMagic = false
	data[type][num].isItem = false
	button:destroyChildren()
	updateIcon(button, type, num)
end

local function selectMagicToQuickKey(button, type, num, object, isItem, iconPath, itemData)
	if not object then return end
	if not object.id then return end
	data[type][num].id = object.id
    if itemData then
        data[type][num].savedItemData = {
            charge = itemData.charge,
            condition = itemData.condition,
            count = itemData.count,
            timeLeft = itemData.timeLeft,
            --soul = itemData.soul and itemData.soul.id,
        }
end
	if isItem then
		data[type][num].name = object.name
	else
		data[type][num].name = nil
	end
	data[type][num].icon = iconPath
	data[type][num].isMagic = true
	data[type][num].isItem = isItem
	button:destroyChildren()
	updateIcon(button, type, num)
end

local function inventoryFilter(e)
	return (e.item.objectType ~= tes3.objectType.miscItem or e.item.isSoulGem)
end

local function onButton(e, button, type, num)
	if e.button == 0 then
		tes3ui.showInventorySelectMenu{
			title = tes3.findGMST(tes3.gmst.sQuickMenu6).value,
			noResultsText = tes3.findGMST(tes3.gmst.sInventorySelectNoItems).value,
			filter = inventoryFilter,
			callback = function(e)
				quickItemSelected(e, button, type, num)
			end
		}
elseif e.button == 1 then
    tes3ui.showMagicSelectMenu{
        title = tes3.findGMST(tes3.gmst.sMagicSelectTitle).value,
        selectSpells = true,
        selectPowers = true,
        selectEnchanted = true,
        callback = function(params)
            if params.spell then
                local iconPath = params.spell.effects[1].object.bigIcon
                selectMagicToQuickKey(button, type, num, params.spell, false, iconPath)
            elseif params.item then
                selectMagicToQuickKey(button, type, num, params.item, true, nil, params.itemData)
            end
        end
    }
	elseif e.button == 2 then
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
	if data[type][num].id == 0 then
	else
		tes3.messageBox{
			message = tes3.findGMST(tes3.gmst.sQuickMenu1).value,
			buttons = {
				tes3.findGMST(tes3.gmst.sQuickMenu2).value,
				tes3.findGMST(tes3.gmst.sQuickMenu3).value,
				tes3.findGMST(tes3.gmst.sQuickMenu4).value
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
		if lastRow then
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
		else
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
	if data[type][num].id == 0 then
	elseif data[type][num].isMagic and not data[type][num].isItem then
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
	elseif data[type][num].id ~= nil then
        local item = tes3.getObject(data[type][num].id)
        if item then
            local itemData = common.getItemData(item.id)
            tes3ui.createTooltipMenu({ item = item, itemData = itemData })
        end
    end
end

local function closeQuickMenu()
	local vanillaMenu = tes3ui.findMenu(tes3ui.registerID("MenuQuick"))
	if not vanillaMenu then return end

	tes3ui.leaveMenuMode()
	vanillaMenu:destroy()
end

local function createQuickMenu(mainBlock, type)
	mainBlock.flowDirection = "top_to_bottom"
	mainBlock.autoHeight = true
	mainBlock.autoWidth = true
	mainBlock.childAlignX = 0.5

	local textBlock = mainBlock:createBlock()
	textBlock.flowDirection = "top_to_bottom"
	textBlock.childAlignX = 0.5
	textBlock.autoHeight = true
	textBlock.autoWidth = true 
	textBlock.paddingAllSides = 5
	textBlock.wrapText = true

	local mainLabel
	if type == "quick_" then 
		mainLabel = i18n("HotBar1.Label")
	elseif type == "quick2" then 
		mainLabel = i18n("HotBar2.Label", {modifierKey = tes3.getKeyName(config.mcm.modifierKey2.keyCode) or "2."})
	else
		mainLabel = i18n("HotBar3.Label", {modifierKey = tes3.getKeyName(config.mcm.modifierKey3.keyCode) or "3."})
	end

	local mainLabelBlock = textBlock:createBlock()
	mainLabelBlock.autoHeight = true
	mainLabelBlock.autoWidth = true
	mainLabelBlock:createLabel{ text = mainLabel }

	local row1 = mainBlock:createBlock()
	row1.flowDirection = "left_to_right"
	row1.widthProportional = 1
	row1.childAlignX = 0.5
	row1.autoHeight = true
	row1.autoWidth = true

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

	for i=6, 9 do
		local button = row2:createThinBorder()
		setQuickButton(button, type, i)
		button:register("mouseOver", function() getTooltip(type, i) end)
		button:register("mouseClick", function() openQuickKeySelect(button, type, i) end)
	end

	if type == "quick_" then
		local button = row2:createThinBorder()
		setQuickButton(button, type, 10)
		button:register("mouseOver", function() getTooltip(type, 10) end)
		button:register("mouseClick", function() openQuickKeySelect(button, type, 10) end)
	end
end

local function quickMenuExit()
	local vanillaMenu = tes3ui.findMenu(tes3ui.registerID("MenuQuick"))
	if vanillaMenu then return end
	if (tes3ui.findMenu(quickMainid) ~= nil) then
		tes3ui.leaveMenuMode()
		local quickMainMenu = tes3ui.findMenu(quickMainid)
		quickMainMenu:destroy()

		event.unregister("enterFrame", quickMenuExit)
	end
end

local function quickMenuOpen()
	if (tes3ui.findMenu(quickMainid) ~= nil) then return end

	local vanillaMenu = tes3ui.findMenu(tes3ui.registerID("MenuQuick"))
	if not vanillaMenu then return end

	local isEmpty = true
	local slots = {"MenuQuick_Quick_One", "MenuQuick_Quick_Two", "MenuQuick_Quick_Three", "MenuQuick_Quick_Four", "MenuQuick_Quick_Five", "MenuQuick_Quick_Six", "MenuQuick_Quick_Seven", "MenuQuick_Quick_Eight", "MenuQuick_Quick_Nine"}
	for i=1, 9 do
		local slot = vanillaMenu:findChild(tes3ui.registerID(slots[i]))
		if slot and slot.children then
			if #slot.children >= 1 then
				if slot.children[1] and slot.children[1].children and #slot.children[1].children >= 1 then
                    log:info(i.." is not empty")
					isEmpty = false
					break
				end
			end
		end
	end

	if isEmpty == false then
		tes3.messageBox(i18n("HotBar.message.VanillaNotEmpty"))
	else
		vanillaMenu.visible = false

		local quickMainMenu = tes3ui.createMenu{ id = quickMainid, fixedFrame = true }
		quickMainMenu.autoHeight = true
		quickMainMenu.autoWidth = true
		quickMainMenu.absolutePosAlignX = 0.5
		quickMainMenu.absolutePosAlignY = 0.5
		
		local titleBlock = quickMainMenu:createBlock()
		titleBlock.flowDirection = "top_to_bottom"
		titleBlock.autoHeight = true
		titleBlock.widthProportional = 1
		titleBlock.childAlignX = 0.5
		titleBlock.paddingTop = 5
		
		local titleLabel = titleBlock:createLabel{ text = tes3.findGMST(tes3.gmst.sQuickMenuTitle).value }
		titleLabel.color = tes3ui.getPalette("header_color")
		
		local descBlock = quickMainMenu:createBlock()
		descBlock.flowDirection = "top_to_bottom"
		descBlock.autoHeight = true
		descBlock.widthProportional = 1
		descBlock.childAlignX = 0.5
		descBlock.paddingAllSides = 5
		
		local descLabel = descBlock:createLabel{ text = tes3.findGMST(tes3.gmst.sQuickMenuInstruc).value }
        descLabel.widthProportional = 1
		descLabel.wrapText = true
        descLabel.autoWidth = true
		
		local container = quickMainMenu:createBlock()
		container.flowDirection = "top_to_bottom"
		container.autoHeight = true
		container.autoWidth = true
		container.paddingAllSides = 5
		container.childAlignX = 0.5
		
		for _, type in ipairs(types) do
			local quickBlock = container:createThinBorder()
			quickBlock.autoHeight = true
			quickBlock.autoWidth = true
			quickBlock.paddingAllSides = 10
			createQuickMenu(quickBlock, type)
			
			local spacer = container:createBlock()
			spacer.height = 10
			spacer.widthProportional = 1

		end

		local okBlock = container:createBlock()
		okBlock.widthProportional = 1
		okBlock.autoHeight = true
		okBlock.childAlignX = 1
		okBlock.paddingRight = 5

		local okButton = okBlock:createButton{ text = tes3.findGMST(tes3.gmst.sOK).value }
		okButton:register("mouseClick", closeQuickMenu)

		quickMainMenu:updateLayout()
		tes3ui.enterMenuMode(quickMainid)
		event.register("enterFrame", quickMenuExit)
	end
end
event.register("uiActivated", quickMenuOpen, { filter = "MenuQuick" })

local function clearData(keybind)
	keybind.id = nil
    keybind.savedItemData = nil
	keybind.name = nil
	keybind.icon = nil
	keybind.isMagic = false
	keybind.isItem = false
end

local function validateData(keybind)
	keybind.id = keybind.id or nil
    keybind.savedItemData = keybind.savedItemData or nil
	keybind.name = keybind.name or nil
	keybind.icon = keybind.icon or nil
	keybind.isMagic = keybind.isMagic or false
	keybind.isItem = keybind.isItem or false

	if (type(keybind.id) == "string") then
		local object = tes3.getObject(keybind.id)
		if (object == nil) then
            log:info("Hotkey for object '%s' was removed; the object no longer exists.", keybind.id)
			clearData(keybind)
			return
		end
	end
end

local function loaded()
	lastWeaponEquipped = nil

	tes3.player.data.quickKeys = tes3.player.data.quickKeys or {}
	data = tes3.player.data.quickKeys

	data.quick_ = data.quick_ or {}
	data.quick2 = data.quick2 or {}
	data.quickH = data.quickH or {}

	for i=1, 10 do
		for _, type in ipairs(types) do
			data[type][i] = data[type][i] or {}
			validateData(data[type][i])
		end
	end
	data.quick_[10].id = 0
    log:info("Quick Keys Extended Loaded")
end
event.register("loaded", loaded)
