local types = require('openmw.types')
local NPC = require('openmw.types').NPC
local core = require('openmw.core')
local storage = require('openmw.storage')
local playerSection = storage.playerSection('SettingsPlayerHUDMarkers')
local I = require("openmw.interfaces")
local self = require("openmw.self")
local nearby = require('openmw.nearby')
local camera = require('openmw.camera')
local util = require('openmw.util')
local ui = require('openmw.ui')
local auxUi = require('openmw_aux.ui')
local aux_util = require('openmw_aux.util')
local async = require('openmw.async')
local vfs = require('openmw.vfs')
local KEY = require('openmw.input').KEY
local input = require('openmw.input')
local time = require('openmw_aux.time')
local v2 = util.vector2
local v3 = util.vector3
local boxCache = {}
local frame = 0
local animation = require('openmw.animation')
local lastCameraRotation = camera.viewportToWorldVector(v2(0.5,0.5))
NAME = nil
HP = nil
HP_MAXHP = nil
BUFFS = nil
local helpers = require("scripts.HUDMarkers.helpers")
hdTexPath, vfx, unpackV3, nextValue, tableFind, readFont = unpack(helpers)
local TYPE_UNDEAD = types.Creature.TYPE.Undead
local interfaceMarkers = {}
require("scripts.HUDMarkers.settings")

RT_MAX_DISTANCE = 300*21


	ICON_SET = playerSection:get("ICON_SET")
	if playerSection:get("HEART_ICON") == "Alternative 2" and vfs.fileExists("HUDM_Textures/"..ICON_SET.."/heart3.dds") then
		HEART_ICON = "HUDM_Textures/"..ICON_SET.."/heart3.dds"
	elseif playerSection:get("HEART_ICON") == "Alternative" and vfs.fileExists("HUDM_Textures/"..ICON_SET.."/heart2.dds") then
		HEART_ICON = "HUDM_Textures/"..ICON_SET.."/heart2.dds"	
	else
		HEART_ICON = "HUDM_Textures/"..ICON_SET.."/heart.dds"	
	end
	HEART_DEAD_ICON = "HUDM_Textures/"..ICON_SET.."/heart_dead.dds"	
	ITEM_PURPLE_ICON = "HUDM_Textures/"..ICON_SET.."/item_purple.dds"
	ITEM_ICON = "HUDM_Textures/"..ICON_SET.."/item.dds"
	MECHANICAL_ICON = "HUDM_Textures/"..ICON_SET.."/mechanical.dds"
	MECHANICAL_BROKEN_ICON = "HUDM_Textures/"..ICON_SET.."/mechanical_broken.dds"
	UNDEAD_ICON = "HUDM_Textures/"..ICON_SET.."/undead.dds"
	UNDEAD_DEAD_ICON = "HUDM_Textures/"..ICON_SET.."/undead_dead.dds"
	KEY_ICON = "HUDM_Textures/"..ICON_SET.."/key.dds"
	DOOR_ICON = "HUDM_Textures/"..ICON_SET.."/door.dds"
	DOOR_VISITED_ICON = "HUDM_Textures/"..ICON_SET.."/door_visited.dds"
	HERB_ICON = "HUDM_Textures/"..ICON_SET.."/herb.dds"
	CONTAINER_ICON = "HUDM_Textures/"..ICON_SET.."/container.dds"
	INDEX_ICON = "HUDM_Textures/"..ICON_SET.."/propylon_index.dds"
	ORE_ICON = "HUDM_Textures/"..ICON_SET.."/ore.dds"
	
	SHOW_UNENCHANTED_ITEMS = playerSection:get("SHOW_UNENCHANTED_ITEMS2")
	SHOW_KEYS = playerSection:get("SHOW_KEYS")

local database = require("scripts.HUDMarkers.database")
local customHeights, computedBoxes, customScales, modelBlacklist, checkedModels, customOffsets, tempMining  = unpack(database)
miningNodes ={}
for item, nodes in pairs(tempMining) do
	for _, node in pairs(nodes) do
		miningNodes[node] = item
	end
end



local organicContainers = {
	barrel_01_ahnassi_drink=true,
	barrel_01_ahnassi_food =true,
	com_chest_02_fg_supply =true,
	com_chest_02_mg_supply =true,
	flora_treestump_unique =true,
}
local blacklistDetectActors = {}

--local inProgress = {}
barCache = {}
local AI_DB = {}
--raytracing
local raytracing = {}
local nextRay = nil
local raysPerTick = 1
-- Textures
local background = ui.texture { path = 'black' }
local buffCache = {}
local iconCache = {}
local nextBuffUpdate = nil
local activeBars = {}
local cellCache = nil
detectKeyCache = 999999999
detectActorCache = 999999999
detectItemCache = 999999999
detectKey = 0
detectActor = 0
detectItem = 0
detectHerb = 0
detectIngredient = 0
detectHerbCache = 999999999
detectIngredientCache = 999999999
detectHerbBonus = 0
detectIngredientBonus = 0
detectHerbBonuses = {}
detectIngredientBonuses = {}
oreMult = 1

local periodicRefresh = 0
local itemCache = nil
local textureCache = {}
function getTexture(path)
	if not textureCache[path] then
		textureCache[path] = ui.texture{path = path}
	end
	return textureCache[path]
end

local function tableLength(t)
	local i=0
	for _ in pairs(t) do
		i=i+1
	end
	return i
end

local function idToNumber(str)
    if str:byte(1) == 64 then -- '@'
        return tonumber(str:sub(2), 16)  -- "@0x240" -> "0x240"
    else
        return tonumber(str, 16)
    end
end

local function colorTableToHex(c)
	if not c then 
		return ""
	end
	return c[1].."/"..c[2].."/"..c[3]
end

local function colorTableToColor(c)
	if not c then 
		return nil
	end
	return util.color.rgba(c[1],c[2],c[3],c[4] or 1)
end

local resolveRefresh = false
local detectChanged = false
local blacklistLength= 0

local refreshCycle = 0

function getBoundingBoxPoint(halfSizes, center, rotation, lerp)
    -- Define the two extreme local space points
    -- Lowest back: center of back face, bottom
    local lowestBackLocal = util.vector3(0, -halfSizes.y/2, -halfSizes.z)
    -- Highest front: center of front face, top  
    local highestFrontLocal = util.vector3(0, halfSizes.y/2, halfSizes.z)
    
    -- Transform to world space using OpenMW's efficient transform
    local lowestBackWorld = rotation:apply(lowestBackLocal) + center
    local highestFrontWorld = rotation:apply(highestFrontLocal) + center
    
    -- Manual linear interpolation
    return lowestBackWorld + (highestFrontWorld - lowestBackWorld) * lerp
