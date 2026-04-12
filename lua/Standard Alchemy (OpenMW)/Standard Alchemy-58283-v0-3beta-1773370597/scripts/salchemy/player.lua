local self                      = require('openmw.self')
local types                     = require('openmw.types')
local core                      = require('openmw.core')
local input                     = require('openmw.input')
local async                     = require('openmw.async')
local ui                        = require('openmw.ui')
local store                     = require('openmw.storage')
local util                      = require('openmw.util')
local I                         = require('openmw.interfaces')
local ambient                   = require('openmw.ambient')
local auxUi                     = require('openmw_aux.ui')
local storage                   = require('openmw.storage')

local v2 = util.vector2

local invSnap = {}

local settings = storage.playerSection('Settings_Salchemy')

local function printTable(tab)
  for k,v in ipairs(tab) do
    print(v)
  end
end

local potionTable = {
  ["absorbattribute"] = "p_absorb_#",
  ["absorbFatigue"] = "p_absorb_fatigue",
  ["absorbHealth"] = "p_absorb_health",
  ["absorbMagicka"] = "p_absorb_magicka",
  ["absorbSkill"] = "p_absorb_s#",
  ["almsiviintervention"] = "p_almsivi_intervention",
  
  ["blind"] = "p_blind",
  ["boundbattleaxe"] = "p_bound_battleaxe",
  ["boundboots"] = "p_bound_boots",
  ["bounddagger"] = "p_bound_dagger",
  ["boundgloves"] = "p_bound_gloves",
  ["boundhelm"] = "p_bound_helm",
  ["boundlongbow"] = "p_bound_longbow",
  ["boundlongsword"] = "p_bound_longsword",
  ["boundmace"] = "p_bound_boundmace",
  ["boundshield"] = "p_bound_shield",
  ["boundSpear"] = "p_bound_spear",
  ["burden"] = "p_burden",
  
  ["calmcreature"] = "p_calm_creature",
  ["chameleon"] = "p_chameleon",
  ["charm"] = "p_charm",
  ["commandcreature"] = "p_command_creature",
  ["cureblightdisease"] = "p_cure_blight",
  ["curecommondisease"] = "p_cure_common",
  ["cureparalyzation"] = "p_cure_paralyzation",
  ["curepoison"] = "p_cure_poison_",
  
  ["damageattribute"] = "p_damage_#",
  ["damagefatigue"] = "p_damage_fatigue",
  ["damagehealth"] = "p_damage_health",
  ["damagemagicka"] = "p_damage_magicka",
  ["damageskill"] = "p_damage_skill",
  ["demoralizecreature"] = "p_demoralize_creature",
  ["demoralizehumanoid"] = "p_demoralize_humanoid",
  ["detectanimal"] = "p_detect_creatures",
  ["detectenchantment"] = "p_detect_enchantment",
  ["detectkey"] = "p_detect_key",
  ["disintegratearmor"] = "p_disintegrate_armor",
  ["disintegrateweapon"] = "p_disintegrate_weapon",
  ["dispel"] = "p_dispel",
  ["divineintervention"] = "p_divine_intervention",
  ["drainattribute"] = "p_drain_#",
  ["drainfatigue"] = "p_drain_fatigue",
  ["drainhealth"] = "p_drain_health",
  ["drainmagicka"] = "p_drain_magicka",
  ["drainskill"] = "p_drain_skill",
  
  ["feather"] = "p_feather",
  ["firedamage"] = "p_fire_damage",
  ["fireshield"] = "p_fire_shield",
  ["fortifyattack"] = "p_fortify_attack",
  ["foritfyattribute"] = "p_fortify_#",
  ["fortifyfatigue"] = "p_fortify_fatigue",
  ["fortifymagicka"] = "p_fortify_magicka",
  ["fortifymaximummagicka"] = "p_fortify_maximum_magicka",
  ["fortifyskill"] = "p_fortify_#",
  ["frenzycreature"] = "p_frenzy_creature",
  ["frenzyhumanoid"] = "p_frenzy_humanoid",
  ["frostdamage"] = "p_frost_damage",
  ["frostshield"] = "p_frost_shield",
  
  ["invisibility"] = "p_invisibility",
  ["jump"] = "p_jump",
  ["levitate"] = "p_levitation",
  ["light"] = "p_light",
  ["lightningshield"] = "p_lightning_shield",
  ["mark"] = "p_mark",
  ["nighteye"] = "p_night-eye",
  ["paralyze"] = "p_paralyze",
  ["poison"] = "p_poison",
  
  ["rallycreature"] = "p_rally_creature",
  ["rallyhumanoid"] = "p_rally_humanoid",
  ["recall"] = "p_recall",
  ["reflect"] = "p_reflection",
  ["resistblightdisease"] = "p_blight_resistance",
  ["resistcommondisease"] = "p_disease_resistance",
  ["resistfire"] = "p_fire_resistance",
  ["resistfrost"] = "p_fire_resistance",
  ["resistmagicka"] = "p_magicka_resistance",
  ["resistparalysis"] = "p_paralysis_resistance",
  ["resistpoison"] = "p_poison_resistance",
  ["resistshock"] = "p_shock_resistance",
  ["restoreattribute"] = "p_restore_#",
  ["restorefatigue"] = "p_restore_fatigue",
  ["restorehealth"] = "p_restore_health",
  ["restoremagicka"] = "p_restore_magicka",
  ["restoreskill"] = "p_restore_skill",
  
  ["sanctuary"] = "p_sanctuary",
  ["shield"] = "p_shield",
  ["shockdamage"] = "p_shock_damage",
  ["silence"] = "p_silence",
  ["slowfall"] = "p_slowfall",
  ["soultrap"] = "p_soultrap",
  ["sound"] = "p_sound",
  ["spellabsorbtion"] = "p_spell_absorbtion",
  ["swiftswim"] = "p_swift_swim",
  
  ["telekinesis"] = "p_telekinesis",
  
  ["waterbreathing"] = "p_water_breathing",
  ["waterwalking"] = "p_water_walking",
  ["weaknesstoblightdisease"] = "p_blight_weakness",
  ["weaknesstocommondisease"] = "p_disease_weakness",
  ["weaknesstofire"] = "p_fire_weakness",
  ["weaknesstofrost"] = "p_frost_weakness",
  ["weaknesstomagicka"] = "p_magicka_weakness",
  ["weaknesstonormalweapons"] = "p_normal_weakness",
  ["weaknesstopoison"] = "p_poison_weakness",
  ["weaknesstoshock"] = "p_shock_weakness",
}

