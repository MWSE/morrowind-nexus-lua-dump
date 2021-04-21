
local common = {}

common.numLoadouts = 9

function common.updateInfo()
    if not tes3.player then return end
    for name, config in pairs(tes3.player.data.loadouts) do

        local message = string.format("%s:\n", ( config.name or name ) )
        --weapons
        message = message .. "\n  Weapons\n"
        for slot, item in pairs(config.weaponList) do
            message = message .. string.format("    - %s\n", tes3.getObject(item).name )
        end
        --armor
        message = message .. "\n  Armor\n"
        for slot, item in pairs(config.armorList) do
            message = message .. string.format("    - %s\n", tes3.getObject(item).name)
        end
        --clothing
        message = message .. "\n  Clothing\n"
        for slot, item in pairs(config.clothingList) do
            message = message .. string.format("    - %s\n",  tes3.getObject(item).name)
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
            config.weaponList[tostring(stack.object.type)] = stack.object.id
        end

        local addArmor = (
            config.includeArmor and
            stack.object.objectType == tes3.objectType.armor and
            stack.object.slot ~= tes3.armorSlot.shield
        )
        if addArmor then
            config.armorList[tostring(stack.object.slot)] = stack.object.id
        end
 


        local addShield = ( 
            config.includeShield and
            stack.object.objectType == tes3.objectType.armor and
            stack.object.slot == tes3.armorSlot.shield
        )
        if addShield then
            config.armorList[tostring(stack.object.slot)] = stack.object.id
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
            config.clothingList[tostring(stack.object.slot)] = stack.object.id
        end 

        local addAccessory = (
            config.includeAccessories and
            stack.object.objectType == tes3.objectType.clothing and
            isAccessory
        )
        if addAccessory then
            config.clothingList[tostring(stack.object.slot)] = stack.object.id
        end
    end

    common.updateInfo()

    tes3.messageBox("%s Set!", config.name)
end

function common.equipLoadout(loadout)
    if mustWait then return end
    if not loadout.enableLoadout then return end
    local accessorySlots = { [3]=true, [8]=true, [9]=true}

    local function equip(id)
        if mwscript.getItemCount{ reference = tes3.player, item = id } > 0 then
            tes3.mobilePlayer:equip({ item = id})
        end
    end

    local function equipWeapons()
        --Weapons
        for _, slot in pairs(tes3.weaponType) do 
            local id = loadout.weaponList[tostring(slot)] 
            if id then 
                if loadout.includeWeapons then
                    equip(id)
                    break
                end
            end
        end
    end

    local function equipArmor()
        --Armor
        for i, slot in pairs(tes3.armorSlot) do 
            if slot ~= tes3.armorSlot.shield then
                local id = loadout.armorList[tostring(slot)] 
                if id then
                    if loadout.includeArmor then
                        equip(id)
                    end
                end
            else
                --Shield
                local id = loadout.armorList[tostring(slot)] 
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
        for _, slot in pairs(tes3.clothingSlot) do
            local isAccessory = accessorySlots[slot]

            local id = loadout.clothingList[tostring(slot)]

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
        for _, slot in pairs(tes3.clothingSlot) do
            local isAccessory = accessorySlots[slot]

            local id = loadout.clothingList[tostring(slot)]

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
        for i, slot in pairs(tes3.weaponType) do 
            local id = loadout.weaponList[tostring(slot)] 
            if (not id) and loadout.unequipWeapons then
                tes3.mobilePlayer:unequip({ type = tes3.objectType.weapon })
            end
        end
    end

    local function unequipArmor()
        --Armor
        for i, slot in pairs(tes3.armorSlot) do 
            if slot ~= tes3.armorSlot.shield then
                local id = loadout.armorList[tostring(slot)] 
                if (not id) and loadout.unequipArmor then 
                    --unequip armor
                    tes3.mobilePlayer:unequip({armorSlot = slot, playSound = false})
                end
            else
                --Shield
                local id = loadout.armorList[tostring(slot)] 
                if (not id) and loadout.unequipShield then 
                    --unequip shield
                    tes3.mobilePlayer:unequip({armorSlot = tes3.armorSlot.shield})
                end
            end
        end
    end
    local function unequipClothing()
        
        --Clothing
        for _, slot in pairs(tes3.clothingSlot) do
            local isAccessory = accessorySlots[slot]

            local id = loadout.clothingList[tostring(slot)]

            if isAccessory ~= true then
                if (not id) and  loadout.unequipClothing then
                    tes3.mobilePlayer:unequip({clothingSlot = slot})
                end
            end
        end
    end

    local function unequipAccessories()
        --Clothing
        for _, slot in pairs(tes3.clothingSlot) do
            local isAccessory = accessorySlots[slot]

            local id = loadout.clothingList[tostring(slot)]

            if isAccessory == true then
                if (not id) and loadout.unequipAccessories then 
                    tes3.mobilePlayer:unequip({clothingSlot = slot})
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