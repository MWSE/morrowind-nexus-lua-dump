local core = require('openmw.core')
local ui = require('openmw.ui')
local input = require('openmw.input')
local self = require('openmw.self')
local types = require('openmw.types')
local async = require('openmw.async')
local debug = require('openmw.debug')

-- settings functions
local function boolSetting(sKey, sDef)
  return {
    key = sKey,
    renderer = 'checkbox',
    name = sKey .. '_name',
    description = sKey .. '_desc',
    default = sDef,
  }
end
local function numbSetting(sKey, sDef, sInt, sMin, sMax)
  return {
    key = sKey,
    renderer = 'number',
    name = sKey .. '_name',
    description = sKey .. '_desc',
    default = sDef,
    argument = {
      integer = sInt,
      min = sMin,
      max = sMax,
    },
  }
end
-- handle settings
local storage = require('openmw.storage')
local I = require('openmw.interfaces')
I.Settings.registerPage({
  key = 'SolJumpAirDash',
  l10n = 'SolJumpAirDash',
  name = 'name',
  description = 'description',
})
-- default values!
local enabled = true
local verbose = false
local requireLanding = true
local dashOnEmpty = true -- 0 = allow dash if low fatigue (tradeoff damage on dash on empty), 1 = no dash on empty, damage when moving in air on empty
local buffSpeed = 1000
local statBreakeven = 50
local fatigueCost = 20
local buffDuration = 0.15
local doHurt = true
local hurtVal = 5
local hurtWait = 2
I.Settings.registerGroup({
  key = 'Settings_SolJumpAirDash',
  page = 'SolJumpAirDash',
  l10n = 'SolJumpAirDash',
  name = 'group_name',
  permanentStorage = true,
  settings = {
    boolSetting('enabled', enabled),
    boolSetting('verbose', verbose),
    boolSetting('requireLanding', requireLanding),
    numbSetting('buffSpeed', buffSpeed, true, 1, 10000),
    numbSetting('statBreakeven', statBreakeven, true, 0, 100),
    numbSetting('fatigueCost', fatigueCost, true, 0, 100),
    numbSetting('buffDuration', buffDuration, false, 0.05, 5),
    boolSetting('doHurt', doHurt),
    numbSetting('hurtVal', hurtVal, true, 1, 100),
    numbSetting('hurtWait', hurtWait, true, 1, 5),
    boolSetting('dashOnEmpty', dashOnEmpty),
  },
})
local settingsGroup = storage.playerSection('Settings_SolJumpAirDash')

-- initialize
local scaleBuff = buffSpeed * statBreakeven / 100
local flatBuff = buffSpeed - scaleBuff
-- update
local function updateSettings()
  enabled = settingsGroup:get('enabled')
  verbose = settingsGroup:get('verbose')
  requireLanding = settingsGroup:get('requireLanding')
  buffSpeed = settingsGroup:get('buffSpeed')
  statBreakeven = settingsGroup:get('statBreakeven')
  scaleBuff = buffSpeed * statBreakeven / 100
  flatBuff = buffSpeed - scaleBuff
  fatigueCost = settingsGroup:get('fatigueCost')
  buffDuration = settingsGroup:get('buffDuration')
  doHurt = settingsGroup:get('doHurt')
  hurtVal = settingsGroup:get('hurtVal')
  hurtWait = settingsGroup:get('hurtWait')
  dashOnEmpty = settingsGroup:get('dashOnEmpty')
  if not dashOnEmpty then
    hurtVal = math.ceil(hurtVal / 2)
  end
end
local function init()
  updateSettings()
end
settingsGroup:subscribe(async:callback(updateSettings))

-- shorthand for convenience
local attributes = types.Actor.stats.attributes
local skills = types.NPC.stats.skills
local dynamic = types.Actor.stats.dynamic

-- stance effects
local function spdMod(modSign, modVal)
  if modVal > 0 then -- if positive effect, then modifier; else damage
    modVal = math.abs(modVal)
    attributes.speed(self).modifier = math.max(0, attributes.speed(self).modifier + modSign * modVal)
  else
    modVal = math.abs(modVal)
    attributes.speed(self).damage = math.max(0, attributes.speed(self).damage + modSign * modVal)
  end
end

-- init stance total tracking, used for verbose outputs, and for onSave/onLoad tracking
local buffTotal = 0
-- save state to be removed on load
local function onSave()
  return {
    buffTotal = buffTotal
  }
end
local function onLoad(data)
  if data then
    buffTotal = data.buffTotal
    spdMod(-1, buffTotal)
    buffTotal = 0
  end
end

local buffVal = 0
local hurtTime = 0
local lastHurt = 0
local doBuff = true
local didLand = true
local landLogic = true
local hurtLogic = true
return {
  engineHandlers = {
    -- init settings
    onActive = init,
    -- save and load handling so you don't get stuck with modified stats
    onSave = onSave,
    onLoad = onLoad,

    onInputAction = function(id)
      if enabled then
        if id == input.ACTION.Jump then
          if not types.Actor.isOnGround(self) and not types.Actor.isSwimming(self) then
            landLogic = (didLand and requireLanding) or (not requireLanding)
            if landLogic and doBuff then -- don't allow stacking?
              --if true then -- allow stacking?
              -- apply fatigue cost
              local cfat = dynamic.fatigue(self).current
              hurtLogic = true
              if not dashOnEmpty and not (cfat >= fatigueCost) then
                hurtLogic = false
              end
              if hurtLogic then -- only do buff if enough fatigue for it
                if doHurt and dashOnEmpty and (cfat < fatigueCost) and not debug.isGodMode() then
                  ui.showMessage('Low fatigue dash... That hurt!')
                  dynamic.health(self).current = math.max(0, dynamic.health(self).current - hurtVal) -- don't set to below 0
                end

                doBuff = false
                if requireLanding then
                  didLand = false
                end
                if not debug.isGodMode() then
                  dynamic.fatigue(self).current = math.max(0, cfat - fatigueCost)
                end
                -- apply buff
                buffVal = flatBuff + scaleBuff * (skills.acrobatics(self).modified) / 50
                spdMod(1, buffVal)
                buffTotal = buffTotal + buffVal

                if verbose then
                  ui.showMessage('DASH!')
                end

                -- start release timer
                async:newUnsavableSimulationTimer(
                  buffDuration,
                  function()
                    spdMod(-1, buffTotal)
                    buffTotal = 0
                    doBuff = true
                  end
                )
              end
            end
          end
        end
      end
    end,

    onUpdate = function(dt)
      if requireLanding and not didLand then -- if you haven't landed but you need to
        if types.Actor.isOnGround(self) then
          didLand = true
        end
      end
      if enabled and doHurt and not dashOnEmpty then                                  -- if running this calc
        if not types.Actor.isOnGround(self) and not types.Actor.isSwimming(self) then -- if in air
          local mf = self.controls.movement
          local ms = self.controls.sideMovement
          if mf ~= 0 or ms ~= 0 then                                                               -- if moving
            if dynamic.fatigue(self).current < 1 then                                              -- if out of fatigue
              hurtTime = core.getSimulationTime() - lastHurt
              if (hurtTime > hurtWait) and not debug.isGodMode() then                              -- if enough time has passed
                ui.showMessage('Air moving while out of fatigue!')                                 -- other hurt message for dashing on empty is in above section.
                dynamic.health(self).current = math.max(0, dynamic.health(self).current - hurtVal) -- don't set to below 0
                lastHurt = core.getSimulationTime()                                                -- get timer value
              end
            end
          end
        end
      end
    end,
  }
}
