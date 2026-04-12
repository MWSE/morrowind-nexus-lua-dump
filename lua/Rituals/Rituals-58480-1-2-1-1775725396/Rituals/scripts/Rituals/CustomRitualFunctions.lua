local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local types = require('openmw.types')
local self = require('openmw.self')
local storage = require('openmw.storage')
local nearby = require('openmw.nearby')
local calendar = require('openmw_aux.calendar')

local v2 = util.vector2
local screenSize = ui.screenSize()

-- Goes over the limit cus its magic n shit
-- Alternatively could blow up the weapon if repaired too much
local function ritualRepairGear(data)
  local ritualCircle = data.circle
  local soulGems = {}
  local soulPower = 0
  local closestGear = nil
  local closestDistance = nil
  for _,item in pairs(nearby.items) do
    local distance = (ritualCircle.position - item.position):length()
    if distance <= 250 then
      local data = types.Item.itemData(item)
      if data.soul ~= nil then
        table.insert(soulGems,item)
        soulPower = soulPower + types.Creature.record(data.soul).soulValue
      else
        if data.condition ~= nil and item.type ~= types.Light then
          if closestDistance == nil then
            closestGear = item
            closestDistance = distance
          else
            if distance < closestDistance then
              closestGear = item
              closestDistance = distance
            end
          end 
        end
      end
    end
  end
  if closestGear ~= nil then
    local condition = types.Item.itemData(closestGear).condition
    condition = condition + soulPower*2
    core.sendGlobalEvent('R_RitualRepairGear',{item=closestGear,condition = condition})
    for _,soul in ipairs(soulGems) do
      core.sendGlobalEvent('R_RemoveWithVfx',
      {
        object = soul,
        count = 0,
        vfx = "meshes/e/magic_summon.nif",
        sound = "Sound/Fx/magic/altrH.wav",
      })
    end
  end
end

local function createTeleporter(data)
  local ritualCircle = data.circle
  I.UI.addMode(I.UI.MODE.Interface,{windows={}})
  local popup = ui.create{
    type = ui.TYPE.Container,
    template = I.MWUI.templates.boxSolidThick,
    layer = 'Modal',
    props = {
      relativeSize = v2(0.2,0.1),
      relativePosition = v2(0.5,0.5),
      anchor = v2(0.5,0.5),
    },
    content = ui.content{
      {
        type = ui.TYPE.Widget,
        name = "inner",
        props = {
          size = v2(screenSize.x*0.25,screenSize.y*0.1),
        },
        events = {},
        content = ui.content{
          {
            type = ui.TYPE.Text,
            template = I.MWUI.templates.textHeader,
            props = {
              relativePosition = v2(0.5,0),
              anchor = v2(0.5,0),
              text = "Name the teleporter:",
            }
          },
          {
            type = ui.TYPE.TextEdit,
            template = I.MWUI.templates.textEditLine,
            name = "name",
            props = {
              relativePosition = v2(0,0.5),
              relativeSize = v2(1,0.25),
              anchor = v2(0,0.5),
              text = "Teleporter name",
            },
            events = {
              textChanged = async:callback(function(s,l) l.props.text = s end)
            },
          },
          {
              type = ui.TYPE.Container,
              template = I.MWUI.templates.boxSolidThick,
              name = "button",
              props = {
                relativePosition = v2(0.5,1),
                anchor = v2(0.5,1),
              },
              content = ui.content{
                {
                  type = ui.TYPE.Text,
                  template = I.MWUI.templates.textNormal,
                  props = {
                    text = "Submit",
                  },
                },
              },
            },
          
        },
      },
    },
  }

  -- WHY I DIDINT DO IT LIKE THIS BEFORE
  popup.layout.content.inner.content.button.events = {mouseClick = async:callback(
          function(_,layout)
              core.sendGlobalEvent('R_Create_Teleporter',{circle=ritualCircle,name=popup.layout.content.inner.content.name.props.text})
              popup:destroy()
              I.UI.removeMode(I.UI.MODE.Interface)
          end)
          }
end

--pretty messy lookin
local function skillGain(tab)
  local data = tab.ritual
  local checksum = math.random(1,1e9)
  local ritualStorage = storage.playerSection('RitualsMod')
  local customEffects = ritualStorage:getCopy('CustomEffects') or {}
  customEffects[data.category] = {enabled=true,checksum=checksum}
  ritualStorage:set('CustomEffects',customEffects)
  async:newGameTimer(86400,async:registerTimerCallback('skillGainCallback',
  function(data)
    if data.category == nil then return end
    local ritualEffects = ritualStorage:getCopy('CustomEffects')
    if ritualEffects ~= nil then
      local r = ritualEffects[data.category]
      if r ~= nil and r.checksum ~= data.checksum then return end
      ritualEffects[data.category] = nil
      ritualStorage:set('CustomEffects',ritualEffects)
    end
  end
),{category = data.category,checksum=checksum})
end

local function evalMysticism()
  local myst = types.NPC.stats.skills.mysticism(self).modified
  local drain = myst * 0.5
  return {drain}
end

local function absorbStats(data)
  local drain = data.ritual.effectsEval[1].eval()[1]
  drain = drain/100
  local actor = data.ingredients.actors[1]
--  print(actor)
  local aFat = types.Actor.stats.dynamic.fatigue(actor).base * drain
  local aMagic = types.Actor.stats.dynamic.magicka(actor).base * drain
