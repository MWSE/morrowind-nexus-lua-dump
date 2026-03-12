local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local storage = require('openmw.storage')
local util = require('openmw.util')
local I = require('openmw.interfaces')

local settings = storage.globalSection('SettingsImbuleWeapon')

local function fallbackSound(school)
  local soundsForSchools = {
    alteration = "Sound/Fx/magic/altrH.wav",
    conjuration = "Sound/Fx/magic/conjH.wav",
    destruction = "Sound/Fx/magic/destH.wav",
    illusion = "Sound/Fx/magic/illuH.wav",
    mysticism = "Sound/Fx/magic/mystH.wav",
    restoration = "Sound/Fx/magic/restH.wav"
  }
  return soundsForSchools[school]
end

local function applyVfx(effects)
  local effectIndexes = {}
  for k,effect in pairs(effects) do
    --heh
    effect = effect.effect
    if effect.id ~= "spellabsorption" then
      table.insert(effectIndexes,k-1)
--      print("Inserting effect id:",k-1)
--      print("-------Applying VFX:-------",effect)
      local hitSound = effect.hitSound
      if hitSound == "" then
        core.sound.playSoundFile3d(fallbackSound(effect.school),self)
      else
--        print("effect id:",effect.id)
--        print("Sound:",effect.hitSound)
--        print("cast Sound:",effect.castSound)
--        print("area Sound:",effect.areaSound)
        core.sound.playSound3d(effect.hitSound,self,{})
      end
      local mgef = core.magic.effects.records[effect.id]
      local hitStatic = types.Static.record(mgef.hitStatic)
      if hitStatic ~= nil then
--      print("Effect id: "..mgef.id)
--      print("Hit static: "..mgef.hitStatic)
--      print("Model: "..types.Static.record(mgef.hitStatic).model)
--      print("Particle: "..mgef.particle)
--      print("Loop: ",effect.continuousVfx)
--      print("-----------EOF---------")
        self:sendEvent('AddVfx',
        {
          model = hitStatic.model,
          options = {
            loop = true,
            vfxId = mgef.id,
  --          particleTextureOverride = mgef.particle,
          }
        }
        )
      end
      
      --you gotta do what you gotta do
--      local pos = util.vector3(self.position.x,self.position.y,self.position.z+80)
--      core.sendGlobalEvent('SpawnVfx',
--      {
--      model = types.Static.record(mgef.areaStatic).model,
--      position = pos,
--      options = {scale=3}
--      })
--      
    end
  end
  return effectIndexes
end

-- you gotta do what you gotta do
local function getPlayerMagicSkill(spellSchool,player)
  local playerMagicSkills = {
    alteration     = types.NPC.stats.skills.alteration(player).modified,
    conjuration    = types.NPC.stats.skills.conjuration(player).modified,
    destruction    = types.NPC.stats.skills.destruction(player).modified,
    illusion       = types.NPC.stats.skills.illusion(player).modified,
    mysticism      = types.NPC.stats.skills.mysticism(player).modified,
    restoration    = types.NPC.stats.skills.restoration(player).modified
  }
  
  return playerMagicSkills[spellSchool]
end

-- based on https://wiki.openmw.org/index.php?title=Research:Magic#Spell_Casting
-- ignoring sound effect
-- added lowestSkillName
local function castChance(player)
  local spell = core.magic.spells.records[storage.globalSection('IW_ActiveSpell'):get('activeSpell').id]
  local lowestSkill = nil
  local lowestSkillName = nil
  local y = nil
  for id,effect in ipairs(spell.effects) do
    local x = effect.duration
    x = math.max(1,x)
    x = x*0.1*effect.effect.baseCost
    x = x*0.5*(effect.magnitudeMin+effect.magnitudeMax)
    x = x+effect.area*0.05*effect.effect.baseCost
    if effect.range == core.magic.RANGE.Target then
      x = x*1.5
    end
    x = x*core.getGMST('fEffectCostMult')
    
    local currentSchool = effect.effect.school
    local s = 2*getPlayerMagicSkill(effect.effect.school,player)
    if y == nil or s-x < y then
      y = s - x
      lowestSkill = s
      lowestSkillName = currentSchool
    end
  end
  
  local castChance = (lowestSkill - spell.cost + 0.2 * types.NPC.stats.attributes.willpower(player).modified + 0.1 * types.NPC.stats.attributes.luck(player).modified) * (0.75 + 0.5 * types.Actor.stats.dynamic.fatigue(player).current / types.Actor.stats.dynamic.fatigue(player).base)