end

local function isKey(record)
    if record.isKey then
        return true
    end
    if record.id:find("key") or record.icon:find("key") or record.model:find("key") or record.name:lower():find("key") then
        return true
    end
    return false 
end

local function filterUnenchanted(item, record)
	if SHOW_UNENCHANTED_ITEMS == "none" then
		return false
	elseif SHOW_UNENCHANTED_ITEMS == "all" then
		return true
	else -- filter clutter
		if not types.Miscellaneous.objectIsInstance(item) then
			return true
		elseif isKey(record) then
			return true
		elseif record.id:sub(1,5) == "gold_" then
			if record.id == "gold_001" and item.count == 1 then
				return false
			else
				return true
			end
		else
			return false
		end
	end
end
	


local function updateMarkers(overwriteCycle)
	if detectKey == 0 and detectActor == 0 and detectItem == 0 and detectHerb == 0 and detectIngredient == 0 then
	
		interfaceMarkers.actorHUDMarkers = {}
		interfaceMarkers.containerHUDMarkers = {}
		interfaceMarkers.itemHUDMarkers = {}
		interfaceMarkers.doorHUDMarkers = {}
		return 
	end
	local ORE_COLORS = playerSection:get("ORE_COLORS")
	local cameraPos = camera.getPosition()
	refreshCycle = refreshCycle + 1
	local SHOW_DOORS = playerSection:get("SHOW_DOORS")
	local DETECT_ACTOR_TARGETS = playerSection:get("DETECT_ACTOR_TARGETS")
	local DETECT_ACTOR_FILTER = nil
	if DETECT_ACTOR_TARGETS == "only humanoids" then
		DETECT_ACTOR_FILTER = {[types.Creature.TYPE.Humanoid] = true}
	elseif DETECT_ACTOR_TARGETS == "only creatures" then
		DETECT_ACTOR_FILTER = {[types.Creature.TYPE.Creatures] = true}
	elseif DETECT_ACTOR_TARGETS == "also daedra" then
		DETECT_ACTOR_FILTER = {[types.Creature.TYPE.Creatures] = true, [types.Creature.TYPE.Daedra] = true}
	elseif DETECT_ACTOR_TARGETS == "also humanoids" then
		DETECT_ACTOR_FILTER = {[types.Creature.TYPE.Creatures] = true, [types.Creature.TYPE.Daedra] = true, [types.Creature.TYPE.Humanoid] = true}
	elseif DETECT_ACTOR_TARGETS == "also undead" then
		DETECT_ACTOR_FILTER = {[types.Creature.TYPE.Creatures] = true, [types.Creature.TYPE.Daedra] = true, [types.Creature.TYPE.Humanoid] = true, [TYPE_UNDEAD] = true}
	end -- else "even mechanical"
	
	local needResolve = {}
	-- ACTORS
	if (overwriteCycle or refreshCycle)%4 == 1 or detectChanged then
		interfaceMarkers.actorHUDMarkers = {}
		local HUDMarkers = interfaceMarkers.actorHUDMarkers
		local maxDetectActor = math.max(playerSection:get("DETECT_ACTOR_LOOT") and math.max(SHOW_KEYS and detectKey or 0, detectItem, detectIngredient) or 0, detectActor, detectIngredientBonus)
		if maxDetectActor>0 then
			for _, actor in pairs(nearby.actors) do
				if actor.id~= self.id and (actor.position - cameraPos):length() < (maxDetectActor) * 22+500 then
					local validTarget = true
					local actorRecord = actor.type.records[actor.recordId]
					local isMechanical = actorRecord.soulValue == 0
					local isCreature = types.Creature.objectIsInstance(actor)
					if DETECT_ACTOR_FILTER then
						local type = 999
						if isCreature then
							type = actorRecord.type
						else
							type = types.Creature.TYPE.Humanoid
						end
						validTarget = DETECT_ACTOR_FILTER[type] and not isMechanical
					end
					if validTarget or playerSection:get("DETECT_ACTOR_LOOT") or detectIngredientBonus then
						local hasKey = false
						local hasItem = 0
						local hasIngredient = false
						local hasIndex = false
						if detectItem>0 or SHOW_KEYS and detectKey>0 or detectIngredient>0 then
							if not types.Actor.inventory(actor):isResolved() then
								--print("resolve", actor)
								table.insert(needResolve, actor)
							else
								for _,item in pairs(types.Actor.inventory(actor):getAll()) do
									local itemRecord = item.type.records[item.recordId]
									local isMisc = types.Miscellaneous.objectIsInstance(item)
									if isMisc and (item.recordId:sub(1,6) == "index_" or item.recordId:sub(1,10) == "t_de_index") then
										hasIndex = true
									elseif isMisc and detectKey>0 and SHOW_KEYS and isKey(itemRecord) then
										hasKey = true
									elseif types.Ingredient.objectIsInstance(item) and detectIngredient > 0 then
										hasIngredient = itemRecord.icon
									elseif detectItem>0 then
										if itemRecord.enchant then
											hasItem = 2
										elseif filterUnenchanted(item,itemRecord) then
											hasItem = math.max(hasItem,1)
										end
									end
								end
							end
						end
						if not blacklistDetectActors[actor.id] and validTarget and detectActor>0 then
							local isUndead = actorRecord.type == types.Creature.TYPE.Undead
							table.insert(HUDMarkers,  {object = actor, icon = isMechanical and MECHANICAL_ICON or isUndead and UNDEAD_ICON or HEART_ICON, scale = isUndead and 1.5 or isMechanical and 1.33 or nil, offsetMult = 0.7777777, range = detectActor, deadIcon = isMechanical and MECHANICAL_BROKEN_ICON or isUndead and UNDEAD_DEAD_ICON or HEART_DEAD_ICON, bonusSize = 4 })
						end
						if hasKey then
							table.insert(HUDMarkers,  {object = actor, icon = KEY_ICON, range = math.min(maxDetectActor,detectKey), scale = 0.8, offsetMult = 0.63, screenOffset = hasItem >0 and v2(-5,5) or v2(0,10), bonusSize = 10})
						end
						if hasIndex then
							table.insert(HUDMarkers,  {object = actor, icon = INDEX_ICON, range = math.min(maxDetectActor,math.max(detectKey, detectItem)), offsetMult =  0.63, screenOffset = hasKey and v2(5,10) or v2(0,5), scale = 0.25, bonusSize = 23})
						elseif hasItem >1 then
							table.insert(HUDMarkers,  {object = actor, icon = ITEM_PURPLE_ICON, range = math.min(maxDetectActor,detectItem), offsetMult =  0.63, screenOffset = hasKey and v2(5,10) or v2(0,5), bonusSize = 10})
						elseif hasIngredient then
							table.insert(HUDMarkers,  {object = actor, icon = hasIngredient, range = math.min(maxDetectActor,detectIngredient), offsetMult = 0.63, screenOffset = hasKey and v2(5,5) or v2(0,5), bonusSize = 7})
						elseif hasItem >0 then
							table.insert(HUDMarkers,  {object = actor, icon = ITEM_ICON, range = math.min(maxDetectActor,detectItem), offsetMult = 0.63, screenOffset = hasKey and v2(5,5) or v2(0,5)})
						end
					end
				end
			end
		end
	end
	-- DOORS
	if refreshCycle%4 == 2 or detectKeyCache ~= detectKey then
		interfaceMarkers.doorHUDMarkers = {}
		local HUDMarkers = interfaceMarkers.doorHUDMarkers
		if SHOW_DOORS and detectKey>0 then
			for _, door in pairs(nearby.doors) do
				if (door.position - cameraPos):length() < (detectKey) * 22+500 then
					local destCell = types.Door.destCell(door)
					if destCell and savegameData.visitedCells[types.Door.destCell(door).id or 1] then
						table.insert(HUDMarkers, {object = door, icon = DOOR_VISITED_ICON, range = detectKey, opacity = 0.7, scale = 3, bonusSize = 3})
					elseif destCell then
						table.insert(HUDMarkers, {object = door, icon = DOOR_ICON, range = detectKey, opacity = 0.65, scale = 3, bonusSize = 3})
					end
				end
			end
		end
	end
	
	local detectItemOrKeyChanged = detectKeyCache ~= detectKey or detectItemCache ~= detectItem
	
	-- CONTAINERS
	if refreshCycle%4 == 3 or detectItemOrKeyChanged then
		interfaceMarkers.containerHUDMarkers = {}
		local herbRange = math.max(playerSection:get("SHOW_HERBS") and detectItem or 0, detectHerb)
		local HUDMarkers = interfaceMarkers.containerHUDMarkers
		if detectItem>0 or SHOW_KEYS and detectKey>0 or herbRange > 0 then
			for _, cont in pairs(nearby.containers) do
				if (cont.position - cameraPos):length() < math.max(detectItem,detectKey, herbRange*oreMult) * 22+500 and types.Container.objectIsInstance(cont) then
					if not types.Container.inventory(cont):isResolved() then
						--print(cont.recordId, (cont.position - cameraPos):length())
						if types.Container.record(cont).isOrganic and not organicContainers[cont.recordId] then
							if miningNodes[cont.recordId] then
								table.insert(HUDMarkers, {object = cont, icon = ORE_COLORS and "HUDM_Textures/"..ICON_SET.."/"..miningNodes[cont.recordId]..".dds" or ORE_ICON, range = math.max(detectItem,detectIngredient*oreMult), bonusSize = 7, boundingBoxCenter = true})
							elseif herbRange > 0 then
								--local i=0
								--for _,item in pairs(types.Container.inventory(cont):getAll()) do
								--	i=i+1
								--end
								table.insert(HUDMarkers, {object = cont, icon = HERB_ICON, range = herbRange, boundingBoxCenter = true})
							end
						--
						else
							--print("resolve", cont)
							table.insert(needResolve, cont)
						end
					else
						local hasKey = false
						local hasItem = 0
						local hasIngredient = false
						local hasIndex = false
						for _,item in pairs(types.Container.inventory(cont):getAll()) do
							local itemRecord = item.type.records[item.recordId]
							local isMisc = types.Miscellaneous.objectIsInstance(item)
							if isMisc and (item.recordId:sub(1,6) == "index_" or item.recordId:sub(1,10) == "t_de_index") then
								hasIndex = true
							elseif isMisc and detectKey>0 and SHOW_KEYS and isKey(itemRecord) then
								hasKey = true
							elseif types.Ingredient.objectIsInstance(item) and detectIngredient > 0 then
								hasIngredient = itemRecord.icon
							elseif detectItem>0 then
								if itemRecord.enchant then
									hasItem = 2
								elseif filterUnenchanted(item,itemRecord) then
									hasItem = math.max(hasItem,1)
								end
							end
						end
						if hasKey then
							table.insert(HUDMarkers, {object = cont, icon = KEY_ICON, range = detectKey, bonusSize = 10, screenOffset = hasItem >0 and v2(-5,0) or nil, boundingBoxCenter = true})
						end
						if hasIndex then
							table.insert(HUDMarkers,  {object = cont, icon = INDEX_ICON, range = math.max(detectKey, detectItem), screenOffset = hasKey and v2(5,0) or nil, scale = 0.25, bonusSize = 23, boundingBoxCenter = true})
						elseif hasItem >1 then
							table.insert(HUDMarkers, {object = cont, icon = ITEM_PURPLE_ICON, range = detectItem, bonusSize = 10, screenOffset = hasKey and v2(5,0) or nil, boundingBoxCenter = true})
						elseif hasIngredient then
							table.insert(HUDMarkers,  {object = cont, icon = hasIngredient, range = math.max(detectItem,detectIngredient), screenOffset = hasKey and v2(5,0) or nil, bonusSize = 7, boundingBoxCenter = true})
						elseif hasItem >0 then
							table.insert(HUDMarkers, {object = cont, icon = CONTAINER_ICON, range = detectItem, scale = 0.5, screenOffset = hasKey and v2(5,0) or nil, boundingBoxCenter = true})
						end
					end
				end
			end
		end
	end
	
	-- LOOSE ITEMS
	if refreshCycle%4 == 0 or detectItemOrKeyChanged then
		interfaceMarkers.itemHUDMarkers = {}
		local HUDMarkers = interfaceMarkers.itemHUDMarkers
		if detectItem>0 or SHOW_KEYS and detectKey>0 or detectIngredient > 0 then
			for _, item in pairs(nearby.items) do
				local itemRecord = item.type.record(item)
				local isMisc = types.Miscellaneous.objectIsInstance(item)
				local distance = (item.position - cameraPos):length()
				if isMisc and (item.recordId:sub(1,6) == "index_" or item.recordId:sub(1,10) == "t_de_index") then
					table.insert(HUDMarkers,  {object = item, icon = INDEX_ICON, range = math.max(detectKey, detectItem), scale = 0.25, bonusSize = 23})
				elseif isMisc and SHOW_KEYS and detectKey>0 and isKey(itemRecord) and distance < detectKey * 22+500 then
					table.insert(HUDMarkers, {object = item, icon = KEY_ICON, range = detectKey, offsetMult = 0, offset = v3(0,0,2), bonusSize = 10})
				elseif detectIngredient > 0 and distance < detectIngredient * 22+500 and types.Ingredient.objectIsInstance(item) then
					table.insert(HUDMarkers,  {object = item, icon = itemRecord.icon, range = detectIngredient, offsetMult = 0, bonusSize = 15, scale = 0.15})	
				elseif detectItem>0 and distance < detectItem * 22+500 then
					if itemRecord.enchant then
						table.insert(HUDMarkers, {object = item, icon = ITEM_PURPLE_ICON, range = detectItem, offsetMult = 0, offset = v3(0,0,2), scale = 1.2, bonusSize = 10})
					elseif types.Item.isCarriable(item) and filterUnenchanted(item,itemRecord) then
						table.insert(HUDMarkers, {object = item, icon = ITEM_ICON, range = detectItem, offsetMult = 0, offset = v3(0,0,2), scale = 0.5})
					end
				end
			end
		end
	end
	if next(needResolve) then
		core.sendGlobalEvent("HUDM_resolveAll", {self, needResolve})
	end
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



