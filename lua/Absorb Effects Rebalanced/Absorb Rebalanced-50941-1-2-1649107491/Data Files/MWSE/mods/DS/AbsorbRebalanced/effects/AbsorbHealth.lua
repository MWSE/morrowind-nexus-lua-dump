local absorbHTimer
local function checkBuffH()
local bonusTimer = tes3.player.data.absorbHTimer
local dayPassed = 24
local now = tes3.getSimulationTimestamp()
 if bonusTimer + dayPassed < now then
   if tes3.hasSpell{reference=tes3.mobilePlayer, spell="00HealthBonus"} then
     mwscript.removeSpell{reference=tes3.mobilePlayer, spell="00HealthBonus"}
   end
   tes3.player.data.absorbHTimer = nil
   absorbHTimer:pause()
 end
end
local function startBuffTimer()
   absorbHTimer = nil
    if absorbHTimer == nil then
     absorbHTimer = timer.start{type = timer.game,duration = 3,iterations = -1,callback = checkBuffH}
    end
    if absorbHTimer ~= nil and tes3.player.data.absorbHTimer == nil then
     absorbHTimer:pause()
    end
end
local function HealthBonus(e)
local damage = e.source
local vampire = e.attacker
local isVampire = tes3.isAffectedBy{reference= vampire, effect= tes3.effect.vampirism}
local magnitude = -e.damage
local Hbonus = tes3.getObject("00HealthBonus")
if not isVampire or damage ~= tes3.damageSource.magic or magnitude <= 0 then 
   goto continue
end
if magnitude > e.mobile.health.base then
  magnitude = e.mobile.health.base
end
Hbonus.effects[1].min = magnitude
Hbonus.effects[1].max = magnitude
if not tes3.hasSpell{reference=vampire, spell=Hbonus} then
   tes3.addSpell{reference=vampire, spell=Hbonus}
end

 ::continue::
 if vampire == tes3.mobilePlayer then
  tes3.messageBox("The blood of your enemy fill you with more life")
  tes3.player.data.absorbHTimer = tes3.getSimulationTimestamp()
  absorbHTimer:resume()
 end
   event.unregister("damaged", HealthBonus)
end

local function absorbRebalance(e)
local caster = e.caster.mobile
local target = e.target.mobile
local isFull = caster.health.normalized >=1
local Hbonus = tes3.getObject("00HealthBonus")
local isVampire = tes3.isAffectedBy{reference= caster, effect= tes3.effect.vampirism}
local hasBonus= tes3.isAffectedBy{reference= caster, object=Hbonus}
if caster == target then return end
 if isFull and e.effect.id == tes3.effect.absorbHealth then
   if tes3.isModActive("Absorb Rebalanced.esp") then
    if isVampire and not hasBonus then
      event.register("damaged", HealthBonus)
    else
      if isVampire then
       local willpower = caster.willpower.current
       if willpower > 100 then willpower = 100 end
       local bonus = 100 - willpower
       e.resistedPercent = e.resistedPercent + bonus
       if caster == tes3.mobilePlayer then
       tes3.messageBox("You cant absorb more health")
       end
      else
        e.resistedPercent = 100
        if caster == tes3.mobilePlayer then
        tes3.messageBox("You cant absorb more health")
        end
      end
    end
   else
      if isVampire then
         local willpower = caster.willpower.current
         if willpower > 100 then willpower = 100 end
         local bonus = 100 - willpower
         e.resistedPercent = e.resistedPercent + bonus
         if caster == tes3.mobilePlayer then
         tes3.messageBox("You cant absorb more health")
         end
      else
        e.resistedPercent = 100
        if caster == tes3.mobilePlayer then
        tes3.messageBox("You cant absorb more health")
        end
      end
   end
 end
end
event.register("spellResist", absorbRebalance, {priority = -15})
if tes3.isModActive("Absorb Rebalanced.esp") then
  event.register("loaded", startBuffTimer)
end