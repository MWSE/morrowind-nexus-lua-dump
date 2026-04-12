local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local async = require('openmw.async')

local summonStorage = storage.globalSection('RitualSummon')
local data = summonStorage:getCopy('SummonData')

local inv_potions = nil
local inv_weapons = nil

local mode = nil
if data then
  mode = data.mode
  if self.id ~= data.gId then
    core.sendGlobalEvent('R_Summon_Remove',{actor=self})
    mode = "deletion"
  end
end

summonStorage:subscribe(async:callback(
  function(section,key)
    if section == 'RitualSummon' then
      if key == 'SummonData' then
        data = summonStorage:getCopy('SummonData')
        if not data then return end
        mode = data.mode
        if self.id ~= data.gId then
          if self.isValid(self) then
            mode = "deletion"
            core.sendGlobalEvent('R_Summon_Remove',{actor=self})
            mode = "deletion"
          end
        end
      end
    end
  end)
)

local function onActivated(actor)
  if actor.type == types.Player then
    actor:sendEvent('R_Summon_GUI_Open',{actor=self})
  end
end

local function onInactive()
  if mode ~= "stay" and mode ~= "deletion" then
    core.sendGlobalEvent('R_TeleportToPlayer',{actor=self})
  end
end

local function onActive()
  if mode ~= "deletion" then
    core.sendGlobalEvent('R_Active_Summon',{actor=self})
  end
end

local function changeMode(data)
  mode = data.mode
end

local function applyRest(data)
  local mRest = core.getGMST('fRestMagicMult')
  
  local hBase = types.Actor.stats.dynamic.health(self).base
  local mBase = types.Actor.stats.dynamic.magicka(self).base
  local fBase = types.Actor.stats.dynamic.fatigue(self).base
  
  local health = types.Actor.stats.dynamic.health(self).current
  local magicka = types.Actor.stats.dynamic.magicka(self).current
  local fatigue = types.Actor.stats.dynamic.fatigue(self).current
  
  local intelligence = types.Actor.stats.attributes.intelligence(self).modified
  local endurance = types.Actor.stats.attributes.endurance(self).modified
  
  local hours = data.duration/3600
--  print("Rested for:",hours,"hours")
  
  local newHealth = health + (0.1 * endurance * hours)
  newHealth = newHealth + (newHealth * mRest)
  
  local newMagicka = magicka + (0.15 * intelligence * hours)
  newMagicka = newMagicka + (newMagicka * mRest)
  
  local newFatigue = fatigue + (1000 * hours)
  
  newFatigue = math.min(newHealth,fBase)
  newHealth = math.min(newHealth, hBase)
  newMagicka = math.min(newMagicka, mBase)
  
  types.Actor.stats.dynamic.health(self).current = newHealth
  types.Actor.stats.dynamic.magicka(self).current = newMagicka
  types.Actor.stats.dynamic.fatigue(self).current = newFatigue
--  print("New stats - Health:", newHealth, "Magicka:", newMagicka, "Fatigue:", newFatigue)
end

local function drinkStart()
  inv_potions = {}
  local temp = types.Actor.inventory(self):getAll(types.Potion)
  for _,potion in ipairs(temp) do
--    print("Saved lookup of",potion.id,potion.count)
    inv_potions[potion.id] = {id=potion.id,count=potion.count}
  end
end

local function drinkEnd()
  local newPotions = {}
  local newInv = types.Actor.inventory(self):getAll(types.Potion)
--  print("New inventory")
  
  for _,potion in ipairs(newInv) do
--    print("checking:",potion.id,potion.count)
    local old = inv_potions[potion.id]
    if not old then
      table.insert(newPotions,{item=potion,count=potion.count})
    else
      local dif = potion.count - old.count
--      print("potions the same, count dif:",dif)
      if dif > 0 then
        table.insert(newPotions,{item=potion,count=dif})
      end
    end
  end
  
  for id,potion in ipairs(newPotions) do
--    print("New potion:",potion.item,potion.count)
    for i=1,potion.count do
      core.sendGlobalEvent('UseItem', {object = potion.item, actor = self, force = true})
    end
  end
  
  inv_potions = nil
end

local function wieldStart()
  inv_weapons = {}
  local temp = types.Actor.inventory(self):getAll(types.Weapons)
  for _,weapon in ipairs(temp) do
--    print("Saved lookup of",weapon.id,weapon.count)
    inv_weapons[weapon.id] = {id=weapon.id,count=weapon.count}
  end
end

local function wieldEnd()
  local newWeapons = {}
  local newInv = types.Actor.inventory(self):getAll(types.Weapon)
  
  for _,weapon in ipairs(newInv) do
    local old = inv_weapons[weapon.id]
    if not old then
      table.insert(newWeapons,{item=weapon,count=weapon.count})
    else
      local dif = weapon.count - old.count
--      print("weapons the same, count dif:",dif)
      if dif > 0 then
        table.insert(newWeapons,{item=weapon,count=dif})
      end
    end
  end
  
  for id,weapon in ipairs(newWeapons) do
--    print("New weapon:",weapon.item,weapon.count)
    core.sendGlobalEvent('UseItem', {object = weapon.item, actor = self, force = true})
  end
  
  inv_potions = nil
end

local function died()
  core.sendGlobalEvent('R_Summon_Remove',{actor=self,clean=true,category='r_summon'})
  mode = "deletion"
end

return {
  eventHandlers = {
    R_SummonChangeMode = changeMode,
    R_RestSummon = applyRest,
    R_DrinkPotion_Start = drinkStart,
    R_DrinkPotion_End = drinkEnd,
    R_Wield_Start = wieldStart,
    R_Wield_End = wieldEnd,
    Died = died,
  },
  engineHandlers = {
    onActivated = onActivated,
    onActive = onActive,
    onInactive = onInactive,
  }
}