local function onFrame(dt)
	---- test
	--if not interfaceMarkers.test then
	--	for _, cont in pairs(nearby.containers) do
	--		if cont.recordId == "flora_treestump_unique" then
	--			interfaceMarkers.test ={{object = cont, icon = ITEM_ICON, range = 21.3*150}}
	--			print("treestump")
	--		end
	--	end
	--end
	if not self.cell then return end
	if self.cell ~= cellCache then
		detectKeyCache = 9999999
		detectActorCache = 9999999
		detectItemCache = 9999999
		detectPlantCache = 999999999
		detectIngredientCache = 999999999
	end
	local itemMagnitude = types.Actor.activeEffects(self):getEffect("detectenchantment").magnitude
	detectKey = playerSection:get("DETECT_KEY_MULT") * types.Actor.activeEffects(self):getEffect("detectkey").magnitude
	detectActor = playerSection:get("DETECT_CREATURE_MULT") * types.Actor.activeEffects(self):getEffect("detectanimal").magnitude
	detectItem = playerSection:get("DETECT_ITEM_MULT") * itemMagnitude
	detectIngredient =playerSection:get("DETECT_INGREDIENT_MULT2") * ((playerSection:get("SHOW_INGREDIENTS") and itemMagnitude or 0) + detectIngredientBonus)
	detectHerb = playerSection:get("DETECT_HERB_MULT2") * ((playerSection:get("SHOW_HERBS") and itemMagnitude or 0) + detectHerbBonus)
	oreMult = playerSection:get("DETECT_ORE_MULT")/playerSection:get("DETECT_INGREDIENT_MULT2")
	
	if detectKeyCache ~= detectKey or detectActorCache ~= detectActor or detectItemCache ~= detectItem or detectIngredient ~= detectIngredientCache or detectHerb ~= detectHerbCache then
		detectChanged = true
	end
	local now = core.getRealTime()
	--local heartbeat = 0.5+math.abs(math.sin(now*3))^0.5/2
	if periodicRefresh > 0.3 or resolveRefresh or detectChanged then
		--print(resolveRefresh , self.cell ~= cellCache , detectKeyCache ~= detectKey , detectActorCache ~= detectActor , detectItemCache ~= detectItem)
		cellCache = self.cell
		savegameData.visitedCells[cellCache.id] = true
		resolveRefresh = false
		updateMarkers()
		periodicRefresh = 0
		detectChanged = false
		detectKeyCache = detectKey
		detectActorCache = detectActor
		detectItemCache = detectItem
		detectIngredientCache = detectIngredient
		detectHerbCache = detectHerb
	elseif detectKey > 0 or detectActor > 0 or detectItem > 0 or detectIngredient > 0 or detectHerb > 0 then
		periodicRefresh = periodicRefresh +core.getRealFrameDuration()
	end
	frame = frame+1
	--local heightDB = modData:getCopy("heightDB")
	local SCALE_MULT = playerSection:get("SCALE") or 1
	local viewportToWorldVector = camera.viewportToWorldVector(v2(0.5, 0.5))
	local viewportLength = viewportToWorldVector:length()
	
	-- fov calculation:
	local leftEdge = camera.viewportToWorldVector(util.vector2(0, 0.5))
	local halfFovDot = viewportToWorldVector:dot(leftEdge)
	local halfFovLength = viewportToWorldVector:length() * leftEdge:length()
	local halfFovCosine = halfFovDot / halfFovLength * 0.98

	local cameraPos = camera.getPosition()
	local now = core.getRealTime()
	local layerId = ui.layers.indexOf("HUD")
	local width = ui.layers[layerId].size.x 
	local screenres = ui.screenSize()
	local uiScale = screenres.x / width
	screenres= screenres:ediv(v2(uiScale,uiScale))
	local updateBars = {}
	
	for mod, modMarkers in pairs (interfaceMarkers) do
	for i,tbl in pairs(modMarkers) do
		local object = tbl.object
		local objectValid = object:isValid()
		if not objectValid then
			tbl[i] = nil
		else
			local objectPos = object.position
			--local objectPos =  object:getBoundingBox().center
			local uniqueId = object.id.."-"..tbl.icon.."-"..colorTableToHex(tbl.color)
			
			-- in front?
			local toObject = objectPos - cameraPos
			local dotProduct = viewportToWorldVector:dot(toObject)
			if dotProduct > 0 then
				local toObjectLength = toObject:length()
				if toObjectLength < (tbl.range or 100) * 21.33333333 and dotProduct / (viewportLength * toObjectLength) > halfFovCosine then
				-- in fov?
				--local cosAngle = dotProduct / (viewportLength * toObjectLength) 
				--if cosAngle > halfFovCosine then
					local isActor = types.Actor.objectIsInstance(object)
					local isDead = isActor and types.Actor.isDead(object)
					if not barCache[uniqueId] then
						barCache[uniqueId] = {
							object = object,
							lastRender = 0,
							deathTimer = isDead and 10 or 0,
							isDead = isDead,
						}
					end
							
					local c = barCache[uniqueId]
					--benchCounter = benchCounter + 1
					
					local isCreature = isActor and types.Creature.objectIsInstance(object)
					local objectRecordId = object.recordId
					local objectScale = object.scale
					if not boxCache[objectRecordId] or math.random()<0.05 and dt > 0 then
						local npcRecord = types.NPC.record(objectRecordId)
						if npcRecord then-- and types.NPC.races.record(npcRecord.race).isBeast then -- somehow beasts have huge bounding boxes
							if not boxCache[objectRecordId] then
								if npcRecord.isMale then
									boxCache[objectRecordId] = {v3(0,0,types.NPC.races.record(npcRecord.race).height.male*67.5/objectScale),v3(0,0,types.NPC.races.record(npcRecord.race).height.male*67.5/objectScale)}
								else
									boxCache[objectRecordId] = {v3(0,0,types.NPC.races.record(npcRecord.race).height.female*67.5/objectScale),v3(0,0,types.NPC.races.record(npcRecord.race).height.female*67.5/objectScale)}
								end
							end
						else
							local box = object:getBoundingBox()
							local newCache = {(box.center-objectPos):ediv(v3(objectScale,objectScale,objectScale)), box.halfSize:ediv(v3(objectScale,objectScale,objectScale)), 1}

							if not boxCache[objectRecordId] then
								boxCache[objectRecordId] = newCache
							else
								local strength = 1/(boxCache[objectRecordId][3]+1)+0.01
								boxCache[objectRecordId] = {boxCache[objectRecordId][1]*(1-strength)+newCache[1]*strength, boxCache[objectRecordId][2]*(1-strength)+newCache[2]*strength, boxCache[objectRecordId][3]+1}
							end
						end
					end
					
					--core.sendGlobalEvent("HPBars_VFX",objectPos-boxCache[objectRecordId][2])
					--local hugeness = math.log10(boxCache[objectRecordId][2].x*boxCache[objectRecordId][2].y*boxCache[objectRecordId][2].z)
					
					local model = isCreature and types.Creature.records[objectRecordId].model:lower()
					local scaleMult = tbl.scale or 1
					if customOffsets[objectRecordId] then
						c.barOffset = customOffsets[objectRecordId]
						if tbl.offset then
							c.barOffset = c.barOffset + tbl.offset
						end
					elseif not c.barOffset then
						local barOffset=v3(0,0,0)
						--print(objectRecordId)
						if model then
							--box center:
							barOffset = (computedBoxes[model] and computedBoxes[model][1]:emul(v3(0,0,1)) or boxCache[objectRecordId][1]:emul(v3(0,0,1)))*objectScale
							--print(computedBoxes[model] and computedBoxes[model][1]:emul(v3(1,1,1)))
							if true or playerSection:get("ANCHOR") == "head" then
								--barOffset =  boxCache[objectRecordId][2]:emul(v3(0,0,objectScale))
								if customHeights[model] then								
									barOffset = v3(barOffset.x, barOffset.y, customHeights[model]*objectScale)
								elseif computedBoxes[model] then
									barOffset = v3(0,0, barOffset.z + computedBoxes[model][2].z/2*objectScale)
								else
									barOffset = v3(0,0, barOffset.z + boxCache[objectRecordId][2].z*objectScale)
								end
							else
								if computedBoxes[model] then
									barOffset = v3(0,0, barOffset.z - computedBoxes[model][2].z/2*objectScale)
								else
									barOffset = v3(0,0, barOffset.z - boxCache[objectRecordId][2].z*objectScale)
								end
							end
						else
							if true or playerSection:get("ANCHOR") == "head" then --npcs are too predictable to use the engine's buggy bounding boxes as fallback already
								barOffset = boxCache[objectRecordId][1]+boxCache[objectRecordId][2]
							else
								barOffset = v3(0,0,0)
							end
						end
						--barOffset = barOffset * (tbl.offsetMult or 0)
						barOffset = barOffset:emul(v3(0, 0, tbl.offsetMult or 0))
						if tbl.offset then
							barOffset = barOffset + tbl.offset
						end
						if tbl.boundingBoxCenter then
							c.barOffset = object:getBoundingBox().center - objectPos + barOffset
						else
							c.barOffset = barOffset
						end
						if not c.lastAnimMult then
							if isDead then
								c.lastAnimMult = 0
							else
								c.lastAnimMult = 1
							end
						end
					end
					local offset = c.barOffset
					if isActor then
						local animMult = 1
						if animation.hasAnimation(object) then
							if (animation.isPlaying(object, "knockout") ) then
								local animStart = animation.getTextKeyTime(object, "knockout: start")
								local animStop = animation.getTextKeyTime(object, "knockout: stop")-animStart
								local animLoopStart = animation.getTextKeyTime(object, "knockout: loop start")-animStart
								local animLoopStop = animation.getTextKeyTime(object, "knockout: loop stop")-animStart
								local animCurrent = animation.getCurrentTime(object, "knockout")-animStart
								if animCurrent <= animLoopStart then
									animMult = 1-((animCurrent/animLoopStart)*1.25-0.25)^2*0.8
								elseif animCurrent >= animLoopStop then
									animCurrent = animCurrent - animLoopStop
									animStop = animStop - animLoopStop
									animStop = animStop *0.9
									animLoopStop = 0
									animMult = math.min(1,((animCurrent/animStop)*1.2-0.2)^2)
								else
									animMult = 0.02
								end
								if c then
									c.lastAnimMult = animMult
								end
							elseif animation.isPlaying(object, "knockdown") then
								local animStart = animation.getTextKeyTime(object, "knockdown: start")
								local animStop = animation.getTextKeyTime(object, "knockdown: stop")-animStart
								local middleMult = 1/3
								local animCurrent = animation.getCurrentTime(object, "knockdown")-animStart
								
								if animCurrent <= animStop*middleMult then
									animCurrent = animCurrent / (animStop*middleMult)
									local animPct = math.min(1,(animCurrent*1.2-0.2)^2)
									animMult = (1-animPct* 0.8) 
								elseif animCurrent >= animStop*(1-middleMult) then
									animCurrent = (animCurrent - animStop*(1-middleMult)) / (animStop*middleMult)
									local animPct = math.min(1,(animCurrent*1.2-0.2)^2)
									animMult = 0.2+animCurrent*0.8
								else
									animMult = 0.2
								end
								if c then
									c.lastAnimMult = animMult
								end
							end
						end
						if isDead and c then
							c.deathTimer = c.deathTimer+dt
							local animPct = math.min(1,(c.deathTimer/0.75)^2)
							animMult = 0.05+c.lastAnimMult*(1-animPct) + c.lastAnimMult*0.01*animPct
							offset = offset* animMult
							if offset.z < 12 then
								offset = v3(offset.x*animMult, offset.y*animMult, 12)
							end
							
						elseif tbl.icon == HEART_ICON then
							offset = offset* animMult
							objectPos = objectPos + object.rotation:apply(v3(0, 8, 0))
						else
							offset = offset* animMult
						end
					
					end
					objectPos = objectPos + offset
					
					local viewPos_XYZ = camera.worldToViewportVector(objectPos)
					local viewpPos = v2(viewPos_XYZ.x/uiScale, viewPos_XYZ.y/uiScale)
		
					
					if (not model or not modelBlacklist[model]) 
					--and ( not isDead)  
					--and viewPos_XYZ.z < playerSection:get("MAX_DISTANCE") +100
					--and viewportToWorldVector:dot(objectPos - cameraPos) > 0 --angleInRadians < math.pi/2 
					and viewpPos.x >= screenres.x*-0.1 
					and viewpPos.x <= screenres.x*1.1 
					--and (viewpPos.y >= screenres.y*-0.02 or viewpPos.y < screenres.y*-0.02 and rootViewPos_XYZ.y >= screenres.y*0.5 and rootViewPos_XYZ.y <screenres.y*1.4)
					and viewpPos.y <= screenres.y*1.1
					then
						--print(hugeness)
						local rayCheck = true
						local raytracingAlphaMult = 1
						if tbl.raytracing then
							if not raytracing[uniqueId] then
								raytracing[uniqueId] = {}
								raytracing[uniqueId].lastHit = 0
								raytracing[uniqueId].object = object
								raytracing[uniqueId].failedHits = 0
							end
							raytracing[uniqueId].objectPos = objectPos
							raytracing[uniqueId].objectPos = objectPos
							raytracing[uniqueId].distance = viewPos_XYZ.z
							if raytracing[uniqueId].lastHit < now-1 then
								rayCheck = false
							elseif raytracing[uniqueId].lastHit < now-0.05 and  raytracing[uniqueId].failedHits > 0 then
								raytracingAlphaMult = 1-(now - raytracing[uniqueId].lastHit)/1
							end
						end
						if rayCheck then
							c.lastRender = now
							if not c.hugeness then
								local hugeness2 = 0.85
								local hugeness3 = 0.85
								local hugeness = 0.85--model and customScales[model] and customScales[model]/100 or 1
								if model then
									local height = boxCache[objectRecordId][2].z*2
									if customHeights[model] then
										height = math.max(height,customHeights[model])
									end
									if computedBoxes[model] then
										height = math.max(height, computedBoxes[model][2].z)
									end
									height = height*objectScale
									if height < 110 then
										hugeness = 0.66 + height/323								
									else
										hugeness = 1 + 3*(1-0.7^((height-110)/215))
									end
								end
								if model then
									if computedBoxes[model] then
										hugeness2 = (computedBoxes[model][2].x*computedBoxes[model][2].y*computedBoxes[model][2].z)^0.333 / 90
										hugeness3 = (computedBoxes[model][2].x*computedBoxes[model][2].y)^0.333 / 90
									else
										hugeness2 = (boxCache[objectRecordId][2].x*boxCache[objectRecordId][2].y*boxCache[objectRecordId][2].z)^0.333 / 90
										hugeness3 = (boxCache[objectRecordId][2].x*boxCache[objectRecordId][2].y)^0.5 / 90
									end
								end
								local maxHealth = (isActor and types.Actor.stats.dynamic.health(object).base or 0)+1
								hugeness = 0.3 + hugeness/4 + hugeness2/4 + hugeness3/4 + math.log10(maxHealth/10)/4
								if model then
									hugeness = hugeness + (customScales[model] or 0)
								end
								--print(object.recordId, hugeness,  hugeness * (1.4 - 0.6 * hugeness))
								if isActor then
									--hugeness = hugeness * 0.57
									hugeness = hugeness * (1.4 - 0.6 * hugeness)
								end
								c.hugeness = hugeness * scaleMult
							end
							local offsetScale = 500/ viewPos_XYZ.z*SCALE_MULT
							if offsetScale >1 then
								offsetScale = 1 + 10.7*(1-0.75^((offsetScale-1)/3))
							end
							local sizeMult = offsetScale*c.hugeness*0.85
							--update(c)
							
							if not c.bar then
								--core.sendGlobalEvent("HUDM_VFX", {self,object.position})
								c.bar = ui.create({	--root
									type = ui.TYPE.Image,
									layer = 'HUD',
									props = {
										position = v2(65,10),
										--size = v2(28*sizeMult+2,28*sizeMult+2),
										anchor = tbl.icon == HEART_ICON and v2(0.5,0.43) or v2(0.5,0.5),
										resource = isDead and tbl.deadIcon and getTexture(tbl.deadIcon) or getTexture(tbl.icon),
										--relativePosition= v2(0,0.5),
										tileH = false,
										tileV = false,
										--alpha = tbl.opacity or 0.7,
										color = colorTableToColor(tbl.color)
									},
								})
							end
							--if isActor and tbl.anchor ~= 2 then
							if tbl.screenOffset then
								viewpPos = v2(viewpPos.x+tbl.screenOffset.x*offsetScale,viewpPos.y+tbl.screenOffset.y*offsetScale)
							end
							if viewpPos.y > screenres.y  then
								viewpPos = v2(viewpPos.x,screenres.y)
							end
							if c.isDead ~= isDead and tbl.deadIcon then
								c.bar.layout.props.resource = isDead and getTexture(tbl.deadIcon) or getTexture(tbl.icon)
							end
							if not isDead and tbl.icon == HEART_ICON then
								local objId = idToNumber(c.object.id)
								if types.Actor.getStance(c.object) == types.Actor.STANCE.Nothing then
									sizeMult = 0.41*sizeMult*(1.25+math.abs(math.sin((now+objId)*(3.75+objId%5/8)))^0.7*0.95) -- slow heartbeat (75 - 81.2 bpm)
								else
									sizeMult = 0.41*sizeMult*(1.25+math.abs(math.sin((now+objId)*(7.5+objId%5/8)))^0.7*0.95) -- 143.2 - 152.8 bpm
								end
							end
							c.isDead = isDead
							c.bar.layout.props.position = viewpPos
							c.bar.layout.props.alpha = (tbl.opacity or 0.7)*raytracingAlphaMult
								
							c.bar.layout.props.size = v2(28*sizeMult+2+(tbl.bonusSize or 0),28*sizeMult+2+(tbl.bonusSize or 0))
							--updateBars[sizeMult] = c.bar

							c.bar:update()
							
						end
					else
						--if barCache[uniqueId] and barCache[uniqueId].bar then
						--	barCache[uniqueId].bar:destroy()
						--end
						--barCache[uniqueId] = nil
						--raytracing[uniqueId] = nil
					end
				else  --out of range
					--if barCache[uniqueId] then
					--	if barCache[uniqueId].bar then
					--		barCache[uniqueId].bar:destroy()
					--	end
					--	barCache[uniqueId] = nil
					--end
				end
			end
		end
	end
	end
	--local sortBars = {}
	--for a,b in pairs(updateBars) do
	--	table.insert(sortBars,a)
	--end
	--table.sort(sortBars)
	--for a,b in pairs(sortBars) do
	--	updateBars[b]:update()
	--end
	if true or playerSection:get("RAYTRACING") then
		rayCounter = 0
		for i=1,30 do
			if not raytracing[nextRay] then
				nextRay = nil
			end
			nextRay = next(raytracing,nextRay)
			if not raytracing[nextRay]  or raytracing[nextRay].distance > RT_MAX_DISTANCE then
				
			else
				rayCounter = rayCounter + 1
				--print("queuing "..raytracing[nextRay].object.id)
				--print(camera.getPosition(), raytracing[nextRay].objectPos)
				--local rayTarget = (raytracing[nextRay].objectPos-camera.getPosition()):normalize():emul(v3(RT_MAX_DISTANCE))
				local rayTarget = nil
				local forward = (raytracing[nextRay].objectPos-cameraPos):normalize()
				local up = v3(0,0,1)
				local right = forward:cross(up)
				--print("right",right)
				local objectId = nextRay
				if raytracing[objectId].failedHits %4 == 0 then
					rayTarget = raytracing[nextRay].objectPos +right:emul(v3(20,20,20))
				elseif raytracing[objectId].failedHits %4 == 1 then
					rayTarget = raytracing[nextRay].objectPos -right:emul(v3(20,20,20))
				elseif raytracing[objectId].failedHits %4 == 2 then
					rayTarget = (raytracing[nextRay].objectPos + raytracing[nextRay].objectPos):ediv(v3(2,2,2))+right:emul(v3(20,20,20))
				elseif raytracing[objectId].failedHits %4 == 3 then
					rayTarget = (raytracing[nextRay].objectPos + raytracing[nextRay].objectPos):ediv(v3(2,2,2))-right:emul(v3(20,20,20))
				end
				--vfx(rayTarget)
				local startPos = cameraPos
				nearby.asyncCastRenderingRay(
					async:callback(function(res)
						if not raytracing[objectId] then return end
						if not res.hit or res.hitObject and res.hitObject == raytracing[objectId].object then
							raytracing[objectId].lastHit = now
							raytracing[objectId].failedHits = 0
						elseif (res.hitPos - startPos):length() < raytracing[objectId].distance-100 then
							raytracing[objectId].failedHits = raytracing[objectId].failedHits + 1
						else
							raytracing[objectId].lastHit = now
							raytracing[objectId].failedHits = 0
						end
					end), 
					cameraPos,rayTarget )
			end
			if rayCounter >= raysPerTick then
				break
			end
		end
			
		for a,b in pairs(raytracing) do
			if b.distance > RT_MAX_DISTANCE then
				raytracing[a] = nil
			end
		end
	
	end
	
	for a,b in pairs(barCache) do
		if b.lastRender < now-0.02 and b.bar then
			
			b.bar:destroy()
			barCache[a] = nil
			raytracing[a] = nil
			--print("destroy",b.object.recordId)
		end
	end
	--print("benchCounter", benchCounter)
