-- Check MWSE Build.
if (mwse.buildDate == nil) or (mwse.buildDate < 20190821) then
    local function warning()
        tes3.messageBox(
            "[Astral Pocket ERROR] Your MWSE is out of date!"
            .. " You will need to update to a more recent version to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

-- Check Magicka Expanded framework.
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")
if (framework == nil) then
    local function warning()
        tes3.messageBox(
            "[Astral Pocket ERROR] Magicka Expanded framework is not installed!"
            .. " You will need to install it to use this mod."
        )
    end
    event.register("initialized", warning)
    event.register("loaded", warning)
    return
end

-- Dependencies
local common = require("OperatorJack.AstralPocket.common")

-- Register the Spell Effect ID.
tes3.claimSpellEffectId("teleportToAstralPocket", 265)

-- Effect Section --
local function updateAstralPocketTravelDestination(_position, _orientation, _cell)
	local _door = tes3.getReference(common.doorId)
	local params ={
		reference = _door,
		position = _position,
		orientation = _orientation,
		cell = _cell
	}

	tes3.setDestination(params)
end

local function onTeleportToAstralPocketTick(e)
    -- Trigger into the spell system.
    if (not e:trigger()) then
        return
    end

	local canTeleport = not tes3.worldController.flagTeleportingDisabled
    if canTeleport then
        local caster = e.sourceInstance.caster
		updateAstralPocketTravelDestination(caster.position, caster.orientation, caster.cell)

		local params={
			reference = caster,
			position = common.cell.position,
			orientation = common.cell.orientation,
			cell = common.cell.id
		}

		tes3.positionCell(params)
	else
		tes3.messageBox("You are not able to cast that spell here.")
	end
    
    e.effectInstance.state = tes3.spellState.retired
end

local function addTeleportToAstralPocketEffect()
	framework.effects.mysticism.createBasicEffect({
		-- Base information.
		id = tes3.effect.teleportToAstralPocket,
		name = "Teleport to Astral Pocket",
		description = "Teleports the caster to the Astral Pocket.",

		-- Basic dials.
		baseCost = 150,

		-- Various flags.
		appliesOnce = true,
		canCastSelf = true,
		hasNoDuration = true,
		hasNoMagnitude = true,
		nonRecastable = true,

		-- Graphics/sounds.
		icon = "RFD\\RFD_teleport.dds",
		lighting = { 0.99, 0.95, 0.67 },

		-- Required callbacks.
		onTick = onTeleportToAstralPocketTick,
	})
end

event.register("magicEffectsResolved", addTeleportToAstralPocketEffect)
-------------------

-- Spell Section --
local function registerSpells()
    framework.spells.createBasicSpell({
        id = common.spellIds.TeleportToAstralPocket,
        name = "Teleport to Astral Pocket",
        effect = tes3.effect.teleportToAstralPocket,
        range = tes3.effectRange.self
    })
end

event.register("MagickaExpanded:Register", registerSpells)
------------------

-- Book Section --
local function readAstrologicalElements(e)
    local player = tes3.getPlayerRef()
    if tes3.mobilePlayer.mysticism.current > 80 then
        local teleportToAstralPocketSpell = tes3.getObject( common.spellIds.TeleportToAstralPocket ) or "nothing"
        if (not tes3.player.object.spells:contains(teleportToAstralPocketSpell)) then
            tes3.updateJournal({id=common.journalIds.QuestOne, index=20})
            mwscript.addSpell({reference = player, spell = teleportToAstralPocketSpell})
        end
    else
        tes3.messageBox("You try to learn the spell to teleport to the Astral Pocket, but you find you are not skilled enough in the art of Mysticism.")
    end
end

local function readNelasNote(e)
    local questOneIndex = tes3.getJournalIndex({ id = common.journalIds.QuestOne}) or -1
    if questOneIndex < 30 then
        tes3.updateJournal({id = common.journalIds.QuestOne,index=30})
    end
end
---------------------------

-- Initilization Section --
local function initialized(e)
	if not tes3.isModActive("Astral Pocket.ESP") then
		print("[Astral Pocket: INFO] ESP not loaded")
		return
    end
    
    local AstrologicalElementsObject = tes3.getObject(common.bookIds.AstrologicalElements)
    local NelasNoteObject = tes3.getObject(common.bookIds.NelasNote)

    event.register("bookGetText", readAstrologicalElements, { filter = AstrologicalElementsObject } )
    event.register("bookGetText", readNelasNote, { filter = NelasNoteObject } )


	print("[Astral Pocket: INFO] Initialized Astral Pocket")
end
event.register("initialized", initialized)
----------------------------