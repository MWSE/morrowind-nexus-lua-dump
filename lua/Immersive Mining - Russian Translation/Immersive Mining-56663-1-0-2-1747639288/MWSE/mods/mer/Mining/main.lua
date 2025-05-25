--Persistent variables
local swings
swings = swings or 0
local swingsNeeded
local lastRef
local mobilePlayer
local playerRef
--CONFIGS
local minLookDistance = 230--How close the ore needs to be to activate
local maxHarvest = 4 --Max ore harvested in one go

--Rock values: index represents hardness (avg number of swings required to mine before weapon multiplier)
local rockValues = { 
	[2] = "glass",
	[3] = "ebony", 
	[4] = "diamond", 
	[5] = "adam",
}
local hardMax = 5--set to hardest material

--debug
local debugMode = false
local function debugMsg(message)
	if debugMode == true then
		tes3.messageBox(message)
	end
end


--[[
	Containers are not instances until opened. This function takes
	a container reference and returns the object after forcing it to become
	an instance
]]--
local function forceInstance(reference)
    local object = reference.object
    if (object.isInstance == false) then
        --tes3.messageBox("Cloning object!!!")
        object:clone(reference)
        reference.object.modified = true 
    end
    
    return reference.object
end


--[[
	Function to mine ore when striking a vein with a pickaxe
]]--
local function onAttack(e)
	--Return if attacker isn't player
	if e.mobile.reference ~= playerRef then return end

	--Use RayTest to get object of whatever the player is looking at
    local result = tes3.rayTest{
        position = tes3.getCameraPosition(),
        direction = tes3.getCameraVector(),
    }
	
	--Exit conditions
	if not ( result and result.reference) then
		return
	end
	local objectType = result.reference.object.objectType
	if objectType ~= tes3.objectType.container then 
		if debugMode == true then
			tes3.messageBox("objectType: " .. result.reference.object.objectType)
		end
		return 
	end
	

	--Pick strength
	
	local weaponStack = mobilePlayer.readiedWeapon	
	local weapon = weaponStack.object---@type tes3weapon
	local chopFloor = 10
	local chopCeiling = 50
	local pickStrength = weapon.chopMax
	pickStrength = pickStrength > chopFloor and pickStrength or chopFloor
	pickStrength = pickStrength < chopCeiling and pickStrength or chopCeiling
	pickStrength = ( pickStrength / chopCeiling / 2 ) + 1

	--Chopping at close distance with a pick?
	local distanceToTarget = playerRef.position:distance(result.intersection)
	local swingType = mobilePlayer.actionData.attackDirection	
	local chop = 2 --MW representation of chop swingType
	if distanceToTarget < minLookDistance and swingType == chop and string.find(string.lower(weapon.id), "pick") then
		--Containers with rock in the name (maybe needs to be more specific for mod compatability)
		local containerRef = result.reference
		if string.lower(string.sub(containerRef.id, 1, 4)) == "rock" then
		
			--Loop through container contents
			local container = forceInstance(containerRef)
			local inventory = container.inventory
			local contents = {}
			local oreCount = 0
			local totalOreValue = 0
			for stack in tes3.iterate(inventory.iterator) do
				local item = stack.object
				totalOreValue = totalOreValue + item.value*stack.count
				contents[item] = stack.count
				oreCount = oreCount + stack.count
			end
			
			--Empty?
			if oreCount == 0 then
				tes3.playSound({reference=playerRef, sound="SwishL"})
				tes3.messageBox("Эта жила уже выработана")
				return
			end
			
			--Get hardness of rock from id name
			local rockHardness
			local index = {}
			for hardness,rock in pairs(rockValues) do
				if string.find(string.lower(containerRef.id), rock) then
					rockHardness = hardness
				end
			end
			--not a known rock type
			if not rockHardness then return end
			
			--Exit conditions done, we're definitely hitting something!
			tes3.playSound({reference=playerRef, sound="Heavy Armor Hit"})

			--Calculate swings
			if lastRef ~= containerRef then
				swings = 0
				swingsNeeded = rockHardness * math.random(0.6, 1.4)
				lastRef = containerRef
			end
			local swingStrength = mobilePlayer.actionData.attackSwing	
			local playerStrength = ( mobilePlayer.strength.current / 100 ) 
			swings = swings + swingStrength * pickStrength * ( 0.5 + playerStrength / 2 )	
			
			--Pick degradation: Harder rock degrades pick faster
			local armorerModifier = ( mobilePlayer.armorer.current < 100 and mobilePlayer.armorer.current or 100 ) / 100
			local conditionDamage = ( (rockHardness/hardMax) * 10 ) 	-- Glass == 4, Adamantium = 10
									* ( 1 + ( playerStrength / 2 ) ) 	-- 0-100STR == x1-1.5 damage
									* ( 2 - ( armorerModifier / 2 ) )	-- 100-0 Armorer == x1-1.5 damage
									* swingStrength						-- 0.0-1.0 
			
			weaponStack.variables.condition = weaponStack.variables.condition - conditionDamage
			--Unequip if broken
			if weaponStack.variables.condition <= 0 then
				weaponStack.variables.condition = 0
				mobilePlayer:unequip({ item = weaponStack.object })
			end
			
			--Mine the ore after enough swings
			local owner = tes3.getOwner(containerRef)
			if swings >= swingsNeeded then 
			
				--Crime
				
				tes3.triggerCrime({
					type = 5, --theft
					victim = owner,
					value = totalOreValue
				})
				
				--Harvest ore
				local harvestCount = math.random(1, 3) * ( mobilePlayer.luck.current / 50 )
				harvestCount = harvestCount < maxHarvest and harvestCount or maxHarvest
				local itemName
				for item,count in pairs(contents) do
					if count > 0 then
						harvestCount = harvestCount < count and harvestCount or count
						mwscript.addItem({ reference=playerRef, item=item.id, count=harvestCount })
						mwscript.removeItem({ reference=containerRef, item=item.id, count=harvestCount })
						itemName = item.name
						break
					end
				end
				tes3.playSound({reference=playerRef, sound="Item Misc Up"})
				tes3.messageBox("Добыто: %.0f %s", harvestCount, itemName)
				swings = 0
			else
			--Slap on the wrist crime
				tes3.triggerCrime({
					type = 6, --tresspass 5g
					victim = owner,
				})
			end
		end
	end
