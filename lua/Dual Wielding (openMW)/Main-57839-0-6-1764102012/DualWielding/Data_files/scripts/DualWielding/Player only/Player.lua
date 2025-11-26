local self=require('openmw.self')
local anim = require('openmw.animation')
local types = require('openmw.types')
local core = require('openmw.core')
local camera=require('openmw.camera')
local I=require('openmw.interfaces')
local input=require('openmw.input')
local util=require('openmw.util')
local ui=require('openmw.ui')
local time=require('openmw_aux.time')
local async = require('openmw.async')
local storage = require('openmw.storage')
local nearby = require('openmw.nearby')
local MWUI= require('openmw.interfaces').MWUI

local LeftAttacks={"weaponleftslash","weaponleftchop","weaponleftthrust"}
local LastAttack="Right"
local LastCameraMode=camera.MODE.FirstPerson
local EquipSecondWeaponState=false
local SecondWeapon
local SecondWeaponConstantEnchant
local Stance=types.Actor.getStance(self)

local SwitchFrameTempo=3


local SecondWeaponInfos=nil
local SecondWeaponUI
local SecondWeaponUIPosition=util.vector2(0.15,0.95)
local EnchantTypes={"Cast When Strikes","Cast When Used", "Constant Effect", "Cast Once"}
local RangeTypes={"on Self ","on Touch ","on Range "}