end

local function onLoad(data)
	if data then
		savegameData = data.savegameData or {}
	else
		savegameData = {}
	end
	if not savegameData.visitedCells then
		savegameData.visitedCells = {}
	end
	if not savegameData.lastHarvest then
		savegameData.lastHarvest = {}
	end
end

local function onSave()
    return {
        savegameData = savegameData
    }
end

local function HUDM_resolveRefresh()
	resolveRefresh = true
end

local function objectRemoved(object)
	local tempDetectActor = playerSection:get("DETECT_ACTOR_LOOT") and (SHOW_KEYS and detectKey>0 or detectItem>0) and 150 or detectActor
	if tempDetectActor > 0 then
		local objectId = object.id
		for i, tbl in pairs( interfaceMarkers.actorHUDMarkers) do
			if tbl.object.id == objectId then
				interfaceMarkers.actorHUDMarkers[i] = nil
			end			
		end	
	end
end

local function recheckObject(object)
	--async:newUnsavableSimulationTimer(0.3, function()
	--	print(object)
	--	print(object.count)
	--	print(object.enabled)
	--	print(object.position)
	--	print(object:isValid())
	--	for i, tbl in pairs( interfaceMarkers.itemHUDMarkers) do
	--	end
	--end)
	--do return end
	
	local objectId = object.id
	
	-- LOOSE ITEMS
	if types.Item.objectIsInstance(object) then
		if detectItem > 0 or SHOW_KEYS and detectKey>0 or detectIngredient > 0 then
			for i, tbl in pairs( interfaceMarkers.itemHUDMarkers) do
				if tbl.object.id == objectId then
					interfaceMarkers.itemHUDMarkers[i] = nil
					break
				end
			end
		end
	-- CONTAINERS
	elseif types.Container.objectIsInstance(object) then
		if types.Container.record(object).isOrganic and not organicContainers[object.recordId] then
			savegameData.lastHarvest[objectId] = core.getGameTime()
			if (detectItem > 0 or detectHerb > 0) and types.Container.inventory(object):isResolved() then
				for i, tbl in pairs( interfaceMarkers.containerHUDMarkers) do
					if tbl.object.id == objectId then
						interfaceMarkers.containerHUDMarkers[i] = nil
						break
					end
				end
			end
		elseif detectItem > 0 or detectKey > 0 or detectIngredient > 0 then
			for i, tbl in pairs(interfaceMarkers.containerHUDMarkers) do
				if tbl.object.id == objectId then
					interfaceMarkers.containerHUDMarkers[i] = nil
				end
			end
			local hasKey = false
			local hasItem = 0
			local hasIngredient = false
			for _,item in pairs(types.Container.inventory(object):getAll()) do
				local itemRecord = item.type.records[item.recordId]
				if detectKey>0 and SHOW_KEYS and types.Miscellaneous.objectIsInstance(item) and isKey(itemRecord) then
					hasKey = true
				elseif types.Ingredient.objectIsInstance(item) and detectIngredient > 0 then
					hasIngredient = itemRecord.icon
				elseif detectItem>0 then
					if itemRecord.enchant then
						hasItem = 2
					elseif filterUnenchanted(item,itemRecord) then
						hasItem = math.max(hasItem,1)
					end
				end
			end
			if hasKey then
				table.insert(interfaceMarkers.containerHUDMarkers, {object = object, icon = KEY_ICON, range = detectKey, bonusSize = 10, screenOffset = hasItem >0 and v2(-5,0) or nil})
			end
			
			if hasItem >1 then
				table.insert(interfaceMarkers.containerHUDMarkers, {object = object, icon = ITEM_PURPLE_ICON, range = detectItem, bonusSize = 10, screenOffset = hasKey and v2(5,0) or nil})
			elseif hasIngredient then
				table.insert(interfaceMarkers.containerHUDMarkers, {object = object, icon = hasIngredient, range = math.max(detectItem,detectIngredient), screenOffset = hasKey and v2(5,0) or nil, bonusSize = 7})
			elseif hasItem >0 then
				table.insert(interfaceMarkers.containerHUDMarkers, {object = object, icon = CONTAINER_ICON, range = detectItem, screenOffset = hasKey and v2(5,0) or nil})
			end
		end
	-- ACTORS
	elseif types.Actor.objectIsInstance(object) and (playerSection:get("DETECT_ACTOR_LOOT") and (SHOW_KEYS and detectKey>0 or detectItem>0 or detectIngredient>0) or detectActor > 0 or detectIngredientBonus > 0) then
		local hasKey = false
		local hasItem = 0
		local hasIngredient = false
		if detectItem>0 or SHOW_KEYS and detectKey>0 or detectIngredient>0 then
			for _,item in pairs(types.Actor.inventory(object):getAll()) do
				local itemRecord = item.type.records[item.recordId]
				if detectKey>0 and SHOW_KEYS and types.Miscellaneous.objectIsInstance(item) and isKey(itemRecord) then
					hasKey = true
				elseif types.Ingredient.objectIsInstance(item) and detectIngredient > 0 then
					hasIngredient = true
				elseif detectItem>0 then
					if itemRecord.enchant then
						hasItem = 2
					else
						hasItem = math.max(hasItem,1)
					end
				end
			end
		end
		for i, tbl in pairs( interfaceMarkers.actorHUDMarkers) do
			if tbl.object.id == objectId then
				if tbl.icon == KEY_ICON and not hasKey
				or tbl.icon == ITEM_ICON and hasItem == 0
				or tbl.icon == ITEM_PURPLE_ICON and hasItem <= 1
				or tbl.bonusSize == 7 and not hasIngredient
				then
					interfaceMarkers.actorHUDMarkers[i] = nil
				end
			end			
		end	
	end