end

--[[ 
	When activating ore vein normally, tells player to use a pick
	if they are using a pick gives a clue as to how much ore is left in the vein
]]--
local function onActivate(e)
	local target = e.target
	if not target then 
		debugMsg("no target")
		return 
	end
	
	local container = target.object
	if (container.objectType == tes3.objectType.container) then
		if string.lower(string.sub(target.id, 1, 4)) == "rock" then 
			container = forceInstance(target)
			local oreCount = 0
			local oreName
			local weaponID = mobilePlayer.readiedWeapon and mobilePlayer.readiedWeapon.object.id or ""
			local inventory = container.inventory
			--Loop through contents of ore vein
			for stack in tes3.iterate(inventory.iterator) do
				oreName = stack.object.name
				oreCount = oreCount + stack.count
			end
			if oreCount == 0 then 
				tes3.messageBox("Эта жила уже выработана")
			elseif string.find(string.lower(weaponID), "pick") then
				if oreCount < 3 then
					tes3.messageBox("Эта жила почти выработана")
				elseif oreCount < 5 then
					tes3.messageBox("Эта жила богата рудой")
				else
					tes3.messageBox("Эта жила весьма богата рудой")
				end
			else
				tes3.messageBox("Требуется кирка")
			end
			return false
		else
			debugMsg("not a rock container")
		end
	else	
		debugMsg("not a container")
	end
end


local function onLoaded(e)
	-- update outer scoped vars
	mobilePlayer = tes3.player.mobile
	playerRef = tes3.player
	swings = 0
end

local function initialized(e)
	--Register events
	event.register("loaded", onLoaded)
	event.register("attack", onAttack )
	event.register("activate", onActivate)
	
	print("Initialized Immersive Mining")
end

event.register("initialized", initialized)






