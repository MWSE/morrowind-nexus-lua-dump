-----------------------------------
-- Ability Switch
-----------------------------------


local common = include("q.PredatorBeastRaces.common")

local fatigueDrainingAbility = {}
local abilities = {}
local returnScentAbility


local function decreasePCFatigue(amount)
	tes3.modStatistic({
		reference = tes3.mobilePlayer,
		name = "fatigue",
		current = -amount
	})
end

local function keyDown(e)
	if	e.isControlDown or
		e.isSuperDown or
		e.isAltDown or
		tes3.menuMode() then
		return
	end

	if tes3.mobilePlayer:isAffectedByObject(abilities[e.keyCode]) then

		common.removeSpell(abilities[e.keyCode])

		if fatigueDrainingAbility[e.keyCode] then
			fatigueDrainingAbility[e.keyCode]:cancel()
			fatigueDrainingAbility[e.keyCode] = nil
		end

	else
		if e.keyCode == common.settings.scentKey.keyCode and
		   common.playerHeadIsUnderwater() and
		   common.isKhajiit(tes3.player) then

			common.message("You can't use that power underwater.")
			return
		end

		local minFatigue = tes3.mobilePlayer.fatigue.base * ( common.settings.lowFatigue / 100 )
		local currentFatigue = tes3.mobilePlayer.fatigue.current

		if currentFatigue < minFatigue then

			common.message("Your fatigue is too low to use that ability.")
			return
		end

		common.addSpell(abilities[e.keyCode])

		fatigueDrainingAbility[e.keyCode] = timer.start{
			duration = 0.1,
			iterations = -1,
			callback = function ()
				local currentFatigue = tes3.mobilePlayer.fatigue.current
				if currentFatigue < minFatigue then

					common.removeSpell(abilities[e.keyCode])

					fatigueDrainingAbility[e.keyCode]:cancel()
					fatigueDrainingAbility[e.keyCode] = nil

					if e.keyCode == common.settings.scentKey.keyCode then

						common.message("Your fatigue is low, Scent ability is now stopped.")

					elseif e.keyCode == common.settings.visionKey.keyCode then

						common.message("Your fatigue is low, Vision ability is now stopped.")

					end

				elseif e.keyCode == common.settings.scentKey.keyCode then

					decreasePCFatigue(common.settings.scentFatigueCost / 10)

				elseif e.keyCode == common.settings.visionKey.keyCode then

					decreasePCFatigue(common.settings.visionFatigueCost / 10)
				end
			end
		}
	end
end

local function khajiitScentUnderwater()

	if common.playerHeadIsUnderwater() and
	   tes3.mobilePlayer:isAffectedByObject(abilities[common.settings.scentKey.keyCode]) then

		common.removeSpell(abilities[common.settings.scentKey.keyCode])

		fatigueDrainingAbility[common.settings.scentKey.keyCode]:pause()
		returnScentAbility = true

	elseif returnScentAbility and
		   not common.playerHeadIsUnderwater() then

		common.addSpell(abilities[common.settings.scentKey.keyCode])

		fatigueDrainingAbility[common.settings.scentKey.keyCode]:resume()
		returnScentAbility = false
    end
end

-----------------------------------


local function setup()

	event.unregister("keyDown", keyDown, { filter = common.settings.scentKey.keyCode })
	event.unregister("keyDown", keyDown, { filter = common.settings.visionKey.keyCode })
	event.unregister("calcMoveSpeed", khajiitScentUnderwater)

	if common.isArgonian(tes3.player) then

		common.removeSpell("q_Argonian_Scent_Start")

		abilities[common.settings.scentKey.keyCode] = tes3.getObject("q_Argonian_Scent")

		event.register("keyDown", keyDown, { filter = common.settings.scentKey.keyCode })

	elseif common.isKhajiit(tes3.player) then

		common.removeSpell("q_Khajiit_Scent_Start" )
		common.removeSpell("q_Khajiit_Vision_Start" )

		abilities[common.settings.visionKey.keyCode] = tes3.getObject("q_Khajiit_Vision")
		abilities[common.settings.scentKey.keyCode] = tes3.getObject("q_Khajiit_Scent")

		event.register("keyDown", keyDown, { filter = common.settings.scentKey.keyCode })
		event.register("keyDown", keyDown, { filter = common.settings.visionKey.keyCode })
		event.register("calcMoveSpeed", khajiitScentUnderwater)
	end
end

-----------------------------------
-- Enhanced Detection Interop
-----------------------------------

local enhancedDetection = include("OperatorJack.EnhancedDetection.effects")
local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

if (enhancedDetection == nil) then
	local function noEnhancedDetection()
		mwse.log(
   			"[PredatorBeastRaces]> Enhanced Detection is not installed. "..
   			"To enjoy all of this mod's features, you will need to install Enhanced Detection."
		)
	end

	event.register("initialized", noEnhancedDetection)
else
	if framework == nil then
		local function noFramework()
			mwse.log(
				"[PredatorBeastRaces]> Enhanced Detection is installed, but Magicka Expanded isn't. "..
   				"To enjoy all of this mod's features, you will need to install Magicka Expanded."
			)
		end

		event.register("initialized", noFramework)
	end

	local function updateSpells()
		framework.spells.createComplexSpell({
			id = "q_Khajiit_Scent",
			name = "Scent",
			magickaCost = 0,
			effects = {
				[1] = {
					id = tes3.effect.detectAnimal,
					range = tes3.effectRange.self,
					duration = 1,
					min = 200,
					max = 200
				},
				[2] = {
					id = tes3.effect.detectHumanoid,
					range = tes3.effectRange.self,
					duration = 1,
					min = 200,
					max = 200
				},
				[3] = {
					id = tes3.effect.detectDead,
					range = tes3.effectRange.self,
					duration = 1,
					min = 250,
					max = 250
				},
				[4] = {
					id = tes3.effect.detectUndead,
					range = tes3.effectRange.self,
					duration = 1,
					min = 250,
					max = 250
				},
			}
		})
		framework.spells.createComplexSpell({
			id = "q_Argonian_Scent",
			name = "Scent",
			magickaCost = 0,
			effects = {
				[1] = {
					id = tes3.effect.detectAnimal,
					range = tes3.effectRange.self,
					duration = 1,
					min = 150,
					max = 150
				},
				[2] = {
					id = tes3.effect.detectHumanoid,
					range = tes3.effectRange.self,
					duration = 1,
					min = 150,
					max = 150
				},
				[3] = {
					id = tes3.effect.detectDead,
					range = tes3.effectRange.self,
					duration = 1,
					min = 200,
					max = 200
				},
				[4] = {
					id = tes3.effect.detectUndead,
					range = tes3.effectRange.self,
					duration = 1,
					min = 200,
					max = 200
				},
			}
		})
		setup()
	end

	event.register("MagickaExpanded:Register", updateSpells, { priority = -10 })
end

-----------------------------------

event.register("PBR_chargenEnded", setup)
