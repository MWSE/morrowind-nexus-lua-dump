
local common = {}

common.numLoadouts = 9

function common.updateInfo()
    if not tes3.player then return end
    local accessorySlots = { [3]=true, [8]=true, [9]=true}
    for name, config in pairs(tes3.player.data.loadouts) do

        local message = string.format("%s:\n", ( config.name or name ) )
        --weapons
        message = message .. "\n  Оружие\n"
        for item in pairs(config.weaponList) do
            message = message .. string.format("    - %s\n", tes3.getObject(item).name )
        end
        --armor
        message = message .. "\n  Броня\n"
        for item in pairs(config.armorList) do
            message = message .. string.format("    - %s\n", tes3.getObject(item).name)
        end
        --clothing
        message = message .. "\n  Одежда\n"
        for item, slot in pairs(config.clothingList) do
            if not accessorySlots[slot] then
                message = message .. string.format("    - %s\n",  tes3.getObject(item).name)
            end
        end
        --accessories
        message = message .. "\n  Аксессуары\n"
        for item, slot in pairs(config.clothingList) do
            if accessorySlots[slot] then
                message = message .. string.format("    - %s\n",  tes3.getObject(item).name)
            end
        end

        config.loadoutInfo = message
        event.trigger("MCM:refresh")
        event.trigger("MCM:refresh")
    end
end

local mustWait = false
local waitTime = 0.2

function common.assignLoadout(self)
    --iterate equipped gear
    --Add to playerData
    tes3.player.data.loadouts = tes3.player.data.loadouts or {}
    local config = tes3.player.data.loadouts[self.id]
    config.weaponList = {}
    config.armorList = {}
    config.clothingList = {}

    if not config.enableLoadout then return end

    for i, stack in pairs(tes3.player.object.equipment) do

        local addWeapon = (
            config.includeWeapons and
            stack.object.objectType == tes3.objectType.weapon
        )
        if addWeapon then
            config.weaponList[stack.object.id] = stack.object.type
        end

        local addArmor = (
            config.includeArmor and
            stack.object.objectType == tes3.objectType.armor and
            stack.object.slot ~= tes3.armorSlot.shield
        )
        if addArmor then
            config.armorList[stack.object.id] = stack.object.slot
        end



        local addShield = (
            config.includeShield and
            stack.object.objectType == tes3.objectType.armor and
            stack.object.slot == tes3.armorSlot.shield
        )
        if addShield then
            config.armorList[stack.object.id] = stack.object.slot
        end

        local accessorySlots = { 3, 8, 9}
        local isAccessory
        for _, slot in ipairs(accessorySlots) do
            if stack.object.slot == slot then
                isAccessory = true
                break
            end
        end

        local addClothing = (
            config.includeClothing and
            stack.object.objectType == tes3.objectType.clothing and
            not isAccessory
        )

        if addClothing then
            config.clothingList[stack.object.id] = stack.object.slot
        end

        local addAccessory = (
            config.includeAccessories and
            stack.object.objectType == tes3.objectType.clothing and
            isAccessory
        )
        if addAccessory then
            config.clothingList[stack.object.id] = stack.object.slot
        end
    end

    common.updateInfo()

    tes3.messageBox("%s Комплект!", config.name)
end