--  print("Cast chance:",castChance)
  if castChance > math.random(0,100) then
    return true, lowestSkillName
  else
    return false
  end
end

local function buffElementalAttack(attackType,damage,effects)
  local buffAmount = settings:get('ElementalBuffAmount')
     -- slash,chop,thrust
  local fire,shock,ice = false
  for _,effect in pairs(effects) do
    if effect.id == "firedamage" then
      fire = true 
    elseif effect.id == "frostdamage" then
      ice = true
    elseif effect.id == "shockdamage" then
      shock = true
    end
  end
  -- chop,slash,thrust - 0,1,2, self.ATTACK_TYPE is lying
  if attackType == 1 and fire then
--    print("Slash-fire combo")
    local buffDamage = damage.health
    buffDamage = buffDamage + buffDamage * buffAmount
    damage.health = buffDamage
  elseif attackType == 0 and shock then
--    print("chop-shock combo")
    local buffDamage = damage.health
    buffDamage = buffDamage + buffDamage * buffAmount
    damage.health = buffDamage
  elseif attackType == 2 and ice then
--  print("thrust-ice combo")
    local buffDamage = damage.health
    buffDamage = buffDamage + buffDamage * buffAmount
    damage.health = buffDamage
  end
  return damage
end

local function handleHit(attack)
  if attack.attacker.recordId == "player" and attack.successful then
--    print("Player attack!!!")
    attack.attacker:sendEvent('IW_RefreshVFX',{})
    local storedSpell = storage.globalSection('IW_ActiveSpell'):get('activeSpell')
    
    if storedSpell ~= nil and storedSpell.charges ~= 0 then
      local spell = core.magic.spells.records[storedSpell.id]
      local fisrtUse = storedSpell.firstUse
      
      local mode = settings:get('CastMethod')
--      print("Mode:",mode)
      
      if spell == nil then return end
      
      if settings:get('ElementalBuff') then
        attack.damage = buffElementalAttack(attack.type,attack.damage,spell.effects)
      end
      
      if mode == "Charges" then
        local indexes = applyVfx(spell.effects)
        types.Actor.activeSpells(self):add({id = spell.id, effects = indexes, caster = attack.attacker})
        core.sendGlobalEvent('IW_DecrementSpellCharge',{})
      else
        if fisrtUse then
          local indexes = applyVfx(spell.effects)
          types.Actor.activeSpells(self):add({id = spell.id, effects = indexes, caster = attack.attacker})
          core.sendGlobalEvent('IW_DecrementSpellCharge',{firstUse=false})
        else
          local magicka = types.Actor.stats.dynamic.magicka(attack.attacker).current
--          print("Current mana: ",magicka)
--          print("Spell cost: ",spell.cost)
          if magicka >= spell.cost then
--            print("Enough mana, casting spell.")
            local castChance,lowestSkillname = castChance(attack.attacker)
            if settings:get('IgnoreChance') then
              local indexes = applyVfx(spell.effects)
              types.Actor.activeSpells(self):add({id = spell.id, effects = indexes, caster = attack.attacker})
              attack.attacker:sendEvent("IW_RemoveMagicka",{amount=spell.cost})
              if settings:get('IgnoreChanceSkillGain') then
                attack.attacker:sendEvent("IW_ProgressSpell",{skill=lowestSkillname})
              end
            else
              if castChance then
                local indexes = applyVfx(spell.effects)
                types.Actor.activeSpells(self):add({id = spell.id, effects = indexes, caster = attack.attacker})
                attack.attacker:sendEvent("IW_RemoveMagicka",{amount=spell.cost})
                attack.attacker:sendEvent("IW_ProgressSpell",{skill=lowestSkillname})
              else
--                print("Failed casting spell.")
                attack.attacker:sendEvent("IW_FailedCast",{})
                attack.attacker:sendEvent("IW_RemoveMagicka",{amount=spell.cost})
              end
            end
          else
--            print("Not enough mana to cast spell.")
          end
        end
      end
    end
  end
end

return{

  eventHandlers = {
    Hit = handleHit
  },
}