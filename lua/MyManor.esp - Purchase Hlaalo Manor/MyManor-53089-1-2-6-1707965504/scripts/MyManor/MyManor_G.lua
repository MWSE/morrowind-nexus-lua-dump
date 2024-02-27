local MyManor = {}
local types = require("openmw.types")
local world = require("openmw.world")
local acti = require("openmw.interfaces").Activation
local core = require("openmw.core")
local util = require("openmw.util")
local storage = require("openmw.storage")
local doorLocksReplaced = false
local ownershipTransferred = false
local oldFurnitureExteriorMoved = false
local oldFurnitureMoved = false
local useOffsetExt = -1536
local useOffsetInt = 2036
local function onSave()
	return {
		doorLocksReplaced = doorLocksReplaced,
		ownershipTransferred = ownershipTransferred,
		oldFurnitureExteriorMoved = oldFurnitureExteriorMoved,
		oldFurnitureMoved = oldFurnitureMoved
	}
end
local function drawLavaSquares(cell, basePos, countx, county)
	for x = 1, countx, 1 do
		for y = 1, county, 1 do
			local position = util.vector3(basePos.x + ((x - 1) * 512), basePos.y - ((y - 1) * 512), basePos.z)
			world.createObject("in_lava_blacksquare"):teleport(cell, position)
		end
	end
end
local function onLoad(data)
	if not data then
		return
	end
	doorLocksReplaced = data.doorLocksReplaced
	ownershipTransferred = data.ownershipTransferred
	oldFurnitureExteriorMoved = data.oldFurnitureExteriorMoved
	oldFurnitureMoved = data.oldFurnitureMoved
end
function MyManor.replaceDoorLocks(cell)
	local key_hlaalo_manor = "key_hlaalo_manor"
	local jsmk_mm_mi_key = types.Miscellaneous.record("jsmk_mm_mi_key")
	if not jsmk_mm_mi_key then return end
	for i, doorRef in ipairs(cell:getAll(types.Door)) do
		types.Lockable.setKeyRecord(doorRef, jsmk_mm_mi_key)
	end
	doorLocksReplaced = true
end

local player = nil

function MyManor.deleteRalenHlaalo()
	world.getCellByName("Balmora, Hlaalo Manor"):getAll()
	local hlaalo = world.getObjectByFormId("FormId:0x104be28")
	if hlaalo and hlaalo.enabled then
		hlaalo.enabled = false
		hlaalo:remove()
	end
	local nirith = world.getObjectByFormId("FormId:0x104be29")
	if nirith and nirith.enabled then
		nirith.enabled = false
		nirith:remove()
	end
end

function MyManor.transferOwnership(cell)
	
	for i, ref in ipairs(cell:getAll()) do
		if ref.owner.recordId then
			ref.owner.recordId = nil
		end
		if ref.owner.factionId then
			ref.owner.factionId = nil
		end
	end
	ownershipTransferred = true
end

function MyManor.tidyUp(cell)
	for i, ref in ipairs(cell:getAll()) do
		if ref.recordId == "active_de_r_bed_01" then
			local rotate = util.transform.rotateZ(math.rad(270))
			ref:teleport(cell, util.vector3(-280.986, 248.210, 803.742), rotate)
		elseif ref.recordId == "furn_de_r_chair_03" then
			if ref.position.z > 700 then -- there are multiple chairs
				local rotate = util.transform.rotateZ(math.rad(0))
				ref:teleport(cell, util.vector3(-162.458, 317.430, 817.039), rotate)
			end
		elseif ref.recordId == "furn_de_r_wallscreen_01" then
			if ref.position.z > 700 then -- there are multiple chairs
				local rotate = util.transform.rotateZ(math.rad(180))
				ref:teleport(cell, util.vector3(-8.553, 173.233, 855.204), rotate)
			end
		elseif ref.recordId == "key_ralen_hlaalo" then
			ref:remove()
		elseif ref.recordId == "light_de_paper_lantern_off" then
			ref:remove()
			local newRec = world.createObject("light_de_paper_lantern_01")
			local rotate = util.transform.rotateZ(math.rad(40))
			newRec:teleport(cell, util.vector3(-264.304, 66.302, 955.784), rotate)
		elseif ref.recordId == "misc_uni_pillow_01" then
			if ref.position.z > 700 then -- there are two pillows
				local rotate = util.transform.rotateZ(math.rad(270))
				ref:teleport(cell, util.vector3(-281.772, 312.087, 828.966), rotate)
			end
		end
	end
end

local function isWhitelisted(object)
	if object.type == types.Light then return false end -- dark_64 is a location marker for some reason
	if object.type == types.Door then return true end -- in_h_trapdoor_01
	local id = object.recordId
	if id:match("^in_hlaalu") then return true end   -- in_hlaalu_hall_end
	if id:match("^t_de_sethla") then return true end -- t_de_sethla_x_win_01
	if id:match("^ex_hlaalu") then return true end   -- ex_hlaalu_win_01
	if id:match("^ab_in_hla") then return true end   -- ab_in_hlaroomfloor
	return false
end

function MyManor.moveOldFurnitureExterior(cell, offset)
	local function isInBox(position, x1, x2, y1, y2, z1, z2)
		if position.x < x1 or position.x > x2 then return false end
		if position.y < y1 or position.y > y2 then return false end
		if position.z < z1 or position.z > z2 then return false end
		return true
	end
	for i, ref in ipairs(cell:getAll()) do
		if ref.contentFile and ref.contentFile == "beautiful cities of morrowind.esp" then
			if isInBox(ref.position, -24280, -24010, -11390, -11140, 1300, 1340) then
				if not isWhitelisted(ref) then
					ref:teleport(cell, util.vector3(0, 0, offset) + ref.position)
				end
			end
		end
	end
	oldFurnitureExteriorMoved = true
end

function MyManor.moveOldFurniture(cell, offset)
	for i, ref in ipairs(cell:getAll()) do
		if not isWhitelisted(ref) then
			ref:teleport(cell, util.vector3(offset, 0, 0) + ref.position)
		end
	end
	oldFurnitureMoved = true
end

local function journalUpdated(journalIndex)        --called by the player script, only for the quest id MManor_journalUpdated
	if journalIndex < 20 then return end
	local outsideCell = world.getExteriorCell(-3, -2) --The cell outside of the manor
	local insideCell = world.getCellByName("Balmora, Hlaalo Manor")
	MyManor.replaceDoorLocks(outsideCell)
	if not ownershipTransferred then
		MyManor.deleteRalenHlaalo()
		MyManor.transferOwnership(insideCell)
		MyManor.tidyUp(insideCell)
	end
	if journalIndex < 30 then return end
	if not oldFurnitureExteriorMoved then
		MyManor.moveOldFurnitureExterior(outsideCell,
			useOffsetExt)
	end
	if not oldFurnitureMoved then
		MyManor.moveOldFurniture(insideCell, useOffsetInt)
		drawLavaSquares(insideCell, util.vector3(1400.33, 601.247, 1389.21), 5, 5)
	end
end
local function reRunOwnership()
	if not ownershipTransferred then return end
	local insideCell = world.getCellByName("Balmora, Hlaalo Manor")
	MyManor.transferOwnership(insideCell)
end
return {
	interfaceName  = "MyManor",
	interface      = {
		version = 1,
		journalUpdated = journalUpdated,
		drawLavaSquares = drawLavaSquares,

	},
	engineHandlers = {
		onSave = onSave,
		onLoad = onLoad,
	},
	eventHandlers  = {
		MManor_journalUpdated = journalUpdated,
		MManor_reRunOwnership = reRunOwnership,
	}
}
