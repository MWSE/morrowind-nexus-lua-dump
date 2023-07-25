local logging = require("logging.logger")

local defaults = { logLevel = "INFO" }
local config = mwse.loadConfig("Adventurer's Backpack", defaults)
local log = logging.new({ name = "Adventurer's Backpack", logLevel = config.logLevel })

local backpacks = {
	["aa_backpack_a"] = true,
	["aa_backpack_AF"] = true,
	["aa_backpack_BN"] = true,
	["aa_backpack_dummy"] = true,
	["aa_backpack_FW"] = true,
	["aa_backpack_NoM"] = true,
	["aa_backpack_comp"] = true,
}
local backpackPath = {}

local backpackSlot = 11

local backpackOffset =
{ translation = tes3vector3.new(22.9866, 0.5588, -1.9998), rotation = tes3matrix33.new(0.2339, -0.0440, 0.9713, 0.0114, -0.9988, -0.0480, 0.9722, 0.0222, -0.2331), scale = 1 }

local function registerBackpacks()
	pcall(function() tes3.addArmorSlot({ slot = backpackSlot, name = "Backpack" }) end)
	for id, isBackpack in pairs(backpacks) do
		if isBackpack then
			local obj = tes3.getObject(id)
			-- remap slot to custom backpackSlot
			obj.slot = backpackSlot
			-- store the bodypart mesh for later
			backpackPath[id] = obj.parts[1].male.mesh
			-- clear bodypart so it doesn't overwrite left pauldron
			obj.parts[1].type = 255
			obj.parts[1].male = nil
			log:info("Registered backpack: %s (slot=%s)", obj, obj.slot)
		end
	end
end

---@param parent niNode
---@param fileName string
local function attachBackpack(parent, fileName)
	local node = tes3.loadMesh(fileName)
	if node then
		local clone = node:clone() ---@cast clone niNode
		-- rename the root node so we can easily find it for detaching
		clone.name = "Bip01 AttachBackpack"
		-- offset the node to emulate vanilla's left pauldron behavior
		clone.translation = backpackOffset.translation:copy()
		clone.rotation = backpackOffset.rotation:copy()
		clone.scale = backpackOffset.scale
		parent:attachChild(clone, true)
	end
end

---@param parent niNode
local function detachBackpack(parent)
	local node = parent:getObjectByName("Bip01 AttachBackpack")
	if node then parent:detachChild(node) end
end

---@param reference tes3reference
---@param item tes3item|tes3armor|any
local function onEquipped(reference, item)
	-- must be a valid backpack
	local isBackpack = backpacks[item.id]
	if not isBackpack then return end

	-- get parent for attaching
	local parent = reference.sceneNode:getObjectByName("Bip01 Spine1") ---@cast parent niNode

	-- detach old backpack mesh
	detachBackpack(parent)

	-- attach new backpack mesh
	attachBackpack(parent, backpackPath[item.id])

	-- update parent scene node
	parent:update()
	parent:updateEffects()
end

---@param e unequippedEventData
local function onUnequipped(e)
	-- must be a valid backpack
	local isBackpack = backpacks[e.item.id]
	if not isBackpack then return end

	-- get parent for detaching
	local parent = e.reference.sceneNode:getObjectByName("Bip01 Spine1") ---@cast parent niNode

	-- detach old backpack mesh
	detachBackpack(parent)

	-- update parent scene node
	parent:update()
	parent:updateEffects()
end

---@param e mobileActivatedEventData
local function onMobileActivated(e) if e.reference.object.equipment then for _, stack in pairs(e.reference.object.equipment) do onEquipped(e.reference, stack.object) end end end

local function onLoaded(e)
	onMobileActivated({ reference = tes3.player })
	for i, cell in ipairs(tes3.getActiveCells()) do for ref in cell:iterateReferences(tes3.objectType.npc) do onMobileActivated({ reference = ref }) end end
end

event.register("initialized", function()
	if tes3.isModActive("Adventurer's backback.ESP") then
		registerBackpacks()
		event.register("loaded", onLoaded)
		---@param e equippedEventData
		event.register("equipped", function(e) onEquipped(e.reference, e.item) end)
		event.register("unequipped", onUnequipped)
		event.register("mobileActivated", onMobileActivated)
		log:info("Initialized")
	else
		log:info("Mod Inactive")
	end
end)