end


 return {    
	engineHandlers = {
		onFrame = onFrame,
		onSave = onSave,
        onLoad = onLoad,
        onInit = onLoad,
    },
	eventHandlers = {
		HUDM_resolveRefresh = HUDM_resolveRefresh,
		HUDM_recheckObject = recheckObject,
		HUDM_objectRemoved = objectRemoved,
    },
	interfaceName = "HUDMarkers",
    interface = {
        version = 6,
        setMarkers = function(otherMod, markers)
			interfaceMarkers[otherMod] = markers
			-- {object = [actor/door/item/container], -- required, gameobject reference
			--  icon = texturePath, -- required, texturepath
			--  scale = 0.33, -- default: 0.6
			--  raytracing = true, -- default: off
			--  range = 50, --in ft, default: 100
			--  opacity = 0.5, -- default: 1
			--  offsetMult = 0.5, -- multiplied with model size, default: 0 (at world position)
			--  screenOffset = v2(5,0), -- multiplied with distance scaling, default: no offset
			--  deadIcon = texturePath, -- icon when the actor is dead (optional)
			--  bonusSize = 10, -- increases icon size by x pixels, regardless of distance, default: 0
			--  boundingBoxCenter = true -- apply difference between bounding box center and actor pos to world offset. do not use for living things, as it gets only applied on caching
			-- }) 
		end,
		FHBarsBlacklist = function(blacklist) -- floating healthbars integration, so the dot from detect creature doesn't get displayed when the healthbar is shown
			blacklistDetectActors = blacklist
			local newLength = tableLength(blacklistDetectActors)
			if interfaceMarkers.actorHUDMarkers then
				for i, tbl in pairs(interfaceMarkers.actorHUDMarkers) do
					if blacklistDetectActors[tbl.object.id] then
						interfaceMarkers.actorHUDMarkers[i] = nil
					end
				end
				if newLength < blacklistLength then
					updateMarkers(1)
				end
			end
			blacklistLength = newLength
		end,
		setIngredientBonus = function(otherMod, value)
			detectIngredientBonuses[otherMod] = value
			local maxValue = 0
			for _, v in pairs(detectIngredientBonuses) do
				maxValue = math.max(v, maxValue)
			end
			detectIngredientBonus = maxValue
		end,
		setHerbBonus = function(otherMod, value)
			detectHerbBonuses[otherMod] = value
			local maxValue = 0
			for _, v in pairs(detectHerbBonuses) do
				maxValue = math.max(v, maxValue)
			end
			detectHerbBonus = maxValue
		end,
    }
}


