local logging = require("JosephMcKean.archery.logging")
local log = logging.createLogger("headshot")

local config = require("JosephMcKean.archery.config")
local bnsData = require("JosephMcKean.archery.bipNodesData")
local supportedCreatures = bnsData.supportedCreatures
local defaults = bnsData.defaults

---@param bipNodesData table<string, archery.bipNodeData>
---@return string[]
local function getBipNodeNames(bipNodesData)
	local bipNodeNames = {}
	for bipNodeName, _ in pairs(bipNodesData) do table.bininsert(bipNodeNames, bipNodeName) end
	return bipNodeNames
end

---@class archery.calcDistPointToLine.params
---@field point tes3vector3
---@field lineInit tes3vector3 a point of the line
---@field lineDirection tes3vector3 the unit vector in the direction of the line

-- Calculate the distance from a point to a line,
--
-- which is represented in vector form: x = a + t * n,
--
-- where x gives the locus of the line, a is the `lineInit`, t is the scalar, n is `lineDirection`.
---@param e archery.calcDistPointToLine.params
---@return number distance
local function calcDistPointToLine(e)
	log:trace("calcDistPointToLine({ point = %s, lineInit = %s, lineDirection = %s })", e.point, e.lineInit, e.lineDirection)
	-- The distance of `point` to line x is denoted as `distance`
	local distance ---@type number
	-- `point - lineInit` is a vector from `point` to point `lineInit`
	--
	-- Then `(point - lineInit) * lineDirection` is the projected length onto the line
	local projectedLength = (e.point - e.lineInit):dot(e.lineDirection)
	-- So `lineInit + projectedLength * lineDirection` is a vector that is the projection of `point - lineInit` onto the line
	--
	-- and represents the point on the line closest to point
	local closestPoint = e.lineInit + e.lineDirection * projectedLength
	-- Thus, `point - closestPoint` is the component of `point - lineInit` perpendicular to the line
	local shortestVector = e.point - closestPoint
	distance = shortestVector:length()

	return distance
end

---Calculate which node is the clocest to the line the arrow is on
---@param e projectileHitActorEventData
---@param bipNodesData table<string, archery.bipNodeData>
---@return string closestBipNodeName 
---@return number closestDistance 
local function getClosestBipNode(e, bipNodesData)
	log:trace("getClosestBipNode()")
	local closestBipNodeName = ""
	local closestDistance = math.huge
	for _, bipNodeName in ipairs(getBipNodeNames(bipNodesData)) do
		local bipNode = e.target.sceneNode:getObjectByName(bipNodeName) ---@cast bipNode niNode
		if bipNode then
			local bipNodeData = bipNodesData[bipNodeName]
			local offset = bipNodeData.nodeOffset or tes3vector3.new()
			local distance = calcDistPointToLine({ point = bipNode.worldBoundOrigin + offset, lineInit = e.collisionPoint, lineDirection = e.mobile.velocity:normalized() })
			if distance < closestDistance then
				closestBipNodeName = bipNodeName
				closestDistance = distance
			end
		end
	end
	if closestBipNodeName ~= "" then log:debug("%s is the closest bipNode", closestBipNodeName) end
	return closestBipNodeName, closestDistance
end

-- Get the worldBoundRadius of bip node of reference
---@param ref tes3reference
---@param bipNodesData table<string, archery.bipNodeData>
---@param bipNodeName string
---@return number
local function getBipNodeRadius(ref, bipNodesData, bipNodeName)
	log:debug("getBipNodeRadius(%s, %s)", ref, bipNodeName)
	if not ref.data.bipNodesRadius then
		log:trace("bipNodesRadius data doesn't exist for reference %s, initializing new radius data", ref.id)
		ref.data.bipNodesRadius = {}
		for bnName, bipNodeData in pairs(bipNodesData) do
			if not bipNodeData.radius then
				local name = bipNodeData.radiusNode or bnName
				local bp = ref.sceneNode:getObjectByName(name)
				if bp then
					if bipNodeData.useChild then bp = bp.children[1] end
					log:trace("bp = %s", bp)
					log:trace("bp.worldBoundRadius = %s", bp and bp.worldBoundRadius)
					ref.data.bipNodesRadius[name] = bp and bp.worldBoundRadius
				end
			end
		end
	end
	bipNodeName = bipNodesData[bipNodeName] and bipNodesData[bipNodeName].radiusNode or bipNodeName
	return ref.data.bipNodesRadius[bipNodeName]
end

