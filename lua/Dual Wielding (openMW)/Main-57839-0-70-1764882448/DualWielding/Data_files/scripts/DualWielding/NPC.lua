local self=require('openmw.self')
local anim = require('openmw.animation')
local types = require('openmw.types')
local core = require('openmw.core')
local I=require('openmw.interfaces')
local util=require('openmw.util')
local time=require('openmw_aux.time')
local async = require('openmw.async')
local storage = require('openmw.storage')
local nearby = require('openmw.nearby')
local debug

local isPlayer = types.Player.objectIsInstance(self)

if isPlayer then
    debug = require 'openmw.debug'
end
local fatigue = self.type.stats.dynamic.fatigue(self)
local debug
local self = require 'openmw.self'
local types = require 'openmw.types'

local isPlayer = types.Player.objectIsInstance(self)

if isPlayer then
    debug = require 'openmw.debug'
end
local fatigue = self.type.stats.dynamic.fatigue(self)

local function AttackFatigueLoss(weapon, attackStrength)
    local fFatigueAttackBase = core.getGMST("fFatigueAttackBase")
    local fFatigueAttackMult = core.getGMST("fFatigueAttackMult")
    local fWeaponFatigueMult = core.getGMST("fWeaponFatigueMult")

    local encumbrance = self.type.getEncumbrance(self)
    local capacity = self.type.getCapacity(self)
    local normalizedEncumbrance = encumbrance / capacity

    local godMode = isPlayer and debug.isGodMode()

    if not godMode then
        local fatigueLoss = fFatigueAttackBase + normalizedEncumbrance * fFatigueAttackMult

        if weapon then
            local weaponWeight = weapon.type.records[weapon.recordId].weight
            fatigueLoss = fatigueLoss + weaponWeight * attackStrength * fWeaponFatigueMult
        end
        if fatigue.current - fatigueLoss<0 then
          fatigue.current = 0
        else
          fatigue.current = fatigue.current - fatigueLoss
        end
    end
end




local LeftAttacks={"weaponleftslash","weaponleftchop","weaponleftthrust"}
local LastAttack="Right"
local EquipSecondWeaponState=false
local SecondWeapon
local SecondWeaponConstantEnchant
local Stance=types.Actor.getStance(self)

local SwitchFrameTempo=3


local EnchantTypes={"Cast When Strikes","Cast When Used", "Constant Effect", "Cast Once"}
local RangeTypes={"on Self ","on Touch ","on Range "}


local WeaponTypesForSecond={}
WeaponTypesForSecond[types.Weapon.TYPE.ShortBladeOneHand]=true
WeaponTypesForSecond[types.Weapon.TYPE.LongBladeOneHand]=true
WeaponTypesForSecond[types.Weapon.TYPE.AxeOneHand]=true
WeaponTypesForSecond[types.Weapon.TYPE.BluntOneHand]=true


local function RemoveSecondWeapon()
  if SecondWeapon then
    local Enchant=types.Weapon.records[SecondWeapon.recordId].enchant
    if Enchant and  core.magic.enchantments.records[Enchant].type==core.magic.ENCHANTMENT_TYPE.ConstantEffect then
      types.Actor.activeSpells(self):remove(Enchant)
      SecondWeaponConstantEnchant=nil
    end
    SecondWeapon=nil
    anim.removeVfx(self, "LeftWeaponVFX")
    core.sound.playSound3d("item weapon shortblade down", self) 
    self:sendEvent("RemoveSecondWeaponUI")
            
    LastAttack="Right"
    anim.cancel(self, "weaponleftslash")
    anim.cancel(self, "weaponleftchop")
    anim.cancel(self, "weaponleftthrust")
  end
end


