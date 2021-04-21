local skillModule = require("OtherSkills.skillModule")


local lastRef
--Set to true if you want to chop trees in towns
local bypassIllegal = false

--How many swings required to collect wood. Randomised again after each harvest
local swingsNeeded
local swings = swings or 0
--How close the tree needs to be to activate
local lookDistance = 230

local function onAttack(e)
--[[
	Use an axe on a tree to chop firewood
	- Number of swings is based on the size of your swing
	- Number of wood collected is based on the size of swing and axe attack power
]]--


	--Return if attacker isn't player
	if not ( e.mobile.reference == tes3.getPlayerRef() ) then return end

	--Use RayTest to get object of whatever the player is looking at
    local result = tes3.rayTest{
        position = tes3.getCameraPosition(),
        direction = tes3.getCameraVector(),
    }
	--not looking at anything, return
	if not result or not result.reference then return end

	--get references
	local playerRef = tes3.getPlayerRef()
	local targetRef = result.reference
	--Get distance between player and object
	local distanceToTarget = playerRef.position:distance(result.intersection)
			
	--Get weapon details
	local weapon = tes3.getMobilePlayer().readiedWeapon
	if not weapon then return end
	local swingType = tes3.getMobilePlayer().actionData.attackDirection
	local chop = 2
	local axe1h = 7
	local axe2h = 8
	local swingStrength = tes3.getMobilePlayer().actionData.attackSwing
	
	--More chop damage == more wood collected. Maxes out at chopCeiling. Range 0.0-1.0
	local chopCeiling = 50
	local axeDamageMultiplier = ( 
			( ( weapon.object.chopMax < chopCeiling ) 
			and weapon.object.chopMax 
			or chopCeiling ) 
			/ ( chopCeiling ) )

	--If attacking the same target, accumulate swings
	if lastRef == targetRef then
		swings = swings + swingStrength * ( 1 + axeDamageMultiplier )
	else
		lastRef = targetRef
		swings = 0
	end
	
	--Check target IDs to see whether it counts as a tree
	local yepItsWood = false
	--Vanilla
	if string.find(string.lower(targetRef.id), "flora") then
		if string.find(string.lower(targetRef.id), "tree") then yepItsWood = true end
		if string.find(string.lower(targetRef.id), "root") then yepItsWood = true end	
		if string.find(string.lower(targetRef.id), "log") then yepItsWood = true end
		if string.find(string.lower(targetRef.id), "stump") then yepItsWood = true end
		if string.find(string.lower(targetRef.id), "parasol") then yepItsWood = true end
	end

	--Vurt trees
	if string.find(string.lower(targetRef.id), "vurt") then
		if string.find(string.lower(targetRef.id), "tree") then yepItsWood = true end
		if string.find(string.lower(targetRef.id), "unic") then yepItsWood = true end
		if string.find(string.lower(targetRef.id), "palm") then yepItsWood = true end
	end

	--Chopping with an axe
	if distanceToTarget < lookDistance and swingType == chop and ( weapon.object.type == axe1h or weapon.object.type == axe2h ) then
		--Target is a tree
		if yepItsWood then
			if tes3.getGlobal("a_sleep_illegal") == 0 or bypassIllegal == true then

				tes3.playSound({reference=playerRef, sound="chop"})
				--Weapon degradation, unequip if below 0
				weapon.variables.condition = weapon.variables.condition - (10 * swingStrength)
				if weapon.variables.condition <= 0 then
					weapon.variables.condition = 0
					tes3.mobilePlayer:unequip{ type = tes3.objectType.weapon }
					--mwscript.playSound({reference=playerRef, sound="Item Misc Down"})
					return
				end

				local function getSwingsNeeded()					
					--survival = 0, 0.75
					return ( math.random(4,6) )
				end
				
				if not swingsNeeded then
					swingsNeeded = getSwingsNeeded()
				end
				
				
				--wait until chopped enough times
				if swings >= swingsNeeded then 
					--wood collected based on strength of previous swings
					--Between 0.5 and 1.0 (at chop == 50)

					--if skills are implemented, use Survival Skill				
					local survivalSkill = skillModule.getSkill("Survival").value
					--cap at 100
					survivalSkill = ( survivalSkill < 100 ) and survivalSkill or 100
					--Between 0.5 and 1.0 (at 100 Survival)
					local survivalMultiplier = 1 + ( survivalSkill / 50 )
					local numWood =  math.floor( ( 1 + math.random() * 2 )  * survivalMultiplier )
					--Max 8
					numWood = ( numWood < 100 ) and numWood or 8
					--minimum 1 wood collected
					if numWood == 1 then
						tes3.messageBox("You have harvested 1 piece of firewood.")
					else
						tes3.messageBox("You have harvested %d pieces of firewood.", numWood)
					end
					tes3.playSound({reference=playerRef, sound="Item Misc Up"})
					mwscript.addItem{reference=playerRef, item="a_firewood", count=numWood}
					
					--incrase skill
					skillModule.incrementSkill("Survival", { progress=(swingsNeeded*2) } )
					--reset swings
					swings = 0
					swingsNeeded = getSwingsNeeded()
				end
			else
				tes3.messageBox("You must be in the wilderness to harvest firewood.")
			end
		else
			--tes3.messageBox(targetRef.id)
		end
	end
end

event.register("attack", onAttack )
