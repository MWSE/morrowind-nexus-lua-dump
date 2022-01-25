local cf = mwse.loadConfig("Pincushion", {flag = false})

--[[
	Mod: Pincushion
	Author: Hrnchamd
    Version: 1.1
]]--

-- Version check
if (mwse.buildDate == nil or mwse.buildDate < 20190601) then
	mwse.log("[Pincushion] Build date of %s does not meet minimum build date of 20190601.", mwse.buildDate)
	return
end

local bit = require("bit")
local deque = require("hrnchamd.pincushion.deque")

local pinnedProjectileName = "__pinned__"
local pinnedFlag = 0x1000
local maxPinned = 50

local lastDamage = {}
local projectileDeque = deque.new()

-- Find nodes suitable for attaching. Non-culled and non-special flag nodes.
local function collectPinNodes(array, node)
    table.insert(array, node)

    -- Note: pairs and ipairs won't reach all the children if one of the children is nil.
    -- Should be fixed eventually.
    for i = 1, #node.children do
        local child = node.children[i]
        if (child and child.children) then
            if (not child.appCulled and bit.band(child.flags, pinnedFlag) == 0) then
                collectPinNodes(array, child)
            end
        end
    end
end

-- Find or create CollisionSwitch node for placing projectiles.
local function getProjectileContainer(node)
    local container
    
    -- Container is most likely to be near the end of the array.
    for i = #node.children, 1, -1 do
        local child = node.children[i]
        if (child and bit.band(child.flags, pinnedFlag) ~= 0) then
            container = child
            break
        end
    end
    
    if (not container) then
        container = niCollisionSwitch.new()
        container.flags = bit.bor(container.flags, pinnedFlag)
        container.collisionActive = false
        container.name = pinnedProjectileName
        node:attachChild(container)
    end
    
    return container
end

-- Remove animation controllers and particles.
local function clearVFX(node)
    node:removeAllControllers()

    if (node.children) then
        for i = 1, #node.children do
            local child = node.children[i]
            if (child) then
                -- isInstanceOf NiBSParticleNode
                if (child:isInstanceOfType(0x7DED3C)) then
                    child.appCulled = true
                end
                clearVFX(child)
            end
        end
    end
end

-- Find node closest to the penetration trajectory.
local function closestPenetration(node, pos, vel)
    local pinNodes = {}
    collectPinNodes(pinNodes, node)

    local closest = node
    local bestDist = 3e8
    local bestPos = pos
    
    -- Simulate projectile movement over 20ms.
    for i = 0, 4 do
        local p = pos + vel * (0.005 * i)
        for _, n in ipairs(pinNodes) do
            local dist = (p - n.worldTransform.translation):length()
            if (dist < bestDist) then
                closest = n
                bestDist = dist
                bestPos = p
            end
        end
    end
    
    return closest, bestPos
end

-- Remember new projectile and clear oldest if necessary.
local function enqueueProjectile(p)
    -- Limit amount of projectiles active.
    if (projectileDeque:length() >= maxPinned) then
        local old = projectileDeque:pop_left()
        -- Check if cell is still loaded before detaching projectile.
        if (old.parent) then
            old.parent:detachChild(old)
        end
    end
    -- Add to active list.
    projectileDeque:push_right(p)
end

-- Clear all projectiles.
local function clearProjectiles(p)
    while (not projectileDeque:is_empty()) do
        local old = projectileDeque:pop_left()
        -- Check if cell is still loaded before detaching projectile.
        if (old.parent) then
            old.parent:detachChild(old)
        end
    end
end

-- Clone projectile and set transform so that it appears to attach.
local function placeProjectile(projBaseObject, projTransform, embedNode, embedPos, displaceScale)
    -- Clone projectile model and remove visual effects like animations and particles.
    local clone = projBaseObject.sceneNode:clone()
    clearVFX(clone)

    -- Correct flights-forward pose of thrown weapon models.
    local localRotate = projTransform.rotation
    if (projBaseObject.type == tes3.weaponType.marksmanThrown) then
        local mReverse = tes3matrix33.new()
        mReverse:toRotationZ(math.pi)
        localRotate = localRotate * mReverse
    end
    
    -- Make transform relative to node, then reduce displacement to compensate for large collision radii.
    local invM = embedNode.worldTransform.rotation:invert()
    local invS = 1 / embedNode.worldTransform.scale
    local displacement = (embedPos - embedNode.worldTransform.translation) * invS
    clone.rotation = invM * localRotate
    clone.translation = invM * displacement * displaceScale
    clone.scale = invS

    enqueueProjectile(clone)
    getProjectileContainer(embedNode):attachChild(clone)
    embedNode:update()
    clone:updateProperties()
    clone:updateEffects()