local function HitSucces(attacker,defender,weapon)
  local hit=false
  local attackerFatigueTerm = core.getGMST("fFatigueBase") - core.getGMST("fFatigueMult")*(1 - types.Actor.stats.dynamic.fatigue(attacker).current/types.Actor.stats.dynamic.fatigue(attacker).base)
  local defenderFatigueTerm = core.getGMST("fFatigueBase") - core.getGMST("fFatigueMult")*(1 - types.Actor.stats.dynamic.fatigue(defender).current/types.Actor.stats.dynamic.fatigue(defender).base)
  local skills={}
  skills[types.Weapon.TYPE.BluntOneHand]=types.NPC.stats.skills.bluntweapon(attacker).modified
  skills[types.Weapon.TYPE.LongBladeOneHand]=types.NPC.stats.skills.longblade(attacker).modified
  skills[types.Weapon.TYPE.ShortBladeOneHand]=types.NPC.stats.skills.shortblade(attacker).modified
  skills[types.Weapon.TYPE.AxeOneHand]=types.NPC.stats.skills.axe(attacker).modified
  local skill=skills[types.Weapon.records[weapon.recordId].type]
  local attackTerm =(skill + 0.2 * types.Actor.stats.attributes.agility(attacker).modified + 0.1 * types.Actor.stats.attributes.luck(attacker).modified) * attackerFatigueTerm
  attackTerm=attackTerm+types.Actor.activeEffects(attacker):getEffect(core.magic.EFFECT_TYPE.FortifyAttack).magnitude-types.Actor.activeEffects(attacker):getEffect(core.magic.EFFECT_TYPE.Blind).magnitude

  local defenseTerm = 0
  if types.Actor.stats.dynamic.fatigue(defender).current then
    if types.Actor.canMove(defender)==true and types.Actor.getStance(defender)~=types.Actor.STANCE.Nothing then
      defenseTerm=(0.2*types.Actor.stats.attributes.agility(attacker).modified + 0.1 * types.Actor.stats.attributes.luck(attacker).modified) * attackerFatigueTerm
      if types.Actor.activeEffects(attacker):getEffect(core.magic.EFFECT_TYPE.Sanctuary).magnitude>100 then
        defenseTerm=defenseTerm+100
      else
         defenseTerm=defenseTerm+types.Actor.activeEffects(attacker):getEffect(core.magic.EFFECT_TYPE.Sanctuary).magnitude
      end
    end
  end

  local x=util.round(attackTerm-defenseTerm)
  if x>0 and math.random(100)<x then
    hit=true
  end

  return(hit)
end



local function Damage(Weapon,AttackType,Actor)

  local damageMin,  damageMax
  local WeaponRec=types.Weapon.records[Weapon.recordId]
  if AttackType == self.ATTACK_TYPE.Chop then
    damageMin, damageMax = WeaponRec.chopMinDamage or 0, WeaponRec.chopMaxDamage or 0
  elseif AttackType == self.ATTACK_TYPE.Thrust then
    damageMin, damageMax = WeaponRec.thrustMinDamage or 0, WeaponRec.thrustMaxDamage or 0
  else
    damageMin, damageMax = WeaponRec.slashMinDamage or 0, WeaponRec.slashMaxDamage or 0
  end

  local rawDamage = damageMin + 0.1 * (damageMax - damageMin)
  rawDamage = rawDamage*(0.5 + 0.01 * types.Actor.stats.attributes.strength(Actor).modified)
  rawDamage = rawDamage*types.Item.itemData(Weapon).condition/types.Weapon.records[Weapon.recordId].health
  return(rawDamage)
end  