local function CreateShowVariable()
  local SWRecord=types.Weapon.records[SecondWeapon.recordId]
  local WeaponTypesString={}
  WeaponTypesString[types.Weapon.TYPE.AxeOneHand]="Axe"
  WeaponTypesString[types.Weapon.TYPE.BluntOneHand]="Blunt"
  WeaponTypesString[types.Weapon.TYPE.LongBladeOneHand]="Long Blade"
  WeaponTypesString[types.Weapon.TYPE.ShortBladeOneHand]="Short Blade"


  local Description=ui.content{ {type=ui.TYPE.Text,props={text="",textSize=1}},
                                {type=ui.TYPE.Text,template=MWUI.templates.textHeader ,props={text=" "..SWRecord.name.." "}},
                                {type=ui.TYPE.Text,props={text="",textSize=1}},
                                {type=ui.TYPE.Text,template=MWUI.templates.textNormal ,props={text=" Type: "..WeaponTypesString[SWRecord.type].." Weapon, One Handed "}},
                                {type=ui.TYPE.Text,props={text="",textSize=1}},
                                {type=ui.TYPE.Text,template=MWUI.templates.textNormal ,props={text=" Chop: "..SWRecord.chopMinDamage.." - "..SWRecord.chopMaxDamage.." "}},
                                {type=ui.TYPE.Text,props={text="",textSize=1}},
                                {type=ui.TYPE.Text,template=MWUI.templates.textNormal ,props={text=" Slash: "..SWRecord.slashMinDamage.." - "..SWRecord.slashMaxDamage.." "}},
                                {type=ui.TYPE.Text,props={text="",textSize=1}},
                                {type=ui.TYPE.Text,template=MWUI.templates.textNormal ,props={text=" Thrust: "..SWRecord.thrustMinDamage.." - "..SWRecord.thrustMaxDamage.." "}},
                                {type=ui.TYPE.Text,props={text="",textSize=1}},
                                {type=ui.TYPE.Text,template=MWUI.templates.textNormal ,props={text=" Condition: "..util.round(types.Item.itemData(SecondWeapon).condition).." - "..SWRecord.health.." "}},
                                {type=ui.TYPE.Text,props={text="",textSize=1}},
                                {type=ui.TYPE.Text,template=MWUI.templates.textNormal ,props={text=" Weight: "..tostring(util.round(SWRecord.weight*10)/10).." "}},
                                {type=ui.TYPE.Text,props={text="",textSize=1}},
                                {type=ui.TYPE.Text,template=MWUI.templates.textNormal ,props={text=" Value: "..SWRecord.value.." "}},
                                {type=ui.TYPE.Text,props={text="",textSize=1}},}

  if SWRecord.enchant then
    Description:add({type=ui.TYPE.Text,template=MWUI.templates.textNormal ,props={text=EnchantTypes[core.magic.enchantments.records[SWRecord.enchant].type]}})
    Description:add({type=ui.TYPE.Text,props={text="",textSize=1}})
      for i, effect in ipairs(core.magic.enchantments.records[SWRecord.enchant].effects) do
            local Text
            if core.magic.enchantments.records[SWRecord.enchant].type==core.magic.ENCHANTMENT_TYPE.ConstantEffect then
                if effect.affectedAttribute then
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.affectedAttribute:gsub("^%l", string.upper).." "..effect.magnitudeMax.." pts "
                elseif effect.affectedSkill then
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.affectedSkill:gsub("^%l", string.upper).." "..effect.magnitudeMax.." pts "
                else
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.magnitudeMax.." pts "
                end
            else
                if effect.affectedAttribute then
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.affectedAttribute:gsub("^%l", string.upper).." "..effect.magnitudeMax.." pts for "..effect.duration.." secs "
                elseif effect.affectedSkill then
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.affectedSkill:gsub("^%l", string.upper).." "..effect.magnitudeMax.." pts for "..effect.duration.." secs "
                else
                    Text=" "..core.magic.effects.records[effect.id].name.." "..effect.magnitudeMax.." pts for "..effect.duration.." secs "
                end
              Text=Text..RangeTypes[effect.range+1]
            end
            Description:add({type=ui.TYPE.Flex, props = { horizontal = true, autoSize=true }, content =ui.content {   
                                                                                                                        {type=ui.TYPE.Text, template = I.MWUI.templates.textNormal, props = { text=" "},},  
                                                                                                                        {type=ui.TYPE.Image, props = { size = util.vector2(ui.screenSize().y/80, ui.screenSize().y/80), resource = ui.texture{path =core.magic.effects.records[effect.id].icon},}},
                                                                                                                        {type=ui.TYPE.Text, template = I.MWUI.templates.textNormal, props = { text=Text},},                                                                                
                                                                                                                    }})                                                                                                              
            
        Description:add({type=ui.TYPE.Text,props={text="",textSize=1}})  
      end  

      if core.magic.enchantments.records[SWRecord.enchant].type~=core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        Description:add({name="ChargeFlex",type=ui.TYPE.Flex,props={arrange=ui.ALIGNMENT.Center,horizontal=true},content=ui.content{{type=ui.TYPE.Text,template=MWUI.templates.textNormal ,props={text=" Charge: "}},
                                                                                                                                  {name="ChargeCont",type=ui.TYPE.Container,template=MWUI.templates.boxSolid,content=ui.content{{name="Charge", type=ui.TYPE.Image, props = {size = util.vector2( types.Item.itemData(SecondWeapon).enchantmentCharge/core.magic.enchantments.records[SWRecord.enchant].charge* tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')*4),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY')/2.5)),
                                                                                                                                                                                                                                                                                anchor = util.vector2(0, 0),
                                                                                                                                                                                                                                                                                resource = ui.texture{path ="textures/menu_bar_red.dds"},
                                                                                                                                                                                                                                                                                color=util.color.rgb(0.7, 0.7, 0.7),
                                                                                                                                                                                                                                                                                alpha=0.7}},
                                                                                                                                                                                                                                {name="ChargeBack", type=ui.TYPE.Image, props = {alpha=1, inheritAlpha=false, size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')*4),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY')/2.5)),
                                                                                                                                                                                                                                                                                anchor = util.vector2(0, 0),
                                                                                                                                                                                                                                                                                resource = WeaponTexture}, content=ui.content{{name="ChargeValue",type=ui.TYPE.Text, template = I.MWUI.templates.textNormal, props = {anchor=util.vector2(0.5,0.1), relativePosition=util.vector2(0.5,0), text=util.round(types.Item.itemData(SecondWeapon).enchantmentCharge).."/"..core.magic.enchantments.records[SWRecord.enchant].charge}}}
                                                                                                                                                                                                                                }}}
                                                                                                                                }})
        Description:add({type=ui.TYPE.Text,props={text="",textSize=1}})  
      end
  end
  
    local UIAnchorX=0
    local UIAnchorY=0
    if SecondWeaponUI.layout.props.relativePosition.x>0.5 then
        UIAnchorX=1
    end
    if SecondWeaponUI.layout.props.relativePosition.y>0.5 then
        UIAnchorY=1
    end

    SecondWeaponInfos=ui.create({type=ui.TYPE.Container,template=MWUI.templates.boxSolid, layer="Windows",props = {  autosize=true,
                                                                                                        relativePosition=SecondWeaponUI.layout.props.relativePosition,
                                                                                                        anchor = util.vector2(UIAnchorX, UIAnchorY),},
                                                                                            content=ui.content{{type=ui.TYPE.Flex, props = {arrange=ui.ALIGNMENT.Center, relativePosition = util.vector2(0, 0), anchor = util.vector2(0, 0), horizontal = false, autoSize=true },
                                                                                                                content =Description
                                                                                                          }}})        
end


local function HideVariable(data)
    if SecondWeaponInfos and SecondWeaponUI.layout.props.visible==true then
       SecondWeaponInfos:destroy()
    end