function common.equipLoadout(loadout)
    if mustWait then return end
    if not loadout.enableLoadout then return end
    local accessorySlots = { [3]=true, [8]=true, [9]=true}

    local function equip(id)
        if tes3.player.object.inventory:contains(id) then
            tes3.mobilePlayer:equip({ item = id})
        end
    end

    local function equipWeapons()
        --Weapons
        for id in pairs(loadout.weaponList) do
            if id then
                if loadout.includeWeapons then
                    equip(id)
                end
            end
        end
    end

    local function equipArmor()
        --Armor
        for id, slot in pairs(loadout.armorList) do
            if slot ~= tes3.armorSlot.shield then
                if id then
                    if loadout.includeArmor then
                        equip(id)
                    end
                end
            else
                --Shield
                if id then
                    if loadout.includeShield then
                        equip(id)
                    end
                end
            end
        end
    end

    local function equipClothing()

        --Clothing
        for id, slot in pairs(loadout.clothingList) do
            local isAccessory = accessorySlots[slot]
            if isAccessory ~= true then
                if id then
                    if loadout.includeClothing then
                        equip(id)
                    end
                end
            end

        end
    end

    local function equipAccessories()
        --Clothing
        for id, slot in pairs(loadout.clothingList) do
            local isAccessory = accessorySlots[slot]
            if isAccessory == true then
                if id then
                    if loadout.includeAccessories then
                        equip(id)
                    end
                end
            end
        end
    end



    local function unequipWeapons()
        --Weapons
        for _, stack in pairs(tes3.player.object.equipment) do
            local id = loadout.weaponList[stack.object.id]
            if (not id) and loadout.unequipWeapons and stack.object.objectType == tes3.objectType.weapon then
                tes3.mobilePlayer:unequip({ item = stack.object })
            end
        end
    end

    local function unequipArmor()
        --Armor
        for _, stack in pairs(tes3.player.object.equipment) do
            local id = loadout.weaponList[stack.object.id]
            if stack.object.slot ~= tes3.armorSlot.shield then
                if (not id) and loadout.unequipArmor
                and (stack.object.objectType == tes3.objectType.armor)
                then
                    tes3.mobilePlayer:unequip({ item = stack.object })
                end
            else
                if (not id) and loadout.unequipShield
                and (stack.object.objectType == tes3.objectType.armor)
                then
                    tes3.mobilePlayer:unequip({ item = stack.object })
                end
            end
        end
    end

    local function unequipClothing()

        --Clothing
        for _, stack in pairs(tes3.player.object.equipment) do
            if stack.object.objectType == tes3.objectType.clothing then
                local isAccessory = accessorySlots[stack.object.slot]

                local id = loadout.clothingList[stack.object.id]

                if isAccessory ~= true then
                    if (not id) and  loadout.unequipClothing then
                        tes3.mobilePlayer:unequip({item = stack.object})
                    end
                end
            end
        end
    end

    local function unequipAccessories()
        --Accessories
        for _, stack in pairs(tes3.player.object.equipment) do
            if stack.object.objectType == tes3.objectType.clothing then
                local isAccessory = accessorySlots[stack.object.slot]

                local id = loadout.clothingList[stack.object.id]

                if isAccessory == true then
                    if (not id) and  loadout.unequipClothing then
                        tes3.mobilePlayer:unequip({item = stack.object})
                    end
                end
            end
        end
    end


    unequipAccessories()
    unequipWeapons()
    unequipArmor()
    unequipClothing()

    timer.frame.delayOneFrame(function()
        equipAccessories()
        equipWeapons()
        equipArmor()
        equipClothing()
    end)
end



function common.keyDown(e)
    if not tes3.menuMode() and tes3.player and tes3.player.data.loadouts then
        for loadoutNum, loadout in pairs (tes3.player.data.loadouts) do
            local hotKeyPressed = (
                loadout.hotkey and
                e.keyCode == loadout.hotkey.keyCode and
                not not e.isShiftDown == not not loadout.hotkey.isShiftDown and
                not not e.isControlDown == not not loadout.hotkey.isControlDown and
                not not e.isAltDown == not not loadout.hotkey.isAltDown
            )
            if hotKeyPressed then
                common.equipLoadout(loadout)
            end

            local assignKeyPressed =  (
                loadout.assignKey and
                e.keyCode == loadout.assignKey.keyCode and
                not not e.isShiftDown == not not loadout.assignKey.isShiftDown and
                not not e.isControlDown == not not loadout.assignKey.isControlDown and
                not not e.isAltDown == not not loadout.assignKey.isAltDown
            )
            if assignKeyPressed then
                common.assignLoadout({ id = loadoutNum })
            end
        end
    end
end

return common