I.AnimationController.addTextKeyHandler("", function(group, key)
  if SecondWeapon then


    if types.Player.objectIsInstance(self)==false then
--    print(self.recordId,group,key, LastAttack)----------------------------------------------
    else
--    print(self.recordId,group,key, LastAttack)----------------------------------------------
    end
    if group=="weapononehand" then
      if LastAttack=="Right" then
        if string.find(key,"follow stop") then
          LastAttack="RightStop"
        end
      elseif LastAttack=="RightStop" then
        if core.sound.isSoundPlaying("weapon swish", self) then
          core.sound.stopSound3d("weapon swish", self)
        end
        LastAttack='Left'
        local Animation=LeftAttacks[math.random(3)]
        AttackFatigueLoss(SecondWeapon,0.1)
        I.AnimationController.playBlendedAnimation( Animation, {startKey="start", stopKey="stop", priority  ={	[anim.BONE_GROUP.RightArm] = anim.PRIORITY.Weapon,
                                                                                        [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
                                                                                        [anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,} })
        core.sound.playSound3d("Swishm", self)
        anim.cancel(self, "weapononehand")
      elseif  LastAttack=="Left" then
        if core.sound.isSoundPlaying("weapon swish", self) then
          core.sound.stopSound3d("weapon swish", self)
        end
        anim.cancel(self, "weapononehand")
      end

      
      if  string.find(key,"unequip") then
        LastAttack="Right"
        anim.cancel(self, "weaponleftslash")
        anim.cancel(self, "weaponleftchop")
        anim.cancel(self, "weaponleftthrust")
      end


    elseif LastAttack=='Left' and (group=="weaponleftslash" or group=="weaponleftchop" or group=="weaponleftthrust") then
      if string.find(key,"stop") then
        LastAttack="Right"
      elseif string.find(key,"hit") then       
        local RotZ = self.rotation:getPitch()
        local RotX = self.rotation:getYaw()
        local Distance = types.Weapon.records[SecondWeapon.recordId].reach*100
        local Target = nearby.castRay(
				util.vector3(0, 0, self:getBoundingBox().halfSize.z*3/2) + self.position,
				util.vector3(0, 0, self:getBoundingBox().halfSize.z*3/2) + self.position +
				util.vector3(math.cos(RotZ) * math.sin(RotX), math.cos(RotZ) * math.cos(RotX), -math.sin(RotZ)) * Distance,{ignore=self})


        if Target and Target.hitObject and types.Actor.objectIsInstance(Target.hitObject) and types.Actor.isDead(Target.hitObject)==false then
          local Hit=HitSucces(self,Target.hitObject,SecondWeapon)
          local attackType=self.ATTACK_TYPE.Slash
          local WeaponRec=types.Weapon.records[SecondWeapon.recordId]
          if group=="weaponleftchop" then
            attackType=self.ATTACK_TYPE.Chop
          elseif group=="weaponleftthrust" then
            attackType=self.ATTACK_TYPE.Thrust
          end

            local attack = {
              attacker = self,
              weapon = SecondWeapon,
              sourceType = I.Combat.ATTACK_SOURCE_TYPES.Melee,
              strength = 0.1,
              hitPos=Target.hitPos,
              type = attackType,
              damage = {
                  health = Damage(SecondWeapon,attackType,self),
              },
              successful = Hit,
          }
          Target.hitObject:sendEvent('Hit', attack)
          
          local skill = (WeaponRec.type == types.Weapon.TYPE.ShortBladeOneHand) and 'shortblade'
                     or (WeaponRec.type == types.Weapon.TYPE.LongBladeOneHand)  and 'longblade'
                     or (WeaponRec.type == types.Weapon.TYPE.AxeOneHand)        and 'axe'
                     or (WeaponRec.type == types.Weapon.TYPE.BluntOneHand)      and 'bluntweapon'
                     or nil
          if Hit==true and skill and I.SkillProgression and I.SkillProgression.skillUsed then
            I.SkillProgression.skillUsed(skill, { useType = I.SkillProgression.SKILL_USE_TYPES.Weapon_SuccessfulHit })
          end

          if WeaponRec.enchant and core.magic.enchantments.records[WeaponRec.enchant].type==core.magic.ENCHANTMENT_TYPE.CastOnStrike and types.Item.itemData(SecondWeapon).enchantmentCharge>util.round(core.magic.enchantments.records[WeaponRec.enchant].cost*(1.1-types.NPC.stats.skills.enchant(self).modified/100)) then
            I.SkillProgression.skillUsed("enchant", { useType = I.SkillProgression.SKILL_USE_TYPES.Enchant_CastOnStrike})
          end
        end
        if types.Player.objectIsInstance(self)==false then-----------Better find some better to solve the NPC only idle1h after the left attack
          local CombatTarget=I.AI.getActiveTarget("Combat")
          I.AI.startPackage({type="Wander"})
          if CombatTarget then
            I.AI.startPackage({type="Combat",target=CombatTarget})
          end
        end
--        print("Hit Left")
      end
    end
  end
end)




I.AnimationController.addPlayBlendedAnimationHandler(function (groupname, options)
  if SecondWeapon then
    if groupname=="weaponleftslash" or groupname=="weaponleftchop" or groupname=="weaponleftthrust" then
      options.speed=types.Weapon.records[SecondWeapon.recordId].speed/2
    end
  end
end)


local function EquipSecondWeapon(data)
  local RightWeapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
  SecondWeapon=data.Weapon
  if RightWeapon and types.Weapon.records[RightWeapon.recordId] then
    if types.Item.itemData(SecondWeapon).condition>0 then
      local RightWeaponType=types.Weapon.records[RightWeapon.recordId].type
      if  RightWeaponType==types.Weapon.TYPE.AxeOneHand or RightWeaponType==types.Weapon.TYPE.BluntOneHand or RightWeaponType==types.Weapon.TYPE.LongBladeOneHand or RightWeaponType==types.Weapon.TYPE.ShortBladeOneHand then
        SecondWeaponConstantEnchant=nil
        if types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedLeft) then
          local NewEquipment=types.Actor.getEquipment(self)
          NewEquipment[types.Actor.EQUIPMENT_SLOT.CarriedLeft]=nil
          types.Actor.setEquipment(self,NewEquipment)
        end
        anim.removeVfx(self, "LeftWeaponVFX")
        if types.Actor.getStance(self)==types.Actor.STANCE.Weapon then
          anim.removeVfx(self, "LeftWeaponVFX")
--          anim.addVfx(self, types.Weapon.records[SecondWeapon.recordId].model , {loop=true, boneName="Weapon Left Bone",vfxId ="LeftWeaponVFX"})
          anim.addVfx(self, types.Weapon.records[SecondWeapon.recordId].model , {loop=true, useAmbientLight=false, boneName="Weapon Bone left",vfxId ="LeftWeaponVFX"})
--          print("VFX added 1")
        end
         local Enchant=types.Weapon.records[SecondWeapon.recordId].enchant
        if Enchant then
          if core.magic.enchantments.records[Enchant].type==core.magic.ENCHANTMENT_TYPE.ConstantEffect then
            local effestsnum={}
            for i, effect in pairs(core.magic.enchantments.records[Enchant].effects) do
              anim.addVfx(self,types.Static.records[effect.effect.hitStatic].model)
              core.sound.playSound3d(effect.effect.school.." hit",self)
              effestsnum[i]=i-1
            end
            SecondWeaponConstantEnchant={id=SecondWeapon.recordId, effects=effestsnum, stackable =false, caster=self, item=SecondWeapon, enchantId=Enchant}
            types.Actor.activeSpells(self):add(SecondWeaponConstantEnchant)
          end
        end
        core.sound.playSound3d("item weapon shortblade up",self)
      end
    else
      self:sendEvent('ShowMessage', {message =core.getGMST("sInventoryMessage1")})
    end
  else
    self:sendEvent('ShowMessage', {message "You need a weapon in your right hand to handle a weapon in your left hand."})
  end
end

time.runRepeatedly(function() 	
  if SecondWeapon then
    if SecondWeaponConstantEnchant and SecondWeaponConstantEnchant.id then  ----------------TROUVER une autre solution pour les constnat effect qui ne durent qu'une seconde
      types.Actor.activeSpells(self):add(SecondWeaponConstantEnchant)
    end
    DisintegrateWEffeft=types.Actor.activeEffects(self):getEffect(core.magic.EFFECT_TYPE.DisintegrateWeapon)
    if DisintegrateWEffeft and DisintegrateWEffeft.magnitude then
      core.sendGlobalEvent('ModifyItemCondition', {actor = atself, item = SecondWeapon, amount= -DisintegrateWEffeft.magnitude})
    end
  end
end,
0.95*time.second)

local function onUpdate(dt)
  if SecondWeapon then
--    print(LastAttack)
    local RightWeapon=types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    local RightWeaponType
    if RightWeapon then
      if RightWeapon==SecondWeapon or types.Item.itemData(SecondWeapon).condition<=0 or not(SecondWeapon.parentContainer) or SecondWeapon.parentContainer.id~=self.id  then
        RemoveSecondWeapon()
        return
      end
      if RightWeapon.type==types.Weapon then
        RightWeaponType=types.Weapon.records[RightWeapon.recordId].type
      end
    end
    if types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedLeft) or not(RightWeaponType==types.Weapon.TYPE.AxeOneHand or RightWeaponType==types.Weapon.TYPE.BluntOneHand or RightWeaponType==types.Weapon.TYPE.LongBladeOneHand or RightWeaponType==types.Weapon.TYPE.ShortBladeOneHand) then
      if SwitchFrameTempo>0 then
        SwitchFrameTempo=SwitchFrameTempo-1
      else
        RemoveSecondWeapon()
        SwitchFrameTempo=3
      end
    end


    if Stance~=types.Actor.getStance(self) then
      if types.Actor.getStance(self)==types.Actor.STANCE.Weapon then
        anim.removeVfx(self, "LeftWeaponVFX")
