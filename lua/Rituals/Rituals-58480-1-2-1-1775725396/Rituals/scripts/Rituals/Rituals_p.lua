local core = require('openmw.core')
local ui = require('openmw.ui')
local util = require('openmw.util')
local I = require('openmw.interfaces')
local async = require('openmw.async')
local types = require('openmw.types')
local self = require('openmw.self')
local ritualUi = require('scripts.Rituals.Ritual_UI')
local storage = require('openmw.storage')

local ritualList = require('scripts.Rituals.RitualList')
local failureTable = require('scripts.Rituals.FailureOutcomes')

local focus = nil

local telePopup = nil
local popup = nil
local overwritePopup = nil
local book = nil

local currentCircle = nil
local localIngredients = nil
local localSouls =  nil
local localActors = nil
local enough = false 

local ritualStorage = storage.playerSection('RitualsMod')

local function cleanVars()
  currentCircle = nil
  localIngredients = nil
  localSouls = nil
  localActors = nil
  enough = false
end

--local function effectCallback(id)
--  types.Actor.spells(self):remove(id)
--end

local effectCallback = async:registerTimerCallback('effectCallback',
  function(data)
--    print("ID:",data.id)
--    print("CATEGORY:",data.category)
    if data.id == nil or data.category == nil then return end
    local ritualEffects = ritualStorage:getCopy('Effects')
    if ritualEffects ~= nil then
      if ritualEffects[data.category] ~= nil then
        local r = ritualEffects[data.category][data.id]
        if r == nil or r ~= data.checksum then return end
        types.Actor.spells(self):remove(data.id)
--        print("CALLBACK REMOVED SPELL:",data.id,data.checksum)
        ritualEffects[data.category] = nil
        ritualStorage:set('Effects',ritualEffects)
      end
    end
  end
)

-- effect is {id,duration}
local function addRitualEffect(category,effect)
  -- Im sure its fine
  local checksum = math.random(1,1e9)
  local ritualEffects = ritualStorage:getCopy('Effects') or {}
  if ritualEffects[category] ~= nil then
    --remove existing effects
    for id,effect in pairs(ritualEffects[category]) do
      if type(effect) == 'table' then
        if effect.onDelete then
          core.sendGlobalEvent(effect.onDelete,{})
        end
      else
        types.Actor.spells(self):remove(id)
      end
    end
  end
  ritualEffects[category] = {}
  ritualEffects[category][effect.id] = checksum
  ritualStorage:set('Effects',ritualEffects)
  types.Actor.spells(self):add(effect.id)
  if effect.duration ~= 0 then
    async:newGameTimer(effect.duration,effectCallback,{id = effect.id,category = category,checksum=checksum})
--    print("SET CALLBACK FOR",effect.duration)
--    print("With data:",effect.id,category,checksum)
  end
end

local function addRitualSpell(id)
  local spell = core.magic.spells.records[id]
  local effects = {}
  for _,effect in pairs(spell.effects) do
    table.insert(effects,effect.index)
  end
  
  types.Actor.activeSpells(self):add({
    id = id,
    effects = effects,
  })
end

local function addCategory(category,name,event)
  print("Adding category:",category)
  local ritualEffects = ritualStorage:getCopy('Effects') or {}
  if ritualEffects[category] ~= nil then
    print("Category already exists")
    for id,effect in pairs(ritualEffects[category]) do
      print("Deleting",id,effect)
      if effect.custom then
        print("Its custom")
        if effect.onDelete then
          print("Has event")
          core.sendGlobalEvent(effect.onDelete,{})
        end
      else
        print("is normal ability")
        types.Actor.spells(self):remove(id)
      end
    end
  end
  ritualEffects[category] = {}
  ritualEffects[category][name] = {custom=true,onDelete=event}
  ritualStorage:set('Effects',ritualEffects)
  print("Category set")
end

