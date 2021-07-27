-----------------------------------
-- Argonian Water Hunter Ability
-----------------------------------

local common = include("q.PredatorBeastRaces.common")

local chameleon
local nightEye

local function waterHunter(e)
	local mobile = e.mobile

	--- Early outs ---
	if mobile.objectType ~= tes3.objectType.mobileNPC and
	   mobile.objectType ~= tes3.objectType.mobilePlayer then
		return
	end

	if not common.isArgonian(e.reference) then return end

	local cell = e.reference.cell
	if ( cell.isInterior and not cell.hasWater ) then return end
	------------------


	local waterLevel = cell.waterLevel
	local minPosition = mobile.position.z
	local underwater = minPosition < waterLevel


	if underwater then
		common.addSpell(chameleon, mobile)

	elseif not underwater then
		common.removeSpell(chameleon, mobile)
	end

	if mobile == tes3.mobilePlayer then
		if common.playerHeadIsUnderwater() then
			common.addSpell(nightEye)

		elseif not common.playerHeadIsUnderwater() then
			common.removeSpell(nightEye)
		end
	end
end

-----------------------------------

event.register("initialized", function ()
	event.register("calcMoveSpeed", waterHunter)

	event.register("loaded", function ()
		-- Once the game has loaded, retrieve our spells
		chameleon = tes3.getObject("q_Argonian_Chameleon")
		nightEye  = tes3.getObject("q_Argonian_Vision")
	end)
end)
