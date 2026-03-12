local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local vfs = require('openmw.vfs')
local Activation = require('openmw.interfaces').Activation
local storage = require('openmw.storage')

local materials_table = {}
local hammer_id = "repair_hammer_weapon"

local modSettings = storage.globalSection("SettingsWeaponUpgrade")
local modCapSettings = storage.globalSection("SettingsWeaponUpgradeCap")

local gripLoaded = core.contentFiles.has('GRIP.omwscripts')
local gripRecords = nil

if gripLoaded then
  gripRecords = storage.globalSection('GRIPRecords')
end

local function sendSoundEvent(name,actor)
  actor:sendEvent("PlaySound",{name=name})
end

local function isAmmo(type)
  if type == types.Weapon.TYPE.Arrow or type == types.Weapon.TYPE.Bolt or type == types.Weapon.TYPE.MarksmanThrown then
    return true
  end
  return false
end

local function getWeaponType(weaponType)
    local weaponTypeMap = {
        [types.Weapon.TYPE.Arrow] = "Arrow",
        [types.Weapon.TYPE.AxeOneHand] = "One-Handed Axe",
        [types.Weapon.TYPE.AxeTwoHand] = "Two-Handed Axe",
        [types.Weapon.TYPE.BluntOneHand] = "One-Handed Blunt",
        [types.Weapon.TYPE.BluntTwoClose] = "Two-Handed Blunt (Close)",
        [types.Weapon.TYPE.BluntTwoWide] = "Two-Handed Blunt (Wide)",
        [types.Weapon.TYPE.Bolt] = "Bolt",
        [types.Weapon.TYPE.LongBladeOneHand] = "One-Handed Long Blade",
        [types.Weapon.TYPE.LongBladeTwoHand] = "Two-Handed Long Blade",
        [types.Weapon.TYPE.MarksmanBow] = "Bow",
        [types.Weapon.TYPE.MarksmanCrossbow] = "Crossbow",
        [types.Weapon.TYPE.MarksmanThrown] = "Thrown Weapon",
        [types.Weapon.TYPE.ShortBladeOneHand] = "One-Handed Short Blade",
        [types.Weapon.TYPE.SpearTwoWide] = "Two-Handed Spear",
    }
    return weaponTypeMap[weaponType]
end

local function gripOriginalWeapon(id)
  local newToOld = gripRecords:getCopy('NewToOldRecords')
  local originalId = newToOld[id]
  if originalId ~= nil then
    print("Original ID of weapon:",originalId)
    local original = types.Weapon.record(originalId)
    return original
  end
end

local function upgradeWeapon(object,actor,materials)
  if materials[1] == nil then
   actor:sendEvent('ShowMessage',{message = "There are no materials nearby to upgrade with."})
   return
  end
  
  local usedMaterial = materials[1].item.recordId
  local materialCount = materials[1].item.count
  if materialCount > modSettings:get("MaxMaterials") then
   materialCount = modSettings:get("MaxMaterials")
  end
  
  local requiredSkill = 0
  
  if not modSettings:get("IgnoreDifficulty") then
   requiredSkill = materials_table[usedMaterial].skill
   if tonumber(requiredSkill) > types.Player.stats.skills.armorer(actor).modified then
    actor:sendEvent('ShowMessage',{message = "Not skilled enough to work with that material. ".."("..requiredSkill.." needed)"})
     return
   end
  end
  
  local ammoCount = object.count
  
  if types.Item.itemData(object).condition == 0 then
     actor:sendEvent('ShowMessage',{message="Weapon is too damaged to upgrade."})
   return
  end
  
  local weaponTemplate = types.Weapon.record(object)
  if gripLoaded then
    local original = gripOriginalWeapon(object.recordId)
    if original ~= nil then
      weaponTemplate = original
    end
  end
  
  if not modSettings:get("AlwaysSucceed") then
   local playerSkill = types.Player.stats.skills.armorer(actor).modified
--   print("[DEBUG] player skill:",playerSkill)
   local successRate = 85 + (playerSkill - requiredSkill) * 3 - (materialCount-1) * (6+requiredSkill/10)
   if math.random(1,100) > successRate then
     --failiure
     types.Item.itemData(object).condition = types.Item.itemData(object).condition - weaponTemplate.health * 0.2
     actor:sendEvent('ShowMessage',{message="Failed to upgrade weapon."})
     sendSoundEvent("repair fail",actor)
     return
   end
  end
  
  local name = weaponTemplate.name
  
  if modSettings:get("InfiniteUpgrades") then
   if not string.find(name,"Tempered") then
     name = "Tempered "..name
   end
  elseif string.find(weaponTemplate.name,"Tempered") then
   --Already upgraded
--   print("[DEBUG] Armor already upgraded, aborting.")
    actor:sendEvent('ShowMessage',{message="Can not upgrade weapon again."})
   return
  else
   name = "Tempered "..name
  end
  sendSoundEvent("repair",actor)
  
  local chopMax = weaponTemplate.chopMaxDamage + materials_table[usedMaterial].chop_bonus * weaponTemplate.chopMaxDamage * materialCount
  local chopMin = weaponTemplate.chopMinDamage + materials_table[usedMaterial].chop_bonus * weaponTemplate.chopMinDamage * materialCount
  local slashMax = weaponTemplate.slashMaxDamage + materials_table[usedMaterial].slash_bonus * weaponTemplate.slashMaxDamage * materialCount
  local slashMin = weaponTemplate.slashMinDamage + materials_table[usedMaterial].slash_bonus * weaponTemplate.slashMinDamage * materialCount
  local thrustMax = weaponTemplate.thrustMaxDamage + materials_table[usedMaterial].thrust_bonus * weaponTemplate.thrustMaxDamage* materialCount
  local thrustMin = weaponTemplate.thrustMinDamage + materials_table[usedMaterial].thrust_bonus * weaponTemplate.thrustMinDamage * materialCount
  local enchant_cap = weaponTemplate.enchantCapacity + materials_table[usedMaterial].enchant_bonus * weaponTemplate.enchantCapacity * materialCount
