local poison = ""
local poisonRemovalRequired = false

--misc things
local function isPoison(i)
	if (i == 7) or (i > 13 and i < 39) or (i > 43 and i < 59) then
		return true
	end
end

--poison things
local function applyPoison(e)
	mwscript.equip{reference = e, item = poison}
	mwscript.playSound{reference = e, sound="Potion Success"}
	poison = ""
end

local function flushPoison()
	mwscript.playSound{reference = "player", sound="Potion Fail"}
	poison = ""
end

--events
local function onEnterFrame()
	if poisonRemovalRequired then
		mwscript.removeItem{reference = "player", item = poison}
		poisonRemovalRequired = false
	end
end

local function onEquip(e)
	if e.reference == tes3.getPlayerRef() and e.item.objectType == tes3.objectType.alchemy and isPoison(e.item.effects[1].id) then
		if tes3.getMobilePlayer().readiedWeapon then
			poison = e.item.id
			poisonRemovalRequired = true
			mwscript.playSound{reference = "player", sound ="Potion Success"}
		else
			mwscript.playSound{reference = "player", sound ="Item Alchemy Down"}
		end
		return false
	end
end

local function onUneqiup(e)
	if e.reference == tes3.getPlayerRef() and e.item.objectType == tes3.objectType.weapon and (poison ~= "") then
		flushPoison()
	end
end

local function onAttack(e)
	if (e.reference == tes3.getPlayerRef()) and (poison ~= "") then
		if e.mobile.readiedWeapon.object.type > 8 then
			return
		end
		if e.targetReference and (e.mobile.actionData.physicalDamage > 0) and e.targetMobile then
			applyPoison(e.targetReference)
		else
			flushPoison()
		end
	end
end

local function onProjectileHit(e)
	if (e.firingReference == tes3.getPlayerRef()) and (poison ~= "") then
			flushPoison()
	end
end

local function onDamage(e)
    if e.attackerReference ~= tes3.player then
        return
    end
    if (e.projectile ~= nil) and (e.magicSourceInstance == nil) and (poison ~="") then
		applyPoison(e.reference)
    end
end

--register
event.register("enterFrame", onEnterFrame)
event.register("equip", onEquip)
event.register("unequipped", onUneqiup)
event.register("attack", onAttack)
event.register("projectileHitObject", onProjectileHit)
event.register("projectileHitTerrain", onProjectileHit)
event.register("projectileExpire", onProjectileHit)
event.register("damage", onDamage)
