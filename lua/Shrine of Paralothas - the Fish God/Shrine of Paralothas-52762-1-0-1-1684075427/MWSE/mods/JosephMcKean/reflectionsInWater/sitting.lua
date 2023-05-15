local this = {}

local skillsModule = include("OtherSkills.skillModule")

local prayTimer
local previousAnimationMesh

---@param statue tes3reference
local function movePlayer(statue)
	local position = tes3vector3.new(statue.position.x, statue.position.y, statue.position.z + -7)
	local orientation = { statue.orientation.x, statue.orientation.y, statue.orientation.z + math.pi }
	if tes3.player.cell ~= statue.cell then
		tes3.positionCell { reference = tes3.player, position = position, orientation = orientation, cell = statue.cell, teleportCompanions = false }
	else
		tes3.player.position = position
		tes3.player.orientation = orientation
	end
end

---@param state boolean
local function disableControls(state)
	tes3.mobilePlayer.jumpingDisabled = state
	tes3.mobilePlayer.attackDisabled = state
	tes3.mobilePlayer.magicDisabled = state
	tes3.mobilePlayer.mouseLookDisabled = state
end

local function onTabUp() timer.delayOneFrame(function() tes3.setVanityMode({ enabled = true }) end) end

local function onTabDown() timer.delayOneFrame(function() tes3.setVanityMode({ enabled = false }) end) end

local function stopAnimation()
	tes3.playAnimation({ reference = tes3.player, mesh = previousAnimationMesh, group = tes3.animationGroup.idle })
	tes3.player.facing = tes3.player.facing + math.pi
	previousAnimationMesh = nil
end

local function blockSave() return false end

-- handle keypress to cancel animation
---@param e keyDownEventData
local function checkKeyPress(e)
	if tes3ui.menuMode() then return end
	if e.keyCode == 183 then return end -- allow screenshots

	-- If this is tab being pressed down 
	-- only for non-location, moving messing up camera
	local togglePovKey = tes3.getInputBinding(tes3.keybind.togglePOV).code

	if e.keyCode == togglePovKey then
		onTabDown()
		return
	end
	this.cancel()
end

function this.cancel()
	tes3.runLegacyScript({ command = 'DisablePlayerLooking' });
	stopAnimation()
	prayTimer:cancel()

	disableControls(false)
	tes3.runLegacyScript { command = "EnableInventoryMenu" }

	tes3.setVanityMode({ enabled = false })

	event.unregister("save", blockSave)
	event.unregister("keyDown", checkKeyPress)
	event.unregister("keyUp", onTabUp, { filter = tes3.getInputBinding(tes3.keybind.togglePOV).code })

	tes3.player.data.reflectionsInWater.praying = false
	tes3.runLegacyScript({ command = 'EnablePlayerLooking' })
	tes3.player.data.reflectionsInWater.secondSpentPraying = 0
end

local function completePilgrimage()
	tes3.player.data.reflectionsInWater.pilgrimageComplete = true
	local message = "You received the Grace of Sanctuary. Underwater creatures now will not harm you."
	local questIndex = tes3.getJournalIndex({ id = "jsmk_rw" })
	local healFish = questIndex >= 1 and questIndex < 100
	if healFish then
		tes3.player.data.reflectionsInWater.fishHealed = true
		tes3.messageBox({ message = "The stranded fish is revived.", buttons = { "OK" } })
		local position = tes3vector3.new(tes3.player.position.x - 64, tes3.player.position.y + 64, tes3.player.position.z)
		local orientation = { tes3.player.orientation.x, tes3.player.orientation.y, tes3.player.orientation.z + math.pi }
		tes3.createReference({ object = "jsmk_rw_cr_peacefish", position = position, orientation = orientation, cell = tes3.player.cell })
		tes3.updateJournal({ id = "jsmk_rw", index = 100, showMessage = true })
	end
	if skillsModule then
		local skill = skillsModule.getSkill("fishing")
		if skill then
			for _ = 1, 10 do skill:progressSkill(100) end
			message = message .. "\nYou gained knowledge of the nature of fish. Your fishing skill has improved."
		end
	end
	tes3.messageBox({ message = message, buttons = { "OK" } })
end

---@param statue tes3reference
local function sitDown(statue)
	tes3.player.data.reflectionsInWater.praying = true
	previousAnimationMesh = tes3.player.object.mesh
	tes3.playAnimation({ reference = tes3.player, mesh = "jsmk\\rw\\VA_sitting.nif", group = tes3.animationGroup.idle4 })
	movePlayer(statue)
	tes3.player.data.reflectionsInWater.secondSpentPraying = 0
	prayTimer = timer.start({
		duration = 1,
		type = timer.simulate,
		iterations = -1,
		callback = function()
			tes3.player.data.reflectionsInWater.secondSpentPraying = tes3.player.data.reflectionsInWater.secondSpentPraying + 1
			if tes3.player.data.reflectionsInWater.pilgrimageComplete then return end
			if tes3.player.data.reflectionsInWater.secondSpentPraying >= 60 then completePilgrimage() end
		end,
	})
	tes3.setVanityMode({ enabled = true })
	disableControls(true)
	event.register("save", blockSave)
	event.register("keyUp", onTabUp, { filter = tes3.getInputBinding(tes3.keybind.togglePOV).code })
	event.register("keyDown", checkKeyPress)
end

---@param e activateEventData
local function meditate(e)
	if not (e.activator == tes3.player) then return end
	if e.target.id ~= "jsmk_rw_ex_slaughterfish" then return end
	local questIndex = tes3.getJournalIndex({ id = "jsmk_rw" })
	local healFish = questIndex >= 1 and questIndex < 100
	local message = healFish and "Would you like to pray for the stranded fish's health at the Shrine of Paralothas?" or
	                "Would you like to meditate at the Shrine of Paralothas?"
	tes3.messageBox({ message = message, buttons = { "Yes", "No" }, callback = function(data) if data.button == 0 then sitDown(e.target) end end })
end
event.register("activate", meditate)
