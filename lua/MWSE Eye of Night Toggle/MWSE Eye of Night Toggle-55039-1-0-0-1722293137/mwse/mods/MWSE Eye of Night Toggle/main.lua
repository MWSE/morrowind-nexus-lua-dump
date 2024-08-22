-- MWSE Eye of Night Toggle

local config = require("MWSE Eye of Night Toggle.config")
-- pulls in stored config values, specifically we are using config.nightEyeLevel
-- which is the desired magnitude of the night eye effect added


local NightEyeOn
-- off/on switch to determine if Night Eye effect is currently active or not

local effectTable = {
	"eye of night effect 64",
	"eye of night effect 32",
	"eye of night effect 16",
	"eye of night effect 8",
	"eye of night effect 4",
	"eye of night effect 2",
	"eye of night effect 1"
}
-- 7 effect levels defined in our mod, each binary bit from 1 to 64.  This will
-- let us add bits together to make any desired magnitude from 1 to 100

local function determineIfOnOrOff()
	--[[
	this function will:
	1) get the player and list of active magic effects on the player
	2) set NightEyeOn to false to start
	3) Iterate through each magic effect, first checking if it is a Night Eye
		effect.  This is for speed of calculation.  I don't want to Iterate
		through another list for a player with many magic effects
	4) If the effect is Night Eye, then we iterate through effectTable
		checking to see if the effect is in effectTable.  If it is, set
		NightEyeOn to true, as we've found a mod effect.
	5) Return early if a mod Night Eye effect is found to save time
	]]--
	local player = tes3.mobilePlayer
	local effectList = player:getActiveMagicEffects()
	
	NightEyeOn = false
	for k,v in pairs(effectList) do
		if v.effectId == 43 then
			for j,b in pairs(effectTable) do
				if v.instance.magicID == b then
					NightEyeOn = true
					return
				end
			end
		end
	end
end

local function toBits(num, bits)
	--[[
	Pulled from https://stackoverflow.com/a/26702880
	Inputs a number to convert to binary and a desired number of bits to check
	Returns a table of bits oriented highest number to lowest
	So we'll set bits to 7 to represent 1, 2, 4, 8, 16, 32, and 64
	Enough to add to 100
	Then we'll add one nighteye power for each bit!
	]]--
    local t={}
    for b=bits,1,-1 do
        rest=math.fmod(num,2)
        t[b]=rest
        num=(num-rest)/2
    end
    if num==0 then return t else return {'Not enough bits to represent this number'}end
end

local function toggleSpellEffect(event)
	--[[
	Main function of the mod.
	When player casts "eye of night" power:
	1) First determine if night eye mod effects are present or not using
		determineIfOnOrOff which sets NightEyeOn flag.  If On, then turn Off.  
		If Off, turn On.
	2) To turn Off, just remove all mod effects.  Removing effects that aren't
		there doesn't hurt anything.
	3) To turn On, check the config.nightEyeLevel and convert it to a table of
		bits.  Iterate over the table and for each bit that is on, add that 
		level of effect.  Eg a magnitude of 20 = 16 + 4, so add
		"eye of night effect 16" and "eye of night effect 4" but not the others.
	4) The "eye of night" power itself has been edited to have a magnitude of 0,
		so it doesn't add any visual effect itself and edited to end in 1 second
	]]--
	if event.source.id == "eye of night" then
		determineIfOnOrOff()
		
		if NightEyeOn then
			tes3.removeSpell({ reference = tes3.player, spell = "eye of night effect 64"})
			tes3.removeSpell({ reference = tes3.player, spell = "eye of night effect 32"})
			tes3.removeSpell({ reference = tes3.player, spell = "eye of night effect 16"})
			tes3.removeSpell({ reference = tes3.player, spell = "eye of night effect 8"})
			tes3.removeSpell({ reference = tes3.player, spell = "eye of night effect 4"})
			tes3.removeSpell({ reference = tes3.player, spell = "eye of night effect 2"})
			tes3.removeSpell({ reference = tes3.player, spell = "eye of night effect 1"})
			NightEyeOn = false
		else
			local bitTable = toBits(config.nightEyeLevel,7)
			for k=7,1,-1 do
				if bitTable[k] == 1 then
					tes3.addSpell({ reference = tes3.player, spell = effectTable[k]})
				end
			end
			NightEyeOn = true
		end		
	end
end

local function initialized()
	--[[
	Sets the event listener for a spell cast once the game is initialized.
	]]--
	event.register("spellCasted", toggleSpellEffect)
end

event.register("initialized", initialized)
-- kicks the whole thing off once the game is initialized

event.register("modConfigReady", function()
	require("MWSE Eye of Night Toggle.mcm")
end)
-- connects to the MCM setting