--[[

"Cloud Storage Warehouse" v1.0
A cloud storage system a lua mod.
By 
The Wanderer

This is the base for a modder's cross-mod resource for fast, safe, storage from anywhere in Morrowind, That adds auto-sorting of Items.
It does not however add containers unless you have a supported mod. 

To better understand what this mod does.
Try my Cloud Storage for Inns and Tavern's :- Make link to mod
and/or My player home The Wanderer’s Lodge.
and/or My version of Rethan Manor.


The Cloud Storage Warehouse adds a cloud storage layer to Morrowind.
12 Primary Storage displays provide secure, cross-mod storage, accessible through a wide variety of highly automated and attractive activators. 
These activators function just like regular chests in-game, with many styles to fit any decor and playing style. 
Whether you want OCD levels of dedicated containers, a single auto sort chest, the Cloud Storage Warehouse has you covered.

All stored items are held safely as long as this mod is active.

The Panic! menu button will return all stored items from all stores to your inventory in one click. (Referernce to The Hitchhiker's guide to the galaxy)

Requirements:
Bloodmoon, Tribunal
MGE XE

Installation Instructions:
This main file is required for all mods that want to use this system.
Copy all the mods content into your Data Files folder

Modders:
To use this system in your own mods is simplicity itself.
All that is needed is to add one or more of the included activators anywhere you want them.
You can find copies of them all in the test cell tw_storage.
When saving make sure to mark tw_cloud_storage.esm as a master for your mod. It is needed.

Stores currently available: 
"Weapons", "Armor", "Clothes", "Ingredients", "Alchemy", "Books", "Scrolls", "Tools", "Apperatus", "Soul Gems", "Keys", "Misc"

Any new items added by other mods should also be recognised under these groups and stored.
Currently Equipped Items, Bag of Holding, Lock Picks, Probes, Lights and Gold are excluded from the auto store feature for obvious reasons.

There are 12 General Stores Chests of various styles that store everything in one click
And upto 12 variations of individual group stores which will store and retrieve only the group of items represented.

Users will need to install and activate this mod to enable the cross-mod capabilities and link all mods that are using this system together.

Possible development:
Add a working keyring all linked to the system.
Add a merchant who will sell portable containers that can then be added anywhere in Morrowind as cloud linked container. separate mod.

Credits:
Morrowind Modding Community particularly Merlord and Greatness7 for lua coding help.
Various Group Meshes: Mika, Danae, DietBob, Greatness7, The Wanderer.

Permissions:
Do not edit or change any code in this mod without my permission.
This is a cross-mod storage system any change here will effect everyone else who uses this mod as a base.

Do not copy or add this code anywhere else.
This is a cross-mod storage system any change here will effect everyone else who uses this mod as a base.

DO NOT UPLOAD ANYWHERE ELSE WITHOUT MY PERMISSION !!! 

--]]

local messageBox = require("tw_cloud_storage.MessageBox") 

mwse.log("[Cloud Storage Warehouse] Loaded successfully.")

local lStore, lWeapon, lCloths, lArmor, lAmmo, lBooks, lMisc, lTools, lIngred, lAlchemy, lBOH, lScroll, lSoulgem, lKeys, lApparatus
local iTarget

local storeForType = {
    [tes3.objectType.weapon]     = "tw_weapons_store",
    [tes3.objectType.clothing]   = "tw_cloths_store",
    [tes3.objectType.armor]      = "tw_armour_store",
    [tes3.objectType.ammunition] = "tw_armour_store",
    [tes3.objectType.alchemy]    = "tw_potions_store",
    [tes3.objectType.ingredient] = "tw_ingred_store",
    [tes3.objectType.apparatus]  = "tw_apparatus_store",
    [tes3.objectType.repairItem] = "tw_tools_store",
}

----------------------------------------------------------------------------------------------------
-- lStore, lWeapon, lCloths, lArmor, lAmmo, lBooks, lMisc, lTools, lIngred, lAlchemy, lBOH, lScroll, lSoulgem, lKeys, lApparatus
local enabledStores = {
    tw_armour_store    = true, 
    tw_weapons_store   = true, 
    tw_cloths_store    = true, 
    tw_potions_store   = true, 
    tw_ingred_store    = true, 
    tw_apparatus_store = true,
    tw_misc_store      = true, 
    tw_scrolls_store   = true, 
    tw_books_store     = true, 
    tw_keys_store      = true, 
    tw_soulgems_store  = true, 
    tw_tools_store     = true,  
}

if (tes3.menuMode() == true) then
  return
end

----------------------------------------------------------------------------------------------------
--- Given an item, returns what store it should go into.
--- @param item tes3item The item we want to find a sorter for.
--- @return string storeId The reference ID that the item should get sorted into.
local function getStoreForItem(item)
  
    if item.isGold or   --then
       item.id:lower() == "tw_bagofholding_misc" then
      -- Hands off!     
      return
    end
    -- Misc items are a bit complicated, they can be multiple things. So we check them first.
    if (lStore == 1 or lMisc == 1 or lKeys == 1 or lSoulgem == 1) then
      if (item.objectType == tes3.objectType.miscItem) then
          if (item.isSoulGem) then
             if(lStore == 1 or lSoulgem == 1) then           
                return "tw_soulgems_store"
             end

          elseif (item.isKey) then
            if (lStore == 1 or lKeys == 1) then             
               return "tw_keys_store"
             end
          
          else
              return "tw_misc_store"
          end
      end
    end
    if ( lStore == 1 or lBooks == 1 or lScroll == 1) then
        -- seperate books from scrolls
        
        if (item.objectType == tes3.objectType.book) then
            if (item.type == tes3.bookType.scroll) then      
                if (lStore == 1 or lScroll == 1 ) then
                  return "tw_scrolls_store"
                end
            else
                if (lStore == 1 or lBooks == 1 ) then
                  return "tw_books_store"
                end
            end
        end
    end

    -- Check to see if we have an object type specific store.
    return storeForType[item.objectType] -- or "tw_bagofholding_misc"

end

----------------------------------------------------------------------------------------------------
local function isItemStoreEnabled(item)
    return enabledStores[getStoreForItem(item)] == true
end

----------------------------------------------------------------------------------------------------

local function StoreItems(e) 
  
local target = tes3.player
if (not target or not target.object.inventory) then
	return
end

-- A dictionary of items we don't want to blindly transfer, along with prohibited item data.
local blocklist = {} ---@type table<tes3item, tes3itemData[]>

-- Gather up quick keyed items.
for slot = 1, 9 do
	local quickKey = tes3.getQuickKey({ slot = slot })
	if (quickKey and quickKey.item) then
		blocklist[quickKey.item] = blocklist[quickKey.item] or {}
		table.insert(blocklist[quickKey.item], quickKey.itemData)
	end
end

-- Gather up equipped items.
for _, stack in pairs(tes3.player.object.equipment) do
	blocklist[stack.object] = blocklist[stack.object] or {}
	table.insert(blocklist[stack.object], stack.itemData)
end

-- Go through inventory and build a list of things to transfer.
local transferOrders = {}
for _, stack in pairs(tes3.player.object.inventory) do
	-- Do we need to do any filtering?
	if (blocklist[stack.object]) then
		-- Add an order for all items without item data.
		local countWithoutData = stack.count - #(stack.variables or {})
		if (countWithoutData > 0) then
			table.insert(transferOrders, { item = stack.object, count = countWithoutData })
		end

		-- Go through and add any other item data as separate orders.
		for _, stackData in ipairs(stack.variables or {}) do
			-- If the item is in our blocklist, don't make use of it.
			if (not table.find(blocklist[stack.object], stackData)) then
				table.insert(transferOrders, { item = stack.object, itemData = stackData })
			end
		end
	else
		table.insert(transferOrders, { item = stack.object, count = stack.count })
	end
end

-- Transfer what we need to.
local store
for _, order in ipairs(transferOrders) do
  store = getStoreForItem(order.item)
	if ( store ~= nil ) then
    tes3.transferItem({
        from = tes3.player,
        to = store,   --target,
        item = order.item,
        itemData = order.itemData,
        count = order.count,
        limitCapacity = false,
        playSound = true,
        updateGUI = false,
    })
end

end

-- Be sure to update the player/target GUIs since we were doing batching earlier.
tes3.updateInventoryGUI({ reference = tes3.player })
tes3.updateMagicGUI({ reference = tes3.player })
tes3.updateInventoryGUI({ reference = target })
tes3.updateMagicGUI({ reference = target })

end

----------------------------------------------------------------------------------------------------
local function PanicButton(e)
-- return everything back to the player.
-- always available from main menu :)
local objectIDs = {
    "tw_weapons_store",
    "tw_cloths_store",
    "tw_armour_store",
    "tw_books_store",
    "tw_potions_store",
    "tw_ingred_store",
    "tw_tools_store",
    "tw_misc_store",
    "tw_scrolls_store",
    "tw_soulgems_store",
    "tw_keys_store",
    "tw_apparatus_store",
}
local ref
local inv
  for _, id in pairs(objectIDs) do
      ref = tes3.getReference(id)    
      inv = ref.object.inventory
      if ( ref ~= nil ) then -- **
          for _, stack in pairs(inv) do
              tes3.transferItem({
                  from  = ref, 
                  to    = tes3.player, 
                  item  = stack.object, 
                  count = stack.count, 
                  playSound = true, 
                  updateGUI = false,
                  reevaluateEquipment = false,
              })
          end
      end
  end
  
  -- Be sure to update the player/target GUIs since we were doing batching earlier.
  tes3.updateInventoryGUI({ reference = tes3.player })
  tes3.updateMagicGUI({ reference = tes3.player })
  tes3.updateInventoryGUI({ reference = target })
  tes3.updateMagicGUI({ reference = target })
 
  tes3.messageBox("All your items have been returned.")

