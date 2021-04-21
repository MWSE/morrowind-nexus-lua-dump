-- Check MWSE Build --
if (mwse.buildDate == nil) or (mwse.buildDate < 20200405) then
    local function warning()
        tes3.messageBox(
            "[Cosmetic Overrides ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end
----------------------------
local function getKeyFromValue(tbl, value)
  for key, tblValue in pairs(tbl) do
    if (tblValue == value) then return key end
  end
  return nil
end

local function getSlotNameFromObject(obj)
  local slotName
  if (obj.objectType == tes3.objectType.armor) then
    slotName = getKeyFromValue(tes3.armorSlot, obj.slot)
  else 
    slotName = getKeyFromValue(tes3.clothingSlot, obj.slot)
  end

  if (slotName) then
    return slotName:lower()
  else
    return nil
  end
end

local categories = {
  [mwse.longToString(tes3.objectType.armor)] = {
    text = "Armor",
    types = tes3.armorSlot,
    blockedSlots = {
      ["shield"] = true
    }
  },
  [mwse.longToString(tes3.objectType.clothing)] = {
    text = "Clothing",
    types = tes3.clothingSlot,
    blockedSlots = {
      ["amulet"] = true,
      ["belt"] = true,
      ["ring"] = true,
    }
  }
}

local options = {}
local function getOptions(objectTypeId, objectTypeName)
  objectTypeName = objectTypeName:lower()
  local labels = {
    { label = "-- None --", value = "nil"}
  }

  if (tes3.player == nil) then
    return labels
  elseif (tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeId] == nil) then
    return labels
  end
    
  for id, text in pairs(tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeId][objectTypeName]) do
    table.insert(labels, {
      label = text .. " - " .. id,
      value = id
    })
  end

  return labels
end

local function updateOptions(objectTypeId, objectTypeName)
  objectTypeName = objectTypeName:lower()

  for key in pairs (options[objectTypeId][objectTypeName]) do
    options[objectTypeId][objectTypeName][key] = nil
  end

  table.insert(options[objectTypeId][objectTypeName], {
    label = "-- None --",
    value = "nil"
  })

  if (tes3.player ~= nil and tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeId] ~= nil) then
    for id, text in pairs(tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeId][objectTypeName]) do
      table.insert(options[objectTypeId][objectTypeName], {
        label = text .. " - " .. id,
        value = id
      })
    end
  end


end

local function getOverrideItemId(objectType, objectTypeName)
  if(tes3.player.data.OJ_CosmeticOverrides.Active[objectType]) then
    if (tes3.player.data.OJ_CosmeticOverrides.Active[objectType][objectTypeName] == "nil") then
      return nil
    end  
    
    return tes3.player.data.OJ_CosmeticOverrides.Active[objectType][objectTypeName]
  end
  return nil
end

local cachedObjects = {}
local function getOverrideObject(objectType, objectTypeName)
  local overrideItemId = getOverrideItemId(objectType, objectTypeName)
  if (overrideItemId) then
    if (cachedObjects[overrideItemId] == nil) then
      cachedObjects[overrideItemId] = tes3.getObject(overrideItemId)
    end
    
    return cachedObjects[overrideItemId]
  end
  return nil
end

-- Enable costmetic overrides.
local function onBodyPartAssigned(e)
  -- We only care about item-based assignment on the player.
  if (e.reference == tes3.player and e.object) then
    -- Do we have an override for it?
    local slotName = getSlotNameFromObject(e.object)
    local objectTypeString = mwse.longToString(e.object.objectType)

    local overrideItem = getOverrideObject(objectTypeString, slotName)
    if (overrideItem) then
        -- Find the matching body part index.
        for _, potentialPartPair in ipairs(overrideItem.parts) do
            if (potentialPartPair.type ~= -1 and potentialPartPair.type == e.index) then
                -- We found the right body part on the item. Use it, based on sex assignment.
                if (potentialPartPair.female and tes3.player.baseObject.female) then
                    e.bodyPart = potentialPartPair.female
                else
                    e.bodyPart = potentialPartPair.male
                end

                return
            end
        end

        -- No matching body part for this index? Block the visual.
        return false
    end
  end
end
event.register("bodyPartAssigned", onBodyPartAssigned)


local function onEquipped(e)
  local item = e.item

  if (item.objectType == tes3.objectType.armor or item.objectType == tes3.objectType.clothing) then
    local slotName = getSlotNameFromObject(item)
    local objectTypeString = mwse.longToString(e.item.objectType)
    if (categories[objectTypeString].blockedSlots[slotName] == true) then
      return
    end

    tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString] = tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString] or {}
    tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString][slotName] = tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString][slotName] or {}
    tes3.player.data.OJ_CosmeticOverrides.Possible[objectTypeString][slotName][item.id] = item.name

    updateOptions(objectTypeString, slotName)
  end
end
event.register("equipped", onEquipped)

local function initializePlayerData()
  tes3.player.data.OJ_CosmeticOverrides = tes3.player.data.OJ_CosmeticOverrides or {
    Active = {},
    Possible = {}
  }
end

local function initializePlayerDataOptions()
  for objectType, objectTypeTbl in pairs(tes3.player.data.OJ_CosmeticOverrides.Possible) do
    for slotName in pairs(objectTypeTbl) do
      updateOptions(objectType, slotName)
    end
  end
end

local function triggerBodyPartsUpdate()
  tes3.player:updateEquipment()
end

local function onLoaded(e)
  initializePlayerData()
  initializePlayerDataOptions()

  triggerBodyPartsUpdate()

  print("[Cosmetic Overrides: INFO] Initialized for current save game.")
end
event.register("loaded", onLoaded)

local function onMenuExit(e)
  triggerBodyPartsUpdate()
end
event.register("menuExit", onMenuExit)

-----------------------------------
------------ Add MCM --------------
-----------------------------------
local function sortedKeys(query, sortFunction)
  local keys, len = {}, 0
  for k,_ in pairs(query) do
    len = len + 1
    keys[len] = k
  end
  table.sort(keys, sortFunction)
  return keys
end

local function createDropDownsForCategory(category, typeId, typeObject)
  for _, slotName in pairs(sortedKeys(typeObject.types)) do
    if (typeObject.blockedSlots[slotName] == nil) then
      local slotNameLower = slotName:lower()
      if (options[typeId] == nil) then
        options[typeId] = {}
      end
      options[typeId][slotNameLower] = getOptions(typeId, slotNameLower)
      

      category:createDropdown{
        label = slotName,
        description = "Set the cosmetic override for the " .. slotName .. " slot.",
        options = options[typeId][slotNameLower],
        variable = mwse.mcm.createPlayerData{
          id = slotNameLower,
          path = "OJ_CosmeticOverrides.Active." .. typeId,
          defaultSetting = "nil"
        }
      }
    end
  end
end

-- Handle mod config menu.
local function createCategory(template, typeId, typeObject)
  local page = template:createSideBarPage{
    label = typeObject.text,
    description = "Hover over a setting to learn more about it."
  }

  local category = page:createCategory{ 
    label = typeObject.text,
    description = "Manage the cosmetic overrides for " .. typeObject.text .. ".",
  }



  createDropDownsForCategory(category, typeId, typeObject)
end

local function registerModConfig()
  local template = mwse.mcm.createTemplate("Cosmetic Overrides")

  for key, value in pairs(categories) do
      createCategory(template, key, value)
  end

  mwse.mcm.register(template)
end

event.register("modConfigReady", registerModConfig)