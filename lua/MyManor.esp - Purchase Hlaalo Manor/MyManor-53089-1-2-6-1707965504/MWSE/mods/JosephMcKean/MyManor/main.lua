local MyManor = {}

---@param cell tes3cell
function MyManor.replaceDoorLocks(cell)
	local key_hlaalo_manor = "key_hlaalo_manor"
	local jsmk_mm_mi_key = tes3.getObject("jsmk_mm_mi_key")
	if not jsmk_mm_mi_key then return end ---@cast jsmk_mm_mi_key tes3misc
	for doorRef in cell:iterateReferences(tes3.objectType.door) do
		local lockNode = doorRef.lockNode
		if lockNode then if lockNode.key and lockNode.key.id == key_hlaalo_manor then lockNode.key = jsmk_mm_mi_key end end
	end
	tes3.player.data.MyManor.doorLocksReplaced = true
end

function MyManor.deleteRalenHlaalo()
	local hlaalo = tes3.getReference("ralen hlaalo")
	if hlaalo then
		hlaalo:disable()
		hlaalo:delete()
	end
	local nirith = tes3.getReference("uryne nirith")
	if nirith then
		nirith:disable()
		nirith:delete()
	end
end

---@param cell tes3cell
function MyManor.transferOwnership(cell)
	for ref in cell:iterateReferences() do
		if tes3.getOwner({ reference = ref }) then
			tes3.setOwner({ reference = ref, remove = true })
			ref.modified = true
		end
	end
	tes3.player.data.MyManor.ownershipTransferred = true
end

---@param cell tes3cell
function MyManor.tidyUp(cell)
	for ref in cell:iterateReferences() do
		if ref.baseObject.id:lower() == "active_de_r_bed_01" then
			ref.position = tes3vector3.new(-280.986, 248.210, 803.742)
			ref.orientation = tes3vector3.new(0, 0, math.rad(270))
		elseif ref.baseObject.id:lower() == "furn_de_r_chair_03" then
			if ref.position.z > 700 then -- there are multiple chairs
				ref.position = tes3vector3.new(-162.458, 317.430, 817.039)
				ref.orientation = tes3vector3.new(0, 0, 0)
			end
		elseif ref.baseObject.id:lower() == "furn_de_r_wallscreen_01" then
			if ref.position.z > 700 then -- there are multiple chairs
				ref.position = tes3vector3.new(-8.553, 173.233, 855.204)
				ref.orientation = tes3vector3.new(0, 0, math.rad(180))
			end
		elseif ref.baseObject.id:lower() == "key_ralen_hlaalo" then
			ref:disable()
			ref:delete()
		elseif ref.baseObject.id:lower() == "light_de_paper_lantern_off" then
			ref:disable()
			ref:delete()
			tes3.createReference({ object = "light_de_paper_lantern_01", cell = cell, position = tes3vector3.new(-264.304, 66.302, 955.784), orientation = tes3vector3.new(0, 0, math.rad(40)) })
		elseif ref.baseObject.id:lower() == "misc_uni_pillow_01" then
			if ref.position.z > 700 then -- there are two pillows
				ref.position = tes3vector3.new(-281.772, 312.087, 828.966)
				ref.orientation = tes3vector3.new(0, 0, math.rad(270))
			end
		end
	end
end

---@param cell tes3cell
function MyManor.canRest(cell)
	cell.restingIsIllegal = false
	tes3.player.data.MyManor.cellCanRest = true
end

---@param object tes3object
local function isWhitelisted(object)
	if object.objectType == tes3.objectType.light then return false end -- dark_64 is a location marker for some reason
	if object.isLocationMarker then return true end -- DoorMarker
	if object.objectType == tes3.objectType.door then return true end -- in_h_trapdoor_01
	local id = object.id:lower()
	if id:match("^in_hlaalu") then return true end -- in_hlaalu_hall_end
	if id:match("^t_de_sethla") then return true end -- t_de_sethla_x_win_01
	if id:match("^ex_hlaalu") then return true end -- ex_hlaalu_win_01
	if id:match("^ab_in_hla") then return true end -- ab_in_hlaroomfloor
	return false
