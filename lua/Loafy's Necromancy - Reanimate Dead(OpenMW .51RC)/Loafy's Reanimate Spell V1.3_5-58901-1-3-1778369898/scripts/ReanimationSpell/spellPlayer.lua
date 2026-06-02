local self                      = require('openmw.self')
local types                     = require('openmw.types')
local core                      = require('openmw.core')
local I                         = require('openmw.interfaces')
local ui                        = require('openmw.ui')
local util                      = require('openmw.util')
local input                     = require('openmw.input')
local storage                   = require('openmw.storage')
local nearby                    = require('openmw.nearby')



local function isHostileWitness(actor)
    if not types.NPC.objectIsInstance(actor) or types.Actor.isDead(actor) then
        return false
    end

    local actorName = types.NPC.record(actor).name
    if string.find(actorName, types.NPC.record(self).name .. "'s Zombie") then
        return false
    end

    if types.Actor.stats.ai.fight(actor).base >= 70 then return false end

    if types.Player.objectIsInstance(actor) then
      return false
    end

    if types.NPC.record(actor).class == "slave" then
        return false
    end

    local cellName = self.cell.name:lower()
    local safeNecromancyArea = false
    local safeKeywords = {
        "tel ", "sadrith ", "Llothanis", "Alt Bosara", "uvirith",
      "fyr", "mothrivra",  "ruin", "shrine"
    }

    for _, keyword in ipairs(safeKeywords) do
      if string.find(cellName, keyword) then
        safeNecromancyArea = true
      end
    end
    
    local actorFactions = types.NPC.getFactions(actor)
    local isTelvanni = false
    for _, f in pairs(actorFactions) do if f == "telvanni" then isTelvanni = true end end

    if safeNecromancyArea then
        if isTelvanni or #actorFactions == 0 then return false end
    end

    return true
end

local function checkNecroCrime(corpse)
    if not corpse then return end
    local playerSettings = storage.playerSection('SettingsReanimateSpellGeneral')
    
    -- If the corpse is a creature then return
    if types.Creature.objectIsInstance(corpse) then return end
    
    local isSneaking = self.controls.sneak
   -- local spotDistance = isSneaking and 500 or 1200 
    local spotDistance = playerSettings:get("witnessDistanceModeNormal") or playerSettings:get("witnessDistanceModeSneak") 

    for _, actor in ipairs(nearby.actors) do
        if isHostileWitness(actor) then
            
            local distance = (actor.position - self.position):length()
            if distance <= spotDistance then
                
             
                local eyeOffset = util.vector3(0, 0, 95)
                local plyBodyOffset = util.vector3(0, 0, 80)
                local los = nearby.castRay(actor.position + eyeOffset, self.position + plyBodyOffset, {
                    ignore = actor,
                    collisionType = nearby.COLLISION_TYPE.World + nearby.COLLISION_TYPE.Door
                })

                if not los.hit then
                    core.sendGlobalEvent("doCrimes",{actor = actor,summoner = self})
                    return 
                end
            end
        end
    end
end

local function displayMessage(message)
  local playerSettings = storage.playerSection('SettingsReanimateSpellGeneral')
  if playerSettings:get("CastingUiBox") == true then
    self:sendEvent('ShowMessage', { message = tostring(message) })   
    return
  else
    return end
end

local function clearSpell(spellId)
   local activeSpells   =  types.Actor.activeSpells(self)
   for _, spell in pairs(activeSpells) do
        if spell.id == spellId then
          types.Actor.activeSpells(self):remove(spell.activeSpellId) 
        end
      end
end