--  local speed = weaponTemplate.speed + materials_table[usedMaterial].speed_bonus * weaponTemplate.speed * materialCount
  local speed = weaponTemplate.speed - 1
  
  local weight = weaponTemplate.weight
  if not modSettings:get("IgnoreWeight") then
   weight = weaponTemplate.weight + materials_table[usedMaterial].weight_bonus * weaponTemplate.weight
  end
  
  local health = weaponTemplate.health + materials_table[usedMaterial].health_bonus * weaponTemplate.health
  --looks like max health, one over it sets to 0
  health = math.min(health,65535)
  local silver = false
  if materials_table[usedMaterial].isSilver == "TRUE" then
    silver = true 
  end
  
  if modCapSettings:get("GlobalCap") then
    chopMax = math.min(chopMax,modCapSettings:get("GlobalArmorCap"))
    chopMin = math.min(chopMin,modCapSettings:get("GlobalArmorCap"))
    slashMax = math.min(slashMax,modCapSettings:get("GlobalArmorCap"))
    slashMin = math.min(slashMin,modCapSettings:get("GlobalArmorCap"))
    thrustMax = math.min(thrustMax,modCapSettings:get("GlobalArmorCap"))
    thrustMin = math.min(thrustMin,modCapSettings:get("GlobalArmorCap"))
  else
    -- caps for each weapon type
    local weaponType = getWeaponType(weaponTemplate.type)
    --print("[DEBUG] Weapon type:",weaponType)
    chopMax = math.min(chopMax,modCapSettings:get(weaponType))
    chopMin = math.min(chopMin,modCapSettings:get(weaponType))
    slashMax = math.min(slashMax,modCapSettings:get(weaponType))
    slashMin = math.min(slashMin,modCapSettings:get(weaponType))
    thrustMax = math.min(thrustMax,modCapSettings:get(weaponType))
    thrustMin = math.min(thrustMin,modCapSettings:get(weaponType))
  end
  
  local weaponTable = {
    name = name,
    template = weaponTemplate,
    chopMaxDamage = chopMax,
    chopMinDamage = chopMin,
    slashMaxDamage = slashMax,
    slashMinDamage = slashMin,
    thrustMaxDamage = thrustMax,
    thrustMinDamage = thrustMin,
    enchantCapacity = enchant_cap,
    weight = weight,
    isSilver = silver,
    health = health
  }
  
  local weaponDraft = types.Weapon.createRecordDraft(weaponTable)
  local newRecord = world.createRecord(weaponDraft)
  if isAmmo(weaponTemplate.type) then
    world.createObject(newRecord.id,ammoCount):teleport(object.cell.name, object.position)
  else
    world.createObject(newRecord.id):teleport(object.cell.name, object.position)
  end
  object:remove()
  materials[1].item:remove(materialCount)
  actor:sendEvent('ShowMessage',{message="Weapon upgraded succesfully."})
end

local function upgradeWeaponHandler(object,actor)
	local weapon = types.Actor.getEquipment(actor,types.Actor.EQUIPMENT_SLOT.CarriedRight)
	local stance = types.Actor.getStance(actor)
	
	if weapon == nil or weapon.recordId ~= hammer_id or stance ~= 1 then return end
	
	actor:sendEvent("GetNearbyWeaponMaterials",{object=object,actor=actor,materials=materials_table})
	return false
end

local function setNearbyMaterials(data)
--	print("[DEBUG] Materials event recieved")
	--print(data)
	--for k,v in ipairs(data.list) do print(v.item,v.distance) end
	local materials = data.list
	local object = data.object
	local actor = data.actor
	
	upgradeWeapon(object,actor,materials)
end

local function loadMaterialTable()
  if vfs.fileExists("scripts\\WeaponUpgrade\\MaterialsStatTable.csv") then
--    print("[DEBUG] File exists")
    local lines = vfs.lines("scripts\\WeaponUpgrade\\MaterialsStatTable.csv")
    lines()
    for line in lines do
    local temp_table = {}
      for item in string.gmatch(line,"([^,]+)") do
        table.insert(temp_table,item)
      end
      
      materials_table[temp_table[1]:lower()] = {
        skill = temp_table[2],
        chop_bonus = temp_table[3],
        slash_bonus = temp_table[4],
        thrust_bonus = temp_table[5],
        enchant_bonus = temp_table[6],
        weight_bonus = temp_table[7],
        health_bonus = temp_table[8],
        isSilver = temp_table[9],
        matches = {}
      }
      
      for i=10,#temp_table do
        table.insert(materials_table[temp_table[1]:lower()].matches,temp_table[i])
      end
      
    end
      print("[WeaponUpgrade] Material stats loaded")
  end
end

Activation.addHandlerForType(types.Weapon,upgradeWeaponHandler)

return{
	eventHandlers = 
		{
		NearbyWeaponMaterials = setNearbyMaterials
		},
		
		engineHandlers = {
		  onLoad = loadMaterialTable,
		  onInit = loadMaterialTable,
		}
}