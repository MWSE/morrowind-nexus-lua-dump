--[[
	Plugin: mwse_PoisonCrafting.esp
--]]

local g7a = require("g7.a.common")

local this = {
	ignore = {},
	enable = true,
}

local player
local currentPoison
local alreadyPoisonList


-- ENEMY

this.classPoisonChance = {
	["alchemist"]          = 30,
	["alchemist service"]  = 30,
	["apothecary"]         = 30,
	["apothecary service"] = 30,
	["assassin"]           = 20,
	["assassin service"]   = 20,
	["bard"]               = 20,
	["scout"]              = 20,
	["nightblade"]         = 10,
	["nightblade service"] = 10,
	["rogue"]              = 10,
	["witch"]              = 10,
}


-- USAGE

local function readyPoison()
	-- retrieve previous poison
	if g7a.data.poison then
		mwscript.addItem{reference=player, item=g7a.data.poison}
	end

	-- store the current poison
	g7a.data.poison = currentPoison.id

	-- remove it from inventory
	mwscript.removeItem{reference=player, item=currentPoison.id}

	-- show poison readied text
	tes3.messageBox{message=currentPoison.name .. " readied for next attack."}

	-- display poison ready hud
	mge.enableHUD{hud="g7a_PoisonHUD"}
end


local function applyPoison(poison, target)
	-- inflict poison on target
	mwscript.equip{reference=target, item=poison}

	-- show poison applied text
	if g7a.config.msgPoisonApplied then
		tes3.messageBox{message="Your target has been poisoned!"}
	end
end


local function enemyPoison(source, target)
	-- poisoning chance based on npc class

	if alreadyPoisonList[source.id] then
		-- already used
		return
	end

	local class = source.object.class
	if not class then
		-- is a creature
		return
	end

	local chance = this.classPoisonChance[class.id:lower()]
	if not chance then
		-- invalid class
		return
	end

	if chance >= math.random(100) then
		local list = tes3.getObject("g7a_levelled_poison")
		-- bypass events
		this.enable = false
		g7a.equip{reference=target, item=list:pickFrom().id}
		this.enable = true
	end

	alreadyPoisonList[source.id] = true
end


local function clearPoison(force)

	if not g7a.data.poison then
		-- poison already cleared
		return
	end

	if not force then
		if tes3.getMobilePlayer().readiedWeapon then
			-- allow weapon swaps
			return
		elseif g7a.config.usePoisonRecovery then
			mwscript.addItem{reference=player, item=g7a.data.poison}
		else
			mwscript.playSound{reference=player, sound="Potion Fail"}
		end
	end

	-- clear the stored poison id
	g7a.data.poison = nil

	-- hiide the poison ready hud
	mge.disableHUD{hud="g7a_PoisonHUD"}
end


-- PROJS

local function appendProjectile(id, poison)
	local list = g7a.data.projectiles[id] or {}

	-- save poison projectile
	table.insert(list, poison)

	-- ensure list is updated
	g7a.data.projectiles[id] = list
end


local function removeProjectile(id)
	local list = g7a.data.projectiles[id] or {}

	-- uses oldest projectile
	return table.remove(list, 1)
end


-- MENUS

local function onButton(e)
	-- Apply poison to your next attack?
	-- 0. Yes
	-- 1. No
	if e.button == 0 then
		readyPoison()
	end
end


local function showMenu()
	--
	if not tes3.getMobilePlayer().readiedWeapon then
		tes3.messageBox{message="You must have a weapon equipped to use poisons."}
		return
	end

	if not g7a.config.msgReadyPoison then
		-- do not call on same frame as equip!
		timer.frame.delayOneFrame(readyPoison)
	else
		tes3.messageBox{
			message = 'Apply "' .. currentPoison.name .. '" to your next attack?',
			buttons = {"Yes", "No"},
			callback = onButton
		}
	end
end


-- EVENT

function this.onAttack(e)
	--
	local source = e.reference
	local target = e.targetReference
	local action = e.mobile.actionData
	local weapon = e.mobile.readiedWeapon
	local poison = g7a.data.poison

	-- all poisons require a weapon
	if not weapon then
		return
	end

	-- handle player poison attacks
	if (source == player) and poison then

		if weapon.object.type > 8 then
			appendProjectile(weapon.object.id, poison)
		elseif target and action.physicalDamage > 0 then
			applyPoison(poison, target)
		else -- ignore misses
			return
		end

		clearPoison(true)
		return
	end

	-- handle others poison attacks
	if (source ~= player) and target then

		if action.physicalDamage == 0 then
			-- ignore misses
		elseif weapon.object.type > 8 then
			-- ignore ranged
		else
			enemyPoison(source, target)
		end

		return
	end
end

--

function this.onProjectileHitActor(e)
	--
	local source = e.firingReference
	local weapon = e.firingWeapon
	local target = e.target

	if not (weapon and target) then
		return
	elseif (source == target) then
		return
	end

	if (source ~= player) then
		enemyPoison(source, target)
		return
	end

	local poison = removeProjectile(weapon.id)
	if poison then
		applyPoison(poison, target)
		return
	end
end


function this.onProjectileExpire(e)
	--
	local source = e.firingReference
	local weapon = e.firingWeapon

	if (source == player) and weapon then
		removeProjectile(weapon.id)
	end
end

--

function this.onEquip(e)
	--
	if (e.reference == player
		and e.item.objectType == tes3.objectType.alchemy
		and mwse.virtualKeyPressed(g7a.config.poisonHotkey)
		and this.ignore[e.item.id] == nil
		and this.enable == true)
	then
		currentPoison = e.item
		showMenu()

		return false
	end
end


function this.onUnequipped(e)
	--
	if (g7a.data.poison
		and e.reference == player
		and e.item.objectType == tes3.objectType.weapon
		and tes3.getMobilePlayer().readiedWeapon == nil)
	then
		timer.delayOneFrame(clearPoison)
	end
end

--

function this.onCombatStarted(e)
	-- NPCs are limited to poisoning once per combat session.
	-- When new combat sessions are started reset that limit.
	alreadyPoisonList[e.actor.reference.id] = nil
end


function this.onLoaded(e)
	-- update outer scoped vars
	player = tes3.getPlayerRef()

	-- clear npc posioners list
	alreadyPoisonList = {}

	-- fix interface visibility
	if player.data.g7a.poison then
		mge.enableHUD{hud="g7a_PoisonHUD"}
	else
		mge.disableHUD{hud="g7a_PoisonHUD"}
	end
end


function this.register()
	event.register("loaded", this.onLoaded)
	event.register("attack", this.onAttack)
	event.register("projectileHitActor", this.onProjectileHitActor)
	event.register("projectileExpire", this.onProjectileExpire)
	event.register("equip", this.onEquip)
	event.register("unequipped", this.onUnequipped)
	event.register("combatStarted", this.onCombatStarted)
end


return this