---Check if the distance from closest bip node to the arrow line is shorter than bip node radius.
---@param e projectileHitActorEventData
---@param bipNodesData table<string, archery.bipNodeData>
---@return boolean wasHit 
---@return string? closestBipNodeName
---@return string? message
local function ifHit(e, bipNodesData)
	log:debug("calculating if the projectile hit any bip node")
	local closestBipNodeName, closestDistance = getClosestBipNode(e, bipNodesData)
	if closestBipNodeName == "" then return false, nil, nil end
	local bipNodeData = bipNodesData[closestBipNodeName]
	local radius = bipNodeData.radius
	if not radius then
		radius = getBipNodeRadius(e.target, bipNodesData, closestBipNodeName)
		if not radius then return false, nil, nil end
		local radiusApproxi = bipNodeData.radiusApproxi or 0
		radius = radius + radiusApproxi
	end
	log:trace("closest distance to %s = %s", closestBipNodeName, closestDistance)
	log:trace("%s radius = %s", closestBipNodeName, radius)
	local wasHit = closestDistance <= radius
	return wasHit, closestBipNodeName, bipNodeData.message
end

---@param bipNodeName string
---@return boolean
local function showMessage(bipNodeName)
	if not config.showMessages then return false end
	if config.onlyHeadshotMessage and bipNodeName ~= "Head" then return false end
	return true
end

---@param actor tes3mobileActor
---@param bipNodesData table<string, archery.bipNodeData>
---@param bipNodeName string
---@return number
local function getDamageMulti(actor, bipNodesData, bipNodeName)
	log:trace("getDamageMulti(%s, %s)", actor.reference.id, bipNodeName)
	local multi = 0
	local bipNodeData = bipNodesData[bipNodeName]
	local damageMultiBase = bipNodeData.damageMultiBase or 1
	multi = damageMultiBase - 1
	local damageMultiFormula = bipNodeData.damageMultiFormula
	if damageMultiFormula then multi = damageMultiFormula(actor) end
	log:trace("damage multiplier = %s", multi)
	return multi
end

-- Apply additional damage
---@param e projectileHitActorEventData
---@param bipNodesData table<string, archery.bipNodeData>
---@param bipNodeName string
local function applyDamage(e, bipNodesData, bipNodeName)
	log:trace("applyDamage(e, %s)", bipNodeName)
	local actor = e.target.mobile ---@cast actor tes3mobileActor|any
	if actor.isDead then return end
	if not e.target.tempData.archeryDamage then return end
	local multi = getDamageMulti(actor, bipNodesData, bipNodeName)
	if multi > 0 then
		local damage = multi * e.target.tempData.archeryDamage ---@type number
		local playerAttack = e.firingReference == tes3.player
		timer.delayOneFrame(function()
			local results = actor:applyDamage({ damage = damage, applyDifficulty = true, playerAttack = playerAttack })
			log:trace("additional %s damage: %s", multi, results)
			log:trace("after damage apply, health: %s", e.target.mobile.health.current)
		end, timer.real)
	end
end

-- Apply additional effect
---@param e projectileHitActorEventData
---@param bipNodesData table<string, archery.bipNodeData>
---@param bipNodeName string
local function applyEffect(e, bipNodesData, bipNodeName)
	local actor = e.target.mobile ---@cast actor tes3mobileActor|any
	if actor.isDead then return end
	local bipNodeData = bipNodesData[bipNodeName]
	local additionalEffect = bipNodeData.additionalEffect
	if not additionalEffect then return end
	local additionalEffectChance = bipNodeData.additionalEffectChance
	local roll = math.random()
	log:trace("rolled %s, %sapply effect", roll, roll > additionalEffectChance and "skip " or "")
	if not additionalEffectChance or roll > additionalEffectChance then return end
	timer.delayOneFrame(function() additionalEffect(actor) end, timer.real)
end

---If target is hit in certain area, apply additional damage
---@param e projectileHitActorEventData
local function headshot(e)
	local firingReference = e.firingReference
	local targetRef = e.target
	if firingReference == targetRef then
		log:trace("projectileHitActor event firingReference and target are the same: %s", firingReference)
		return
	end
	log:debug("%s shot projectile hit target %s", firingReference, targetRef)
	local targetObj = e.target.baseObject
	local bipNodesData = supportedCreatures[targetObj.mesh:lower()] or defaults
	local wasHit, closestBipNodeName, message = ifHit(e, bipNodesData)
	if not config.enableLocationalDamage then return end
	if config.noPlayerHeadshot and (targetRef == tes3.player) then return end
	if wasHit and closestBipNodeName and message then
		log:debug(message)
		if firingReference == tes3.player and showMessage(closestBipNodeName) then tes3.messageBox(message) end
		applyDamage(e, bipNodesData, closestBipNodeName)
		applyEffect(e, bipNodesData, closestBipNodeName)
	end
end

return headshot
