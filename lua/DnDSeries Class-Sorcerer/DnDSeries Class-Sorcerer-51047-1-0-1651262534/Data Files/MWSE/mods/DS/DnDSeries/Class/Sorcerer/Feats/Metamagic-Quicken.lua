local this = {}
local common = require('DS.DnDSeries.Class.Sorcerer.common')
function this.metaMagic(spellId)
    local preparedSpell = tes3.player.data.DnDSeries.MetaMagicPreparedSpell or {}
    local spell = tes3.getObject(spellId)
    local isSpell = common.isValid(spell)
    if isSpell == false then return end
    local isStored = table.find(preparedSpell, spell)
    if isStored == nil then
    table.insert(preparedSpell, spell)
    end
    tes3.player.data.DnDSeries.MetaMagicPreparedSpell = preparedSpell
    local canQuicken
    for i=1, spell:getActiveEffectCount() do
      local effects = spell.effects[i]
      if not (effects.rangeType == tes3.effectRange.touch) then
          canQuicken = true
      else
         canQuicken = false
      end
    end
    if canQuicken == false then
     tes3.messageBox("this spell cant be prepare with Quicken metamagic")
    else
        local stringM = "[Q]"
        local newId
        local k
        if string.find(spell.id, "MetaSpell", 1, true) == nil then
          k = table.find(preparedSpell, spell)
          if k == nil then return end
          if k < 10 then
            newId = string.format("MetaSpell0%s%s", k, stringM)
          else
            newId = string.format("MetaSpell%s%s", k, stringM)
          end
        else
          tes3.messageBox("This spell is already prepare with Metamagic")
          table.remove(preparedSpell, isStored)
          return
          --newId = string.format("%s%s", spell.id, stringM)
        end
        local newSpell =tes3.getObject(newId) or tes3.createObject({
             objectType= tes3.objectType.spell,
             id = newId,
             name = spell.name}
        )
        newSpell.name = spell.name
        for i=1, #spell.effects do
         local effect = newSpell.effects[i]
         local newEffect = spell.effects[i]
         effect.id = newEffect.id
         effect.min = newEffect.min or 0
         effect.max = newEffect.max or 0
         effect.rangeType = newEffect.rangeType
         effect.duration = newEffect.duration or 0
         effect.radius = newEffect.radius or 0
         effect.skill = newEffect.skill or -1
         effect.attribute = newEffect.attribute or -1
        end
        local alteration = tes3.mobilePlayer.alteration.current
        if alteration > 90 then alteration = 90 end
        local constant = math.round((100 - alteration)/100, 2)
        local multiplier = 2.25*constant
        local newCost = math.round((spell.magickaCost+spell.magickaCost*multiplier), 0)
        newSpell.magickaCost = newCost
        tes3.removeSpell{reference=tes3.player, spell=spell, updateGUI= true}
        if not tes3.hasSpell{ reference= tes3.player, spell= newSpell} then
            tes3.addSpell{reference=tes3.player, spell=newSpell, updateGUI= true}
        end
        if event.isRegistered("spellCasted", common.checkCast) == false then
          event.register("spellCasted", common.checkCast)
        end
         if event.isRegistered("simulate", this.quickenMeta) == false then
            event.register("simulate", this.quickenMeta)
         end
         if event.isRegistered("keyDown", this.quickenCast) == false then
            event.register("keyDown", this.quickenCast)
         end
         tes3.mobilePlayer:equipMagic{source=newSpell}
    end
end
function this.quickenMeta(e)
local spellId = tes3.mobilePlayer.currentSpell.id
if spellId == nil then return end
if string.find(spellId, "[Q]", 1, true) == nil then
 tes3.setPlayerControlState{enabled = true ,attack = true, magic = true}
else
 tes3.setPlayerControlState{enabled = true ,attack = true, magic = false}
 if tes3.mobilePlayer.castReady == true then
     tes3.mobilePlayer.castReady = false
 end
end
end
function this.quickenCast(e)
local spell = tes3.mobilePlayer.currentSpell
local cost = spell.magickaCost
if spell == nil then return end
if (e.keyCode == tes3.getInputBinding(tes3.keybind.readyMagic).code) and string.find(spell.id, "[Q]", 1, true) then
  if tes3.mobilePlayer.magicka.current >= cost then
  tes3.cast{reference=tes3.mobilePlayer, spell= spell, instant=true}
  tes3.modStatistic{reference=tes3.mobilePlayer, name="magicka", current=-cost}
  return false
 else
   tes3.messageBox("%s", tes3.findGMST(tes3.gmst.sMagicInsufficientSP).value)
   return false
 end
end
end
return this