end

-- Event handler for actors.
local function onHitActor(e)
    local projectile = e.mobile
    local projectileVisual = projectile.reference.sceneNode
    local projBaseObject = projectile.reference.object
    local target = e.target
    
    -- Check all models are loaded.
    if (not projectileVisual or not target.sceneNode) then
        return
    end

    -- Check if the projectile failed the hit roll.
    if (target ~= lastDamage.target or tes3.getSimulationTimestamp() ~= lastDamage.time) then
        return
    end
    
    --mwse.log("Pincushion: Hit actor " .. tostring(target))

    -- Prefer to limit search to skeleton nodes.
    local embedNode = target.sceneNode
    local bip = target.sceneNode:getObjectByName("Bip01")
    if (bip) then
        embedNode = bip
    end

    local embedPos
    embedNode, embedPos = closestPenetration(embedNode, e.collisionPoint, e.velocity)
    --mwse.log("Pincushion: Closest bone " .. (embedNode.name or "<>") .. "\n")
    placeProjectile(projBaseObject, projectileVisual.worldTransform, embedNode, embedPos, 0.5)
end

-- Event handler for non-actors.
local function onHitObject(e)
    local projectile = e.mobile
    local projectileVisual = projectile.reference.sceneNode
    local projBaseObject = projectile.reference.object
    local target = e.target
    
    if (not projectileVisual or not target.sceneNode) then
        return
    end
    
    --mwse.log("Pincushion: Hit object " .. tostring(target))

    local dt = tes3.worldController.deltaTime
    local embedNode = target.sceneNode
    local embedPos = e.collisionPoint + e.velocity * (0.65 * dt)
    
    -- Don't attach directly to statics, because the model instance may be re-used.
    if (target.object.objectType == tes3.objectType.static) then
        embedNode = target.cell.staticObjectsRoot
    end
    
    placeProjectile(projBaseObject, projectileVisual.worldTransform, embedNode, embedPos, 1.0)
end

-- Event handler for terrain.
local function onHitTerrain(e)
    local projectile = e.mobile
    local projectileVisual = projectile.reference.sceneNode
    local projBaseObject = projectile.reference.object

    if (not projectileVisual) then
        return
    end

    -- Find cell to place projectile into.
    local gridX = math.floor(e.position.x / 8192)
    local gridY = math.floor(e.position.y / 8192)
    local cell
    
    for _, c in ipairs(tes3.getActiveCells()) do
        if (c.gridX == gridX and c.gridY == gridY) then
            cell = c
            break
        end
    end
    
    --mwse.log("Pincushion: Hit cell " .. tostring(cell))

    if (not cell or not cell.staticObjectsRoot) then
        return
    end

    -- e.collisionPoint is inaccurate for terrain.
    local dt = tes3.worldController.deltaTime
    local embedNode = cell.staticObjectsRoot
    local embedPos = e.position + e.velocity * (0.4 * dt)
    placeProjectile(projBaseObject, projectileVisual.worldTransform, embedNode, embedPos, 1.0)
end

-- Reset all projectiles on load.
local function onLoaded(e)
    clearProjectiles()
end

-- Reset projectiles on resting.
local menuTimestamp
local function onMenuEnterExit(e)
    if (e.menuMode) then
        menuTimestamp = tes3.getSimulationTimestamp()
    else
        if (menuTimestamp ~= tes3.getSimulationTimestamp()) then
            clearProjectiles()
        end
    end
end

-- Save last successful damage event, to check if a collision was a hit or miss.
local function onDamaged(e)
    lastDamage.target = e.reference
    lastDamage.time = tes3.getSimulationTimestamp()
end

local function onInitialized(mod)
    event.register("loaded", onLoaded)
    event.register("projectileHitActor", onHitActor)
	if cf.flag then event.register("projectileHitObject", onHitObject)		event.register("projectileHitTerrain", onHitTerrain) end
    event.register("damaged", onDamaged)
    event.register("menuEnter", onMenuEnterExit)
    event.register("menuExit", onMenuEnterExit)
end
event.register("initialized", onInitialized)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Pincushion")	tpl:saveOnClose("Pincushion", cf)	tpl:register()	local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createYesNoButton{label = "Allow pseudo-arrows to get stuck in the ground and objects", variable = var{id = "flag", table = cf}, restartRequired = true}
end		event.register("modConfigReady", registerModConfig)
