local config = require("Magicka Regen Suite.config")
local regenerationType = require("Magicka Regen Suite.regenerationType")


---@type table<MagickaRegenSuite.regenerationType, table>
local data = {
	[regenerationType.morrowind] = {
		[tes3.gmst.fRestMagicMult] = 0,
		-- The default is: "Affects your ability to resist magic, and your maximum Fatigue."
		[tes3.gmst.sWilDesc] = "Affects your ability to resist magic, your natural magicka regeneration, and your maximum Fatigue."
	},
	[regenerationType.oblivion] = {
		[tes3.gmst.fRestMagicMult] = 0,
		[tes3.gmst.sWilDesc] = "Affects your ability to resist magic, your natural magicka regeneration, and your maximum Fatigue."
	},
	[regenerationType.skyrim] = {
		[tes3.gmst.fRestMagicMult] = 0,
		-- The default is: "Determines your maximum amount of Magicka."
		[tes3.gmst.sIntDesc] = "Determines your maximum amount of Magicka and indirectly your natural magicka regeneration."
	},
	[regenerationType.logarithmicINT] = {
		[tes3.gmst.fRestMagicMult] = 0,
		[tes3.gmst.sIntDesc] = "Determines your maximum amount of Magicka and your natural magicka regeneration."
	},
}

-- An array of GMST ids this mod changes dynamically. These are the ones that appear in the table above.
local adjustedGMSTs = {
	tes3.gmst.fRestMagicMult, tes3.gmst.sWilDesc, tes3.gmst.sIntDesc
}
-- We save these on initialized
local defaultValues = {}

local function saveDefaults()
	for _, id in ipairs(adjustedGMSTs) do
		defaultValues[id] = tes3.findGMST(id).value
	end

	-- The following GMST is changed unconditionally.
	-- The default is: "Used to cast spells. Magicka is naturally restored by resting."
	tes3.findGMST(tes3.gmst.sMagDesc).value = "Used to cast spells. Magicka regenerates naturally and is restored by resting."
end

-- Needs to have higher priority than the function in main.lua that calls this.updateGMSTs
event.register(tes3.event.initialized, saveDefaults, { priority = 30 })


local function resetToDefaults()
	for _, id in ipairs(adjustedGMSTs) do
		tes3.findGMST(id).value = defaultValues[id]
	end
end


local this = {}

--- Makes adjustments to required GMSTs for this mod to function as intended.
--- Usually needs to be called on initialized and when the mod's settings change.
function this.updateGMSTs()
	resetToDefaults()
	local gmstAdjustments = data[config.regenerationFormula]
	for gmstId, value in pairs(gmstAdjustments) do
		tes3.findGMST(gmstId).value = value
	end
end

return this
