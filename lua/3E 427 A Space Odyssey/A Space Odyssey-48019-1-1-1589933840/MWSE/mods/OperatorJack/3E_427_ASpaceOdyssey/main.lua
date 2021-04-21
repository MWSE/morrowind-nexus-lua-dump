local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

require("OperatorJack.3E_427_ASpaceOdyssey.effects.flotation")


local spellIds = {
  flotation = "OJ_ME_FlotationSpell",
}

local function registerSpells()
	framework.spells.createBasicSpell({
    id = spellIds.flotation,
    name = "Flotation",
    effect = tes3.effect.float,
    range = tes3.effectRange.self,
    min = 30,
    max = 30,
    duration = 30
  })
end
event.register("MagickaExpanded:Register", registerSpells)



local tarhielId = "agronian guy"
local levitationPotionId = "p_levitation_e"
event.register("initialized", function()
  -- TODO: Override global script for stage 20.
  local function levitate()
    if (tes3.menuMode() == true) then
      return
    end
    
    local tarhiel = tes3.getReference(tarhielId)
    tarhiel.position.z = tarhiel.position.z + 3
  end

  local function stage20Event()
    if (tes3.menuMode() == true) then
      return
    end
    
    event.unregister("simulate", stage20Event)

    local tarhiel = tes3.getReference(tarhielId)
    mwscript.equip({
      reference = tarhiel,
      item = levitationPotionId
    })
    tes3.playAnimation({
      reference = tarhiel,
      group = tes3.animationGroup.walkForward,
      startFlag = tes3.animationStartFlag.immediateLoop
    })
    event.unregister("simulate", levitate)
    event.register("simulate", levitate)

    local state = tes3.mobilePlayer.controlsDisabled
    tes3.mobilePlayer.controlsDisabled = true

    timer.start({
      duration = 5,
      callback = function()
        tes3.fadeOut()
        timer.start({
          duration = 3,
          callback = function()
            event.unregister("simulate", levitate)
            
            tes3.playAnimation({
              reference = tarhiel,
              group = tes3.animationGroup.idle,
              startFlag = tes3.animationStartFlag.normal
            })
            tes3.removeEffects({
              effect = tes3.effect.levitate,
              reference = tarhiel
            })

            tes3.fadeIn()
            local globalId = "OJGA_ASpaceOdyssey20Global"
            local global = tes3.findGlobal(globalId)
            global.value = 1
            tes3.mobilePlayer.controlsDisabled = state
          end
        })
      end
    })
  end

  mwse.overrideScript("OJGA_ASpaceOdyssey20Script", function(e)
    local globalId = "OJGA_ASpaceOdyssey20Global"
    local global = tes3.findGlobal(globalId)
    if (global.value == 0) then
      event.register("simulate", stage20Event)
    end
    
    mwscript.stopScript{script="OJGA_ASpaceOdyssey20Script"}
  end)
  
  -- Handle stage 50 floating.
  local function finalEvent(e)
    if (tes3.menuMode() == true) then
      return
    end
    
    event.unregister("simulate", finalEvent)

    local tarhiel = tes3.getReference(tarhielId)
    tes3.cast({
      reference = tarhiel,
      target = tarhiel,
      spell = spellIds.flotation
    })
    local state = tes3.mobilePlayer.controlsDisabled
    tes3.mobilePlayer.controlsDisabled = true

    timer.start({
      duration = 5,
      callback = function()
        tes3.fadeOut()
        timer.start({
          duration = 1,
          callback = function()
            tes3.removeEffects({
              effect = tes3.effect.float,
              reference = tarhiel
            })
            tarhiel:disable()
            tes3.fadeIn()
            tes3.mobilePlayer.controlsDisabled = state
          end
        })
      end
    })
  end

  event.register("journal", function(e)
    if (e.topic.id == "OJGA_ASpaceOdyssey") then
      if (e.index == 50) then
        event.register("simulate", finalEvent)
      end
    end
  end)
end)