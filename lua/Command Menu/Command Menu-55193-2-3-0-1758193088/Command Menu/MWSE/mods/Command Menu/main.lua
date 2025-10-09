local config = require("Command Menu.config")
local ui = require("Command Menu.ui")
local util = require("Command Menu.util")

local i18n = mwse.loadTranslations("Command Menu")
local log = mwse.Logger.new({
	name = "Command Menu",
	logLevel = config.logLevel
})

--- @type CommandMenu.objectsTable
local objects = {}

dofile("Command Menu.mcm")


event.register(tes3.event.initialized, function()
	objects = util.getObjects()
end)

event.register(tes3.event.loaded, function()
	ui.createMenu(objects)
end)

--- @param e keyDownEventData|mouseWheelEventData|mouseButtonDownEventData
local function openMenu(e)
	if not tes3.isKeyEqual({ actual = e, expected = config.openMenuKey }) then return end

	if ui.isMenuOpen() then
		ui.closeMenu()
		return
	end

	ui.openMenu()
end
event.register(tes3.event.keyDown, openMenu)
event.register(tes3.event.mouseWheel, openMenu)
event.register(tes3.event.mouseButtonDown, openMenu)


--- @param e keyDownEventData|mouseWheelEventData|mouseButtonDownEventData
local function sampleLandscape(e)
	if not tes3.isKeyEqual({ actual = e, expected = config.sampleLandscapeKey }) then return end
	local rayhit = tes3.rayTest({
		position = tes3.getPlayerEyePosition(),
		direction = tes3.getPlayerEyeVector(),
		root = tes3.game.worldLandscapeRoot
	})
	if not rayhit then return end
	local property = rayhit.object.texturingProperty
	if not property then return end
	local baseMap = property.maps[1]
	if not baseMap then return end
	tes3.messageBox(baseMap.texture.fileName)
end
event.register(tes3.event.keyDown, sampleLandscape)
event.register(tes3.event.mouseWheel, sampleLandscape)
event.register(tes3.event.mouseButtonDown, sampleLandscape)

-- Disable combat feature.
--- @param e combatStartEventData
event.register(tes3.event.combatStart, function(e)
	if config.combatEnabled then return end
	e.block = true
end)

-- Disable rest interruption feature.
--- @param e calcRestInterruptEventData
event.register(tes3.event.calcRestInterrupt, function(e)
	if config.restInterruptEnabled then return end
	e.block = true
end)

local unlockable = {
	[tes3.objectType.container] = true,
	[tes3.objectType.door] = true
}

-- Auto unlock feature.
--- @param e activateEventData
event.register(tes3.event.activate, function(e)
	if not config.unlockEnabled then return end
	local ref = e.target
	if not ref then return end
	local object = ref.object
	if not unlockable[object.objectType] then return end
	if ref.lockNode then
		tes3.playSound({ sound = "Open Lock" })
	end
	tes3.unlock({ reference = ref })
	tes3.setTrap({ reference = ref })
end)

-- Allow stealing feature.
--- @param e activateEventData
event.register(tes3.event.activate, function(e)
	if not config.stealingFree then return end
	if e.activator ~= tes3.player then return end
	local target = e.target
	if tes3.hasOwnershipAccess({ reference = tes3.player, target = target }) then return end
	tes3.setOwner({ reference = e.target, remove = true })
end)

-- 100 % hit chance.
--- @param e calcHitChanceEventData
event.register(tes3.event.calcHitChance, function(e)
	if not config.alwaysHit then return end
	e.hitChance = 100
end)

-- 100 % cast chance.
--- @param e spellCastEventData
event.register(tes3.event.spellCast, function(e)
	if not config.castingAlwaysSucceeds then return end
	e.castChance = 100
end)

-- 0 magicka cost spell casting.
--- @param e spellMagickaUseEventData
event.register(tes3.event.spellMagickaUse, function(e)
	if not config.spellsConsumeNoMagicka then return end
	e.cost = 0
end)

-- 0 charge enchantment casting.
--- @param e enchantChargeUseEventData
event.register(tes3.event.enchantChargeUse, function(e)
	if not config.enchantmentsConsumeNoCharge then return end
	e.charge = 0
end)

-- Creating potions always succeeds.
--- @param e potionBrewSkillCheckEventData
event.register(tes3.event.potionBrewSkillCheck, function(e)
	if not config.potionBrewingAlwaysSucceeds then return end
	-- The calculation was taken from the example in the docs.
	local player = tes3.mobilePlayer
	local x = player.alchemy.current + 0.1 * player.intelligence.current + 0.1 * player.luck.current
	local fPotionStrengthMult = tes3.findGMST(tes3.gmst.fPotionStrengthMult).value
	e.potionStrength = fPotionStrengthMult * e.mortar.quality * x
	e.success = true
end)

-- Reparing always succeeds.
--- @param e repairEventData
event.register(tes3.event.repair, function(e)
	if not config.repairingAlwaysSucceeds then return end
	e.chance = 100
end)

-- Probing and picking locks always succeeds. Picking locks isn't considered a crime.
--- @param e lockPickEventData|trapDisarmEventData
local function onLockPick(e)
	if config.lockPickNotCrime and
	not tes3.hasOwnershipAccess({ reference = tes3.player, target = e.reference }) then
		tes3.setOwner({ reference = e.reference, remove = true })
	end

	if not config.lockPickAlwaysSucceeds then return end
	e.chance = 100
end
event.register(tes3.event.lockPick, onLockPick)
event.register(tes3.event.trapDisarm, onLockPick)

-- Essential actors can't be damaged.
--- @param e damageEventData
event.register(tes3.event.damage, function(e)
	if not config.blockDamageForEssentialActors then return end
	if not e.reference.object.isEssential then return end
	e.damage = 0
end)

-- Player doesn't recieve Sun Damage as a vampire
--- @param e calcSunDamageScalarEventData
event.register(tes3.event.calcSunDamageScalar, function(e)
	if not config.blockSunDamage then return end
	e.damage = 0
end)

-- Fatigueless jumping.
--- @param e jumpEventData
event.register(tes3.event.jump, function(e)
	if not config.fatiguelessJumping then return end
	e.applyFatigueCost = false
end)
