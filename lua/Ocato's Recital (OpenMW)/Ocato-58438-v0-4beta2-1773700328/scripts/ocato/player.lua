local self                      = require('openmw.self')
local types                     = require('openmw.types')
local core                      = require('openmw.core')
local input                     = require('openmw.input')
local async                     = require('openmw.async')
local ui                        = require('openmw.ui')
local store                     = require('openmw.storage')
local util                      = require('openmw.util')
local I                         = require('openmw.interfaces')
local T                         = require("openmw.types")
local ambient                   = require('openmw.ambient')
local auxUi                     = require('openmw_aux.ui')
local storage                   = require('openmw.storage')
local debug                     = require('openmw.debug')

local ocatoStorage = storage.playerSection('ocatoStorage')

local v2 = util.vector2
local rgb = util.color.rgb

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

local spellActive = false

local storeSuccess = false

local preSpells = {}

local messageBox = nil

local fontNormal = getColorFromGameSettings("FontColor_color_normal")
local fontCount = getColorFromGameSettings("FontColor_color_count")
local fontNegative = getColorFromGameSettings("FontColor_color_negative")

local function printTable(tab)
  for k,v in pairs(tab) do
    print(k .. "|" .. v)
  end
end

local function removeOcato()
  local activeSpells = types.Actor.activeSpells(self)
  local spellactiveid
  for k,v in pairs(activeSpells) do
    local spellid = v.id
    
    if spellid == "ocatos recital" then
      spellactiveid = v.activeSpellId
    end
  end
  
  types.Actor.activeSpells(self):remove(spellactiveid)
end

local function paddedBox(layout, template)
  return {
    template = template,
    content = ui.content {
      {
        template = I.MWUI.templates.padding,
        content = ui.content { layout },
      },
    }
  }
end

local messageBoxCallback = async:registerTimerCallback('ocatoMessageBox',function(data)
  if messageBox then
    messageBox:destroy()
  end
end)

local function drawMessageBox(message, timeout)
  if messageBox then
    messageBox:destroy()
  end

  messageBox = ui.create {
    --template = I.MWUI.templates.boxSolidThick,
    layer = 'Modal',
    type = ui.TYPE.Container,
    props = {
      relativePosition = v2(0.5,0.8),
      anchor = v2(0.5,0.5),
    },
    content = ui.content {}
  }
  
  local messageFlex = {
    type = ui.TYPE.Flex,
    props = {
      autoSize = true,
      arrange = ui.ALIGNMENT.Start,
      align = ui.ALIGNMENT.Start,
      horizontal = false,
    },
    content = ui.content {}
  }
  messageBox.layout.content:add(paddedBox(messageFlex,I.MWUI.templates.boxSolid))
  
  for k,v in ipairs(message) do 
    local messageTextFlex = {
      type = ui.TYPE.Flex,
      props = {
        autoSize = true,
        arrange = ui.ALIGNMENT.Center,
        align = ui.ALIGNMENT.Center,
        horizontal = true,
      },
      content = ui.content {}
    }
    messageFlex.content:add(messageTextFlex)
  
    if v[4] then
      local messageImg = {
        type = ui.TYPE.Image,
        props = {
          resource = ui.texture { path = v[4] },
          tileH = false,
          tileV = false,
          relativePosition = v2(0,0),
          size = v2(v[2],v[2]),
          alpha = 1,
          color = rgb(1,1,1),
        },
      }
      messageTextFlex.content:add(messageImg)
    end
    if v[1] then
      local size = 16
      local color = rgb(1,1,1)
      if v[2] then
        size = v2
      end
      if v[3] then
        color = rgb(1,1,1)
      end
    
      local messageText = ui.create {
        template = I.MWUI.templates.textNormal,
        type = ui.TYPE.Text,
        props = {
          multiline = true,
          text = v[1],
          relativePosition = util.vector2(0.5,0.5),
          textSize = v[2],
          textColor = v[3],
        },
      }
      messageTextFlex.content:add(messageText)
    end
  end
  async:newSimulationTimer(3, messageBoxCallback, {})
end

local function castHandler(groupname,key)
  if key == "self release" then
    self:sendEvent("OCATO_handleCast",{})
    --print("cast release")
  end
  if key == "self start" then
    local activeSpells = types.Actor.activeSpells(self)
    for k,v in pairs(activeSpells) do
      table.insert(preSpells, v)
    end
  end
end

local function storeSpell(spell)
  local alreadyStored = false
  storedSpells = ocatoStorage:getCopy("storedSpells")
  
  for k,v in ipairs(storedSpells) do
    if spell.id == v then
      alreadyStored = true
    end
  end

  if not alreadyStored then
    table.insert(storedSpells, spell.id)
    
    ocatoStorage:set("storedSpells", storedSpells)
    
    storedSpells = ocatoStorage:getCopy("storedSpells")
    
    printTable(storedSpells)
    
    drawMessageBox({{"Spell stored", 16, fontNormal, nil}})
    ambient.playSoundFile('sound/fx/magic/enchant.wav', {volume =0.9})
    
    --spellActive = false
    storeSuccess = true
    
    --removeOcato()
  else
    drawMessageBox({{"Spell already stored", 16, fontNegative, nil}})
    
    storeSuccess = true
  end