--        anim.addVfx(self, types.Weapon.records[SecondWeapon.recordId].model , {loop=true, boneName="Weapon Left Bone",vfxId ="LeftWeaponVFX"})
        anim.addVfx(self, types.Weapon.records[SecondWeapon.recordId].model , {loop=true, useAmbientLight=false, boneName="Weapon Bone left",vfxId ="LeftWeaponVFX"})
--        print("VFX added 2")
        Stance=types.Actor.getStance(self)
      else
        anim.removeVfx(self, "LeftWeaponVFX")
        print("CHANGE TO RIGHT")
        LastAttack="Right"
        I.AnimationController.playBlendedAnimation( "weapononehand", {startKey="unequip detach", stopKey="unequip stop", priority  ={	[anim.BONE_GROUP.RightArm] = anim.PRIORITY.Weapon,
                                                                                        [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
                                                                                        [anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,} })
        Stance=types.Actor.getStance(self)
      end
    end
  elseif types.Player.objectIsInstance(self)==false then
    if types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedLeft)==nil and types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight) and WeaponTypesForSecond[types.Weapon.records[types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight).recordId].type] then
      for i, weapon in pairs(types.Actor.inventory(self):getAll(types.Weapon)) do
        if weapon~=types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedRight) and WeaponTypesForSecond[types.Weapon.records[weapon.recordId].type] then
          self:sendEvent("EquipSecondWeapon",{Weapon=weapon})
          break
        end
      end

    end


  end

