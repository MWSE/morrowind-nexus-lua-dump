local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local vfs = require('openmw.vfs')
local Activation = require('openmw.interfaces').Activation
local storage = require('openmw.storage')

local materials_table = {}
local hammer_id = "repair_hammer_weapon"

local modSettings = storage.globalSection("SettingsArmorUpgrade")

local function determineArmorClass(weight,type)
  local typeMap = {
    [types.Armor.TYPE.Boots] = "iBootsWeight",
    [types.Armor.TYPE.Cuirass] = "iCuirassWeight",
    [types.Armor.TYPE.Greaves] = "iGreavesWeight",
    [types.Armor.TYPE.Helmet] = "iHelmWeight",
    [types.Armor.TYPE.LBracer] = "iGauntletWeight",
    [types.Armor.TYPE.LGauntlet] = "iGauntletWeight",
    [types.Armor.TYPE.LPauldron] = "iPauldronWeight",
    [types.Armor.TYPE.RBracer] = "iGauntletWeightt",
    [types.Armor.TYPE.RGauntlet] = "iGauntletWeight",
    [types.Armor.TYPE.RPauldron] = "iPauldronWeight",
    [types.Armor.TYPE.Shield] = "iShieldWeight",
  }
  
  local iWeight = core.getGMST(typeMap[type])
  local epsilon = 0.0005
  
  if weight <= iWeight*core.getGMST("fLightMaxMod")+epsilon then return modSettings:get("LightCap")
  elseif weight <= iWeight*core.getGMST("fMedMaxMod")+epsilon then return modSettings:get("MediumCap")
  else return modSettings:get("HeavyCap")
  end
  
end

local function sendSoundEvent(name,actor)
  actor:sendEvent("PlaySound",{name=name})
end

local function sendMessageEvent(content,actor)
  actor:sendEvent("ShowMessage",{text=content})
end

local function upgradeArmor(object,actor,materials)
--	print("[DEBUG] Starting the upgrade.")
	local armorTemplate = types.Armor.record(object)
--	print(armorTemplate.id)
	
	if materials[1] == nil then
	-- No mats to upgrade with
	 sendMessageEvent("There are no materials nearby to upgrade with.",actor)
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
	   sendMessageEvent("Not skilled enough to work with that material. ".."("..requiredSkill.." needed)",actor)
	   return
	 end
--	 print("[DEBUG] required skill:",requiredSkill)
	end
	
	if types.Item.itemData(object).condition == 0 then
	   sendMessageEvent("Armor is too damaged to upgrade.",actor)
	 return
	end
	
	if not modSettings:get("AlwaysSucceed") then
	 local playerSkill = types.Player.stats.skills.armorer(actor).modified
--	 print("[DEBUG] player skill:",playerSkill)
   local successRate = 85 + (playerSkill - requiredSkill) * 3 - (materialCount-1) * (6+requiredSkill/10)
	 if math.random(1,100) > successRate then
	   --failiure
	   types.Item.itemData(object).condition = types.Item.itemData(object).condition - armorTemplate.health * 0.2
	   sendMessageEvent("Failed to upgrade armor.",actor)
	   sendSoundEvent("repair fail",actor)
	   return
	 end
	end
	
	--sucess
	
	local name = armorTemplate.name
	--local name = "Tempered "..armorTemplate.name
	
--	print("[DEBUG] Inifinite upgrades: ",modSettings:get("InfiniteUpgrades"))
	if modSettings:get("InfiniteUpgrades") then
	 if not string.find(name,"Tempered") then
	   name = "Tempered "..name
	 end
	elseif string.find(armorTemplate.name,"Tempered") then
	 --Already upgraded
--	 print("[DEBUG] Armor already upgraded, aborting.")
	 sendMessageEvent("Can not upgrade armor again.",actor)
	 return
	else
	 name = "Tempered "..name
	end
	
	sendSoundEvent("repair",actor)
	
