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
    local canExtent
    for i=1, spell:getActiveEffectCount() do
      local effects = spell.effects[i]
      if not (effects.duration <= 1) then
          canExtent = true
      else
         canExtent = false
      end
    end
    if canExtent == false then
     tes3.messageBox("this spell cant be prepare with Extend metamagic")
    else
        local stringM = "[Ex]"
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
         effect.min = newEffect.min
         effect.max = newEffect.max
         effect.rangeType = newEffect.rangeType
         effect.duration = newEffect.duration*2
         effect.radius = newEffect.radius or 0
         effect.skill = newEffect.skill or -1
         effect.attribute = newEffect.attribute or -1
        end
        local illusion = tes3.mobilePlayer.illusion.current
        if illusion > 90 then illusion = 90 end
        local constant = math.round((100 - illusion)/100, 2)
        local multiplier = 1.5*constant
        local newCost = math.round((spell.magickaCost+spell.magickaCost*multiplier), 0)
        newSpell.magickaCost = newCost
        tes3.removeSpell{reference=tes3.player, spell=spell, updateGUI= true}
        if not tes3.hasSpell{ reference= tes3.player, spell= newSpell} then
            tes3.addSpell{reference=tes3.player, spell=newSpell, updateGUI= true}
        end
        tes3.mobilePlayer:equipMagic{source=newSpell}
        if event.isRegistered("spellCasted", common.checkCast) == false then
          event.register("spellCasted", common.checkCast)
        end
    end
end
return this