local potionTableAlt = { -- tamriel_data
  ["damageattribute"] = "T_Com_Poison_Damage#",
  ["damagefatigue"] = "T_Com_Poison_DamageFatigue",
  ["damagehealth"] = "T_Com_Poison_DamageHealth",
  ["damagemagicka"] = "T_Com_Poison_DamageMagicka",
  ["drainattribute"] = "T_Com_Poison_Drain#",
  ["drainfatigue"] = "T_Com_Poison_DrainFatigue",
  ["drainhealth"] = "T_Com_Poison_DrainHealth",
  ["drainmagicka"] = "T_Com_Poison_DrainMagicka",
  ["sound"] = "T_Com_Poison_Sound",
  
  ["blind"] = "T_Com_Poison_Blind",
  ["burden"] = "T_Nor_Potion_Burden",
  ["feather"] = "p_feather",

  ["fireshield"] = "T_Nor_Potion_ShieldFire",
  ["frostshield"] = "T_Nor_Potion_ShieldFrost",
  ["jump"] = "T_Nor_Potion_Jump",
  ["levitation"] = "T_Nor_Potion_Levitation",
  ["shield"] = "T_Com_Potion_Shield",
  ["levitate"] = "T_Nor_Potion_Levitation",
  ["shockshield"] = "T_Nor_Potion_ShieldLightning",
  ["swiftswim"] = "T_Nor_Potion_SwiftSwim",
  
  ["sanctuary"] = "T_Com_Potion_Sanctuary",
  ["chameleon"] = "T_Nor_Potion_Chameleon",
  ["light"] = "T_Nor_Potion_Light",
  ["nighteye"] = "T_Nor_Potion_NightEye",
  ["paralyze"] = "T_Nor_Potion_Paralyze",
  ["silence"] = "T_Nor_Potion_Silence",
  
  ["reflect"] = "T_Nor_Potion_Reflection",
  ["spellabsorbtion"] = "T_Nor_Potion_SpellAbsorbtion",
  
  ["curecommondisease"] = "T_Nor_Potion_CureCommon_01",
  ["fortifyattack"] = "T_Com_Potion_FortifyAttack",
  ["foritfyattribute"] = "T_Nor_Potion_Fortifya@",
  ["fortifyfatigue"] = "T_Nor_Potion_FortifyFatigue",
  ["fortifyhealth"] = "T_Nor_Potion_FortifyHealth",
  ["fortifymagicka"] = "T_Nor_Potion_FortifyMagicka",
  ["resistcommondisease"] = "T_Nor_Potion_ResistDisease",
  ["resistfire"] = "T_Nor_Potion_ResistFire",
  ["resistfrost"] = "T_Nor_Potion_ResistFrost",
  ["resistmagicka"] = "T_Nor_Potion_ResistMagicka",
  ["resistparalysis"] = "T_Com_Potion_ResistParalysis",
  ["resistpoison"] = "T_Nor_Potion_ResistPoison",
  ["resistshock"] = "T_Nor_Potion_ResistShock",
  ["restoreattribute"] = "T_Nor_Potion_Restore#",
  ["restorefatigue"] = "T_Nor_Potion_RestoreFatigue",
  ["restorehealth"] = "T_Nor_Potion_RestoreHealth",
  ["restoremagicka"] = "T_Nor_Potion_RestoreMagicka",
}