--	print("[DEBUG] Closest material: ",materials[1].item.recordId,"Distance:",materials[1].distance,"Count:",materials[1].item.count)

	local armorCap = determineArmorClass(armorTemplate.weight,armorTemplate.type)
--	print("[DEBUG] Armor cap: ",armorCap)
	
	local ar_bonus = armorTemplate.baseArmor + (materials_table[usedMaterial].ar_bonus * materialCount)
	ar_bonus = math.min(ar_bonus,armorCap)
	--It's linear, not compounding
	local enchant_bonus = armorTemplate.enchantCapacity + armorTemplate.enchantCapacity * materials_table[usedMaterial].enchant_bonus * materialCount
	local health_bonus = armorTemplate.health + armorTemplate.health * materials_table[usedMaterial].health_bonus * materialCount
	
	if modSettings:get("IgnoreWeight") then
	 local weight_bonus = armorTemplate.weight
	else
	 --No weight stacking using multiple materials, yippeee!
	 local weight_bonus = armorTemplate.weight + armorTemplate.weight * materials_table[usedMaterial].weight_bonus
	end
	
	
	local armorTable = {
  	name = name,
  	template = armorTemplate,
  	baseArmor = ar_bonus,
  	enchantCapacity = enchant_bonus,
  	health = health_bonus,
  	weight = weight_bonus
  	}
	
	local armorDraft = types.Armor.createRecordDraft(armorTable)
--	print("Armor ID: ",armorDraft.id)
	local newRecord = world.createRecord(armorDraft)
	world.createObject(newRecord.id):teleport(object.cell.name, object.position)
	object:remove()
	materials[1].item:remove(materialCount)
	
	sendMessageEvent("Armor upgraded successfully.",actor)
--	print("[DEBUG] Upgrade finished.")
--	print("-------------------------------")
	--for k,v in pairs(types.Armor.records) do print(v,v.id) end
	--world.createObject(newRecord.id):moveInto(actor)
end

local function upgradeHandler(object,actor)
	local weapon = types.Actor.getEquipment(actor,types.Actor.EQUIPMENT_SLOT.CarriedRight)
	local stance = types.Actor.getStance(actor)
	
	if weapon.recordId ~= hammer_id or stance ~= 1 then return end
	
	--this is redundant if function is applied only to armors
	if object.type == types.Armor then
		actor:sendEvent("GetNearbyMaterials",{object=object,actor=actor,materials=materials_table})
--		actor:sendEvent("ArmorActivated",{})
		
		--upgradeArmor(object,actor)
		--core.sendGlobalEvent("UpgradeArmor",{object=object,actor=actor})
		return false
	end
end

function setNearbyMaterials(data)
--	print("[DEBUG] Materials event recieved")
	--print(data)
	--for k,v in ipairs(data.list) do print(v.item,v.distance) end
	local materials = data.list
	local object = data.object
	local actor = data.actor
	
	upgradeArmor(object,actor,materials)
end

function loadMaterialTable()
  if vfs.fileExists("scripts\\ArmorUpgrade\\MaterialsStatTable.csv") then
--    print("[DEBUG] File exists")
    local lines = vfs.lines("scripts\\ArmorUpgrade\\MaterialsStatTable.csv")
    lines()
    for line in lines do
    local temp_table = {}
      for item in string.gmatch(line,"([^,]+)") do
        table.insert(temp_table,item)
      end
      
      materials_table[temp_table[1]] = {
        ar_bonus = temp_table[2],
        skill = temp_table[3],
        health_bonus = temp_table[4],
        enchant_bonus = temp_table[5],
        weight_bonus = temp_table[6]
      }
    end
      print("[ArmorUpgrade] Material stats loaded")
  end
end

Activation.addHandlerForType(types.Armor,upgradeHandler)

return{
	eventHandlers = 
		{
		NearbyMaterials = setNearbyMaterials
		},
		
		engineHandlers = {
		  onLoad = loadMaterialTable,
		  onInit = loadMaterialTable,
		}
}