end





local function onSave()
    return{SecondWeaponSaved=SecondWeapon,SecondWeaponConstantEnchantSaved=SecondWeaponConstantEnchant}
end


local function onLoad(data)
    if data and data.SecondWeaponConstantEnchantSaved then
      SecondWeaponConstantEnchant=data.SecondWeaponConstantEnchantSaved
    end
    if data and data.SecondWeaponSaved then
      SecondWeapon=data.SecondWeaponSaved
--      print("LOAD",SecondWeapon)
      if types.Player.objectIsInstance(self)==false then
        anim.removeVfx(self, "LeftWeaponVFX")
 --       anim.addVfx(self, types.Weapon.records[SecondWeapon.recordId].model , {loop=true, boneName="Weapon Left Bone",vfxId ="LeftWeaponVFX"})
        anim.addVfx(self, types.Weapon.records[SecondWeapon.recordId].model , {loop=true, useAmbientLight=false, boneName="Weapon Bone left",vfxId ="LeftWeaponVFX"})
--        print("VFX added 3")
      end
    end
end



return {
    interfaceName = "DualWielding",
    interface = {
        version = 1,
        SecondWeapon=function() return(SecondWeapon) end,
    },
  


  engineHandlers = {onUpdate=onUpdate,
                    onSave=onSave,
                    onLoad=onLoad,


  },
  eventHandlers={EquipSecondWeapon=EquipSecondWeapon,
                RemoveSecondWeapon=RemoveSecondWeapon



  }
}