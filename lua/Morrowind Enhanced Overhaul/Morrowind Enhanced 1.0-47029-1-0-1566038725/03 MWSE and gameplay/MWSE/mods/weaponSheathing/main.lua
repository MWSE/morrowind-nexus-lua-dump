--[[
	Weapon Sheathing
	By Greatness7
--]]

local this = {}
local noop = function () end

local attachNodes = {
	[0] = "Bip01 ShortBladeOneHand",
	[1] = "Bip01 LongBladeOneHand",
	[2] = "Bip01 LongBladeTwoClose",
	[3] = "Bip01 BluntOneHand",
	[4] = "Bip01 BluntTwoClose",
	[5] = "Bip01 BluntTwoWide",
	[6] = "Bip01 SpearTwoWide",
	[7] = "Bip01 AxeOneHand",
	[8] = "Bip01 AxeTwoClose",
	[9] = "Bip01 MarksmanBow",
	[10] = "Bip01 MarksmanCrossbow",
	[11] = "Bip01 MarksmanThrown",
	[-1] = "Bip01 AttachWeapon",
	[-2] = "Bip01 AttachShield",
}


------------
-- CONFIG --
------------
if (mwse.buildDate == nil) or (mwse.buildDate < 20181006) then
	local function warning()
		tes3.messageBox(
			"[Weapon Sheathing] Your MWSE is out of date!"
			.. " You will need to update to a more recent version to use this mod."
		)
	end
	event.register("initialized", warning)
	event.register("loaded", warning)
	return
end

local config = require("weaponSheathing.mcm").config
mwse.log("[Weapon Sheathing] Initialized Version 1.4")
-- mwse.log(json.encode(config, {indent=true}))
------------


-------------
-- STARTUP --
-------------
local function getOverrides()

	-- get weapon/shield meshes
	local meshes = {}

	for obj in tes3.iterateObjects(tes3.objectType.weapon) do
		meshes[obj.mesh] = true
	end
	for obj in tes3.iterateObjects(tes3.objectType.armor) do
		if obj.slot == tes3.armorSlot.shield then
			meshes[obj.mesh] = true
		end
	end

	-- get valid override files
	local done = {}

	for mesh in pairs(meshes) do
		mesh = mesh:lower()

		if not mesh:find("%.nif$") then
			-- block invalid file types
			config.blocked[mesh] = true
		else
			if not done[mesh] then
				local override = mesh:sub(1, -5) .. "_sh.nif"
				if tes3.getFileExists("meshes\\" .. override) then
					done[mesh] = override
				end
			end
		end
	end

	this.override = done
end
event.register("initialized", getOverrides)


local function patchBipeds()

	-- get target meshes
	local meshes = {}

	for obj in tes3.iterateObjects(tes3.objectType.npc) do
		meshes[obj.mesh] = true
	end
	for obj in tes3.iterateObjects(tes3.objectType.creature) do
		if obj.biped and obj.usesEquipment then
			meshes[obj.mesh] = true
		end
	end

	-- load attach nodes
	local nodes = {}
	do
		local data = tes3.loadMesh("xbase_anim_sh.nif")
		if not data then
			mwse.log("[Weapon Sheathing] ERROR: failed to load 'xbase_anim_sh.nif'")
			return
		end
		for i, name in pairs(attachNodes) do
			nodes[i] = data:getObjectByName(name)
		end
	end

	-- update all bipeds
	local done = {}

	for mesh in pairs(meshes) do
		mesh = mesh:lower()

		if not done[mesh] and mesh:find("%.nif$") then
			local dir, name = mesh:match("(.-)([^\\]+)$")
			local xnif = dir .. "x".. name

			local data = (
				tes3.getFileExists("meshes\\" .. xnif) and tes3.loadMesh(xnif)
				or tes3.getFileExists("meshes\\" .. mesh) and tes3.loadMesh(mesh)
			)

			if data then
				-- merge in attach nodes
				for i, node in pairs(nodes) do
					local parent = data:getObjectByName(node.parent.name)
					if not parent then
						mwse.log("[Weapon Sheathing] ERROR: Failed to patch %s.", mesh)
						data = nil
						break
					end
					parent:attachChild(node:clone(), true)
				end
				done[mesh] = data
			end
		end
	end

	this.patched = done
end
event.register("initialized", patchBipeds)
-------------


-------------
-- UTILITY --
-------------
local function clearControllers(node)
	node:removeAllControllers()
	if node.children then
		for i = 1, #node.children do
			clearControllers(node.children[i])
		end
	end
end


local function validateAmmoType(weapon, ammo)
	return (weapon.type + 3) == ammo.type
end


local function validateObject(object)
	local file = object.sourceMod
	if file and config.blocked[file:lower()] then
		return false
	elseif config.blocked[object.id:lower()] then
		return false
	end
	return true
end


local function validateRef(ref)
	local object = ref.object
	if not this.patched[object.mesh:lower()] then
		return false
	elseif ref.disabled or not ref.sceneNode then
		return false
	end
	return validateObject(object.baseObject)
end
-------------


