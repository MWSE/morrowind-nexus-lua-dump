local logger = require("logging.logger")
local log = logger.getLogger("Autoloot")
local config = require("autoloot.config")

--[[
	Containers are not instances until opened. This function takes
	a container reference and returns the object after forcing it to become
	an instance
]]--
-- local function forceInstance(reference)
    -- local object = reference.object
    -- if (object.isInstance == false) then
		-- log:debug(tostring('forceInstance "%s"'):format(reference))
        -- object:clone(reference)
        -- reference.object.modified = true 
    -- end
    
    -- return reference.object
-- end

local function forceInstance(reference)
    local object = reference.object
    if (object.isInstance == false) then
		log:debug(tostring('forceInstance "%s"'):format(reference))
        object:clone(reference)
        reference.modified = true
        reference.object.modified = true 
        reference.cell.modified = true
    end
    
    return reference.object
end

local function checkDistance(fromRef, toRef)
	if config.checkDistance and fromRef then
		local distance = mwscript.getDistance({ reference = fromRef, target = toRef })
		distance = math.round(distance, 2)
		log:debug(tostring('checkDistance toRef.object.name "%s" fromRef.position "%s" toRef.position "%s" distance "%s" config.distance "%s"'):format(toRef.object.name, fromRef.position, toRef.position, distance, config.distance))
		return distance < config.distance
	else
		return true
	end
end

local function canLootCell(cell)
	local loot = true
	if config.cells.useWhitelist and table.find(config.cells.whitelist, cell.id) == nil then
		loot = false
	elseif config.cells.useBlacklist and table.find(config.cells.blacklist, cell.id) ~= nil then
		loot = false
	end
	log:debug(tostring('canLootCell cell.name "%s" cell.id "%s" loot "%s"'):format(cell.name, cell.id, loot))
	return loot
end

local function canLootItem(category, item, stack)
	local loot = true
	local itemId = item.id:lower()
	if category.useWhitelist and not category.whitelist[itemId] then
		loot = false
	elseif category.useBlacklist and category.whitelist[itemId] then
		loot = false
	end
	log:debug(tostring('canLootItem category.type "%s" item.name "%s" itemId "%s" loot "%s"'):format(category.type, item.name, itemId, loot))
	return loot
end

local function checkWeight(category, item, stack)
	if config.ignoreEncumberance then
		return true
	end
	local weight = math.round(stack.object.weight * stack.count, 2)
	if not config.ignoreEncumberance then
		local playerWeight = math.round(tes3.player.object.inventory:calculateWeight(), 2)
		local totalWeight = math.round(playerWeight + weight, 2)
		log:debug(tostring('checkWeight encumbrance.base "%s" playerWeight "%s" weight "%s" totalWeight "%s"'):format(tes3.mobilePlayer.encumbrance.base, playerWeight, weight, totalWeight))
		if tes3.mobilePlayer.encumbrance.base < totalWeight then
			return false
		end
	end
	if category.useWeigthValueRatio then
		local value = stack.object.value * stack.count
		local ratio = value / weight
		log:debug(tostring('checkWeight value "%s" weight "%s" ratio "%s" config.weigthValueRatio "%s"'):format(value, weight, ratio, config.weigthValueRatio))
		return ratio >= config.weigthValueRatio
	end
	return true
end

local function isDetected()
	local isDetected = false
	for ref in tes3.player.cell:iterateReferences(tes3.objectType.npc) do
		local npc = ref.mobile
		if not isDetected then
			-- local inLOS = tes3.testLineOfSight({reference1 = npc, reference2 = tes3.mobilePlayer})
			local inLOS = tes3.testLineOfSight({position1 = ref.position, position2 = tes3.mobilePlayer.position})
			log:trace(tostring('isDetected ref.object.name "%s" ref.position "%s" mobilePlayer.position "%s" inLOS "%s"'):format(ref.object.name, ref.position, tes3.mobilePlayer.position, inLOS))
			if inLOS then
				log:debug(tostring('isDetected ref "%s" isPlayerDetected "%s" isDetected "%s"'):format(ref.id, npc.isPlayerDetected, isDetected))
				isDetected = npc.isPlayerDetected or false
			end
		end
	end
	return isDetected
end

local function canSteal()
	local detected = false;
	if config.enableSteal then
		detected = isDetected()
		return table.pack(true, detected)
	end
	if config.enableHiddenSteal and tes3.mobilePlayer.isSneaking then
		detected = isDetected()
		return table.pack(not detected, detected)
	end
	return table.pack(false, detected)
end

-- Detect if the reference is a valid herbalism subject.
local function isHerb(ref)
    if ref and ref.object.organic then
        return (ref.object.script == nil)
    end
    return false
end

-- Detect if the reference is a valid mining subject.
local function isRock(ref)
	return string.lower(string.sub(ref.id, 1, 4)) == "rock"
end

