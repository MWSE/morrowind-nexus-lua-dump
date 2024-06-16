local KEY = require('openmw.input').KEY
local types = require('openmw.types')
local util = require('openmw.util')
local v3 = util.vector3
local core = require('openmw.core')
local self = require("openmw.self")
local nearby = require('openmw.nearby')
local input = require('openmw.input')
function vfx(pos)
	local effect = core.magic.effects.records[9]
	core.vfx.spawn(effect.castStatic, pos)
end

nextCreature = 0
boundingDB = {}


checkTick = 0
spawnCounter = 0
local offset = 500

function onKey(key) -- for computed bounding boxes
	if key.code == KEY.F then
		for i=1,2000 do
			nextCreature = nextCreature+1
			if not types.Creature.records[nextCreature] then
				return
			end
			if not checkedModels[types.Creature.records[nextCreature].model] and not computedBoxes[types.Creature.records[nextCreature].model] then
				break
			end
		end
		if types.Creature.records[nextCreature] then
			spawnCounter = spawnCounter + 1
			local offsetMult = spawnCounter % 1 +1
			local spawnPos = v3(offsetMult*offset,offsetMult*offset,0)---offset)
			checkedModels[types.Creature.records[nextCreature].model] = true 
			print(nextCreature,types.Creature.records[nextCreature].id,"[\""..types.Creature.records[nextCreature].model:gsub("\\","\\\\").."\"] = true,")
			core.sendGlobalEvent("HPBars_CreateObject",{cell = self.object.cell.name, position = self.object.position +spawnPos ,recordId = types.Creature.records[nextCreature].id})
			castRays = self.object.position + spawnPos
			checkTick = 0
			checkModel = types.Creature.records[nextCreature].model
		end
	end
	if key.code == KEY.H then
		core.sendGlobalEvent("HPBars_Clear")
		nextCreature = 0
		for a,b in pairs(boundingDB) do
			print("[\""..a:gsub("\\","\\\\").."\"] = {v3("..b[1].x..", "..b[1].y..", "..b[1].z.."), v3("..b[2].x..", "..b[2].y..", "..b[2].z..")},")
		end
	end
end
local modifier = 0.1
local defaultValue = 0
local workTable = customScales
function onKey2(key) -- for custom bar heights and scales (rename function)
	if key.code == KEY.F then
		for i=1,2000 do
			nextCreature = nextCreature+1
			if not checkedModels[types.Creature.records[nextCreature].model] then
				break
			end
		end
		if types.Creature.records[nextCreature] then
			checkedModels[types.Creature.records[nextCreature].model] = true 
			print(nextCreature,types.Creature.records[nextCreature].id,"[\""..types.Creature.records[nextCreature].model:gsub("\\","\\\\").."\"] = true,")
			core.sendGlobalEvent("HPBars_CreateObject",{cell = self.object.cell.name, position = self.object.position + v3(0,250,0) ,recordId = types.Creature.records[nextCreature].id})
		end
	end
	if key.code == KEY.G then
		local mod = modifier
		if input.isCtrlPressed() then
			mod = modifier*2
		end
		if input.isShiftPressed() then
		workTable[types.Creature.records[nextCreature].model] = (workTable[types.Creature.records[nextCreature].model] or defaultValue)- mod
		else
		workTable[types.Creature.records[nextCreature].model] = (workTable[types.Creature.records[nextCreature].model] or defaultValue)+ mod
		end
		print('["'..types.Creature.records[nextCreature].model:gsub("\\","\\\\")..'"] = '..workTable[types.Creature.records[nextCreature].model]..",")
	end
	if key.code == KEY.H then
		core.sendGlobalEvent("HPBars_Clear")
		nextCreature = 0
		for a,b in pairs(checkedModels) do
			if workTable[a] == defaultValue then
				--print('["'..a:gsub("\\","\\\\")..'"] = '..( "true")..",")
			else
				print('["'..a:gsub("\\","\\\\")..'"] = '..(workTable[a] or "true")..",")
			end
		end
	end
end

function autoSpawn()
	--onKey({code = KEY.F})
end