local function removeCategory(data)
  local cat = data.category
  local ritualEffects = ritualStorage:getCopy('Effects') or {}
  if ritualEffects[cat] ~= nil then
    for id,effect in pairs(ritualEffects[cat]) do
      if effect.custom then
        if effect.onDelete then
          core.sendGlobalEvent(effect.onDelete,{})
        end
      else
        types.Actor.spells(self):remove(id)
      end
    end
  end
  ritualEffects[cat] = nil
  ritualStorage:set('Effects',ritualEffects)
end

local function addRitual(id,notify)
  if notify == nil then notify = false end
  local list = ritualStorage:getCopy('KnownRituals') or {}
  if list[id] == nil or list[id] == false then
    if notify then
      local name = ritualList[id].name
      ui.showMessage("You have learned how to perform: "..name)
    end
  end
  list[id] = true
  ritualStorage:set('KnownRituals',list)
end

----TEMPORARY v
--ritualStorage:set('KnownRituals',{})
--
--for id,_ in pairs(ritualList) do
--  addRitual(id)
--end
--
--ritualStorage:set('Effects',{})
----TEMPORARY ^


local function destroyPopup()
  if popup ~= nil then
    popup:destroy()
    I.UI.removeMode(I.UI.MODE.Interface)
  end
end

local function bookOpen(data)
--for id,_ in pairs(ritualList) do
--  addRitual(id)
--end
  if self.controls.sneak then
    I.UI.addMode(I.UI.MODE.Interface,{windows={}})
    popup = ritualUi.removeCirclePopup(data.object)
  else
    I.UI.addMode(I.UI.MODE.Interface,{windows={}})
    book = ritualUi.book()
    ritualUi.clearDescription(book)
    book.layout.content.Ribbon.content.Search.props.text = "Search rituals"
    ritualUi.displayRituals(book,ritualList)
    currentCircle = data.object
  end
end

local function checkOnGround(data)
  if types.Actor.isOnGround(self) then
    core.sendGlobalEvent('R_CreateRitualCircle',data)
  end
end

local dremoraVendor = nil

local function uiChanged(data)
  if data.arg ~= nil and data.arg.recordId == 'r_dremora_vendor' then dremoraVendor = data.arg end
  if data.oldMode == 'Interface' then
    if book ~= nil then
      book:destroy()
      cleanVars()
    end
    
    if telePopup ~= nil then
      telePopup:destroy()
    end
  elseif data.oldMode == 'Dialogue' and data.newMode ~= 'Barter' and dremoraVendor then
    core.sendGlobalEvent('R_RemoveVendor',{actor=dremoraVendor})
  end
end

local function showDescription(data)
  local ing = ritualUi.showDescription(book,data.id,ritualList,currentCircle)
  localIngredients = ing.ingredients
  localSouls = ing.souls
  localActors = ing.actors
  enough = ing.enough  
end

local function beginRitual()
  local id = ritualUi.getRitualId(book)
  local data = ritualList[id]
  --check if ritual can be started
  if not enough then
    I.UI.showInteractiveMessage("Not enough materials to start the ritual.")
--    cleanVars()
    return
  end

  if data.customValidate ~= nil then
    local success,msg = data.customValidate()
    if not success then
      I.UI.showInteractiveMessage(msg)
      return
    end
  end

  local ritualEffects = ritualStorage:getCopy('Effects')
  --check for existing rituals with same category
  if ritualEffects ~= nil and ritualEffects[data.category] ~= nil and next(ritualEffects[data.category]) ~= nil then
    --popup to override existing category
    overwritePopup = ritualUi.overwriteEffectPopup(ritualEffects[data.category])
    return
  end
  
  --yucky
  self:sendEvent('R_OverwriteProceed',{overwrite=true})
end

local function removeWithVfx(object,count,vfx,sound)
  core.sendGlobalEvent('R_RemoveWithVfx',
  {
    object = object,
    count = count or 0,
    vfx = vfx or "meshes/e/magic_summon.nif",
    sound = sound or "Sound/Fx/magic/restH.wav",
  })
end