end

---@param cell tes3cell
function MyManor.moveOldFurnitureExterior(cell, offset)
	---@param position tes3vector3
	---@param x1 number
	---@param x2 number
	---@param y1 number
	---@param y2 number
	---@param z1 number
	---@param z2 number
	---@return boolean
	local function isInBox(position, x1, x2, y1, y2, z1, z2)
		if position.x < x1 or position.x > x2 then return false end
		if position.y < y1 or position.y > y2 then return false end
		if position.z < z1 or position.z > z2 then return false end
		return true
	end
	for ref in cell:iterateReferences() do
		if ref.sourceMod and ref.sourceMod:lower() == "beautiful cities of morrowind.esp" then
			if isInBox(ref.position, -24280, -24010, -11390, -11140, 1300, 1340) then if not isWhitelisted(ref.baseObject) then ref.position = ref.position + tes3vector3.new(0, 0, offset) end end
		end
	end
	tes3.player.data.MyManor.oldFurnitureExteriorMoved = true
end
local function drawLavaSquares(cell, basePos, countx, county)
	for x = 1, countx, 1 do
		for y = 1, county, 1 do
		local position = tes3vector3.new(basePos.x + ((x - 1) * 512), basePos.y - ((y - 1) * 512), basePos.z)
		tes3.createReference{
		object = "in_lava_blacksquare",
		position = position,
		cell = cell
		}
		end
	end
end
---@param cell tes3cell
function MyManor.moveOldFurniture(cell, offset)
	for ref in cell:iterateReferences() do if not isWhitelisted(ref.baseObject) then ref.position = ref.position + tes3vector3.new(offset, 0, 0) end end
	tes3.player.data.MyManor.oldFurnitureMoved = true
end

---@param e cellChangedEventData
local function cellChanged(e)
	local journalIndex = tes3.getJournalIndex({ id = "jsmk_mm" })
	if not journalIndex then return end
	if journalIndex < 20 then return end
	-- bought the manor
	local cellName = e.cell.editorName
	if cellName == "Balmora (-3, -2)" then MyManor.replaceDoorLocks(e.cell) end
	if cellName == "Balmora, Hlaalo Manor" then
		if not tes3.player.data.MyManor.ownershipTransferred then
			MyManor.deleteRalenHlaalo()
			MyManor.transferOwnership(e.cell)
			MyManor.tidyUp(e.cell)
		end
		if not tes3.player.data.MyManor.cellCanRest then MyManor.canRest(e.cell) end
	end
	if journalIndex < 30 then return end
	-- empty the manor
	if cellName == "Balmora (-3, -2)" and not tes3.player.data.MyManor.oldFurnitureExteriorMoved then MyManor.moveOldFurnitureExterior(e.cell, -1536) end
	if cellName == "Balmora, Hlaalo Manor" and not tes3.player.data.MyManor.oldFurnitureMoved then 
		MyManor.moveOldFurniture(e.cell, 2036) 
		drawLavaSquares(e.cell, tes3vector3.new(1400.33, 601.247, 1389.21), 5, 5)
	end
end

event.register("initialized", function()
	event.register("loaded", function()
		tes3.player.data.MyManor = tes3.player.data.MyManor or
		                           {
			doorLocksReplaced = false,
			ownershipTransferred = false,
			oldFurnitureMoved = false,
			oldFurnitureExteriorMoved = false,
			cellCanRest = false,
			displayName = "Balmora, Hlaalo Manor",
		}
	end)
	event.register("cellChanged", cellChanged)
	-- MyManor.planner = require("JosephMcKean.MyManor.planner")
	event.register("UIEXP:sandboxConsole", function(e) e.sandbox.MyManor = MyManor end)
end)

return MyManor