local qualityTable = {
  "",
  "_b",
  "_c",
  "_s",
  "_q",
  "_e",
}

local attributeTable = {
  ["strength"] = {"strength", "str"},
  ["intelligence"] = {"intelligence", "int"},
  ["willpower"] = {"willpower", "will"},
  ["agility"] = {"agility", "agility"},
  ["speed"] = {"speed", "speed"},
  ["endurance"] = {"endurance", "end"},
  ["personality"] = {"personality", "personality"},
  ["luck"] = {"luck", "luck"},
}

local inAlchemy = false

function getColorFromGameSettings(colorTag)
	local result = core.getGMST(colorTag)
	if not result then
		return util.color.rgb(1,1,1)
	end
	local rgb = {}
	for color in string.gmatch(result, '(%d+)') do
		table.insert(rgb, tonumber(color))
	end
	if #rgb ~= 3 then
		print("UNEXPECTED COLOR: rgb of size=", #rgb)
		return util.color.rgb(1, 1, 1)
	end
	return util.color.rgb(rgb[1] / 255, rgb[2] / 255, rgb[3] / 255)
end


local function getEffectStrength(magicEffect)
  local baseCost = magicEffect.effect.baseCost
  local area = magicEffect.area
  local duration = magicEffect.duration
  local magnitudeMax = magicEffect.magnitudeMax
  local magnitudeMin = magicEffect.magnitudeMin
    
  local strength = math.floor( ( ( magnitudeMin + magnitudeMax) * math.max( duration, 1 ) + area ) * baseCost / 40 )
  
  return strength
end

local function parseEntry(entry, effect, alt)
  local special = string.sub(entry, -1)
  
  if special ~= '#' then
    return entry
  end
  
  local newEntry = string.sub(entry, 1, -2)
  local skillOrAttribute = effect.affectedAttribute
  
  if not skillOrAttribute then 
    skillOrAttribute = effect.affectedSkill
  end
  
  if alt == false then
    newEntry = newEntry .. attributeTable[skillOrAttribute][1]
  else
    newEntry = newEntry .. attributeTable[skillOrAttribute][2]
  end
  
  --print(newEntry)
  
  return newEntry
end

local function getClosestPotions(oldPotion)
  local oldRecord = types.Potion.record(oldPotion)
  local effects = oldRecord.effects
  
  local newPotionRecords = {}
  
  for k,v in ipairs(effects) do
    local newID = potionTable[v.id]
    local altID = potionTableAlt[v.id]
    local altAltID = potionTableAlt[v.id] --blame TR
    local oldEffectStr = getEffectStrength(v)
    
    newID = parseEntry(newID, v, false)
    if altID then
      altAltID = parseEntry(altID, v, true)
      altID = parseEntry(altID, v, false)
    end
    
    local newRecord = nil
    
    for kk,vv in ipairs(qualityTable) do
      local tryRecord = types.Potion.record(newID .. vv)
      local altRecord
      local altAltRecord
      
      if altID then 
        altRecord = types.Potion.record(altID .. vv)
      end
      
      if altAltID then 
        altAltRecord = types.Potion.record(altAltID .. vv)
      end
      
      if not tryRecord then
        if not altRecord then
          tryRecord = altAltRecord
        else
          tryRecord = altRecord
        end
      end
      
      if tryRecord then
        local tryEffect = tryRecord.effects[1]
        local tryEffectStr = getEffectStrength(tryEffect)
        --print(tryRecord.id .. " " .. tryEffectStr)
        
        if tryEffectStr <= oldEffectStr then
          newRecord = tryRecord
        end
      end
    end
    
    table.insert(newPotionRecords, newRecord)
  end
  
  return newPotionRecords
end

local function doAlchemy()
  local newSnap = types.Actor.inventory(self):getAll(types.Potion)
  
  local diff = {}
  
  for k,v in ipairs(newSnap) do
    local newRecord = types.Potion.record(v)
    local isNew = true
    
    for kk,vv in ipairs(invSnap) do
      local oldRecord = types.Potion.record(vv)
      
      if newRecord.id == oldRecord.id then
        isNew = false
      end
    end
    
    if isNew then
      --print(v)
      table.insert(diff, v)
    end
  end
  
  for k,v in ipairs(diff) do
    local newPotionRecords = getClosestPotions(v)
    local count = v.count
    --print(count)
    if newPotionRecords then
      for kk,vv in ipairs(newPotionRecords) do 
        core.sendGlobalEvent('SALC_GiveObject', {actor = self, objID = vv.id, count = count})
      end
      core.sendGlobalEvent('SALC_PotRemoveObject', {obj = v, count = count})
    end
  end
  
end 

local uiMain = {}

local function destroyUI()
  uiMain:destroy()
end

local function createAlchUI()
  uiMain = ui.create {
    template = I.MWUI.templates.boxSolid,
    layer = 'Modal',
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(0.5,0.1),
      anchor = v2(0.5,0.5),
    },
    content = ui.content {}
  }
  
  local mainWidget = {
    type = ui.TYPE.Widget,
    props = {
      size = v2(128,24),
    },
    content = ui.content {}
  }
  uiMain.layout.content:add(mainWidget)
  
  local entryTitle = ui.create {
    template = I.MWUI.templates.textHeader,
    type = ui.TYPE.Text,
    props = {
      text = "Standard",
      relativePosition = util.vector2(0.22,0.2),
      textColor = getColorFromGameSettings("FontColor_color_negative"),
    },
  }
  mainWidget.content:add(entryTitle)
end

local function handleUiModeChanged(data)
  if data.newMode == "Alchemy" then
    if input.isShiftPressed() == settings:get("normalOn") then
      print("alchemy start")
      inAlchemy = true
      invSnap = types.Actor.inventory(self):getAll(types.Potion)
      createAlchUI()
    end
  end
  if data.oldMode == "Alchemy" then
    if inAlchemy then
      print("alchemy end")
      doAlchemy()
      destroyUI()
      inAlchemy = false
    end
  end
end

local function init()
  --destroyUI()
  inAlchemy = false
end

return {
  engineHandlers = {
    onInit = init,
    onLoad = init,
  },
  eventHandlers = {
    UiModeChanged = handleUiModeChanged,
  },
}