local storeGMST
local lastDamage = {}
	
local function onThrownDamage(e)
	-- Halves the damage recieved from thrown weapons, because in-game thrown weapons count as both projectile and firing weapon and their damage gets doubled
	if e.projectile and e.projectile.firingMobile.readiedWeapon and e.projectile.firingMobile.readiedWeapon.object.type == tes3.weaponType.marksmanThrown then
		--tes3.messageBox("Halving damage of %f.", e.damage)
		e.damage = e.damage / 2
		--tes3.messageBox("Halved damage: %f.", e.damage)
	end	
end

local function onDamaged(e)
    lastDamage.target = e.reference
    lastDamage.time = tes3.getSimulationTimestamp()
end

local function onProjectileHit(e)
	local projWeap = e.firingWeapon
	local proj = e.mobile.reference
	local target = e.target
	local attacker = e.firingReference
	
	-- Checking if the target recieved damage (if not, the attacker missed and the function is aborted)
    if (target ~= lastDamage.target or tes3.getSimulationTimestamp() ~= lastDamage.time) then
        return
    end
	
	if projWeap.id == proj.id then 
		-- Check if the attacker is using a thrown weapon, if so set the GMST chance for storing spent projectiles on target to 100.
		--tes3.findGMST("fProjectileThrownStoreChance").value = 100
		--tes3.messageBox("Setting store chance to 100.")
		
		-- Alternate implementation which simulates store event and sets the GMST to 0. This allows for the player to store NPC thrown weapons, unlike the vanilla game. 
		-- Also does not simulate vanilla behavior with enchanted projectiles as I didn't account for that :todd:
		tes3.findGMST("fProjectileThrownStoreChance").value = 0
		tes3.addItem({reference = target, item = projWeap.id, count = 1, playSound = false})	
		--tes3.messageBox("Setting store chance to 0 and simulating.")
	end	
	
end


local function initialized(e)
	-- On game initialization, check and store the default value for the store chance GMST (with delay so that other mods which change GMST on intialize e.g pete's lua gmst config take precedence).
	timer.start({
		iterations = 1,
		duration = 1,
		type = timer.real,
		callback = function()
			storeGMST = tes3.findGMST("fProjectileThrownStoreChance").value
		end
	})
end

local function resetGMST(e)
	-- Restores store chance GMST to default value taken at initialization
	tes3.findGMST("fProjectileThrownStoreChance").value = storeGMST
	--tes3.messageBox("Restoring original store chance.")
end

event.register("initialized", initialized)

event.register("load", resetGMST)
event.register("weaponUnreadied", resetGMST, {filter=tes3.getObject("player")})


event.register("projectileHitActor", onProjectileHit)
event.register("damage", onThrownDamage)
event.register("damaged", onDamaged)