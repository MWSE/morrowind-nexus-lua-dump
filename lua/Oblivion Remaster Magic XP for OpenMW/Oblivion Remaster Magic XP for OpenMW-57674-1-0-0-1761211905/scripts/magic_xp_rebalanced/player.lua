local ui = require('openmw.ui')
local I = require('openmw.interfaces')
local types = require('openmw.types')
local self_module = require('openmw.self')
local core = require('openmw.core')

local function getSpellRecord(selectedSpell)
  if(selectedSpell) then
    local spellId = selectedSpell.id
    if(spellId) then
      return core.magic.spells.records[spellId]
    end
  end
  return nil
end

local function isMagicSchool(skillid)
  return skillid == 'alteration' or
    skillid == 'conjuration' or
    skillid == 'destruction' or
    skillid == 'illusion' or
    skillid == 'mysticism' or
    skillid == 'restoration'
end


I.SkillProgression.addSkillUsedHandler(function(skillid, params)
  if isMagicSchool(skillid) then

    if (params.useType == I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success) then
      local playerActor = self_module.object
      -- We are attached to the Player, so this should always be an Actor.
      if not types.Actor.objectIsInstance(playerActor) then
        ui.showMessage('Magic XP Rebalanced: there is an error with the installation, report this error or remove the mod')
        print("The script is not attached to a player")
        return
      end

      local baseSkillGain = params.skillGain

      local selectedSpell = types.Actor.getSelectedSpell(playerActor)
      local spellId = selectedSpell.id
      local spellRecord = core.magic.spells.records[spellId]
      --print("Spell cost: " .. spellRecord.cost)

      local spell = getSpellRecord(selectedSpell)
      if(spell) then
        --give extra xp

        print("Normal XP: " .. params.skillGain)
        --Using the same formula as Oblivion Remaster:
        -- ( ( SpellBaseCost * [School]ExpCastMult ) / 0.75 ) + ( [School]UseValue / 1.5 )
        -- SpellBaseCost is the magicka cost before the reduction of the skill (in Morrowind there is no reduction)
        -- ExpCastMult is always 0.1
        -- UseValue technically varies from 6.0 to 0.6 based on the school, I used an average value of 3
        params.skillGain = ((spell.cost * 0.1) / 0.75) + (3.0 / 1.5)
        print("Modified XP: " .. params.skillGain)
      end

    else
      print('I couldn\'t find the spell, gaining normal XP.')
    end
  end
end)
