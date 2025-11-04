
local I = require('openmw.interfaces')
local util = require('openmw.util')
local async = require('openmw.async')
local self = require('openmw.self')
local nearby = require('openmw.nearby')
local types = require('openmw.types')
local core = require('openmw.core')

local ReanimateEffect=core.magic.EFFECT_TYPE.TurnUndead
local Harvested={}


local MiscUndeads={
  ksn_skeleton="_skeleton",
  ksn_shambles="shambles",
  ksn_skull_spider="skullspider",
  ksn_bone_coloss="bonecoloss",
  ksn_bonelord="bonelord",
  ksn_bonewalker="bonewalker",
  ksn_greater_bonewalker="bonewalker_greater",
  ksn_ghost="ghost",
}


local function ReanimateLoop(EffectPosition,Loop,Area)
  local TargetList={}
  local SpellLoop=Loop
  for i, actor in pairs(nearby.actors) do 
    if actor.type==types.NPC and types.Actor.isDead(actor) and string.find(types.NPC.records[actor.recordId].race,"zombie")==nil then
      table.insert(TargetList,actor) 
    end
  end
  for i, item in pairs(nearby.items) do 
    if MiscUndeads[item.recordId] then 
      table.insert(TargetList,item) 
    end 
  end
  for i, target in ipairs(TargetList) do
    if (target.position-EffectPosition):length()<Area*22 then
      if target.type==types.NPC then
        if Harvested[target.id] then
          self:sendEvent("ShowMessage",{message="You can't reanimate an harvested corpse"})
        else
          core.sendGlobalEvent("CreateZombie",{NPC=target,Caster=self, Effect=ReanimateEffect})
          self:sendEvent("ShowMessage",{message="You reanimate the corpse"})
          core.sendGlobalEvent("NecromancyCrime",{Player=self})
          SpellLoop=SpellLoop-1
        end
      elseif target.type==types.Miscellaneous and MiscUndeads[target.recordId] then
        core.sendGlobalEvent("ReanimateUndead",{Object=target,Caster=self,Undead=MiscUndeads[target.recordId], Effect=ReanimateEffect})
        core.sendGlobalEvent("NecromancyCrime",{Player=self})
        SpellLoop=SpellLoop-1
      end
      if SpellLoop==0 then break end
    end
  end  
end


local function CastReanimateSpell(EffectDatas)------------ Réécrire avec spell loop sur tout les lancés
  


  nearby.asyncCastRenderingRay(async:callback(function(rayResult)
      local RayEndPosition=util.vector3(0, 0, 110) + self.position+util.vector3(math.cos(self.rotation:getPitch()) * math.sin(self.rotation:getYaw()), math.cos(self.rotation:getPitch()) * math.cos(self.rotation:getYaw()), -math.sin(self.rotation:getPitch()))*EffectDatas.Range
      if rayResult.hitPos then
        RayEndPosition=rayResult.hitPos
      end
      if rayResult.hitObject and types.NPC.objectIsInstance(rayResult.hitObject) == true and  types.Actor.isDead(rayResult.hitObject) == true then
        if string.find(types.NPC.records[rayResult.hitObject.recordId].race,"zombie")==nil then
          if Harvested[rayResult.hitObject.id] then
            self:sendEvent("ShowMessage",{message="You can't reanimate an harvested corpse"})
          else
            core.sendGlobalEvent("CreateZombie",{NPC=rayResult.hitObject,Caster=self, Effect=ReanimateEffect})
            self:sendEvent("ShowMessage",{message="You reanimate the corpse"})
            core.sendGlobalEvent("NecromancyCrime",{Player=self})
            ReanimateLoop(rayResult.hitPos,EffectDatas.Magnitude-1,EffectDatas.Area)
          end
        end
      elseif rayResult.hitObject and rayResult.hitObject.type==types.Miscellaneous and MiscUndeads[rayResult.hitObject.recordId] then
        core.sendGlobalEvent("ReanimateUndead",{Object=rayResult.hitObject,Caster=self,Undead=MiscUndeads[rayResult.hitObject.recordId], Effect=ReanimateEffect})
        core.sendGlobalEvent("NecromancyCrime",{Player=self})
        ReanimateLoop(rayResult.hitPos,EffectDatas.Magnitude-1,EffectDatas.Area)
      else
        ReanimateLoop(RayEndPosition,EffectDatas.Magnitude,EffectDatas.Area)
      end
		end),
		util.vector3(0, 0, 110) + self.position,
		util.vector3(0, 0, 110) + self.position +
		util.vector3(math.cos(self.rotation:getPitch()) * math.sin(self.rotation:getYaw()), math.cos(self.rotation:getPitch()) * math.cos(self.rotation:getYaw()), -math.sin(self.rotation:getPitch()))*EffectDatas.Range,
    {ignore=self})
