--Effect Id Claiming
tes3.claimSpellEffectId("pocket", 701)

-- Including the magicka expanded framework
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[POCKET: ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end


local containers = {}
local tomes = {{
    id = "YK_PT_TomePocket",
    spellId = "ExtradimensionalPockets"
  }}

local function addTomesToLists()
  local listId = "OJ_ME_LeveledList_Common"
  for _, tome in pairs(tomes) do
    mwscript.addToLevItem({
      list = listId,
      item = tome.id,
      level = 1
    })
  end
end
event.register("initialized", addTomesToLists)

local function onLoad(e)
	if(e.newGame)then
		containers = {}
		return
	end
	
	containers = json.loadfile("Pockets"..e.filename)
	if (not containers) then
		containers = {}
	end
end

local function onSave(e)
	json.savefile("Pockets"..e.filename, containers)
end

event.register("load", onLoad)
event.register("saved", onSave)

local function onPocketTick(e)
	if (not e:trigger()) then
		return
	end
	
	--using e.sourceInstance.source gets the spell that was cast
	containerRef = tes3.getReference(containers[e.sourceInstance.source.id])
	if(not containerRef) then
		pocketsSize = table.size(containers)
		tes3.createObject({
			objectType = tes3.objectType.container,
			id = "YK_PT_Pocket" .. tostring(pocketsSize),
			name = e.sourceInstance.source.name,
			mesh = "ME\\RES\\merchantCrate.nif",
			capacity = e.sourceInstance.sourceEffects[e.effectIndex + 1].duration
		})
		containers[e.sourceInstance.source.id] = "YK_PT_Pocket" .. tostring(pocketsSize)
		
		containerID = containers[e.sourceInstance.source.id]
		containerRef = tes3.createReference({
		object = tes3.getObject(containerID),
		position = tes3.player.position:copy(),
		orientation = tes3.player.orientation:copy(),
		cell = tes3.getPlayerCell()
		})
	end
    timer.delayOneFrame(
        function() 
			tes3.player:activate(containerRef)
        end,
        timer.real
    )
	e.effectInstance.state = tes3.spellState.retired
end

local function addPocketEffects()
	framework.effects.conjuration.createBasicEffect({
  -- Base information.
  id = tes3.effect.pocket,
  name = "Pocket",
  description = "Opens a pocket in the plane of Oblivion allowing you to store items in the void. Duration determines the size of the pocket.",
  -- Basic dials.
  baseCost = 10.0,
  -- Various flags.
  allowEnchanting = false,
  allowSpellmaking = true,
  canCastTarget = false,
  canCastTouch = false,
  canCastSelf = true,
  hasNoMagnitude = true,
  hasNoDuration = false,
  nonRecastable = false,
  -- Graphics/sounds. left as defaults
  -- Required callbacks.
  onTick = onPocketTick,
 })
end

event.register("magicEffectsResolved", addPocketEffects)

local function registerSpells()
	framework.spells.createBasicSpell({
		id = "ExtradimensionalPockets",
		name = "Extradimensional Pockets",
		effect = tes3.effect.pocket,
		range = tes3.effectRange.self,
		duration = 50
	})
	framework.tomes.registerTomes(tomes)
end

event.register("MagickaExpanded:Register", registerSpells)

--MCM code
local function registerModConfig()
	EasyMCM = require("easyMCM.EasyMCM")
    local template = EasyMCM.createTemplate("Pockets")
    local page = template:createPage()
    local category = page:createCategory("Pockets")
    category:createButton{ buttonText = "Add Base Spell", callback = (function()
		tes3.addSpell({
			reference = tes3.player,
			spell = "ExtradimensionalPockets"
		})
	end)
	}
    EasyMCM.register(template)
end
event.register("modConfigReady", registerModConfig)

local function onInit()
	print("[POCKET: INFO] Initialized Pocket")
	
end

event.register("initialized", onInit)