--  print("DRAINED AMOUNT:",aFat,aMagic)
  local pFat = types.Actor.stats.dynamic.fatigue(self).current
  local pMagic = types.Actor.stats.dynamic.magicka(self).current
  types.Actor.stats.dynamic.fatigue(self).current = pFat + aFat
  types.Actor.stats.dynamic.magicka(self).current = pMagic + aMagic
end

local function summonVendor(data)
  local ids = {}
  for k,v in pairs(I.Rituals.getAllRituals()) do
    table.insert(ids,k)
  end
  core.sendGlobalEvent('R_Spawn_DremoraVendor',{cell=data.circle.cell.name,pos=data.circle.position,rituals=ids})
  core.sendGlobalEvent('PlaySound3d',{file="Sound/Fx/magic/conjH.wav",position=data.circle})
end

local function canCastToday()
  local ritualStorage = storage.playerSection('RitualsMod')
  local customEffects = ritualStorage:getCopy('CustomEffects') or {}
  local customEffect = customEffects['r_prepare_spell']
  if customEffect == nil then
    return true
  else
    if customEffect.day == nil then
      return true
    else
      local day = calendar.formatGameTime("%w", calendar.gameTime())
--      print("Comparing days: ",day,customEffect.day)
      if day == customEffect.day then
        return false,"Prepared spell was already cast this day!"
      else
        return true
      end
    end 
  end
end

local function prepareSpell(data)
  local spell = types.Actor.getSelectedSpell(self)
  local cost = spell.cost
--  print("Spell name:",spell.name)
--  print("Spell cost:",spell.cost)
  
  ---TODO: Take all the mana and overflow health
  local mana = types.Actor.stats.dynamic.magicka(self).current
  if mana < cost then
    local dif = cost - mana
--    print("missing mana:",dif)
--    print("taking as health")
    types.Actor.stats.dynamic.magicka(self).current = 0
    local health = types.Actor.stats.dynamic.health(self).current
    health = health - dif
    -- can kill which is good  >:)
    types.Actor.stats.dynamic.health(self).current = health
  else
    mana = mana - cost
    types.Actor.stats.dynamic.magicka(self).current = mana
  end
  
  core.sendGlobalEvent('PlaySound3d',{file="Sound/Fx/magic/altrC.wav",position=self})
  self:sendEvent('AddVfx',{model = 'meshes/e/magic_cast_restore.nif'})
  
  local ritualStorage = storage.playerSection('RitualsMod')
  local customEffects = ritualStorage:getCopy('CustomEffects') or {}
  customEffects[data.ritual.category] = {enabled=true,spell=spell.id,cost=cost}
  ritualStorage:set('CustomEffects',customEffects)
end

local function ebonyToDaedric(id)
  local ebony_to_daedric = {
    ["ebony_boots"]           = "daedric_boots",
    ["ebony_closed_helm"]     = { 
        "daedric_god_helm",
        "daedric_fountain_helm",
        "daedric_terrifying_helm"
    },
    ["ebony_cuirass"]         = "daedric_cuirass",
    ["ebony_greaves"]         = "daedric_greaves",
    ["ebony_bracer_left"]     = "daedric_gauntlet_left",
    ["ebony_bracer_right"]    = "daedric_gauntlet_right",
    ["ebony_pauldron_left"]   = "daedric_pauldron_left",
    ["ebony_pauldron_right"]  = "daedric_pauldron_right",
    ["ebony_shield"]          = "daedric_shield",
    ["ebony_towershield"]     = "daedric_towershield",

    ["ebony arrow"]           = "daedric arrow",
    ["ebony broadsword"]      = "daedric longsword",
    ["ebony dart"]            = "daedric dart",
    ["ebony longsword"]       = "daedric longsword",
    ["ebony mace"]            = "daedric mace",
    ["ebony shortsword"]      = "daedric shortsword",
    ["ebony spear"]           = "daedric spear",
    ["ebony staff"]           = "daedric staff",
    ["ebony throwing star"]   = "daedric dart",
    ["ebony war axe"]         = "daedric war axe",
  }
  local new_id = ebony_to_daedric[id]
  
  if not new_id then
    return false
  end
  
  if id == "ebony_closed_helm" then
    new_id = ebony_to_daedric[id]
    new_id = new_id[math.random(1,#new_id)]
  end
  
  return new_id
end

local function daedricUpgrade(data)
  for _,i in pairs(data.ingredients.items) do
    i = i.item
    if i.type == types.Armor or i.type == types.Weapon then
      print(i.recordId)
      local item = ebonyToDaedric(i.recordId)
      print(item)
      if item then
        local isArrow = item == 'daedric arrow' or item == 'daedric dart'
        local count = i.count
        if not isArrow then count = 1 end
        core.sendGlobalEvent('R_SpawnItem',{id=item,cell=i.cell.name,pos=i.position,count=count})
        if i.count > 1 and isArrow then
          core.sendGlobalEvent('R_RemoveWithVfx',
          {
            object = i,
            count = 0,
            vfx = "meshes/e/magic_summon.nif",
            sound = "Sound/Fx/magic/altrH.wav",
          })
        end
        break
      end
    end
  end
end

return {
  ritualRepairGear = ritualRepairGear,
  createTeleporter = createTeleporter,
  skillGain = skillGain,
  evalMysticism = evalMysticism,
  absorbStats = absorbStats,
  summonVendor = summonVendor,
  prepareSpell = prepareSpell,
  canCastToday = canCastToday,
  daedricUpgrade = daedricUpgrade,
}