end

local function ReanimateSpell(spell)
  local SpellDatas
  for i, effect in pairs(spell.effects) do
    if effect.id==ReanimateEffect then
      if not(SpellDatas) then
        SpellDatas={Range=0,Magnitude=0,Area=0}
      end
      if effect.duration==1332 then
        if effect.range==core.magic.RANGE.Self then
          SpellDatas.Range=0
        elseif effect.range==core.magic.RANGE.Target then
          SpellDatas.Range=10000
        elseif effect.range==core.magic.RANGE.Touch then
          SpellDatas.Range=100
        end
        SpellDatas.Magnitude=effect.magnitudeMin
        SpellDatas.Area=effect.area
      end
    end
  end
  return(SpellDatas)
end
                                
I.AnimationController.addTextKeyHandler("spellcast", function(group, key)
  if key=="touch release" or key=="target release" or key=="self release"  then
    local EffectDatas=ReanimateSpell(types.Actor.getSelectedSpell(self))
    if core.sound.isSoundPlaying("spell failure mysticism",self)==false 
      and core.sound.isSoundPlaying("spell failure restoration",self)==false 
      and core.sound.isSoundPlaying("spell failure illusion",self)==false 
      and core.sound.isSoundPlaying("spell failure destruction",self)==false 
      and core.sound.isSoundPlaying("spell failure alteration",self)==false 
      and core.sound.isSoundPlaying("spell failure mysticism",self)==false 
      and core.sound.isSoundPlaying("spell failure conjuration",self)==false 
      and EffectDatas and types.Actor.stats.dynamic.magicka(self).current>=core.magic.spells.records[types.Actor.getSelectedSpell(self).id].cost then
        CastReanimateSpell(EffectDatas)
    end
  end
end)

local LastEnchantment={Item,Charge}
local function onUpdate(dt)
  if dt>0 then
    local EnchatedItem=types.Actor.getSelectedEnchantedItem(self)
    if EnchatedItem and core.magic.enchantments.records[EnchatedItem.type.records[EnchatedItem.recordId].enchant].type==core.magic.ENCHANTMENT_TYPE.CastOnUse then
      local ItemCharge=types.Item.itemData(EnchatedItem).enchantmentCharge 
      if EnchatedItem==LastEnchantment.Item then
        if LastEnchantment.Charge>ItemCharge then
          LastEnchantment.Item=ItemCharge
--          print("triggerEnchant")
          local EffectDatas=ReanimateSpell(core.magic.enchantments.records[EnchatedItem.type.records[EnchatedItem.recordId].enchant])
          if EffectDatas then
            print("REanimateEnchant")
            CastReanimateSpell(EffectDatas)
          end
        end
      else
        LastEnchantment.Item=EnchatedItem
        LastEnchantment.Charge=ItemCharge
      end

    end

  end

end


local function UpdateHarvested(data)
  for harvested, boolean in pairs(data.Harvested) do
    Harvested[harvested]=boolean
  end
end




local function onSave()
	return{Harvested=Harvested}

end

local function onLoad(data)
	if data and data.Harvested then
		Harvested=data.Harvested
	end
end


return {
  engineHandlers = {  onSave=onSave,
                      onLoad=onLoad,
                      onUpdate=onUpdate,


  },
  eventHandlers={UpdateHarvested=UpdateHarvested



  }
}