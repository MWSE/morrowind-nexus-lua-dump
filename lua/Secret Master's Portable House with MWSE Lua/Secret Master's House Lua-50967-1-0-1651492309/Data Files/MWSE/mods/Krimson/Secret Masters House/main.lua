local config

event.register("modConfigReady", function()
    require("Krimson.Secret Masters House.mcm")
	config  = require("Krimson.Secret Masters House.config")
end)

local function itemCheck(e)

--ALCHEMY STATION
    if config.alchemyStation then
        if tes3.getItemCount({ reference = tes3.player, item = "apparatus_sm_mortar_01"}) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "apparatus_sm_mortar_01", count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
        end
        if tes3.getItemCount({ reference = tes3.player, item = "apparatus_sm_alembic_01"}) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "apparatus_sm_alembic_01", count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
        end
        if tes3.getItemCount({ reference = tes3.player, item = "apparatus_sm_retort_01"}) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "apparatus_sm_retort_01", count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
        end
        if tes3.getItemCount({ reference = tes3.player, item = "apparatus_sm_calcinator_01"}) > 0 then
            tes3.removeItem({ reference = tes3.player, item = "apparatus_sm_calcinator_01", count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
        end
    end
end

local function onActivatedRef(e)

    if (e.activator ~= tes3.player) then
        return
    end

---INGREDIENT PICKER
    local ingredCont2 = tes3.getReference("AAA_ingredCont")
    local ingredientPicker = tes3.getReference("AAA_ingredient_scale")

    if (e.target == ingredientPicker) then
        for _, itemStack in pairs( tes3.getReference("AAA_ingredCont").object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count

            if ( sortItem.objectType == tes3.objectType.ingredient ) then
                tes3.removeItem({ reference = ingredCont2, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = false })
                tes3.addItem({ reference = tes3.player, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = true })
            end
        end
        tes3.messageBox("Done Taking Ingredients")
    end

--ALCHEMY STATION
    local alchemyStation = tes3.getReference("AAA_alchemyStation")

    if (e.target == alchemyStation) then
        if config.alchemyStation then
            tes3.addItem({ reference = tes3.player, item = "apparatus_sm_mortar_01", count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
            tes3.addItem({ reference = tes3.player, item = "apparatus_sm_alembic_01", count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
            tes3.addItem({ reference = tes3.player, item = "apparatus_sm_retort_01", count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
            tes3.addItem({ reference = tes3.player, item = "apparatus_sm_calcinator_01", count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
        end
        tes3.showAlchemyMenu()
    end

--TRAINING CHESTS
    local trainingChest = tes3.getReference("AAA_training_chest")
    local trainingChest02 = tes3.getReference("AAA_training_chest_02")
    local playerSneaking = tes3.mobilePlayer.isSneaking
    local pcSecurity = tes3.mobilePlayer.security.base

    if config.lockChest then
        if (e.target == trainingChest) then
            if playerSneaking then
                e.block = true
                if pcSecurity >= 100 then
                    tes3.lock({ reference = trainingChest, level = 100 })
                elseif pcSecurity >= 90 then
                    tes3.lock({ reference = trainingChest, level = 90 })
                elseif pcSecurity >= 80 then
                    tes3.lock({ reference = trainingChest, level = 80 })
                elseif pcSecurity >= 70 then
                    tes3.lock({ reference = trainingChest, level = 70 })
                elseif pcSecurity >= 60 then
                    tes3.lock({ reference = trainingChest, level = 60 })
                elseif pcSecurity >= 50 then
                    tes3.lock({ reference = trainingChest, level = 50 })
                elseif pcSecurity >= 40 then
                    tes3.lock({ reference = trainingChest, level = 40 })
                elseif pcSecurity >= 30 then
                    tes3.lock({ reference = trainingChest, level = 30 })
                elseif pcSecurity >= 20 then
                    tes3.lock({ reference = trainingChest, level = 20 })
                elseif pcSecurity >= 10 then
                    tes3.lock({ reference = trainingChest, level = 10 })
                end
            end
        end
    end

    if config.trapChest then
        if (e.target == trainingChest02) then
            if playerSneaking then
                e.block = true
                tes3.setTrap({reference = trainingChest02, spell = "trap_silence00" })
            end
        end
    end

--SORTERS
    local magicLamp = tes3.getObject("AAA_magic_lamp_01")
    local bookCont = tes3.getReference("AAA_bookCont")
    local potionCont = tes3.getReference("AAA_potionCont")
    local weapCont = tes3.getReference("AAA_weaponCont")
    local ingredCont = tes3.getReference("AAA_ingredCont")
    local armorCont = tes3.getReference("AAA_armorCont")
    local toolCont = tes3.getReference("AAA_toolCont")
    local apparatusCont = tes3.getReference("AAA_apparatusCont")
    local miscCont = tes3.getReference("AAA_miscCont")
    local clothesCont = tes3.getReference("AAA_clothesCont")

    if (e.target.object == tes3.getObject("AAA_sorter_potion")) then
        for _, itemStack in pairs( tes3.player.object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count

            if ( sortItem.objectType == tes3.objectType.alchemy ) then
                tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                tes3.addItem({ reference = potionCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
            end
        end
        tes3.messageBox("Done Sorting Potions")
    end

    if (e.target.object == tes3.getObject("AAA_sorter_apparatus")) then
        for _, itemStack in pairs( tes3.player.object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count

            if ( sortItem.objectType == tes3.objectType.apparatus ) then
                tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                tes3.addItem({ reference = apparatusCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
            end
        end
        tes3.messageBox("Done Sorting Apparatuses")
    end

    if (e.target.object == tes3.getObject("AAA_sorter_armor")) then
        for _, itemStack in pairs( tes3.player.object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count
            local itemEquipped = tes3.player.object:hasItemEquipped(sortItem.id)

            if ( sortItem.objectType == tes3.objectType.armor ) then
                if itemEquipped then
                    while itemCount > 1 do
                        tes3.removeItem({ reference = tes3.player, item = sortItem, count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
                        tes3.addItem({ reference = armorCont, item = sortItem, count = 1, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                        itemCount = itemCount - 1
                    end
                else
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = armorCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
        end
        tes3.messageBox("Done Sorting Armor")
    end

    if (e.target.object == tes3.getObject("AAA_sorter_book")) then
        for _, itemStack in pairs( tes3.player.object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count

            if ( sortItem.objectType == tes3.objectType.book ) then
                tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                tes3.addItem({ reference = bookCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
            end
        end
        tes3.messageBox("Done Sorting Books and Scrolls")
    end

    if (e.target.object == tes3.getObject("AAA_sorter_clothes")) then
        for _, itemStack in pairs( tes3.player.object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count
            local itemEquipped = tes3.player.object:hasItemEquipped(sortItem.id)

            if ( sortItem.objectType == tes3.objectType.clothing ) then
                if sortItem.id ~= magicLamp.id then
                    if itemEquipped then
                        while itemCount > 1 do
                            tes3.removeItem({ reference = tes3.player, item = sortItem, count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
                            tes3.addItem({ reference = clothesCont, item = sortItem, count = 1, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                            itemCount = itemCount - 1
                        end
                    else
                        tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                        tes3.addItem({ reference = clothesCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                    end
                end
            end
        end
        tes3.messageBox("Done Sorting Clothing")
    end

    if (e.target.object == tes3.getObject("AAA_sorter_ingred")) then
        for _, itemStack in pairs( tes3.player.object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count

            if ( sortItem.objectType == tes3.objectType.ingredient ) then
                tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                tes3.addItem({ reference = ingredCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
            end
        end
        tes3.messageBox("Done Sorting Ingredients")
    end

    if (e.target.object == tes3.getObject("AAA_sorter_misc")) then
        for _, itemStack in pairs( tes3.player.object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count

            if ( sortItem.objectType == tes3.objectType.miscItem ) then
                if not sortItem.isGold then
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = miscCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
        end
        tes3.messageBox("Done Sorting Misc Items")
    end

    if (e.target.object == tes3.getObject("AAA_sorter_tool")) then
        for _, itemStack in pairs( tes3.player.object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count

            if ( sortItem.objectType == tes3.objectType.repairItem ) then
                tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                tes3.addItem({ reference = toolCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
            end
            if ( sortItem.objectType == tes3.objectType.light ) then
                tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                tes3.addItem({ reference = toolCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
            end
            if ( sortItem.objectType == tes3.objectType.lockpick ) then
                tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                tes3.addItem({ reference = toolCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
            end
            if ( sortItem.objectType == tes3.objectType.probe ) then
                tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                tes3.addItem({ reference = toolCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
            end
        end
        tes3.messageBox("Done Sorting Tools")
    end

    if (e.target.object == tes3.getObject("AAA_sorter_weapon")) then
        for _, itemStack in pairs( tes3.player.object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count
            local itemEquipped = tes3.player.object:hasItemEquipped(sortItem.id)

            if ( sortItem.objectType == tes3.objectType.ammunition ) then
                if itemEquipped then
                    while itemCount > 1 do
                        tes3.removeItem({ reference = tes3.player, item = sortItem, count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
                        tes3.addItem({ reference = weapCont, item = sortItem, count = 1, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                        itemCount = itemCount - 1
                    end
                else
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = weapCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
            if ( sortItem.objectType == tes3.objectType.weapon ) then
                if itemEquipped then
                    while itemCount > 1 do
                        tes3.removeItem({ reference = tes3.player, item = sortItem, count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
                        tes3.addItem({ reference = weapCont, item = sortItem, count = 1, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                        itemCount = itemCount - 1
                    end
                else
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = weapCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
        end
        tes3.messageBox("Done Sorting Weapons and Ammo")
    end
--MAIN SORTER
    if (e.target.object == tes3.getObject("AAA_sorter_all")) then

        for _, itemStack in pairs( tes3.player.object.inventory ) do

            local sortItem = itemStack.object
            local itemCount = itemStack.count
            local itemEquipped = tes3.player.object:hasItemEquipped(sortItem.id)

            --INGREDIENTS
            if config.sortingredient then
                if ( sortItem.objectType == tes3.objectType.ingredient ) then
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = ingredCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
            --BOOKS/SCROLLS
            if config.sortbook then
                if ( sortItem.objectType == tes3.objectType.book ) then
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = bookCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
            --POTIONS
            if config.sortalchemy then
                if ( sortItem.objectType == tes3.objectType.alchemy ) then
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = potionCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
            --AMMO
            if config.sortammunition then
                if ( sortItem.objectType == tes3.objectType.ammunition ) then
                    if itemEquipped then
                        while itemCount > 1 do
                            tes3.removeItem({ reference = tes3.player, item = sortItem, count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
                            tes3.addItem({ reference = weapCont, item = sortItem, count = 1, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                            itemCount = itemCount - 1
                        end
                    else
                        tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                        tes3.addItem({ reference = weapCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                    end
                end
            end
            --APPARATUS
            if config.sortapparatus then
                if ( sortItem.objectType == tes3.objectType.apparatus ) then
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = apparatusCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
            --LIGHTS
            if config.sortlight then
                if ( sortItem.objectType == tes3.objectType.light ) then
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = toolCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
            --LOCKPICKS
            if config.sortlockpick then
                if ( sortItem.objectType == tes3.objectType.lockpick ) then
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = toolCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
            --PROBES
            if config.sortprobe then
                if ( sortItem.objectType == tes3.objectType.probe ) then
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = toolCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
            --REPAIR
            if config.sortrepairItem then
                if ( sortItem.objectType == tes3.objectType.repairItem ) then
                    tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                    tes3.addItem({ reference = toolCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                end
            end
            --MISC
            if config.sortmiscItem then
                if ( sortItem.objectType == tes3.objectType.miscItem ) then
                    if not sortItem.isGold then
                        tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                        tes3.addItem({ reference = miscCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                    end
                end
            end
            --WEAPONS
            if config.sortweapon then
                if ( sortItem.objectType == tes3.objectType.weapon ) then
                    if itemEquipped then
                        while itemCount > 1 do
                            tes3.removeItem({ reference = tes3.player, item = sortItem, count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
                            tes3.addItem({ reference = weapCont, item = sortItem, count = 1, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                            itemCount = itemCount - 1
                        end
                    else
                        tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                        tes3.addItem({ reference = weapCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                    end
                end
            end
            --ARMOR
            if config.sortarmor then
                if ( sortItem.objectType == tes3.objectType.armor ) then
                    if itemEquipped then
                        while itemCount > 1 do
                            tes3.removeItem({ reference = tes3.player, item = sortItem, count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
                            tes3.addItem({ reference = armorCont, item = sortItem, count = 1, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                            itemCount = itemCount - 1
                        end
                    else
                        tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                        tes3.addItem({ reference = armorCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                    end
                end
            end
            --CLOTHING
            if config.sortclothing then
                if ( sortItem.objectType == tes3.objectType.clothing ) then
                    if sortItem.id ~= magicLamp.id then
                        local itemEquipped = tes3.player.object:hasItemEquipped(sortItem.id)
                        if itemEquipped then
                            while itemCount > 1 do
                                tes3.removeItem({ reference = tes3.player, item = sortItem, count = 1, playSound = false, reevaluateEquipment = false, updateGUI = true })
                                tes3.addItem({ reference = clothesCont, item = sortItem, count = 1, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                                itemCount = itemCount - 1
                            end
                        else
                            tes3.removeItem({ reference = tes3.player, item = sortItem, count = itemCount, playSound = false, reevaluateEquipment = false, updateGUI = true })
                            tes3.addItem({ reference = clothesCont, item = sortItem, count = itemCount, limit = false, playSound = false, reevaluateEquipment = false, updateGUI = false })
                        end
                    end
                end
            end
        end
        tes3.messageBox("Done Sorting Everything")
    end
end

local function onTrapDisarm(e)

	local secretProbe = tes3.getObject("probe_secretmaster_02")
	local currentTool = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.probe })

    if e.tool == secretProbe then
        currentTool.itemData.condition = 25
    end
end

local function onLockPick(e)

	local secretPick = tes3.getObject("pick_secretmaster_02")
	local currentTool = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.lockpick })

    if e.tool == secretPick then
        currentTool.itemData.condition = 25
    end
end

local function onUiObjectTooltip(e)

	local secretHammer = tes3.getObject("repair_secretmaster_02")
	local secretProbe = tes3.getObject("probe_secretmaster_02")
	local secretPick = tes3.getObject("pick_secretmaster_02")

	if e.object == secretHammer then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == secretProbe then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	elseif e.object == secretPick then
		local use = e.tooltip:findChild(tes3ui.registerID("HelpMenu_uses"))
		if use then
			use.text = "Uses: Unlimited"
			e.tooltip:updateLayout()
		end
	else
		return
	end
end

local function onInitialized(e)

    event.register("trapDisarm", onTrapDisarm)
	event.register("lockPick", onLockPick)
	event.register("uiObjectTooltip", onUiObjectTooltip)
    event.register("simulate", itemCheck)
    event.register("activate", onActivatedRef)
    print("Secret Master's House Initialized")
end

event.register("initialized", onInitialized)