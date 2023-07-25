local logging = require("JosephMcKean.archery.logging")
local log = logging.createLogger("bipNodesData")

local config = require("JosephMcKean.archery.config")

---@class archery.bipNodeData
---@field damageMultiFormula fun(actor: tes3mobileActor)
---@field damageMultiBase number
---@field nodeOffset tes3vector3
---@field radiusApproxi number
---@field radius number
---@field radiusNode string
---@field useChild boolean
---@field message string
---@field additionalEffect fun(actor: tes3mobileActor)?
---@field additionalEffectChance number?

---Check if helmet is a closed helmet
---@param helmet tes3armor
---@return boolean
local function getIfHelmetClosed(helmet)
	for _, part in ipairs(helmet.parts) do if part.type == tes3.activeBodyPart.head then return true end end
	return false
end

---@param actor tes3mobileActor|any
---@return number multi
local function helmetProtection(actor)
	log:trace("helmetProtection(%s)", actor.reference.id)
	local rating = 0
	local helmetStack = tes3.getEquippedItem({ actor = actor, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet })
	if helmetStack then
		local helmet = helmetStack.object ---@cast helmet tes3armor
		local weightMax = 8
		local armorRatingMax = 45
		local isClosed = getIfHelmetClosed(helmet) and 1 or 0
		local weight = math.clamp(helmet.weight, 0, weightMax) / weightMax
		local weightClass = (helmet.weightClass + 1) / table.size(tes3.armorWeightClass)
		local armorRating = math.clamp(helmet.armorRating, 0, armorRatingMax) / armorRatingMax
		rating = isClosed + weight + weightClass + armorRating
		-- x-intercept at (2.195, 0)
		-- wearing anything better than a Chuzei Bonemold Helm
		-- which is a Closed Medium helmet with AR 17
		-- takes no additional headshot damage
		--
		-- Glass Helm, which is an Open Light helmet with AR 40
		-- has rating 1.41. Wearing it takes 3.41 times damage
		--
		-- y-intercept at (0, 18.685)
		-- not wearing helmet takes additional 18.685 times damage
	end
	return math.clamp(16.4 * math.exp(-0.8 * (rating - 0.4)) - 3.9, 0, math.huge) ---@type number
end

---@param actor tes3mobileActor|any
---@return number duration
local function greavesProtection(actor)
	log:trace("greavesProtection(%s)", actor.reference.id)
	local rating = 0
	local greavesStack = tes3.getEquippedItem({ actor = actor, objectType = tes3.objectType.armor, slot = tes3.armorSlot.greaves })
	if greavesStack then
		local greaves = greavesStack.object ---@cast greaves tes3armor
		local armorRatingMin = 40
		local armorRating = math.clamp(greaves.armorRating, 0, armorRatingMin) / armorRatingMin
		rating = armorRating
		-- x-intercept at (1, 0)
		-- wearing anything better than a Glass Greaves
		-- which is with AR 40
		-- takes no additional knee shot damage
		--
		-- y-intercept at (0, 5)
		-- not wearing greaves takes additional 5 times damage
	end
	return math.clamp(-0.5 * math.exp(1.3 * (rating + 1)) + 6.8, 0, math.huge) ---@type number
end

---@param actor tes3mobileActor|any
local function slowdown(actor)
	local duration = math.ceil(greavesProtection(actor) * 2)
	if duration == 0 then return end
	local speed = actor.speed.current
	tes3.modStatistic({ reference = actor, attribute = tes3.attribute.speed, current = -speed })
	log:trace("slowdown %s at %s to %s for %s seconds", actor.reference.id, speed, actor.speed.current, duration)
	timer.start({
		duration = 1,
		callback = function()
			tes3.modStatistic({ reference = actor, attribute = tes3.attribute.speed, current = speed / duration })
			log:trace("recover speed to %s", actor.speed.current)
		end,
		iterations = duration - 1,
	})
end

local bipNodesData = {}

---@type table<string, archery.bipNodeData>
bipNodesData.supportedCreatures = {
	["necrocraft\\skel.nif"] = { ["Tri upperteeth02"] = { damageMultiBase = 5, nodeOffset = tes3vector3.new(0, 0, 1), radiusApproxi = -1, message = config.headshotMessage } },
}

---@type table<string, archery.bipNodeData>
bipNodesData.defaults = {
	["Head"] = { damageMultiFormula = helmetProtection, nodeOffset = tes3vector3.new(0, 0, 1), radiusApproxi = 1, message = config.headshotMessage },
	["Neck"] = { damageMultiBase = 1.5, useChild = true, radiusApproxi = -2.8, message = "A shot in the neck!" },
	["Left Knee"] = {
		damageMultiFormula = greavesProtection,
		nodeOffset = tes3vector3.new(0, 0, 6),
		radius = 6,
		additionalEffectChance = 1,
		additionalEffect = slowdown,
		message = "An arrow to the knee!",
	},
	["Right Knee"] = {
		damageMultiFormula = greavesProtection,
		nodeOffset = tes3vector3.new(0, 0, 6),
		radius = 6,
		additionalEffectChance = 1,
		additionalEffect = slowdown,
		message = "An arrow to the knee!",
	},
}

return bipNodesData