local function skillCheck(dif)
  local myst = types.NPC.stats.skills.mysticism(self).modified
  local will = types.NPC.stats.attributes.willpower(self).modified
  local success = nil
  local roll = math.random()
  local skill = (myst + will*0.1)
  local chance = 0.8735 + (skill - dif) * 0.02353
  local chance = math.max(0.01,chance)
--  print("SKILL CHECK TEST")
--  print("Ritual difficulty: "..tostring(dif))
--  print("Skill: "..tostring(skill))
--  print("Chance: "..tostring(chance))
--  print("Random roll: "..tostring(roll))
  if myst > dif then
    success = true
  else
    if roll < chance then success = true else success = false end
  end
  local skill_deficit = math.max(0, dif - myst)
  local roll_deficit = math.max(0, roll - chance)
  local severity = math.min(1, (skill_deficit / dif + roll_deficit) / 2)
--  print("Outcome: "..tostring(success))
--  print("Severity: ",severity)
  
  -- harmless events can happen if you succeed.
  if success then
    if roll < 0.1 then
      local data = {ingredients=localIngredients,souls=localSouls,circle=currentCircle}
      local events = failureTable[1].events
      local randomEvent = math.random(1,#events)
      events[randomEvent].func(data)
      ui.showMessage('Ritual had a unintended side effect!')
    end
    return true
  else
    local outcome = failureTable[1]
    for _,failure in ipairs(failureTable) do
      if severity >= failure.severity then
        outcome = failure
      else
        break
      end
    end
    local randomEvent = math.random(1,#outcome.events)
    local data = {ingredients=localIngredients,souls=localSouls,circle=currentCircle}
    outcome.events[randomEvent].func(data)
    ui.showMessage('The ritual failed with '..outcome.name..' consequences...')
  end
end

local function ritualContinue(data)
  
  if not data.overwrite then
    overwritePopup:destroy()
    return
  end
  
  if overwritePopup ~= nil then overwritePopup:destroy() end

  local id = ritualUi.getRitualId(book)
  local data = ritualList[id]
--  print(types.Static.record(core.magic.spells.records[data.effects[1].id].effects[1].effect.areaStatic).model)

  book:destroy()
  I.UI.removeMode(I.UI.MODE.Interface)
  
  --skill check
  local passed = skillCheck(data.difficulty)
  
  --temp
--  local data = {ingredients=localIngredients,souls=localSouls,circle=currentCircle}
--  failureTable[4].events[4].func(data)
--  passed=false
  --temp
  
  if not passed then return end
  
  for _,item in pairs(localIngredients) do
    removeWithVfx(item.item,item.amount)
  end
  
  for _,item in pairs(localSouls) do
    removeWithVfx(item,0)
  end
  
  for _,actor in pairs(localActors) do
    removeWithVfx(actor,0)
  end

  if data.effects ~= nil and #data.effects > 0 then
    for _,effect in pairs(data.effects) do
      if effect.type == "ability" then
        addRitualEffect(data.category,effect)
      elseif effect.type == "spell" then
        addRitualSpell(effect.id)
      end
    end
  else
    --no effects, put in the category and lasts (No one time effects)
    if data.isPermanent then
      if data.onDelete then
        addCategory(data.category,data.name,data.onDelete)
      else
        addCategory(data.category,data.name)
      end
    end
  end
  
  -- run the custom function
  if data.customFunction ~= nil then
    local i = {items=localIngredients,souls=localSouls,actors=localActors}
    local d = {circle=currentCircle,ritual=data,ingredients=i}
    data.customFunction(d)
  end
  
  -- send custom event
  if data.customEvent ~= nil then
    local arg = data.customEventArgs or {}
    arg.circle = currentCircle
    core.sendGlobalEvent(data.customEvent,arg)
  end
  
  -- nil all the variables (circle,ingreds,enough)
  cleanVars()
end

local function updateRitualList(data)
  if book ~= nil then
    ritualUi.displayRituals(book,ritualList,data.pattern)
  end
end

local function teleporterActivated(data)
  if self.controls.sneak then
    I.UI.addMode(I.UI.MODE.Interface,{windows={}})
    popup = ritualUi.removeCirclePopup(data.object)
  else
    telePopup = ritualUi.teleporterList(data.object)
  end
end

local function onMouseWheel(v,h)
  if focus ~= nil then
    if focus == "teleporter" then
      local pos = telePopup.layout.content.scroll.content.listWidget.content.list.props.position
      pos = pos + util.vector2(0,v*27)
      if pos.y < 0 then pos = util.vector2(pos.x,0) end
      telePopup.layout.content.scroll.content.listWidget.content.list.props.position = pos
      ui.updateAll()
    elseif focus == "ritualList" then
      local pos = book.layout.content.MainLayout.content.RitualListOuter.content.RitualListInner.props.position
      pos = pos + util.vector2(0,v*27)
      if pos.y > 0 then pos = util.vector2(pos.x,0) end
      book.layout.content.MainLayout.content.RitualListOuter.content.RitualListInner.props.position = pos
      ui.updateAll()
    elseif focus == "desc" then
      local pos = book.layout.content.MainLayout.content.Description.content.Desc.content.TextDescription.props.position
      pos = pos + util.vector2(0,v*27)
      if pos.y > 0 then pos = util.vector2(pos.x,0) end
      book.layout.content.MainLayout.content.Description.content.Desc.content.TextDescription.props.position = pos
      ui.updateAll()
    end
  end
end

local function onFocus(data)
  if data.focus then
    focus = data.ui
  else
    focus = nil
  end
end

local function learnRitual(data)
  addRitual(data.id,true)
end

local function onLoad(save)
  save = save or {}
  local effects = save.ritualEffects or {}
  local customEffects = save.customRitualEffects or {}
  local knownRituals = save.knownRituals or {}
  
  --learn rituals which are supposed to be known
  for id,ritual in pairs(ritualList) do
    if ritual.known then
      knownRituals[id] = true
    end
  end
  
  ritualStorage:set('Effects',effects)
  ritualStorage:set('CustomEffects',customEffects)
  ritualStorage:set('KnownRituals',knownRituals)
end

local function onSave()
  local effects = ritualStorage:getCopy('Effects')
  local customEffects = ritualStorage:getCopy('CustomEffects')
  local knownRituals = ritualStorage:getCopy('KnownRituals')
  return {ritualEffects=effects,
          customRitualEffects=customEffects,
          knownRituals=knownRituals,
         }
end

local function onInit()
  local knownRituals = {}
  
  --learn rituals which are supposed to be known
  for id,ritual in pairs(ritualList) do
    if ritual.known then
      knownRituals[id] = true
    end
  end
  
  ritualStorage:set('Effects',{})
  ritualStorage:set('CustomEffects',{})
  ritualStorage:set('KnownRituals',knownRituals)
end

local function registerRitual(ritual)
  local id = ritual.id
  if ritualList[id] ~= nil then
    error("Ritual with id: "..id.." already exists!")
  end
  ritualList[id] = ritual
  print("[RITUALS] Ritual: "..id.." successfully added.")
end

local interface = {}
interface.learnRitual = addRitual
interface.registerRitual = function(ritual,notify)
  local s,e = pcall(registerRitual,ritual,notify)
  if not s then
    print("[RITUALS] Failed to register ritual:",e)
  end
  return s
end
interface.getAllRituals = function() return ritualList end

return {
  interfaceName = "Rituals",
  interface = interface,
  eventHandlers = {
    UiModeChanged = uiChanged,
    R_BookOpen = bookOpen,
    R_RitualCircleCreation = checkOnGround,
    R_DestroyPopup = destroyPopup,
    R_RitualSelected = showDescription,
    R_RitualBegin = beginRitual,
    R_OverwriteProceed = ritualContinue,
    R_UpdateRitualList = updateRitualList,
    R_TeleporterActivated = teleporterActivated,
    R_FocusEvent = onFocus,
    R_LearnRitual = learnRitual,
    R_RemoveCategory = removeCategory,
  },
  engineHandlers = {
    onMouseWheel = onMouseWheel,
    onLoad = onLoad,
    onSave = onSave,
    onInit = onInit,
  }
}