local function spellUsed(data)
  --send the players settings to global since we can't do it ourself for some dumb fucking reason
  local playerSettings = storage.playerSection('SettingsReanimateSpellGeneral')
  core.sendGlobalEvent("getPlayerSettings", {
    requireMasterySetting = playerSettings:get("MasteryMode"),
    requireCrimeSetting = playerSettings:get("CrimeMode"),
    requireExpulsion = playerSettings:get("expulsionMode"),
    requireMasteryUiBox = playerSettings:get("masteryUiBox"),
    requireCastingUiBox = playerSettings:get("CastingUiBox")
  })

  local ray = I.SharedRay.get()
  local actor = nil
  local reanimateSpell
  local selectedSpell
  local activeSpells   =  types.Actor.activeSpells(self)

  --Automaton filter, player shouldn't be able to raise spheres, spiders etc.
   local automatons = {
                    "centurion_sphere", "centurion_sphere_nchur", "centurion_sphere_hts2",
                    "centurion_sphere_summon", "centurion_shock_baladas", "centurion_fire_dead",
                    "centurion_spider", "centurion_spider_nchur", "centurion_spider_tga1", "centurion_spider_tga2",
                    "centurion_steam", "centurion_steam_exhibit", "centurion_steam_nchur", "centurion_steam_hts",
                    "centurion_Mudan_unique", "centurion_steam_dead", "centurion_steam_advance", "centurion_steam_c_l", "centurion_steam_a_c",
                    "centurion_projectile", "centurion_projectile_c", "centurion_sphere_bbot1", "centurion_sphere_bbot5", 
                    "centurion_sphere_bbot6", "centurion_spider_bbot1","centurion_spider_bbot3","centurion_spider_bbot7",
                    "centurion_steam_bbot2", "centurion_steam_bbot2", "centurion_steam_bbot4", "centurion_steam_bbot8",
                    "fabricant_hulking_c", "fabricant_hulking_attac", "fabricant_hulkin_attack", "fabricant_hulking_ss",
                    "fabricant_hulking", "fabricant_hulking_c_l", "fabricant_machine_1", "fabricant_verm_attack", "fabricant_verminous",
                    "fabricant_verminous_c", "fabricant_summon", "fabricant_verminous-rs", "fabricant_verminousDead", "imperfect"
                  }
  
  if data.isEnchantedItem then
    for _, spell in pairs(activeSpells) do
       if spell.activeSpellId == data.enchantedItemSpell then
        selectedSpell = spell
       end
    end
  else
    selectedSpell = types.Actor.getSelectedSpell(self)
  end

    if self then
      for _, spell in pairs(activeSpells) do
        for _, effect in pairs(spell.effects) do
          if effect.id == "reanimatedead" and spell.id == selectedSpell.id then
            
            reanimateSpell = spell  
          end
        end
      end
  if reanimateSpell then
      if ray.hit then
        
        local object = ray.hitObject
        if object and types.Actor.objectIsInstance(object) then
          actor = object
          if types.Actor.stats.dynamic.health(actor).current <= 0 then

            if reanimateSpell and actor  then
              -- Apply automaton check
               print(actor.recordId)
              if not playerSettings:get("automatonMode") then
                for _, automaton in pairs(automatons) do
                  if actor.recordId == automaton then
                      print("Can't summon: "..actor.recordId)
                      self:sendEvent("clearSpell", reanimateSpell.id)
                      displayMessage("spell target must not be automaton.")
                      return
                  end
                end
            end

              for _, effect in ipairs(reanimateSpell.effects) do
                if effect.id == "reanimatedead" then
                 
                  core.sendGlobalEvent("createZombie", {corpseActor = actor, spellId = tostring(reanimateSpell.id), magnitude = effect.magnitudeThisFrame})
                  self:sendEvent("checkNecroCrime",actor)
                end
              end
            end
          else
            self:sendEvent("clearSpell", reanimateSpell.id)
           -- core.sendGlobalEvent("createZombie", {corpseActor = actor, spellId = tostring(reanimateSpell.id)})
            displayMessage("spell target must be dead.")
          end
         else
            self:sendEvent("clearSpell", reanimateSpell.id)
            --core.sendGlobalEvent("createZombie", {corpseActor = actor, spellId = tostring(reanimateSpell.id)})
            displayMessage("spell target must be a corpse")
        end
      else
          self:sendEvent("clearSpell", reanimateSpell.id)
          --core.sendGlobalEvent("createZombie", {corpseActor = actor, spellId = tostring(reanimateSpell.id)})
          displayMessage("spell target must be a corpse")
      end

    end
  end
end

I.SkillProgression.addSkillUsedHandler(function(skillId, params)
  if skillId == "conjuration" then
    self:sendEvent("spellUsed",{
      isEnchantedItem = false,
      enchantedItemSpell = nil
    })
	end
end)


local EnchantedItemsActive = {}
local function checkEnchantedItems()
 -- Get all active constant effect spells on the player, only check once every item equip
  local activeSpells   =  types.Actor.activeSpells(self)
    for _, spell in pairs(activeSpells) do
        if spell then
          if spell.fromEquipment and not spell.temporary and not EnchantedItemsActive[spell.activeSpellId] then
            for _, effect in pairs(spell.effects) do
              if effect.id == "reanimatedead" then
                 EnchantedItemsActive[spell.activeSpellId] = true
                self:sendEvent("spellUsed",{
                isEnchantedItem =  true,
                enchantedItemSpell = spell.activeSpellId
              })
              end
            end
          end
          if spell.item and spell.temporary and not EnchantedItemsActive[spell.activeSpellId] then
             for _, effect in pairs(spell.effects) do
              if effect.id == "reanimatedead" then
                EnchantedItemsActive[spell.activeSpellId] = true
                self:sendEvent("spellUsed",{
                isEnchantedItem =  true,
                enchantedItemSpell = spell.activeSpellId
              })
              end
            end
          end
    end
  end
end


local function onUpdate(dt)
  checkEnchantedItems()
end

local function onSave()
  return {
    savedConstantEnchantedItems = EnchantedItemsActive
  }
end

local function onLoad(data)
  EnchantedItemsActive = data.savedConstantEnchantedItems
end

return{
    eventHandlers = {
        checkNecroCrime = checkNecroCrime,
        spellUsed     = spellUsed,
        clearSpell    = clearSpell,
        checkEnchantedItems = checkEnchantedItems
    },
    engineHandlers = {
      onUpdate = onUpdate,
      onSave = onSave,
      onLoad = onLoad
    }
}