end

local spellTimeoutCallback = async:registerTimerCallback('spellTimeout',function(data)
  if storeSuccess == false then
    spellActive = false
    drawMessageBox({{"Ocato's Recital Timeout:", 16, fontNormal, nil},{"Spell storage cleared", 16, fontCount, nil}})
  else
    spellActive = false
    
    local storedSpells = ocatoStorage:getCopy("storedSpells")
    local messageStart = "Stored spell"
    
    if #storedSpells > 1 then
      messageStart = messageStart .. "s"
    end
    messageStart = messageStart .. ": "
    
    local messageText = {{messageStart, 24, fontNormal, nil}}
    
    for k,v in ipairs(storedSpells) do
      local spell = types.Actor.spells(self)[v]
      
      local messageLine = {spell.name, 24, fontCount, spell.effects[1].effect.icon}
      
      table.insert(messageText, messageLine)
    end
    
    drawMessageBox(messageText)
  end
end)

local function handleCast(data)
  local activeSpells = types.Actor.activeSpells(self)
  local activeEffects = types.Actor.activeEffects(self)

  local newSpell
  
  if spellActive == true then
    for k,v in pairs(activeSpells) do
      local instances = 0
      for kk,vv in pairs(preSpells) do
        if v.id == vv.id then
          instances = instances + 1
        end
      end
      if instances == 0 then
        local actorSpells = types.Actor.spells(self)
        --print(actorSpells[v.id])
        if actorSpells[v.id] then
          newSpell = actorSpells[v.id]
          break
        else
          drawMessageBox({{"Cannot store a spell you do not know", 16, fontNegative, nil}})
        end
      end
    end
    --print(newSpell)
    
    if newSpell then
      if newSpell.id ~= "ocatos recital" then
        storeSpell(newSpell)
      else
        drawMessageBox({{"Cannot store Ocato's Recital in itself", 16, fontNegative, nil}})
      end
    end
    
    preSpells = {}
    return
  end

  if activeSpells:isSpellActive("ocatos recital") then
    print("spell store start")
    spellActive = true
    storeSuccess = false
    
    ocatoStorage:set("storedSpells", {})

    local duration = types.Actor.spells(self)["ocatos recital"].effects[1].duration
    async:newSimulationTimer(duration, spellTimeoutCallback, {})
  end
end

local soundBank = {
  ["illusion"] = "illusion hit",
  ["conjuration"] = "conjuration hit",
  ["alteration"] = "alteration hit",
  ["destruction"] = "destruction hit",
  ["mysticism"] = "mysticism hit",
  ["restoration"] = "restoration hit",
}

local function playSpellSound(school)
  local sound = soundBank[school]
  
  ambient.playSound(sound, {volume =0.9})
end

local function procStored()
  print("stored spell proc")
  
  
  
  if self.type.isDead(self) then
    return
  end
  
  local spellids = ocatoStorage:getCopy("storedSpells")
  
  for k,v in ipairs(spellids) do
    local spell = types.Actor.spells(self)[v]
    local school = spell.effects[1].effect.school
    
    local magicka = types.Actor.stats.dynamic.magicka(self).current
    local cost = spell.cost
    
    if magicka < cost then
      return
    end
    
    types.Actor.stats.dynamic.magicka(self).current = magicka - cost
    
    local effect = spell.effects[1].effect.hitStatic
    local model
    if effect and types.Static.records[effect] then
      model = types.Static.records[effect].model
    end
    
    types.Actor.activeSpells(self):add({id = v, effects = { 0 }, stackable = false, caster = self, ignoreResistances = true, ignoreSpellAbsorption = true, ignoreReflect = true})
    
    I.SkillProgression.skillUsed(school, {skillGain = 1, useType = 0})
    
    playSpellSound(school)
    if model then
      core.sendGlobalEvent('SpawnVfx', {model = model, position = self.position, options = { useAmbientLight = false, vfxId = "myVfx" }})
    end
  end
end

local fightingActors = {}
local inCombat

local function onCombatTargetsChanged(data)
    local actor, targets = data.actor, data.targets

    if actor == nil then 
      return 
    end
    
    if next(targets) ~= nil then
        fightingActors[data.actor.id] = data.actor
    else
        fightingActors[data.actor.id] = nil
    end
   
    newCombat = next(fightingActors) ~= nil and debug.isAIEnabled()
    
    if newCombat ~= inCombat and newCombat == true then
      procStored()
    end
    
    inCombat = newCombat
end

I.AnimationController.addTextKeyHandler('spellcast',castHandler)

return {
  engineHandlers = {
    onInit = init,
    onLoad = init,
    
    onKeyPress = function(key)
      --if key.code == input.KEY.X then
      --  procStored()
      --end
    end,
      
    onMouseButtonPress = function(key)
    end,
  },
  eventHandlers = {
    OCATO_handleCast = handleCast,
    OMWMusicCombatTargetsChanged = onCombatTargetsChanged,
  },
}