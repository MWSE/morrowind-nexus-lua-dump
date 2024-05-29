--# ----------------------------------------------------------------------------------
--#
--# This will when the unique ring is equipped dress the player in a random set of clothing.
--# Note: 
--#	it will unequip any armour, weapon or shield and will also add a small random amount of gold.
--#
--# ----------------------------------------------------------------------------------

mwse.log("[What2Wear] Loaded successfully.")

local minGold = 100 -- Minimum amount of gold to add
local maxGold = 900 -- Maximum amount of gold to add

local ringID = "tw_what2wear_ring"

-- Replace and or add any item with any other valid item within each list, which can in this case include armour.
-- Define tables of clothing IDs for male and female characters
local maleClothingLists = {
    { "common_amulet_02", "common_ring_02", "common_belt_02", "common_shoes_02", "common_shirt_02", "common_pants_02" },
    { "common_amulet_03", "common_ring_03", "common_belt_03", "common_shoes_03", "common_shirt_03","common_pants_03" },
    { "expensive_amulet_02", "expensive_ring_02", "expensive_belt_02", "expensive_shoes_02", "expensive_shirt_02", "expensive_pants_02" },
    { "expensive_amulet_03", "expensive_ring_03", "expensive_belt_03", "expensive_shoes_03", "expensive_shirt_03", "expensive_pants_03" },
    { "exquisite_amulet_01", "exquisite_ring_02", "exquisite_belt_01", "exquisite_shoes_01", "exquisite_shirt_01", "exquisite_pants_01" },
    { "extravagant_amulet_01", "extravagant_ring_01", "extravagant_belt_01", "extravagant_shoes_01", "extravagant_shirt_01", "extravagant_pants_01" },
    { "extravagant_amulet_02", "extravagant_ring_02", "extravagant_belt_02", "extravagant_shoes_02", "extravagant_shirt_02", "extravagant_pants_02" },
    { "extravagant_robe_01_b", "extravagant_shoes_02" },
    { "common_robe_02_t", "common_shoes_02" }
}

local femaleClothingLists = {
    { "common_amulet_02", "common_ring_02", "common_belt_02", "common_shoes_02", "common_shirt_02", "common_glove_left_01", "common_glove_right_01", "common_skirt_02" },
    { "common_amulet_03", "common_ring_03", "common_belt_03", "common_shoes_03", "common_shirt_03", "common_skirt_03" },
    { "expensive_amulet_02", "expensive_ring_02", "expensive_belt_02", "expensive_shoes_02", "expensive_shirt_02", "expensive_glove_left_01", "expensive_glove_right_01", "expensive_skirt_02" },
    { "expensive_amulet_03", "expensive_ring_03", "expensive_belt_03", "expensive_shoes_03", "expensive_shirt_03", "expensive_glove_left_01", "expensive_glove_right_01", "expensive_skirt_03" },
    { "exquisite_amulet_01", "exquisite_ring_02", "exquisite_belt_01", "exquisite_shoes_01", "exquisite_shirt_01", "exquisite_skirt_01" },
    { "extravagant_amulet_01", "extravagant_ring_01", "extravagant_belt_01", "extravagant_shoes_01", "extravagant_shirt_01", "extravagant_glove_left_01", "extravagant_glove_right_01", "extravagant_skirt_01" },
    { "extravagant_amulet_02", "extravagant_ring_02", "extravagant_belt_02", "extravagant_shoes_02", "extravagant_shirt_02", "extravagant_glove_left_01", "extravagant_glove_right_01", "extravagant_skirt_02" },
    { "extravagant_robe_01_b", "extravagant_shoes_02" },
    { "common_robe_02_t", "common_shoes_02" }
}

-- local function writeToLogFile(message) -- no longer used, left it in for reference.
--     local logFileName = "tw_log_file.txt" -- Name of the log file
--     local file = io.open(logFileName, "a") -- Open the file in append mode
-- 
--     -- Check if the file was opened successfully
--     if file then
--         file:write(message .. "\n") -- Write the message to the file
--         file:close() -- Close the file
--     else
--         tes3.messageBox("Failed to open log file!")
--     end
-- end

local function setDoOnce(ref,Var)
    local refData = ref.data -- Crossing the C-Lua border result is usually not a bad idea.
    refData.What2Wear = refData.What2Wear or {} -- Force initializing the parent table.
    refData.What2Wear.doOnce = Var -- Actually set your value.
