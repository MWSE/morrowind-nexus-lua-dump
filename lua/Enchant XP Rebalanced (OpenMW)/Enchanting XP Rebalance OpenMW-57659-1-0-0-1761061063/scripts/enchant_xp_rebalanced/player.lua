local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local self_module = require('openmw.self')
local core = require('openmw.core')

local function getRecord(item)
  if item.type and item.type.record then
    return item.type.record(item)
  end
  return nil
end
local function getEnchantment(item)
  local record = getRecord(item)
  if record and record.enchant then
    return core.magic.enchantments.records[record.enchant]
  end
  return nil
end


I.SkillProgression.addSkillUsedHandler(function(skillid, params)
  if skillid == 'enchant' then
    local playerActor = self_module.object
    -- We are attached to the Player, so this should always be an Actor.
    if not types.Actor.objectIsInstance(playerActor) then
      ui.showMessage('Enchanting XP Rebalanced: there is an error with the installation, report this error or remove the mod')
      return
    end
    
    local baseSkillGain = params.skillGain

    if(params.useType == I.SkillProgression.SKILL_USE_TYPES.Enchant_UseMagicItem) then
      local enchantedItem = types.Actor.getSelectedEnchantedItem(playerActor)


      if enchantedItem then
        local enchIt = getEnchantment(enchantedItem)
        if(enchIt) then
          --give extra xp

          --ui.showMessage("Normal XP:" .. params.skillGain)
          params.skillGain = baseSkillGain * enchIt.cost
          --ui.showMessage("Modified XP:" .. params.skillGain)
        end

      else
        --ui.showMessage('No enchanted item was selected, gain normal XP.')
      end
    end

    --if it's cast on strike change the base xp to 0.01 so that it's not 0 when multiplied
    if params.useType == I.SkillProgression.SKILL_USE_TYPES.Enchant_CastOnStrike then
      baseSkillGain = 0.1
      local equipped_weapon = types.Actor.getEquipment(playerActor, types.Actor.EQUIPMENT_SLOT.CarriedRight)
      local enchIt = getEnchantment(equipped_weapon)
        if(enchIt) then
          --give extra xp

          --ui.showMessage("Normal XP:" .. params.skillGain)
          params.skillGain = baseSkillGain * enchIt.cost
          --ui.showMessage("Modified XP:" .. params.skillGain)
        end
    end
    
    if params.useType == I.SkillProgression.SKILL_USE_TYPES.Enchant_CreateMagicItem then --Enchant_Recharge
        --local inventory = types.Actor.inventory(playerActor)
        params.skillGain = 50
    end
    
    if params.useType == I.SkillProgression.SKILL_USE_TYPES.Enchant_Recharge then
        --local inventory = types.Actor.inventory(playerActor)
        params.skillGain = 15
    end
    
  end
end)