end

local SelectedMoveUI=false

local function SelectMoveUI(MouseEvent)
    SelectedMoveUI=true
end
local function ReleasetMoveUI(MouseEvent)
    SelectedMoveUI=false
end

local function MoveUI(MouseEvent,elem)
    if SelectedMoveUI==true then
        elem.props.relativePosition=util.vector2(MouseEvent.position.x/ui.screenSize().x,MouseEvent.position.y/ui.screenSize().y)
        if elem.props.relativePosition.x>1 then
            elem.props.relativePosition=util.vector2(1,elem.props.relativePosition.y)
        elseif elem.props.relativePosition.x<0 then
            elem.props.relativePosition=util.vector2(0,elem.props.relativePosition.y)
        end
        if elem.props.relativePosition.y>1 then
            elem.props.relativePosition=util.vector2(elem.props.relativePosition.x,1)
        elseif elem.props.relativePosition.y<0 then
            elem.props.relativePosition=util.vector2(elem.props.relativePosition.x,0)
        end
        SecondWeaponInfos.layout.props.relativePosition=elem.props.relativePosition
        SecondWeaponUI:update()
        SecondWeaponInfos:update()
       SecondWeaponUIPosition=SecondWeaponUI.layout.props.relativePosition
    end
end

local function RemoveSecondWeapon()
  local Enchant=types.Weapon.records[SecondWeapon.recordId].enchant
  if Enchant and  core.magic.enchantments.records[Enchant].type==core.magic.ENCHANTMENT_TYPE.ConstantEffect then
    types.Actor.activeSpells(self):remove(Enchant)
    SecondWeaponConstantEnchant=nil
  end
  SecondWeapon=nil
  SecondWeaponUI.layout.props.visible=false
  SecondWeaponUI:update()
  anim.removeVfx(self, "LeftWeaponVFX")
  if SecondWeaponInfos then SecondWeaponInfos:destroy() end
  core.sound.playSound3d("item weapon shortblade down", self) 

end



for i,record in pairs(types.Weapon.records) do
  if ui.texture{path =record.icon} then
    local WeaponTexture=ui.texture{path =record.icon}
    SecondWeaponUI=ui.create({type=ui.TYPE.Flex, layer="Windows",props = { anchor=util.vector2(0.5,0.5), visible=false, relativePosition=util.vector2(0.15,0.95)}, content=ui.content{
                                                                                                                                                      {name="IconCont",type=ui.TYPE.Container,template=MWUI.templates.boxSolid,content=ui.content{{ name="MagicIcon", type=ui.TYPE.Image, props = {size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY'))),
                                                                                                                                                                                                                                                    anchor = util.vector2(0, 0),visible=false,
                                                                                                                                                                                                                                                    resource = ui.texture{path="textures/menu_icon_magic_mini.dds"}}},
                                                                                                                                                                                                                                                  { name="WeaponIcon", type=ui.TYPE.Image, props = {size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY'))),
                                                                                                                                                                                                                                                    anchor = util.vector2(0, 0),
                                                                                                                                                                                                                                                    resource = WeaponTexture},}}},


                                                                                                                                                      {name="Space", type=ui.TYPE.Image, props = {visible=false, size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY'))/100),
                                                                                                                                                                                                                                                      anchor = util.vector2(0, 0),
                                                                                                                                                                                                                                                      resource = WeaponTexture}},
                                                                                                                                                      {name="ConditionCont",type=ui.TYPE.Container,template=MWUI.templates.boxSolid,content=ui.content{{name="Condition", type=ui.TYPE.Image, props = {size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY')/10)),
                                                                                                                                                                                                                                                      anchor = util.vector2(0, 0),
                                                                                                                                                                                                                                                      resource = ui.texture{path ="textures/menu_bar_red.dds"}}},
                                                                                                                                                                                                                                                      {name="ConditionBack", type=ui.TYPE.Image, props = {visible=false, size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY')/10)),
                                                                                                                                                                                                                                                      anchor = util.vector2(0, 0),
                                                                                                                                                                                                                                                      resource = WeaponTexture}}}},                                                                                              
                                                                                                                                                      },
                                                                                    events={focusGain = async:callback(CreateShowVariable),
                                                                                            focusLoss = async:callback(HideVariable),
                                                                                            mousePress = async:callback(SelectMoveUI),
                                                                                            mouseMove= async:callback(MoveUI),
                                                                                            mouseRelease = async:callback(ReleasetMoveUI),
                                                                                            mouseClick = async:callback(RemoveSecondWeapon)}})
  break
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
    if group=="weapononehand" then
      if LastAttack=="Right" then
        if string.find(key,"follow stop") then
          LastAttack="RightStop"
        end
      end
    elseif LastAttack=='Left' and (group=="weaponleftslash" or group=="weaponleftchop" or group=="weaponleftthrust") then
      if string.find(key,"stop") then
        LastAttack="Right"
      elseif string.find(key,"hit") then
        

        
        local RotZ = self.rotation:getPitch()
        local RotX = self.rotation:getYaw()
        local Distance = types.Weapon.records[SecondWeapon.recordId].reach*100
        local Target = nearby.castRay(
				util.vector3(0, 0, 110) + self.position,
				util.vector3(0, 0, 110) + self.position +
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
              strength = 1,
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

--        print("Hit Left")
      end
    end
  end
end)




