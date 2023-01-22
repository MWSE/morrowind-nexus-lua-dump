local core = require('openmw.core')
local self = require('openmw.self')
local types = require('openmw.types')
local input = require('openmw.input')
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
   name = 'group_name',
   permanentStorage = false,
   settings = {
      {
         key = 'enabled',
         default = true,
         renderer = 'checkbox',
         name = 'enabled_name',
      },
      {
         key = 'readyAnimationDuration',
         default = 0.7,
         renderer = 'number',
         name = 'readyAnimationDuration_name',
         description = 'readyAnimationDuration_description',
         argument = {
            min = 0.0,
         },
      },
   },
})

local settingsGroup = storage.playerSection('Settings_urm_QuickSpellCast')

local STANCE = types.Actor.STANCE

local STAGES = {
   Idle = 0,
   SpellStance = 1,
   Use = 2,
   StopUse = 3,
   RevertStance = 4,
}







local stageHandlers = {
   [STAGES.Idle] = function(state, _)
      state.previousStance = types.Actor.stance(self)
      state.stage = STAGES.Idle
   end,
   [STAGES.SpellStance] = function(state, _)
      if types.Actor.stance(self) ~= STANCE.Spell then
         types.Actor.setStance(self, STANCE.Spell)
      else
         state.stage = STAGES.Use
      end
   end,
   [STAGES.Use] = function(state, dt)
      self.controls.use = 1
      state.useHeld = state.useHeld + dt
      if state.useHeld > settingsGroup:get('readyAnimationDuration') then
         state.useHeld = 0
         state.stage = STAGES.StopUse
      end
   end,
   [STAGES.StopUse] = function(state, _)
      self.controls.use = 0
      state.stage = STAGES.RevertStance
   end,
   [STAGES.RevertStance] = function(state, _)
      if types.Actor.stance(self) ~= state.previousStance then
         types.Actor.setStance(self, state.previousStance)
      else
         state.stage = STAGES.Idle
      end
   end,
}

local state = {
   stage = STAGES.Idle,
   previousStance = STANCE.Nothing,
   useHeld = 0,
}

return {
   engineHandlers = {
      onInputAction = function(action)
         if action ~= input.ACTION.ToggleSpell or state.stage ~= STAGES.Idle then return end
         state.stage = STAGES.SpellStance
      end,
      onFrame = function(dt)
         if not settingsGroup:get('enabled') then return end
         if core.isWorldPaused() then return end
         stageHandlers[state.stage](state, dt)
      end,
      onSave = function()
         return state
      end,
      onLoad = function(savedState)
         if not savedState then return end
         state.stage = math.min(savedState.stage, STAGES.Use)
         state.previousStance = savedState.previousStance
         state.useHeld = 0
      end,
   },
}