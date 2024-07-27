local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local input = require('openmw.input')
local animation = require('openmw.animation')
local storage = require('openmw.storage')

local I = require('openmw.interfaces')

I.Settings.registerPage({
   key = 'urm_QuickSpellCast',
   l10n = 'urm_QuickSpellCast',
   name = 'name',
   description = 'description',
})

I.Settings.registerGroup({
   key = 'Settings_urm_QuickSpellCast',
   page = 'urm_QuickSpellCast',
   l10n = 'urm_QuickSpellCast',
   name = 'input_group_name',
   permanentStorage = false,
   settings = {
      {
         key = 'castWithReadyMagick',
         default = true,
         renderer = 'checkbox',
         name = 'castWithReadyMagick_name',
      },
      {
         key = 'castWithQuickKeys',
         default = true,
         renderer = 'checkbox',
         name = 'castWithQuickKeys_name',
         description = 'castWithQuickKeys_description',
      },
      {
         key = 'debug',
         default = false,
         renderer = 'checkbox',
         name = 'debug_name',
      },
   },
})

local settingsGroup = storage.playerSection('Settings_urm_QuickSpellCast')
local gameplaySettings = storage.globalSection('Settings_urm_QuickSpellCast_Gameplay')

local function debugOnly(f)
   if not settingsGroup:get('debug') then return end
   f()
end


local STANCE = types.Actor.STANCE

local STAGES = {
   Idle = 0,
   SpellStance = 1,
   WaitForStance = 2,
   Use = 3,
   WaitForCast = 4,
   RevertStance = 5,
   EnforceStance = 6,
}

local function enumName(value, enum)
   for name, v in pairs(enum) do
      if v == value then return name end
   end
   error('invalid enum value', value)
end












local selfObject = self


local function currentActive()
   local item = types.Actor.getSelectedEnchantedItem(selfObject)
   local spell = types.Actor.getSelectedSpell(selfObject)
   return item and item.id or (spell and spell.id)
end
local previousActive = currentActive()

local stageHandlers = {
   [STAGES.Idle] = function(state)
      if state.queuedCast then
         state.stage = STAGES.WaitForStance
         state.waitingForSpellStance = true
      else
         previousActive = currentActive()
         state.previousStance = types.Actor.getStance(selfObject)
      end
   end,
   [STAGES.SpellStance] = function(state)
      state.shouldSpeedUp = true
      if types.Actor.getSelectedSpell(selfObject) == nil then
         state.stage = STAGES.EnforceStance
      elseif types.Actor.getStance(selfObject) ~= STANCE.Spell then
         types.Actor.setStance(selfObject, STANCE.Spell)
      else
         state.stage = STAGES.WaitForStance
         state.waitingForSpellStance = true
      end
   end,
   [STAGES.WaitForStance] = function(state)
      if not state.waitingForSpellStance then
         state.stage = STAGES.Use
      end
   end,
   [STAGES.Use] = function(state)
      self.controls.use = 1
      state.stage = STAGES.WaitForCast
      state.waitingForCast = true
   end,
   [STAGES.WaitForCast] = function(state)
      if
not state.waitingForCast or
         not state.startedCast then

         state.stage = STAGES.RevertStance
         state.waitingForRevertedStance = true
         state.waitingForCast = false
         state.startedCast = false
      end
   end,
   [STAGES.RevertStance] = function(state)
      if state.previousStance == STANCE.Spell then
         state.waitingForRevertedStance = false
      end
      if types.Actor.getStance(selfObject) ~= state.previousStance then
         types.Actor.setStance(selfObject, state.previousStance)
      end
      if not state.waitingForRevertedStance then
         state.stage = STAGES.EnforceStance
      end
   end,
   [STAGES.EnforceStance] = function(state)


      if types.Actor.getStance(selfObject) ~= state.previousStance then
         types.Actor.setStance(selfObject, state.previousStance)
      end
      state.stage = STAGES.Idle
      state.shouldSpeedUp = false
      state.waitingForRevertedStance = false
      state.queuedCast = false
   end,
}

local state = {
   stage = STAGES.Idle,
   queuedCast = false,
   previousStance = STANCE.Nothing,
   waitingForSpellStance = false,
   waitingForCast = false,
   waitingForRevertedStance = false,
   startedCast = false,
   shouldSpeedUp = false,
}

local spellAnimationTypes = {
   ['target'] = true,
   ['self'] = true,
   ['touch'] = true,
}
local equipPrefix = 'equip'
local stopSuffix = ' stop'

I.AnimationController.addTextKeyHandler('spellcast', function(groupName, key)
   local completed = (animation.getCompletion(selfObject, groupName) or 1) == 1
   if completed and key == 'equip stop' then
      state.waitingForSpellStance = false
   else
      local isSpell = spellAnimationTypes[key:match('[^ ]+')]
      if state.waitingForCast and isSpell then
         state.startedCast = true
      end
      local isStop = key:sub(-#stopSuffix) == stopSuffix
      if isSpell and isStop and completed then
         state.waitingForCast = false
      end
   end
   if state.shouldSpeedUp then
      local speedChange = gameplaySettings:get('stanceAnimationSpeedup')
      if speedChange ~= 1 and key:sub(1, #equipPrefix) == equipPrefix then
         animation.setSpeed(selfObject, groupName, speedChange)
      end
   end
end)

I.AnimationController.addTextKeyHandler('spellcast', function(groupName, key)
   if state.waitingForRevertedStance then
      local completed = (animation.getCompletion(selfObject, groupName) or 1) == 1
      debugOnly(function() print(groupName, key, completed) end)
      if key == 'unequip stop' and completed then
         state.waitingForRevertedStance = false
      end
   end
end)

local quickKeyActions = {}
for i = 1, 10 do
   quickKeyActions[(input.ACTION)['QuickKey' .. tostring(i)]] = true
end

local function castInput(skipStance)
   if state.stage ~= STAGES.Idle then
      state.queuedCast = true
   elseif skipStance and state.previousStance == STANCE.Spell then
      state.stage = STAGES.Use
   else
      state.stage = STAGES.SpellStance
   end
end

local previousStage = state.stage

local function magicControlSwitch()
   return types.Player.getControlSwitch(self.object, types.Player.CONTROL_SWITCH.Controls) and
   types.Player.getControlSwitch(self.object, types.Player.CONTROL_SWITCH.Magic)
end



return {
   engineHandlers = {
      onInputAction = function(action)
         if not magicControlSwitch() then
            return
         end
         if action == input.ACTION.ToggleSpell and settingsGroup:get('castWithReadyMagick') then
            castInput(false)
         elseif quickKeyActions[action] and settingsGroup:get('castWithQuickKeys') then

            if currentActive() ~= previousActive or types.Actor.getStance(selfObject) == STANCE.Spell then
               castInput(true)
               previousActive = currentActive()
            end
         end
      end,
      onFrame = function()
         if core.isWorldPaused() then return end
         debugOnly(function()
            if previousStage ~= state.stage then
               print('SWITCHED TO', enumName(state.stage, STAGES), 'PREVIOUS STANCE', enumName(state.previousStance, types.Actor.STANCE))
            end
            previousStage = state.stage
         end)
         stageHandlers[state.stage](state)
      end,
      onSave = function()
         return state
      end,
      onLoad = function(savedState)
         if not savedState then return end
         state.stage = math.min(savedState.stage, STAGES.Use)
         state.previousStance = savedState.previousStance


         state.waitingForSpellStance = false
         state.waitingForCast = false
         state.startedCast = false
         state.shouldSpeedUp = false
         state.queuedCast = false
      end,
   },
}