function computeBoundingBoxes_tick()
	checkTick = checkTick+1
	if castRays and checkTick == 5 then
		local res = {}
		local yOffset = 750
		local radius = 200
		--local ignore = self
		--print("spawnpos",castRays)
		--vfx(castRays)
		--vfx((castRays + v3(0,0,-200)))
		--vfx((castRays + v3(0,0,200)))
		table.insert( res, nearby.castRay(castRays + v3(0,0,-2000), castRays + v3(0,0,2000), {ignore=ignore, radius = radius}))
		--if res[#res].hit then vfx(res[#res].hitPos) end
		table.insert( res, nearby.castRay(castRays + v3(0,0,2000), castRays + v3(0,0,-2000), {ignore=ignore, radius = radius}))
		--if res[#res].hit then vfx(res[#res].hitPos) end
			--if res.hitObject and res.hitObject ~= enemy then obstacle = res.hitObject end
		--print(res.hitObject, res.hitPos)
		--print(res.hitObject, res.hitPos)
		if not res[1].hit or not res[2].hit then
			autoSpawn()
			return
		end
		local middleZ = (castRays.z-(res[2].hitPos.z-(res[2].hitPos.z-res[1].hitPos.z)/2))*-1
		table.insert( res, nearby.castRay(castRays + v3(0,1250,middleZ), castRays + v3(0,-1250,middleZ), {ignore=ignore, radius = radius}))
		--if res[#res].hit then vfx(res[#res].hitPos) end
		table.insert( res, nearby.castRay(castRays + v3(0,-1250,middleZ), castRays + v3(0,1250,middleZ), {ignore=ignore, radius = radius}))
		--if res[#res].hit then vfx(res[#res].hitPos) end
		
		table.insert( res, nearby.castRay(castRays + v3(1250,0,middleZ), castRays + v3(-1250,0,middleZ), {ignore=ignore, radius = radius}))
		--if res[#res].hit then vfx(res[#res].hitPos) end
		table.insert( res, nearby.castRay(castRays + v3(-1250,0,middleZ), castRays + v3(1250,0,middleZ), {ignore=ignore, radius = radius}))
		--if res[#res].hit then vfx(res[#res].hitPos) end
		for a,b in pairs(res) do
			if not b.hit then
				autoSpawn()
				return
			end
		end
		--obj = res[1].hitObject
		--box = obj:getBoundingBox()
		--for a,b in pairs(box.vertices) do
		--	vfx(b)
		--end
		--pos = v3(box.center.x+box.halfSize.x,box.center.y,box.center.z)
		--vfx (pos)
		--pos = v3(box.center.x-box.halfSize.x,box.center.y,box.center.z)
		--vfx (pos)
		--pos = v3(box.center.x,box.center.y+box.halfSize.y,box.center.z)
		--vfx (pos)
		--pos = v3(box.center.x,box.center.y-box.halfSize.y,box.center.z)
		--vfx (pos)
		--pos = v3(box.center.x,box.center.y,box.center.z+box.halfSize.z)
		--vfx (pos)
		--pos = v3(box.center.x,box.center.y,box.center.z-box.halfSize.z)
		--vfx (pos)
		
		local z = (res[2].hitPos.z-res[1].hitPos.z)
		local y = -(res[4].hitPos.y-res[3].hitPos.y)
		local x = -(res[6].hitPos.x-res[5].hitPos.x)
		
		local middleZ = (castRays.z-(res[2].hitPos.z-(res[2].hitPos.z-res[1].hitPos.z)/2))*-1
		local middleY = (castRays.y-(res[4].hitPos.y-(res[4].hitPos.y-res[3].hitPos.y)/2))*-1
		local middleX = (castRays.x-(res[6].hitPos.x-(res[6].hitPos.x-res[5].hitPos.x)/2))*-1
		--vfx(castRays+v3(middleX,middleY,middleZ))
		
		
		print(middleX,middleY,middleZ)
		print(x,y,z)
		boundingDB[checkModel] = {v3(middleX,middleY,middleZ),v3(x,y,z)}
		
		--print(res[2].hitObject:getBoundingBox().halfSize*2)
		castRays = nil
		autoSpawn()
		return
	end

end