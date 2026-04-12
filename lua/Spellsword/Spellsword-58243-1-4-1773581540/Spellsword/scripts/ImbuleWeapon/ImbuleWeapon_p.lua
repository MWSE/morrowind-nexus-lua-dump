local core = require('openmw.core')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local I = require('openmw.interfaces')
local storage = require('openmw.storage')
local anim = require('openmw.animation')
local ambient = require('openmw.ambient')

local settings = storage.globalSection('SettingsImbuleWeapon')
--- TODO: Consider the following:
-- perhaps more useful effects for shield, itp

local trigger = settings:get('Trigger') or 'spellabsorption'
trigger = trigger:lower()

local function matchSpellEffect(id)
  local spellEffect = {
      shockdamage = "weaponEffectShock.nif",
      firedamage = "weaponEffectFire.nif",
      frostdamage = "weaponEffectIce.nif",
      poison = "weaponEffectPoison.nif",
      damage = "weaponEffectDamage.nif"
  }
  
  if string.find(id,'drain') ~= nil or string.find(id,'^damage') ~= nil then
    id = "damage"
  end
  return spellEffect[id]
end

local function isImbuleSpell(spell)
  if spell.type == core.magic.SPELL_TYPE.Spell then
    local hasAbsorb = false
    local onlyAbsorb = true
    local absorbIndex = nil
--    print("Amount of effects:",#spell.effects)
    for k,effect in pairs(spell.effects) do
      -- spell absorb on touch only
      if effect.id == trigger then
        if effect.range == 0 then
          hasAbsorb = true
          absorbIndex = k
        end
      else
        -- gotta test if touch/target spells apply like self does
          --they do
--        if effect.range == 0 then end
          onlyAbsorb = false
      end
    end
    if hasAbsorb and not onlyAbsorb then
--      print("isImbuleSPell absorb index:",absorbIndex)
      return true,absorbIndex
    end
  end
  return false
end

local function serializeSpell(spell,absorbId)
--  print(spell.effects[absorbId])
  local absorb = spell.effects[absorbId]
  local charges = math.random(absorb.magnitudeMin,absorb.magnitudeMax)
  local data = {
    name = spell.name,
    id = spell.id,
    charges = charges,
    firstUse = true,
  }  
  return data
end

local function handleCast(data)
  local spell = types.Actor.getSelectedSpell(self)
  if spell == nil then return end
--  print("Spell name: "..spell.name,"Spell id: "..spell.id)
  local effects = spell.effects
  local activeSpells = types.Actor.activeSpells(self)
  
  local activeEffects = types.Actor.activeEffects(self)
  
--  print("PLAYER ACTIVE EFFECTS")
--  for k,effect in pairs(activeEffects) do
--    print(k,effect)
--  end
  
  local isImbule = false
  local absorbId = nil
--  print("-----All active spells:-------")
  -- checks if selected spell is active on player
  for k,v in pairs(activeSpells) do
--    print(v.activeSpellId,v.name)
    if v.id == spell.id then
--      activeSpellId = v.activeSpellId
        isImbule, absorbId = isImbuleSpell(spell)
        if isImbule then
--          print("Imbule spell detected: ",spell.name)
          activeSpells:remove(v.activeSpellId)
          core.sendGlobalEvent("IW_SpellCast",{spell = serializeSpell(spell,absorbId)})
          return
        elseif #spell.effects == 1 then
          if spell.effects[1].id == 'dispel' then
            core.sendGlobalEvent('IW_RemoveSpell',{})
          end
        end
    end
  end
--  print("--------End of active spells------")
--  isImbule, absorbId = isImbuleSpell(spell)
--  if isImbule then
--    core.sendGlobalEvent("IW_SpellCast",{spell = serializeSpell(spell,absorbId)})
--  end
end

local function castHandler(groupname,key)
  if key:sub(-7) == "release" then
--    print("Calling spellcast handler")
    self:sendEvent("SpellCast_IW",{})
  end
end

local function handleWeaponWielding(groupname,key)
  if key == "equip start" then
--    print("Pulling out")
    local spellData = storage.globalSection('IW_ActiveSpell'):get('activeSpell')
    if spellData == nil then return end
    
    if settings:get('AmbientSound') then
      ambient.playSoundFile("sound/imbuedWeaponReady.wav",{loop=true,volume=settings:get('AmbientSoundVolume')})
    end
    
    local message = "Imbuement active: "..spellData.name
    if settings:get('CastMethod') == "Charges" then
      message = message.."\nCharges: "..spellData.charges
    end
    
    self:sendEvent('ShowMessage',{message=message})
    
    local spellId = spellData.id
    local spell = core.magic.spells.records[spellId]
    if spell == nil then return end
    
    for _,effect in pairs(spell.effects) do
    
      local mgef = core.magic.effects.records[effect.id]
      local model = matchSpellEffect(mgef.id)
--      print("effect id:",effect.id)
--      print("Model:",model)
      
      if effect.id ~= trigger then
        if model ~= nil then
          model = "meshes/"..model
        else
          model = "meshes/weaponEffect.nif"
        end
        self:sendEvent('AddVfx', {
          model = model,
          options = {
            boneName='Weapon Bone',
            loop=true,
            vfxId = "iw_weapon_spell_effect"
          },
        })
        if groupname == "handtohand" then
          self:sendEvent('AddVfx', {
          model = model,
          options = {
            boneName='Bip01 L Finger0',
            loop=true,
            vfxId = "iw_weapon_spell_effect"
          },
        })
        end
        break
      end
      
    end
    
  elseif key == "unequip stop" then
--    print("Pulling in")
    anim.removeVfx(self,"iw_weapon_spell_effect")
    ambient.stopSoundFile("sound/imbuedWeaponReady.wav")
    
  end
end

local function refreshVfx()
  local spell = storage.globalSection('IW_ActiveSpell'):get('activeSpell')
  if spell == nil or spell.charges == 0 then
    anim.removeVfx(self,"iw_weapon_spell_effect")
  end
end

local function removeMagicka(data)
  local current = types.Actor.stats.dynamic.magicka(self).current
  current = current - data.amount
  types.Actor.stats.dynamic.magicka(self).current = current
end

local function playFailedCast()
  ambient.playSoundFile('Sound/Fx/magic/destFail.wav')
end

local function progressSpell(data)
  I.SkillProgression.skillUsed(data.skill,{skillGain=1,useType=I.SkillProgression.SKILL_USE_TYPES.Spellcast_Success})
end

I.AnimationController.addTextKeyHandler('spellcast',castHandler)
I.AnimationController.addTextKeyHandler('handtohand',handleWeaponWielding)
I.AnimationController.addTextKeyHandler('weapononehand',handleWeaponWielding)
I.AnimationController.addTextKeyHandler('weapontwohand',handleWeaponWielding)
I.AnimationController.addTextKeyHandler('bowandarrow',handleWeaponWielding)
I.AnimationController.addTextKeyHandler('crossbow',handleWeaponWielding)
I.AnimationController.addTextKeyHandler('throwweapon',handleWeaponWielding)

return{

  eventHandlers = {
    SpellCast_IW = handleCast,
    IW_RefreshVFX = refreshVfx,
    IW_RemoveMagicka = removeMagicka,
    IW_FailedCast = playFailedCast,
    IW_ProgressSpell = progressSpell,
  },

--  engineHandlers = {
--    onMouseButtonRelease = handleMouse
--  }
}