local function iterItems(ref)
    local function iterator()
        for _, stack in pairs(ref.object.inventory) do
            ---@cast stack tes3itemStack
            local item = stack.object

            -- Account for restocking items,
            -- since their count is negative
            local count = math.abs(stack.count)

            -- first yield stacks with custom data
            if stack.variables then
                for _, data in pairs(stack.variables) do
                    if data then
                        coroutine.yield(item, data.count, data)
                        count = count - data.count
                    end
                end
            end
            -- then yield all the remaining copies
            if count > 0 then
                coroutine.yield(item, count)
            end
        end
    end
    return coroutine.wrap(iterator)
end

local function iterateLoot(iterator, fromRef)

	-- for item, count, itemData in iterItems(fromRef) do
		-- if itemData then
			-- debug.log(item)
			-- debug.log(count)
			-- debug.log(itemData)
			-- for k, data in pairs(itemData) do
				-- debug.log(data)
			-- end
		-- end
	-- end
	
	local isLocked = tes3.getLocked({ reference = fromRef })
	if isLocked and not config.ignoreLock then
		return
	end

	-- if isRock(fromRef) then
		-- mwse.log('[Autoloot] ROCK'..fromRef.object.name)
	-- end

	-- if isHerb(fromRef) then
		-- mwse.log('[Autoloot] HERB'..fromRef.object.name)
		-- tes3.player:activate(fromRef)
	-- end

	local hasAccess = tes3.hasOwnershipAccess({ reference = tes3.player, target = fromRef })
	local detected
	if not hasAccess then
		local stealValues = canSteal()
		local steal, detected = table.unpack(stealValues)
		if not steal then
			log:debug(tostring('stealing disabled fromRef "%s" hasAccess "%s" steal "%s" detected "%s"'):format(fromRef, hasAccess, steal, detected))
			return
		end
	end
	
	for stack in tes3.iterate(iterator) do
		local item = stack.object
		
		for k, category in pairs(config.categories) do
			if item.objectType == category.type and category.enabled then
				if canLootItem(category, item, stack) then
					if checkWeight(category, item, stack) then
						if config.lootNotification then
							tes3.messageBox('[Autoloot] "%s" (%s)', item.name, stack.count)
						end
						
						local value = stack.object.value * stack.count
						
						log:debug(tostring('iterateLoot loot fromRef.object.name "%s" item.name, "%s" item.objectType "%s" value "%s"'):format(fromRef.object.name, item.name, item.objectType, value))
						tes3.transferItem({ from = fromRef, to = tes3.player, item = item, count = stack.count })
						
						if not hasAccess then
							local owner = tes3.getOwner(fromRef)
							if owner and detected then
								log:debug(tostring('iterateLoot crime owner "%s" value "%s"'):format(owner, value))
								tes3.triggerCrime({type = tes3.crimeType.theft, victim = owner, value = value})
							end
							log:debug(tostring('iterateLoot theft owner "%s"'):format(owner))
							tes3.setItemIsStolen({ item = item, from = owner, stolen = true })
						end
					end
				end
			end
		end
	end
end

function run()
	log:trace('activated')

	if tes3ui.menuMode() then
		return
	end
	
	if not config.enableMod then
		return
	end

	if not tes3.mobilePlayer then
		return
	end

	local cell = tes3.mobilePlayer.cell
	if not canLootCell(cell) then
		return
	end
	
	local playerRef = tes3.getPlayerRef()
	
	if config.npcs.lootBodies then
		for ref in cell:iterateReferences(tes3.objectType.npc) do
			local npcRef = ref.mobile
			if npcRef and npcRef.isDead then
				if checkDistance(playerRef, npcRef) then
					if (config.npcs.useBlacklist and config.npcs.blacklist[npcRef.object.id:lower()] == nil) or
						(config.npcs.useWhitelist and config.npcs.whitelist[npcRef.object.id:lower()] ~= nil) then
						iterateLoot(npcRef.object.inventory.iterator, npcRef)
					end
				end
			end
		end
		
		for ref in cell:iterateReferences(tes3.objectType.creature) do
			local creatureRef = ref.mobile
			if creatureRef and creatureRef.isDead then
				if checkDistance(playerRef, creatureRef) then
					if (config.npcs.useBlacklist and config.npcs.blacklist[creatureRef.object.id:lower()] == nil) or
						(config.npcs.useWhitelist and config.npcs.whitelist[creatureRef.object.id:lower()] ~= nil) then
						iterateLoot(creatureRef.object.inventory.iterator, creatureRef)
					end
				end
			end
		end
	end
		
	if config.containers.lootContainers then
		for ref in cell:iterateReferences(tes3.objectType.container) do
			if checkDistance(playerRef, ref) then
				local container = forceInstance(ref)
				if (config.containers.useBlacklist and config.containers.blacklist[container.id:lower()] == nil) or
					(config.containers.useWhitelist and config.containers.whitelist[container.id:lower()] ~= nil) then
					iterateLoot(container.inventory.iterator, ref)
				end
			end
		end
	end
	
	log:trace('finished')
end

local this = {}
this.run = run

this.run()

return this