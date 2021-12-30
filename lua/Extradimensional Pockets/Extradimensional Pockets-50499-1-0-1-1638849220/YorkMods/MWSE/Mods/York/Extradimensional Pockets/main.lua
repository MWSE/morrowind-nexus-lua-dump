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
local spellIds = {
	extradimensionalPockets = "ExtradimensionalPockets"
}
local distributions = {
	["Malven Romori"] = {
        spellIds.extradimensionalPockets
    },
	["Minnibi Selkin-Adda"] = {
        spellIds.extradimensionalPockets
    },
	["Salver Lleran"] = {
        spellIds.extradimensionalPockets
    },
	["Lalatia Varian"] = {
        spellIds.extradimensionalPockets
    },
	["Ervona Barys"] = {
        spellIds.extradimensionalPockets
    },
	["Felen Maryon"] = {
        spellIds.extradimensionalPockets
    },
	["Uvele Berendas"] = {
        spellIds.extradimensionalPockets
    }
}
--[[
	["Name Here"] = {
        spellIds.extradimensionalPockets
    },
	
]]



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
		id = spellIds.extradimensionalPockets,
		name = "Extradimensional Pockets",
		effect = tes3.effect.pocket,
		range = tes3.effectRange.self,
		duration = 50
	})
	for npcId, distributionSpellIds in pairs(distributions) do
        local npc = tes3.getObject(npcId)
        if (npc) then
            if (type(distributionSpellIds) ~= "table") then
                local spell = tes3.getObject(distributionSpellIds)
                if (spell) then
                    npc.spells:add(spell)
                end
            else
                for _, spellId in pairs(distributionSpellIds) do
                    local spell = tes3.getObject(spellId)
                    if (spell) then
                        npc.spells:add(spell)
                    end
                end
            end
        end
    end
end

event.register("MagickaExpanded:Register", registerSpells)


local function onInit()
	print("[POCKET: INFO] Initialized Pocket")
end

event.register("initialized", onInit)