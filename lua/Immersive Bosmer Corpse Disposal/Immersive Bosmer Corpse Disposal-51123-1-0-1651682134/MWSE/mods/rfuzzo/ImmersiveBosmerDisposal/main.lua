--[[
	Mod Immersive Bosmer Corpse Disposal
	Author: rfuzzo

	This mod changes the "dispose corpse" button to "eat corpse" if you are playing as a Bosmer and adds some buffs for eating

	TODO:
		- more green pact aspects
		- ashfall butcher interop
		- better ashfall interop
		- debuf when you do not eat a corpse
		- animations
]] --
local config = require("rfuzzo.ImmersiveBosmerDisposal.config")

--- local logger
--- @param msg string
--- @vararg any *Optional*. No description yet available.
local function mod_log(msg, ...)
	local str = "[ %s/%s ] " .. msg
	local arg = { ... }
	return mwse.log(str, config.author, config.id, unpack(arg))
end

--- Init mod
--- @param e initializedEventData
local function initializedCallback(e)
	mod_log("%s v%.1f Initialized", config.mod, config.version)
end

local function eat(e)
	-- block if in combat
	if tes3.mobilePlayer.inCombat then
		tes3.messageBox({ message = "You cannot eat the fallen while in combat" })
		return false
	end

	e.source:forwardEvent(e)

	-- play sound
	local newsound = tes3.getSound('Swallow')
	newsound:play()

	-- buff

	if (tes3.isLuaModActive("mer.ashfall")) then
		-- debuff if not hungry
		local ashfall = include("mer.ashfall.interop")
		if ashfall then

			-- placeholder until butchering is here
			-- local survival = ashfall.getSurvivalSkill()

			ashfall.setHunger(0)
			ashfall.setThirst(0)
			ashfall.setTiredness(0)

			tes3.messageBox({ message = "You have eaten the flesh of your felled enemy." })
		end
	else
		-- just buff in vanilla
		tes3.applyMagicSource {
			reference = tes3.player,
			name = "Devoured the Enemy",
			bypassResistances = true,
			effects = {
				{ id = tes3.effect.restoreHealth, duration = 20, min = 40, max = 80 },
				{ id = tes3.effect.fortifyHealth, duration = 180, min = 20, max = 60 },
				{ id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.strength, duration = 180, min = 20, max = 30 },
				{ id = tes3.effect.fortifyAttribute, attribute = tes3.attribute.willpower, duration = 180, min = 20, max = 30 },
			},
		}

		tes3.messageBox({ message = "You have eaten the flesh of your felled enemy." })
	end

	-- debuf when you do not eat a corpse

end

--[[
    event hooks
]]
event.register(tes3.event.initialized, initializedCallback)
--- @param e uiActivatedEventData
local function uiActivatedCallback(e)
	local element = e.element
	local ref = element:getPropertyObject("MenuContents_ObjectRefr")
	if (ref == nil) then
		return
	end

	-- enable only for bosmer players
	debug.log(ref.object.objectType)
	debug.log(tes3.player.object.race.id:lower())
	debug.log(tes3.player.object.class.name:lower())

	if ((tes3.player.object.race.id:lower() ~= "wood elf") and config.isBosmerOnly) then
		return
	end

	-- enable only for dead npcs
	if (ref.object.objectType ~= tes3.objectType.npc) then
		return
	end
	-- debug.log(ref.object.objectType)

	-- enable only for green pact bosmer
	if ((not string.find(tes3.player.object.class.name:lower(), "green pact")) and config.isGreenPactOnly) then
		return
	end

	-- rename button
	local removebutton = element:findChild('MenuContents_removebutton')
	if (removebutton ~= nil) then
		removebutton.text = "Eat Corpse"
		-- play eating sound
		removebutton:register('mouseClick', eat)
	end

end
event.register(tes3.event.uiActivated, uiActivatedCallback, { filter = "MenuContents" })

--
-- Handle mod config menu.
--
require("rfuzzo.ImmersiveBosmerDisposal.mcm")
