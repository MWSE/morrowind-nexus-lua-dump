--global

local I = require('openmw.interfaces')
local types = require('openmw.types')
local world = require('openmw.world')
local SecondEquipKeys={}

local function EquipSecondWeaponKey(data)
	SecondEquipKeys[data.Actor.id]=data.Bolean
end

local function onUpdate(dt)
    
end

local function setCharge(data)
	types.Item.itemData(data.Item).enchantmentCharge=data.Charge
end


I.ItemUsage.addHandlerForType(types.Weapon, function(weapon, actor)
    if SecondEquipKeys[actor.id]==true then
      local WeaponType=types.Weapon.records[weapon.recordId].type
      if WeaponType==types.Weapon.TYPE.AxeOneHand 
      or WeaponType==types.Weapon.TYPE.BluntOneHand 
      or WeaponType==types.Weapon.TYPE.LongBladeOneHand 
      or WeaponType==types.Weapon.TYPE.ShortBladeOneHand then
        actor:sendEvent("EquipSecondWeapon",{Weapon=weapon})
        return false
      else
          actor:sendEvent('ShowMessage', {message = 'You can only use a one hand weapon with your left hand.'})
      end
    end
end)



return {
    eventHandlers = {
      EquipSecondWeaponKey=EquipSecondWeaponKey,
      OnStrikesetCharge=setCharge,

    },
    engineHandlers = {onUpdate=onUpdate,
    onActivate=onActivate
  
  
  }
  }