end
local function getDoOnce(ref)
    local refData = ref.data
    return refData.What2Wear and refData.What2Wear.doOnce
end

-- Function to generate a random amount of gold
local function generateRandomGold()
    return math.random(minGold, maxGold)
end

-- Function to generate a random clothing list based on player's sex
local function generateRandomClothingList()
    local player = tes3.player
    local clothingList
    if player.object.female then
        clothingList = femaleClothingLists[math.random(1, table.getn(femaleClothingLists))]
    else
        clothingList = maleClothingLists[math.random(1, table.getn(maleClothingLists))]
    end	
    return clothingList
end

-- Function to unequip any equipped weapon or shield  -- no longer used, left it in for reference.
-- local function unequipWeaponOrShield()
--     local player = tes3.mobilePlayer
-- 	
--     -- Iterate through the player's inventory
--     for _, stack in pairs(player.object.inventory) do
--         -- Check if the item is equipped
--         if stack.object.objectType == tes3.objectType.weapon or stack.object.objectType == tes3.objectType.armor then		
--             if stack.object.objectType == tes3.objectType.weapon then -- not sure wanted??? -- and player.weaponReady then
--                 -- Unequip the weapon
--                 player:unequip{ item = stack.object }
-- 			end			
--             if stack.object.objectType == tes3.objectType.armor and stack.object.slot == tes3.armorSlot.shield then
--                 -- Unequip the shield
--                 player:unequip{ item = stack.object }
--             end
--         end
--     end
--  end

-- Function to equip the clothing item
local function tw_equipClothing() --clothingList)
    local player = tes3.mobilePlayer
	local clothingList = generateRandomClothingList()	
    for _, clothingID in pairs(clothingList) do
        local clothing = tes3.getObject(clothingID)
        if clothing then
	            tes3.addItem{
			    reference  = player,
                item = clothing,
                playSound = false
            }
            tes3.mobilePlayer:equip{item = clothing}			
--mwse.log("clothingItem = %s", clothing)			
        end
    end
end

-- Function to remove all clothing items from the player
local function tw_removeAllClothing()
   local player = tes3.mobilePlayer
    -- Get the list of equipped items - appears to also remove weapons not sure about shields ???
	for _, stack in pairs(tes3.player.object.equipment) do
--mwse.log("equippeditem = %s", stack.object.id)
		player:unequip{ item = stack.object.id }
	end	

 end

-- Function to be called when the activator is activated
local function tw_What2Wear(e)
        local shouldEquip = math.random(10) -- == 1  -- Randomly decide whether to equip clothing or remove all clothing
--mwse.log("shouldEquip = %s", shouldEquip)	
	tw_removeAllClothing()	-- always start them off naked...
	if ( shouldEquip == 1 ) then
--		tw_removeAllClothing() -- now done every time.
		local goldAmount = generateRandomGold()
		tes3.addItem({ reference = tes3.player, item = "gold_001", count = goldAmount })
--		tes3.messageBox("You are now wearing your best birthday suit!")		
	else
        tw_equipClothing()
        tes3.messageBox("You are now wearing a random set of clothing.")
    end
end

--# ----------------------------------------------------------------------------------
--# ----------------------------------------------------------------------------------

-- Function to check if a ring is equipped and run the custom script
local function tw_checkEquippedRing()
    local player = tes3.mobilePlayer
--    if equipped then
        for _, stack in pairs(player.object.inventory) do
            if stack.object.id == ringID then
                tw_What2Wear(player)
                --player:unequip{ item = stack.object }
                return
            end
        end
--    end
end


-- Function to be called when the equipped state of an item changes
local function tw_onEquipped(e)
    if e.item.id == ringID then
        tw_checkEquippedRing()
    end
end

-------------------------------------------------------------------------
local function onLoadWhat2Wear(e)

--Only give them the teleportation key once.
  if getDoOnce(e.reference) ~= true then
    setDoOnce(e.reference, true)
    mwscript.addItem({ reference = tes3.player, item = "tw_what2wear_ring", count = 1 })
    tes3.messageBox("You have been given the What to Wear ring" )
  end
  
end

--Register the "loaded" event
event.register("loaded", onLoadWhat2Wear)

--Register the "equipped" event
event.register("equipped", tw_onEquipped)