------------
-- UPDATE --
------------
local function updateQuiver(ref, mobile, quiver)
	-- mwse.log("updateQuiver(%s, %s)", ref, quiver)

	if not (config.showWeapon and config.showCustom) then
		return
	elseif quiver and not validateObject(quiver) then
		return
	end

	-- ensure a valid quiver is equipped
	local attachNode = ref.sceneNode:getObjectByName("Bip01 Ammo")
	if not attachNode then
		return
	end

	-- clear the previous quiver visuals
	for i = 1, #attachNode.children do
		attachNode.children[i]:detachChildAt(1)
	end

	-- don't pass unless quiver equipped
	if not quiver then
		return
	end

	-- don't pass unless valid ammo type
	if mobile.readiedWeapon then
		local weapon = mobile.readiedWeapon.object
		if not validateAmmoType(weapon, quiver) then
			return
		end
	end

	-- load the new ammunition's visuals
	local visual = tes3.loadMesh(quiver.mesh)
	if not visual then
		mwse.log("[Weapon Sheathing] ERROR: failed to load mesh %s.", quiver.mesh)
		return
	end

	-- clone and clear cached transforms
	visual = visual:clone()
	visual:clearTransforms()

	-- apply enchant effect when present
	if quiver.enchantment then
		tes3.worldController:applyEnchantEffect(visual, quiver.enchantment)
	end

	-- clone the visuals into ammo slots
	for i = 1, #attachNode.children do
		local slot = attachNode.children[i]
		slot:attachChild(visual:clone(), true)
	end
end


local function updateShield(ref, mobile, shield)
	-- mwse.log("updateShield(%s, %s)", ref, shield)

	if not config.showShield then
		return
	elseif shield and not validateObject(shield) then
		return
	end

	-- clear the previous shield visuals
	local attachNode = ref.sceneNode:getObjectByName("Bip01 AttachShield")
	attachNode:detachChildAt(1)

	-- temporary show normal shield bone
	local shieldBone = ref.sceneNode:getObjectByName("Shield Bone")
	shieldBone.appCulled = false

	-- ensure the shield should be shown
	if not shield or mobile.weaponDrawn then
		return
	end

	-- load the sheath or shield visuals
	local sheath = this.override[shield.mesh:lower()]
	local visual = tes3.loadMesh(sheath or shield.mesh)
	if not visual then
		mwse.log("[Weapon Sheathing] ERROR: failed to load mesh %s.", sheath or shield.mesh)
		return
	end

	-- clone and clear cached transforms
	visual = visual:clone()
	visual:clearTransforms()

	-- clone the visuals into attachNode
	attachNode:attachChild(visual, true)
	shieldBone.appCulled = true

	-- apply enchant effect when present
	if shield.enchantment then
		tes3.worldController:applyEnchantEffect(visual, shield.enchantment)
	end
end


local function updateWeapon(ref, mobile, weapon)
	-- mwse.log("updateWeapon(%s, %s)", ref, weapon)

	if not config.showWeapon then
		return
	elseif weapon and not validateObject(weapon) then
		return
	end

	-- clear the previous weapon visuals
	local attachNode = ref.sceneNode:getObjectByName("Bip01 AttachWeapon")
	attachNode:detachChildAt(1)

	-- don't pass unless weapon equipped
	if not (weapon and weapon.type) or (weapon.type == 11) then
		-- TODO support throwing weapons
		return
	end

	-- ensure the sheath should be shown
	local sheath = config.showCustom and this.override[weapon.mesh:lower()]
	if not sheath and mobile.weaponDrawn then
		return
	end

	-- get the weapon type's parent node
	local typeNode = ref.sceneNode:getObjectByName(attachNodes[weapon.type])

	-- load the sheath or weapon visuals
	local visual = tes3.loadMesh(sheath or weapon.mesh)
	if not visual then
		mwse.log("[Weapon Sheathing] ERROR: failed to load mesh %s.", sheath or weapon.mesh)
		return
	end

	-- clone and clear cached transforms
	visual = visual:clone()
	visual:clearTransforms()

	-- update AttachWeapon to new parent
	attachNode.parent:detachChild(attachNode)
	typeNode:attachChild(attachNode, true)

	-- clone the visuals into AttachWeapon
	attachNode:attachChild(visual, true)

	-- hide the weapon part if was drawn
	if sheath and mobile.weaponDrawn then
		attachNode:getObjectByName("Bip01 Weapon").appCulled = true
	end

	-- extra handling for ranged weapons
	if weapon.isRanged then
		clearControllers(attachNode)
		if mobile.readiedAmmo then
			local quiver = mobile.readiedAmmo.object
			if validateAmmoType(weapon, quiver) then
				updateQuiver(ref, mobile, quiver)
			end
		end
	end

	-- apply enchant effect when present
	if weapon.enchantment then
		tes3.worldController:applyEnchantEffect(visual, weapon.enchantment)
	end

	-- fix for the 'black texture' bugs?
	ref.sceneNode:updateNodeEffects()
end


local function getUpdater(item)
	if item.objectType == tes3.objectType.ammunition then
		return updateQuiver
	elseif item.objectType == tes3.objectType.weapon then
		return updateWeapon
	elseif item.objectType == tes3.objectType.armor then
		if item.slot == tes3.armorSlot.shield then
			return updateShield
		end
	end
	return noop
end
-------------


------------
-- EVENTS --
------------
local function updateVisuals(e)
	if not validateRef(e.reference) then return end

	local mobile = e.reference.mobile
	local weapon = mobile.readiedWeapon
	local shield = mobile.readiedShield

	if weapon then
		updateWeapon(e.reference, mobile, weapon.object)
	end
	if shield then
		updateShield(e.reference, mobile, shield.object)
	end
end
event.register("loaded", updateVisuals)
event.register("weaponReadied", updateVisuals)
event.register("weaponUnreadied", updateVisuals)
event.register("mobileActivated", updateVisuals)

event.register("equipped", function (e)
	if not validateRef(e.reference) then return end
	getUpdater(e.item)(e.reference, e.mobile, e.item)
end)

event.register("unequipped", function (e)
	if not validateRef(e.reference) then return end
	getUpdater(e.item)(e.reference, e.mobile, false)
end)
------------


return this