end    

----------------------------------------------------------------------------------------------------
local function OpenStore(e)

    --local aButtons = {"Weapons", "Armor", "Clothes", "Ingredients", "Alchemy", "Books", "Scrolls", "Soulgems", "Keys", "Tools", "Apparatus", "Misc", "Cancel"}
    if lStore == 1 then 
        messageBox{
            message = "Select which store to open.",
            buttons = { {text = "Weapons",     callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_weapons_store")) end) end },
                        {text = "Armor",       callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_armour_store")) end) end },
                        {text = "Clothes",     callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_cloths_store")) end) end },
                        {text = "Ingredients", callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_ingred_store")) end) end },
                        {text = "Alchemy",     callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_potions_store")) end) end },
                        {text = "Books",       callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_books_store")) end) end },
                        {text = "Scrolls",     callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_scrolls_store")) end) end }, 
                        {text = "Soul Gems",   callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_soulgems_store")) end) end }, 
                        {text = "Keys",        callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_Keys_store")) end) end }, 
                        {text = "Tools",       callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_tools_store")) end) end }, 
                        {text = "Apparatus",   callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_apparatus_store")) end) end },
                        {text = "Misc",        callback = function() timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_misc_store")) end) end },
                        {text = "Cancel",      callback = function() return end}  }, 
        }                
        
    else 
        -- only auto open the one they need.
        if lWeapon == 1 then
            timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_weapons_store")) end)
        elseif lArmor == 1 then
            timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_armour_store")) end)
        elseif lCloths == 1 then
            timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_cloths_store")) end)
        elseif lIngred == 1 then
                timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_ingred_store")) end)
            elseif lAlchemy == 1 then
                timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_potions_store")) end)
            elseif lBooks == 1 then
                timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_books_store")) end)
        elseif lTools == 1 then
            timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_tools_store")) end)
        elseif lMisc == 1 then
            timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_misc_store")) end)
        elseif lScroll == 1 then
            timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_scrolls_store")) end)
        elseif lSoulgem == 1 then
            timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_soulgems_store")) end)
        elseif lKeys == 1 then
            timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_Keys_store")) end)
        elseif lApparatus == 1 then
            timer.delayOneFrame(function() AllowActivate = true; tes3.player:activate(tes3.getReference("tw_apparatus_store")) end)
        end
    end
end

----------------------------------------------------------------------------------------------------
local function AddPlaceholder(target)

  --if target.activator == tes3.player then - can it ever be anyone else !?!?!?
  local itemlist = dofile("tw.itemlist")

  local misc
  if ( string.sub( target:lower(), -3 ) == "act" ) then
    local item = string.sub( target:lower(),  1, -4 )
    if itemlist[ item ] then
    
      misc = string.format("%s%s", item, "misc")
      misc = tes3.getReference( misc )
      
      if ( misc ) then    
        
          tes3.messageBox("You have been given placeholder %s", misc )
          --Add placeholder to the player's inventory manually.
          tes3.addItem({
            reference = tes3.player,
            item = misc.id,
            count = 1,
            playSound = true,
          })

         mwse.log( "Added to player %s", misc )
         
         return false
      end
    end
    
  elseif ( string.sub( target:lower(), -4 ) == "misc" ) then
    local item = string.sub( target:lower(),  1, -4 )
    if itemlist[ item ] then
      return
    end
  end
end

----------------------------------------------------------------------------------------------------
local function onStoreSet(e)

 local cell = e.target.cell
 local position = e.target.position:copy()
 local rotation = e.target.sceneNode.rotation:copy()

 local container = string.sub( e.target.id,  1, -5 )
 container = string.format("%s%s", container, "act" )

 -- Get the original misc display and create the activator replacement
 local miscRef = tes3.createReference{
       object = container,
       position = position,
       cell = cell
       }
  miscRef.orientation = rotation
 
 tes3.setEnabled({ reference = e.target, enabled = false })  --- disable misc item
 
end

----------------------------------------------------------------------------------------------------
local function onStorePickup(e, target)
  
  tes3.setEnabled({ reference = e.target, enabled = false })  --- disable misc item
  local misc = string.format("%s%s", target, "misc" )
  tes3.addItem({
        reference = tes3.player,
        item = misc,
        count = 1,
        playSound = true,
      })
    
end

----------------------------------------------------------------------------------------------------
local function onActStore(e)

local cell =  e.target.cell.id  --tes3.player.cell
if ( cell == "tw_cloud storage, shoppe" ) then
--mwse.log("*** In the shoppe so add placeholder to player only")    
    
    AddPlaceholder(e.target.id) 
    
    return --false
    
end    
    
if ( string.sub( e.target.id, -4 ) == "misc" ) then
  
  local itemlist = dofile("tw.itemlist")
  local item = string.sub( e.target.id,  1, -5 )

  if itemlist[ item ] then    
      messageBox {
        message = "What do you want to do?",
        buttons = {
            { text = "set"   , callback = function() onStoreSet(e) end },  --cell, position, rotation, e.target.id )
            { text = "Pick-up", callback = function() onStorePickup(e, item) end }
           } }
    
     return false
     
  end
end   
    
if ( cell ~= "tw_cloud storage, shoppe" ) then   -- if not in shop do as csw container
 
    -- reset the flags.
    lStore,
    lWeapon,
    lCloths,
    lArmor,
    lAmmo,
    lBooks,
    lMisc,
    lTools,
    lIngred,
    lAlchemy,
    lBOH,
    lScroll,
    lSoulgem,
    lKeys,
    lApparatus = 0

    if e.activator == tes3.player then
        if (e.target.id == "tw_store01_act") or (e.target.id == "tw_store02_act") or (e.target.id == "tw_store03_act") or 
           (e.target.id == "tw_store04_act") or (e.target.id == "tw_store05_act") or (e.target.id == "tw_store06_act") then
           -- this is a general store so no direct store container.
            lStore = 1      -- Store all               
        elseif (e.target.id == "tw_weapons_01_act") or (e.target.id == "tw_weapons_02_act") or (e.target.id == "tw_weapons_03_act") or
               (e.target.id == "tw_weapons_04_act") or (e.target.id == "tw_weapons_05_act") or (e.target.id == "tw_weapons_06_act") then
            --iTarget = tes3.getReference("tw_weapons_store")
            lWeapon = 1
        elseif (e.target.id == "tw_cloths_01_act") or (e.target.id == "tw_cloths_02_act") or (e.target.id == "tw_cloths_03_act") or
               (e.target.id == "tw_cloths_04_act") or (e.target.id == "tw_cloths_05_act") or (e.target.id == "tw_cloths_06_act")then
            --iTarget = tes3.getReference("tw_cloths_store")
            lCloths = 1
        elseif (e.target.id == "tw_armour_01_act") or (e.target.id == "tw_armour_02_act") or (e.target.id == "tw_armour_03_act") or
               (e.target.id == "tw_armour_04_act") or (e.target.id == "tw_armour_05_act") or (e.target.id == "tw_armour_06_act")or
               (e.target.id == "tw_armour_07_act") or (e.target.id == "tw_armour_08_act") or (e.target.id == "tw_armour_09_act") then
            --iTarget = tes3.getReference("tw_armour_store")
            lArmor = 1
        elseif (e.target.id == "tw_tools_01_act") or (e.target.id == "tw_tools_02_act") or (e.target.id == "tw_tools_03_act") or
               (e.target.id == "tw_tools_04_act") or (e.target.id == "tw_tools_05_act") or (e.target.id == "tw_tools_06_act") then
            --iTarget = tes3.getReference("tw_tools_store")
            lTools = 1
        elseif (e.target.id == "tw_books_01_act") or (e.target.id == "tw_books_02_act") or (e.target.id == "tw_books_03_act") or
               (e.target.id == "tw_books_04_act") or (e.target.id == "tw_books_05_act") or (e.target.id == "tw_books_06_act") then
            --iTarget = tes3.getReference("tw_books_store")
            lBooks = 1
        elseif (e.target.id == "tw_misc01_act") or (e.target.id == "tw_misc02_act") or (e.target.id == "tw_misc03_act") or 
               (e.target.id == "tw_misc04_act") or (e.target.id == "tw_misc05_act") or (e.target.id == "tw_misc06_act") then
            --iTarget = tes3.getReference("tw_misc_store")
            lMisc = 1                       
        elseif (e.target.id == "tw_ingred_01_act") or (e.target.id == "tw_ingred_02_act") or (e.target.id == "tw_ingred_03_act") or
               (e.target.id == "tw_ingred_04_act") or (e.target.id == "tw_ingred_05_act") or (e.target.id == "tw_ingred_06_act") then
            --iTarget = tes3.getReference("tw_ingred_store") 
            lIngred = 1                                     
        elseif (e.target.id == "tw_potions_01_act") or (e.target.id == "tw_potions_02_act") or (e.target.id == "tw_potions_03_act") or
               (e.target.id == "tw_potions_04_act") or (e.target.id == "tw_potions_05_act") or (e.target.id == "tw_potions_06_act") then
            --iTarget = tes3.getReference("tw_potions_store_act")
            lAlchemy = 1       
        elseif (e.target.id == "tw_scroll_01_act") or (e.target.id == "tw_scroll_02_act") or (e.target.id == "tw_scroll_03_act") or
               (e.target.id == "tw_scroll_04_act") or (e.target.id == "tw_scroll_05_act") or (e.target.id == "tw_scroll_06_act") then
            lScroll = 1       
        elseif (e.target.id == "tw_soulgems_01_act") or (e.target.id == "tw_soulgems_02_act") or (e.target.id == "tw_soulgems_03_act") or
               (e.target.id == "tw_soulgems_04_act") or (e.target.id == "tw_soulgems_05_act") or (e.target.id == "tw_soulgems_06_act") then
            lSoulgem = 1       
        elseif (e.target.id == "tw_keys_01_act") or (e.target.id == "tw_keys_02_act") or (e.target.id == "tw_keys_03_act") or
               (e.target.id == "tw_keys_04_act") or (e.target.id == "tw_keys_05_act") or (e.target.id == "tw_keys_06_act") then
            lKeys = 1       
        elseif (e.target.id == "tw_apparatus_01_act") or (e.target.id == "tw_apparatus_02_act") or (e.target.id == "tw_apparatus_03_act") or
               (e.target.id == "tw_apparatus_04_act") or (e.target.id == "tw_apparatus_05_act") or (e.target.id == "tw_apparatus_06_act") then
            lApparatus = 1       

        elseif (e.target.id:lower() == "tw_bagofholding_misc") then  -- set up as a 'all' general store                                                 
            lStore = 1
        else
            return    
        end
        
        enabledStores = {
            tw_armour_store    = (lStore == 1 or lArmor == 1),  --true,
            tw_weapons_store   = (lStore == 1 or lWeapon == 1),  --true,
            tw_cloths_store    = (lStore == 1 or lCloths == 1),  --true,
            tw_potions_store   = (lStore == 1 or lAlchemy == 1),  --true,
            tw_ingred_store    = (lStore == 1 or lIngred == 1),  --true,
            tw_apparatus_store = (lStore == 1 or lApparatus == 1),  --true,
            tw_misc_store      = (lStore == 1 or lMisc == 1),  --true,
            tw_scrolls_store   = (lStore == 1 or lScroll == 1),  --true,
            tw_books_store     = (lStore == 1 or lBooks == 1),  --true,
            tw_keys_store      = (lStore == 1 or lKeys == 1),  --true,
            tw_soulgems_store  = (lStore == 1 or lSoulgem == 1),  --true,
            tw_tools_store     = (lStore == 1 or lTools == 1)  --true,
        }        

        messageBox{
            message = "What do you want to do?",
            buttons = {{ text = "Auto",   callback = function() StoreItems(e) end },
                       { text = "Open",   callback = function() OpenStore(e) end  }, 
                       { text = "Panic!", callback = function() PanicButton(e) end}, 
                       { text = "Cancel", callback = function() return end}  }                
                }

    end
    return

end
end
event.register("activate", onActStore)

----------------------------------------------------------------------------------------------------
local function onEquip(e)

    if (e.item.id:lower() == "tw_bagofholding_misc") then
      

 --       If (tes3.mobilePlayer.inCombat == true) then
 --           tes3.messagebox( "The bag cannot be used while in combat." )
 --       Else   
        -- just activate the 'store all' container this will put the bag back into inventory.
            tes3.player:activate(tes3.getReference("tw_store01_act"))
 --       end
    end    
end
event.register("equip", onEquip)



--      -- Ownership test.
--      local itemdata = target.attachments.variables
--      if (itemdata and itemdata.owner) then
--          local owner = itemdata.owner
--          if (owner.objectType == tes3.objectType.faction and owner.playerJoined and owner.playerRank >= itemdata.requirement) then
--              -- Player has sufficient faction rank.
--          else
--              tes3.messageBox{ message = "OwnedItem" }  -- is this then stolen ??
--              return
--          end
--      end
--

--[[
		local item = data.questItemTable[e.object.id:lower()]
		if item then
       quest item leave it along.

local data = {}
data.questItemTable = {
	-- Morrowind
	["bk_a1_1_caiuspackage"] = { entry = "A1_1_FindSpymaster", index = 12 },
	["lugrub's axe"] = { entry = "IL_WidowLand", index = 70 },
	["dwarven war axe_redas"] = { entry = "HR_RedasTomb", index = 100 },
	["ebony staff caper"] = { entry = "TG_EbonyStaff", index = 100 },
	["rusty_dagger_UNIQUE"] = { entry = "DA_Mehrunes", index = 40 },
	["devil_tanto_tgamg"] = { entry = "TG_LootAldruhnMG", index = 100 },
	["daedric wakizashi_hhst"] = { entry = "HH_SunkenTreasure", index = 100 },
	["glass_dagger_enamor"] = { entry = "TG_SS_Enamor", index = 100 },
	["fork_horripilation_unique"] = { entry = "DA_Sheogorath", index = 70 },
	["dart_uniq_judgement"] = { entry = "TG_DartsJudgement", index = 100 },
	["bonemold_gah-julan_hhda"] = { entry = "HH_DisguisedArmor", index = 50 },
	["bonemold_founders_helm"] = { entry = "HR_FoundersHelm", index = 100 },
	["bonemold_tshield_hrlb"] = { entry = "HR_LostBanner", index = 100 },
	["amuletfleshmadewhole_uniq"] = { entry = "HT_FleshAmulet", index = 100 },
	["amulet_Agustas_unique"] = { entry = "MS_ArenimTomb", index = 110 },
	["expensive_amulet_delyna"] = { entry = "HR_MadMilk", index = 90 },
	["expensive_amulet_aeta"] = { entry = "MV_BanditVictim", index = 100 },
	["sarandas_amulet"] = { entry = "Town_Ald_Bevene", index = 3 },
	["exquisite_amulet_hlervu1"] = { entry = "TG_SS_Generosity1", index = 30 },
	["julielle_aumines_amulet"] = { entry = "IC19_Restless_Spirit", index = 40 },
	["linus_iulus_maran amulet"] = { entry = "IC18_Silver_Staff", index = 50 },
	["linus_iulus_stendarran_belt"] = { entry = "IC18_Silver_Staff", index = 50 },
	["sarandas_belt"] = { entry = "Town_Ald_Tiras", index = 3 },
	["extravagant_rt_art_wild"] = { entry = "TT_AldDaedroth", index = 100 },
	["expensive_glove_left_ilmeni"] = { entry = "IL_MaidenToken", index = 70 },
	["extravagant_glove_left_maur"] = { entry = "MV_VictimRomance", index = 50 },
	["common_pants_02_hentus"] = { entry = "MS_HentusPants", index = 100 },
	["sarandas_pants_2"] = { entry = "Town_Ald_Bivale", index = 3 },
	["adusamsi's_ring"] = { entry = "IC27_Oracle", index = 50 },
	["extravagant_ring_aund_uni"] = { entry = "VA_VampChild", index = 80 },
	["ring_blackjinx_uniq"] = { entry = "HT_BlackJinx", index = 100 },
	["exquisite_ring_brallion"] = { entry = "TG_SS_GreedySlaver", index = 50 },
	["common_ring_danar"] = { entry = "EB_DeadMen", index = 60 },
	["sarandas_ring_2"] = { entry = "Town_Ald_Daynes", index = 3 },
	["ring_keley"] = { entry = "MS_FargothRing", index = 100 },
	["expensive_ring_01_BILL"] = { entry = "MV_LostRing", index = 30 },
	["expensive_ring_aeta"] = { entry = "MV_BanditVictim", index = 100 },
	["sarandas_ring_1"] = { entry = "Town_Ald_Daynes", index = 3 },
	["expensive_ring_01_hrdt"] = { entry = "HR_DagothTanis", index = 100 },
	["exquisite_ring_processus"] = { entry = "MV_DeadTaxman", index = 90 },
	["extravagant_robe_01_red"] = { entry = "HR_RedasTomb", index = 100 },
	["robe of st roris"] = { entry = "HH_WinSaryoni", index = 70 },
	["exquisite_robe_drake's pride"] = { entry = "HT_DrakePride", index = 100 },
	["sarandas_shirt_2"] = { entry = "Town_Ald_Bivale", index = 3 },
	["exquisite_shirt_01_rasha"] = { entry = "MV_TraderLate", index = 40 },
	["sarandas_shoes_2"] = { entry = "Town_Ald_Llethri", index = 3 },
	["therana's skirt"] = { entry = "HT_TheranaClothes", index = 100 },
	["misc_beluelle_silver_bowl"] = { entry = "MS_Piernette", index = 90 },
	["misc_lw_bowl_chapel"] = { entry = "IC15_Missing_Limeware", index = 50 },
	["misc_dwrv_artifact_ils"] = { entry = "IL_Smuggler", index = 100 },
	["misc_dwarfbone_unique"] = { entry = "EB_Bone", index = 30 },
	["misc_dwrv_ark_cube00"] = { entry = "A1_2_AntabolisInformant", index = 10 },
	["misc_fakesoulgem"] = { entry = "MG_Sabotage", index = 100 },
	["ingred_guar_hide_girith"] = { entry = "MV_OutcastAshlanders", index = 100 },
	["misc_uniq_egg_of_gold"] = { entry = "FG_FindPudai", index = 100 },
	["misc_goblet_dagoth"] = { entry = "A2_6_Incarnate", index = 15 },
	["ingred_guar_hide_marsus"] = { entry = "MV_InnocentAshlanders", index = 100 },
	["misc_6th_ash_hrmm"] = { entry = "HR_MorvaynManor", index = 50 },
	["misc_de_goblet_01_redas"] = { entry = "HR_RedasTomb", index = 100 },
	["misc_skull_llevule"] = { entry = "A1_4_MuzgobInformant", index = 15 },
	["misc_6th_ash_hrcs"] = { entry = "HR_ClearSarethi", index = 90 },
	["misc_wraithguard_no_equip"] = { entry = "CX_BackPath", index = 50 },
	["p_cure_common_unique"] = { entry = "MS_Apologies", index = 100 },
	["p_lovepotion_unique"] = { entry = "EB_Unrequited", index = 80 },
	["p_quarrablood_unique"] = { entry = "VA_VampBlood", index = 40 }, { entry = "VA_VampBlood2", index = 100 },
	["p_sinyaramen_unique"] = { entry = "VA_VampChild", index = 70 },
	["ingred_raw_glass_tinos"] = { entry = "MV_AngryTrader", index = 100 },
	["ingred_gold_kanet_unique"] = { entry = "MS_Gold_kanet_flower", index = 100 },
	["ingred_treated_bittergreen_uniq"] = { entry = "DA_Mephala", index = 57 },
	["bk_aedra_tarer_unique"] = { entry = "MS_Apologies", index = 10 },
	["glory_unique"] = { entry = "DA_Boethiah", index = 60 },
	["bk_sharnslegionsofthedead"] = { entry = "MG_Sharn_Necro", index = 10 },
	["bk_alen_note"] = { entry = "TR08_Hlaalu", index = 60 },
	["bk_irano_note"] = { entry = "TR07_Guard", index = 100 },
	["bk_airship_captains_journal"] = { entry = "BM_Airship", index = 70 },
	["bk_snowprince"] = { entry = "BM_Falmer", index = 100 },
	["bk_sovngarde"] = { entry = "BM_BrodirGrove", index = 40 },
	["bk_ajira1"] = { entry = "MG_StolenReport", index = 100 },
	["bk_ajira2"] = { entry = "MG_StolenReport", index = 100 },
	["bk_landdeed_hhrd"] = { entry = "HH_ReplaceDocs", index = 100 },
	["bk_auranefrernis1"] = { entry = "HH_IndEsp1", index = 100 },
	["bk_auranefrernis2"] = { entry = "HH_IndEsp1", index = 100 },
	["bk_auranefrernis3"] = { entry = "HH_IndEsp1", index = 100 },
	["bk_calderaminingcontract"] = { entry = "HH_CaptureSpy", index = 100 },
	["bk_clientlist"] = { entry = "EB_Clients", index = 40 },
	["bk_indreledeed"] = { entry = "TG_SS_Generosity2", index = 50 },
	["bk_dispelrecipe_tgca"] = { entry = "TG_CookbookAlchemy", index = 50 },
	["bk_drenblackmail"] = { entry = "B6_HlaaluHort", index = 50 },
	["bk_uleni's_papers"] = { entry = "town_Sadrith", index = 50 },
	["bk_itermerelsnotes"] = { entry = "MG_EscortScholar2", index = 100 },
	["bk_kagrenac'sjournal_excl"] = { entry = "CX_BackPath", index = 25 },
	["bk_kagrenac'splans_excl"] = { entry = "CX_BackPath", index = 25 },
	["bk_letterfromjzhirr"] = { entry = "EB_Express", index = 30 },
	["bk_letterfromllaalam"] = { entry = "EB_Express", index = 50 },
	["bk_letterfromllaalam2"] = { entry = "EB_TradeSpy", index = 40 },
	["bk_ocato_recommendation"] = { entry = "MG_Guildmaster", index = 50 },
	["bk_a1_2_introtocadiusus"] = { entry = "MG_Excavation", index = 20 },
	["bk_messagefrommasteraryon"] = { entry = "HT_FyrMessage", index = 50 },
	["bk_nemindasorders"] = { entry = "HH_DisguisedArmor", index = 100 },
	["bk_a1_4_sharnsnotes"] = { entry = "A1_4_MuzgobInformant", index = 25 },
	["bk_notefrombashuk"] = { entry = "MV_Bugrol", index = 40 },
	["bk_notefrombugrol"] = { entry = "MV_Bugrol", index = 30 },
	["bk_notefromernil"] = { entry = "MV_SkoomaCorpse", index = 20 },
	["bk_notefromnelos"] = { entry = "MV_VictimRomance", index = 100 },
	["bk_talostreason"] = { entry = "IL_TalosTreason", index = 50 },
	["bk_notetoamaya"] = { entry = "A2_4_MiloGone", index = 10 },
	["bk_enamor"] = { entry = "TG_SS_Enamor", index = 100 },
	["bk_a1_7_huleeyainformant"] = { entry = "A1_V_VivecInformants", index = 50 },
	["bk_landdeedfake_hhrd"] = { entry = "HH_ReplaceDocs", index = 50 },
	["bk_orderesforbivaleteneran"] = { entry = "HH_IndEsp3", index = 50 },
	["bk_progressoftruth"] = { entry = "A1_V_VivecInformants", index = 50 },
	["chargen statssheet"] = { entry = "A1_1_FindSpymaster", index = 1 },
	["bk_responsefromdivaythfyr"] = { entry = "HT_FyrMessage", index = 100 },
	["bk_stronghold_ld_hlaalu"] = { entry = "HH_Stronghold", index = 50 },
	["bk_calderarecordbook2"] = { entry = "HR_CalderaCorrupt", index = 100 },
	["bk_seniliasreport"] = { entry = "MG_Excavation", index = 100 },
	["bk_shishireport"] = { entry = "HR_ShishiReport", index = 100 },
	["bk_sottildescodebook"] = { entry = "FG_Sottilde", index = 100 },
	["bk_tiramgadarscredentials"] = { entry = "MG_SpyCatch", index = 100 },
	["bk_treasury orders"] = { entry = "HH_BankFraud", index = 50 },
	["bk_treasury report"] = { entry = "HH_BankCourier", index = 50 },
	["bk_contract_ralen"] = { entry = "EB_Deed", index = 40 },
	["bk_widowdeed"] = { entry = "IL_WidowLand", index = 100 },
	["bk_ynglingledger"] = { entry = "TG_SS_Yngling", index = 100 },
	["bk_a1_11_zainsubaninotes"] = { entry = "A2_1_MeetSulMatuul", index = 1 },
	-- Tribunal
	["ebony war axe_elanande"] = { entry = "MS_Warlords", index = 70 },
	["dwarven mace_salandas"] = { entry = "MS_Warlords", index = 120 },
	["silver dagger_droth_unique_a"] = { entry = "MS_EstateSale", index = 60 },
	["silver dagger_droth_unique"] = { entry = "MS_EstateSale", index = 60 },
	["ebony shortsword_soscean"] = { entry = "MS_Warlords", index = 40 },
	["silver spear_uvenim"] = { entry = "MS_Warlords", index = 100 },
	["ebony_cuirass_soscean"] = { entry = "MS_Warlords", index = 40 },
	["silver_helm_uvenim"] = { entry = "MS_Warlords", index = 100 },
	["amulet_salandas"] = { entry = "MS_Warlords", index = 120 },
	["extravagant_robe_02_elanande"] = { entry = "MS_Warlords", index = 70 },
	["bladepiece_02"] = { entry = "TR_Blade", index = 65 },
	["bladepiece_03"] = { entry = "TR_Blade", index = 65 },
	["dwemer_shield_battle_unique"] = { entry = "TR_Blade", index = 65 },
	["misc_dwrv_weather"] = { entry = "TR_ShowPower", index = 90 },
	["misc_dwrv_weather2"] = { entry = "TR_ShowPower", index = 90 },
	["bk_playscript"] = { entry = "MS_Performers", index = 30 },
	["sc_chridittepanacea"] = { entry = "MS_CrimsonPlague", index = 110 },
	["pyroil_tar_unique"] = { entry = "TR_Blade", index = 80 },
	-- Bloodmoon
	["fur_colovian_helm_white"] = { entry = "BM_MoonSugar", index = 100 },
	["amulet of infectious charm"] = { entry = "BM_Airship", index = 80 },
	["expensive_ring_erna"] = { entry = "BM_WomanScorned", index = 100 },
	["bm_bearheart_unique"] = { entry = "BM_BearHunt1", index = 100 },
	["misc_skull_oddfrid"] = { entry = "BM_SadSeer", index = 40 },
	["misc_skull_Skaal"] = { entry = "BM_CariusGone", index = 100 },
	["bm_seeds_unique"] = { entry = "BM_Trees", index = 40 },
	["misc_bm_clawFang_unique"] = { entry = "BM_Ceremony1", index = 100 },
	["bm_waterlife_unique1"] = { entry = "BM_Water", index = 100 },
	["bk_bmtrial_unique"] = { entry = "BM_Trial", index = 55 },
	["bk_colony_Toralf"] = { entry = "CO_13", index = 40 },
	["ingred_emerald_pinetear"] = { entry = "BM_Retribution", index = 100 },
	["ingred_innocent_heart"] = { entry = "BM_WolfGiver", index = 100 },
	["ingred_wolf_heart"] = { entry = "BM_WolfGiver", index = 105 },
}
return data
--]]