I.AnimationController.addPlayBlendedAnimationHandler(function (groupname, options)
  if SecondWeapon then
    if groupname=="weapononehand" then
      if LastAttack=="RightStop" then
        if core.sound.isSoundPlaying("weapon swish", self) then
          core.sound.stopSound3d("weapon swish", self)
        end
        LastAttack='Left'
        local Animation=LeftAttacks[math.random(3)]
        I.AnimationController.playBlendedAnimation( Animation, { loops = 0, forceLoop = true, priority  ={	[anim.BONE_GROUP.RightArm] = anim.PRIORITY.Weapon,
                                                                                                            [anim.BONE_GROUP.LeftArm] = anim.PRIORITY.Weapon,
                                                                                                            [anim.BONE_GROUP.Torso] = anim.PRIORITY.Weapon,} })

        core.sound.playSound3d("Swishm", self)
        options.stopKey="start"
      elseif  LastAttack=="Left" then
        if core.sound.isSoundPlaying("weapon swish", self) then
          core.sound.stopSound3d("weapon swish", self)
        end
        options.stopKey="start"
      else
        options.speed=1--0.8
      end
    end
    if groupname=="weaponleftslash" or groupname=="weaponleftchop" or groupname=="weaponleftthrust" then
      options.speed=1--0.8
    end
  end
end)


