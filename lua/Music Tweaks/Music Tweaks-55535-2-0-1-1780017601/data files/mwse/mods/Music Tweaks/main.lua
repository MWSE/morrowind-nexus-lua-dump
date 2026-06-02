local config = require("Music Tweaks.config")
local constants = require("Music Tweaks.constants")
local log = require("Music Tweaks.log")
local MusicStateMachine = require("Music Tweaks.musicStateMachine")

local msm = MusicStateMachine:new()

-- ---------------------------- Helper Functions ---------------------------- --

--- @param cell tes3cell
local function isCellDungeon(cell)
	if not config.enableNoExploreInDungeons then
		return false
	end

	local isInHostileInterior = not cell.isOrBehavesAsExterior and not cell.restingIsIllegal

	local isInRedMountainBeforeMainQuestComplete =
	cell.isOrBehavesAsExterior and cell.region.name == "Red Mountain Region" and
	tes3.getJournalIndex({ id = "C3_DestroyDagoth" }) ~= 50

	if isInHostileInterior or isInRedMountainBeforeMainQuestComplete then
		return true
	end

	return false
end

-- ----------------------------- Event Callbacks ---------------------------- --

--- @param e cellChangedEventData
local function cellChangedCallback(e)
	log("cellChangedCallback called with %s", { state = msm.state, cell = e.cell.id })

	-- If player is in combat after a cell change, it means that the cell change wasn't entering/leaving a dungeon, nothing to do
	if tes3.mobilePlayer.inCombat then
		return
	end

	if msm.state == msm.STATE.COMBAT or msm.state == msm.STATE.OTHER then
		if isCellDungeon(e.cell) then
			log("Entering dungeon state because either the player has fleed from combat to a dungeon, or loaded into a dungeon")
			msm:stateDungeon()
		else
			log(
			"Entering pause state because either the player has fleed from combat from a dungeon, or loaded in outside of a dungeon")
			msm:statePause()
		end

	elseif msm.state == msm.STATE.DUNGEON and not isCellDungeon(e.cell) then
		if e.previousCell.id == "Imperial Prison Ship" then
			log("Entering intro state because player left the prison boat")
			msm:stateIntro()
		else
			log("Entering pause state because player left a dungeon")
			msm:statePause()
		end
	elseif (msm.state == msm.STATE.EXPLORE or msm.state == msm.STATE.PAUSE) and isCellDungeon(e.cell) then
		log("Entering dungeon state because player entered a dungeon")
		msm:stateDungeon()
	end
end

--- @param e combatStartEventData
local function combatStartCallback(e)
	if e.target.reference ~= tes3.player then
		return
	end

	log("combatStartCallback called with %s", { state = msm.state, enemy = e.actor.reference.id })

	if msm.state == msm.STATE.DUNGEON or msm.state == msm.STATE.EXPLORE or msm.state == msm.STATE.PAUSE then
		local enemy = e.actor.reference.object

		-- LuaFormatter off
		if
			not config.enableNoCombatForWeakEnemies or
			(enemy.level * 2 > tes3.player.object.level and
			(enemy.objectType ~= tes3.objectType.creature or enemy.level > 2))
		then
		-- LuaFormatter on
			log("Entering combat state because started combat against strong enemy")
			msm:stateCombat()
		end
	end
end

--- @param e combatStoppedEventData
local function combatStoppedCallback(e)
	log("combatStoppedCallback called with %s",
	    { state = msm.state, enemy = e.actor.reference.id, playerInCombat = tes3.mobilePlayer.inCombat })

	if msm.state == msm.STATE.COMBAT and not tes3.mobilePlayer.inCombat then
		if isCellDungeon(tes3.player.cell) then
			log("Entering dungeon state because combat ended while in a dungeon")
			msm:stateDungeon()
		else
			log("Entering pause state because combat ended while outside a dungeon")
			msm:statePause()
		end
	end
end

--- @param e musicChangeTrackEventData
local function musicChangeTrackCallback(e)
	log("musicChangeTrackCallback called with %s", { state = msm.state, context = e.context })

	-- We only want to intercept musicChangeTrackCallback calls when game is requesting combat or explore music
	-- Title, level up, dying music should still play as normal
	-- Lua means that we are the ones requesting to play a track, that should always go through
	-- There can also be lua and mwscript triggered music change requests made by other mods,
	-- but this is outside of this mod's scope
	if e.context ~= "combat" and e.context ~= "explore" then
		if e.context ~= "lua" and msm.state ~= msm.STATE.OTHER then
			msm:stateOther()
		end

		return
	end

	if msm.state == msm.STATE.COMBAT and e.context == "combat" then
		log("Letting the game play a combat track because we're in combat and the previous combat track ended")

		return
	elseif msm.state == msm.STATE.DUNGEON and e.context == "explore" then
		log(
		"Letting the game play an explore track but substituting it to silence because we're in a dungeon and the previous silence track ended")
		e.music = constants.SILENCE_FILEPATH

		return
	elseif msm.state == msm.STATE.EXPLORE or msm.state == msm.STATE.INTRO then
		local ac = tes3.worldController.audioController
		local didPreviousTrackEnd = math.abs(ac.musicDuration - ac.musicPosition) < 0.001

		if didPreviousTrackEnd then
			if config.enablePause then
				log("Entering pause state because explore track ended and a new one was requested")
				msm:statePause()
			else
				log(
				"Letting the game play an expore track because we're outside a dungeon, the previous explore track ended and pauses are disabled in config")

				return
			end
		end
	elseif msm.state == msm.STATE.OTHER then
		if msm.statePrevious == msm.STATE.COMBAT and e.context == "combat" then
			log("Entering combat state because other track ended, we were in combat before it, and still are")
			msm:stateCombat()
		elseif isCellDungeon(tes3.player.cell) then
			log("Entering dungeon state because other track ended and we were in a dungeon")
			msm:stateDungeon()
		else
			log("Entering pause state because other track ended and we were outside a dungeon")
			msm:statePause()
		end
	end

	return false
end

local function loadCallback()
	if msm.state ~= msm.STATE.OTHER then
		log("Entering other state because loading a game")
		msm:stateOther()
	end
end

local function initialized()
	event.register(tes3.event.cellChanged, cellChangedCallback)
	event.register(tes3.event.combatStart, combatStartCallback)
	event.register(tes3.event.combatStopped, combatStoppedCallback)
	event.register(tes3.event.musicChangeTrack, musicChangeTrackCallback)
	event.register(tes3.event.load, loadCallback)

	log:info("Music Tweaks initialized")
end

event.register(tes3.event.initialized, initialized)

dofile("Music Tweaks.mcm")
