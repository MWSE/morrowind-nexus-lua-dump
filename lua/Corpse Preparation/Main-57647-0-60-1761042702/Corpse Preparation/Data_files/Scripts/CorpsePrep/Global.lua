--global

local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')


local UndeadTable = { ksn_zombie_summon_prop=true, 
                      ksn_skeleton_weak_prop=true, 
                      corpsepreparation_bonelord=true, 
                      _skeleton=true}

local function ReanimateEffects(Object,Effect)
  --world.vfx.spawn(types.Static.records[core.magic.effects.records[Effect].castStatic].model,Object.position)
  Object:sendEvent("AddVfx",{model=types.Static.records[core.magic.effects.records[Effect].castStatic].model,options={}})
  core.sound.playSound3d(core.magic.effects.records[Effect].areaSound,Object)
end

local function NewItemProp(ItemRecord,Propertie,ItemRatio)
  if ItemRecord[Propertie] then
    return(math.floor(ItemRecord[Propertie]*ItemRatio+0.5))
  end
end

local function CraftItem(data)
  local ItemRecord
  local ItemType

  if types.Weapon.records[data.ItemRecordId] then
    ItemRecord=types.Weapon.records[data.ItemRecordId]
    ItemType=types.Weapon
  elseif types.Armor.records[data.ItemRecordId] then
    ItemRecord=types.Armor.records[data.ItemRecordId]
    ItemType=types.Armor
  elseif types.Clothing.records[data.ItemRecordId] then
    ItemRecord=types.Clothing.records[data.ItemRecordId]
    ItemType=types.Clothing
  end

  local ItemRatio=(types.NPC.stats.skills.armorer(data.Actor).modified/100 * (types.Actor.stats.dynamic.fatigue(data.Actor).current / types.Actor.stats.dynamic.fatigue(data.Actor).base)+ math.random(types.Actor.stats.attributes.luck(data.Actor).modified)/100)

  local NewRecordDatas = {enchantCapacity=NewItemProp(ItemRecord,"enchantCapacity",ItemRatio),
                          health=NewItemProp(ItemRecord,"health",ItemRatio),
                          chopMinDamage=NewItemProp(ItemRecord,"chopMinDamage",ItemRatio),
                          chopMaxDamage=NewItemProp(ItemRecord,"chopMaxDamage",ItemRatio),
                          slashMinDamage=NewItemProp(ItemRecord,"slashMinDamage",ItemRatio),
                          slashMaxDamage=NewItemProp(ItemRecord,"slashMaxDamage",ItemRatio),
                          thrustMinDamage=NewItemProp(ItemRecord,"thrustMinDamage",ItemRatio),
                          thrustMaxDamage=NewItemProp(ItemRecord,"thrustMaxDamage",ItemRatio),
                          template = ItemRecord,}

  Record=world.createRecord(ItemType.createRecordDraft(NewRecordDatas))
  if data.ItemRecordId=="bone_throwingknife" then
    world.createObject(Record.id,10):moveInto(data.Actor)
  else
    world.createObject(Record.id):moveInto(data.Actor)
  end

end



local function Remove(data)
  data.Object:remove(data.Number)
end  

local function CreateZombie(data)
  local Zombie
  ReanimateEffects(data.NPC,data.Effect)

  if types.NPC.records[data.NPC.recordId] then
    Zombie=world.createObject("_Zombie_"..types.NPC.records[data.NPC.recordId].race,1)
  else
    Zombie=world.createObject("_Zombie_imperial",1)
  end
  Zombie:addScript("scripts/corpseprep/undead.lua",{Master=data.Caster})

  Zombie:teleport(data.NPC.cell,data.NPC.position,{rotation=data.NPC.rotation})
  local Equipments=types.Actor.getEquipment(data.NPC)

  local attributes={}
  for i, attribute in pairs(types.NPC.stats.attributes) do
    if attribute(data.NPC).base> 30 then
      attributes[i]=attribute(data.NPC).base - 30
    else
      attributes[i]= 0
    end 
  end
  Zombie:sendEvent("setAttributes",{attributes=attributes})


  local skills={}
  for i, skill in pairs(types.NPC.stats.skills) do
    if skill(data.NPC).base> 20 then
      skills[i]=skill(data.NPC).base - 20
    else
      skills[i]= 0
    end 
  end
  Zombie:sendEvent("setSkills",{skills=skills})


  
  Zombie:sendEvent("setLevel",{level=types.NPC.stats.level(data.NPC).current})

  for i, item in ipairs(types.Actor.inventory(data.NPC):getAll()) do
    item:moveInto(Zombie)
  end

  Zombie:sendEvent("Equip",{Equipment=Equipments})
  Zombie:sendEvent("Order",{Order="Follow",Target=data.Caster})
  Zombie:sendEvent("playAnimReanim")
  data.Caster:sendEvent("NewMinion",{Minion=Zombie})
  data.NPC:remove()
end




local function ReanimateUndead(data)
  local Undead
  Undead=world.createObject(data.Undead,1)
  Undead:addScript("scripts/corpseprep/undead.lua",{Master=data.Caster})
  ReanimateEffects(data.Object,data.Effect)
  Undead:teleport(data.Object.cell,data.Object.position)
  Undead:sendEvent("Order",{Order="Follow",Target=data.Caster})
  Undead:sendEvent("playAnimReanim")
  data.Caster:sendEvent("NewMinion",{Minion=Undead})
  data.Object:remove()
end





local function NecromancyCrime(data)
  if data.Player.type==types.Player then
    if types.Player.getCrimeLevel(data.Player) < 1000 then
      I.Crimes.commitCrime(data.Player, {type = types.Player.OFFENSE_TYPE.Murder})
    end
  end
end





return {
    eventHandlers = { CreateZombie=CreateZombie,
                      Remove=Remove, 
                      CraftItem=CraftItem,
                      ReanimateUndead=ReanimateUndead,
                      NecromancyCrime = NecromancyCrime,
    },
    engineHandlers = {
  
  
  }
  }