local function EquipSecondWeapon(data)
  local RightWeapon = types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
  SecondWeapon=data.Weapon
  if RightWeapon then
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
          anim.addVfx(self, types.Weapon.records[SecondWeapon.recordId].model , {loop=true, boneName="Weapon Left Bone",vfxId ="LeftWeaponVFX"})
        end
        SecondWeaponUI.layout.props.visible=true
        SecondWeaponUI.layout.content.IconCont.content.WeaponIcon.props.resource = ui.texture{path =types.Weapon.records[SecondWeapon.recordId].icon}
        SecondWeaponUI.layout.content.IconCont.content.WeaponIcon.props.size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY')))
        SecondWeaponUI.layout.content.IconCont.content.MagicIcon.props.size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY')))
        SecondWeaponUI.layout.content.Space.props.size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY'))/100)
        SecondWeaponUI.layout.content.ConditionCont.content.Condition.props.size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY'))/10)
        SecondWeaponUI.layout.content.ConditionCont.content.ConditionBack.props.size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY'))/10)
        local Enchant=types.Weapon.records[SecondWeapon.recordId].enchant
        if Enchant then
          SecondWeaponUI.layout.content.IconCont.content.MagicIcon.props.visible=true
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
        else
          SecondWeaponUI.layout.content.IconCont.content.MagicIcon.props.visible=false
        end
        SecondWeaponUI:update()
        core.sound.playSound3d("item weapon shortblade up",self)
      end
    else
      ui.showMessage(core.getGMST("sInventoryMessage1"))
    end
  else
    ui.showMessage("You need a weapon in your right hand to handle a weapon in your left hand.")
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

    if LastCameraMode~=camera.getMode() then
      LastCameraMode=camera.getMode()
      if types.Actor.getStance(self)==types.Actor.STANCE.Weapon then
        anim.removeVfx(self, "LeftWeaponVFX")
        anim.addVfx(self, types.Weapon.records[SecondWeapon.recordId].model , {loop=true, boneName="Weapon Left Bone",vfxId ="LeftWeaponVFX"})
      end
    end
    SecondWeaponUI.layout.content.ConditionCont.content.Condition.props.size=util.vector2(types.Item.itemData(SecondWeapon).condition/types.Weapon.records[SecondWeapon.recordId].health*tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY'))/10)
    SecondWeaponUI:update()

    local RightWeapon=types.Actor.getEquipment(self, types.Actor.EQUIPMENT_SLOT.CarriedRight)
    local RightWeaponType
    if RightWeapon then
      if RightWeapon==SecondWeapon or types.Item.itemData(SecondWeapon).condition<=0 or not(SecondWeapon.parentContainer) or SecondWeapon.parentContainer.id~=self.id  then
        RemoveSecondWeapon()
--        SecondWeapon=nil
--        SecondWeaponUI.layout.props.visible=false
--        SecondWeaponUI:update()
--        anim.removeVfx(self, "LeftWeaponVFX")
        return
      end
      RightWeaponType=types.Weapon.records[RightWeapon.recordId].type
    end
    if types.Actor.getEquipment(self,types.Actor.EQUIPMENT_SLOT.CarriedLeft) or not(RightWeaponType==types.Weapon.TYPE.AxeOneHand or RightWeaponType==types.Weapon.TYPE.BluntOneHand or RightWeaponType==types.Weapon.TYPE.LongBladeOneHand or RightWeaponType==types.Weapon.TYPE.ShortBladeOneHand) then
      if SwitchFrameTempo>0 then
        SwitchFrameTempo=SwitchFrameTempo-1
      else
        RemoveSecondWeapon()
--        SecondWeapon=nil
--        SecondWeaponUI.layout.props.visible=false
--        SecondWeaponUI:update()
--        anim.removeVfx(self, "LeftWeaponVFX")
        SwitchFrameTempo=3
      end
    end


    if Stance~=types.Actor.getStance(self) then
      if types.Actor.getStance(self)==types.Actor.STANCE.Weapon then
        anim.addVfx(self, types.Weapon.records[SecondWeapon.recordId].model , {loop=true, boneName="Weapon Left Bone",vfxId ="LeftWeaponVFX"})
        Stance=types.Actor.getStance(self)
      else
        anim.removeVfx(self, "LeftWeaponVFX")
        Stance=types.Actor.getStance(self)
      end
    end
  end

  
  if input.getBooleanActionValue('EquipSecondWeapon')==true and EquipSecondWeaponState==false then
      core.sendGlobalEvent("EquipSecondWeaponKey",{Actor=self, Bolean=true})
      EquipSecondWeaponState=true
  elseif input.getBooleanActionValue('EquipSecondWeapon')==false and EquipSecondWeaponState==true then
      core.sendGlobalEvent("EquipSecondWeaponKey",{Actor=self, Bolean=false})
      EquipSecondWeaponState=false
  end
end





local function onSave()
    return{SecondWeaponUIPositionSaved= SecondWeaponUIPosition, SecondWeaponSaved=SecondWeapon, SecondWeaponConstantEnchantSaved=SecondWeaponConstantEnchant}
end


local function onLoad(data)
    if data and data.SecondWeaponUIPositionSaved then
        SecondWeaponUI.layout.props.relativePosition=data.SecondWeaponUIPositionSaved
        SecondWeaponUI:update()
    end

    if data and data.SecondWeaponConstantEnchantSaved then
      SecondWeaponConstantEnchant=data.SecondWeaponConstantEnchantSaved
    end



    if data and data.SecondWeaponSaved then
      SecondWeapon=data.SecondWeaponSaved
--      anim.addVfx(self, types.Weapon.records[SecondWeapon.recordId].model , {loop=true, boneName="Weapon Left Bone",vfxId ="LeftWeaponVFX"})
      SecondWeaponUI.layout.props.visible=true
      SecondWeaponUI.layout.content.IconCont.content.WeaponIcon.props.resource = ui.texture{path =types.Weapon.records[SecondWeapon.recordId].icon}
      SecondWeaponUI.layout.content.IconCont.content.WeaponIcon.props.size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY')))
      SecondWeaponUI.layout.content.IconCont.content.MagicIcon.props.size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY')))
      SecondWeaponUI.layout.content.Space.props.size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY'))/100)
      SecondWeaponUI.layout.content.ConditionCont.content.Condition.props.size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY'))/10)
      SecondWeaponUI.layout.content.ConditionCont.content.ConditionBack.props.size = util.vector2( tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIX')),  tonumber(storage.playerSection('DualWieldingscontrols'):get('SecondWeaponUIY'))/10)
      if types.Weapon.records[SecondWeapon.recordId].enchant then
        SecondWeaponUI.layout.content.IconCont.content.MagicIcon.props.visible=true
      else
        SecondWeaponUI.layout.content.IconCont.content.MagicIcon.props.visible=false
      end
      SecondWeaponUI:update()
    end
end



return {
  engineHandlers = {onUpdate=onUpdate,
                    onSave=onSave,
                    onLoad=onLoad,


  },
  eventHandlers={EquipSecondWeapon=EquipSecondWeapon



  }
}