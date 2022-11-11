local this = {}

local config = require("tew.AURA.config")
local debugLogOn = config.debugLogOn
local modversion = require("tew.AURA.version")
local version = modversion.version

-- Centralised debug message printer --
function this.debugLog(message)
	if debugLogOn then
		local info = debug.getinfo(2, "Sl")
		local module = info.short_src:match("^.+\\(.+).lua$")
		local prepend = ("[AURA.%s.%s:%s]:"):format(version, module, info.currentline)
		local aligned = ("%-36s"):format(prepend)
		mwse.log(aligned .. " -- " .. string.format("%s", message))
	end
end

-- Thunder sound IDs (as seen in the CS) --
this.thunArray = {
	"Thunder0",
	"Thunder1",
	"Thunder2",
	"Thunder3",
	"ThunderClap"
}

-- Small types of interiors --
this.cellTypesSmall = {
	"in_de_shack_",
	"s12_v_plaza",
	"rp_v_arena",
	"in_nord_house_04",
	"in_nord_house_02",
	"t_rea_set_i_house_"
}

-- Tent interiors --
this.cellTypesTent = {
	"in_ashl_tent_0",
	"drs_tnt",
	"_in_drs_tnt_0",
	"a1_dat_srt_in_0", -- Sea Rover's Tent
	"_ser_tent_in", -- On the move - the ashlander tent deluxe remod
	"t_de_set_i_tent_0", -- Tamriel_Data
	"t_orc_setnomad_i_tent_0", -- Tamriel_Data
	"rpnr_in_ashl_tent_0",
	"rpnr_t_de_set_i_tent_0",
	"rpnr_tent_bannered", -- yup, interior
}

-- String bit to match against window object ids --
this.windows = {
	"winkynaret",
	"_win_",
	"window",
	"cwin",
	"wincover",
	"swin",
	"palacewin",
	"triwin",
	"_windowin_"
}

-- Check if transitioning int/ext or the other way around --
function this.checkCellDiff(cell, cellLast)
	if (cellLast == nil) then return true end

	if (cell.isInterior) and (cellLast.isOrBehavesAsExterior)
		or (cell.isOrBehavesAsExterior) and (cellLast.isInterior) then
		return true
	end

	return false
end

-- Pass me the cell and cell type array and I'll tell you if it matches --
function this.getCellType(cell, celltype)
	if not cell.isInterior then
		return false
	end
	for stat in cell:iterateReferences(tes3.objectType.static) do
		for _, pattern in pairs(celltype) do
			if string.startswith(stat.object.id:lower(), pattern) then
				return true
			end
		end
	end
end

-- Return doors and windows objects --
function this.getWindoors(cell)
	local windoors = {}
	for door in cell:iterateReferences(tes3.objectType.door) do
		if door.destination then
			if (not door.destination.cell.isInterior)
				or (door.destination.cell.behavesAsExterior and
					(not string.find(cell.name:lower(), "plaza") and
						(not string.find(cell.name:lower(), "vivec") and
							(not string.find(cell.name:lower(), "arena pit"))))) then
				table.insert(windoors, door)
			end
		end
	end

	if table.empty(windoors) then
		return nil
	else
		for stat in cell:iterateReferences(tes3.objectType.static) do
			if (not string.find(cell.name:lower(), "plaza")) then
				for _, window in pairs(this.windows) do
					if string.find(stat.object.id:lower(), window) then
						table.insert(windoors, stat)
					end
				end
			end
		end
		return windoors
	end
end

-- Pass me a table and an element and I'll tell you the index it's stored at --
function this.getIndex(tab, elem)
	local index = nil
	for i, v in ipairs(tab) do
		if (v == elem) then
			index = i
		end
	end
	return index
end

function this.findMatch(stringArray, str)
	for _, pattern in pairs(stringArray) do
		if string.find(str, pattern) then
			return true
		end
	end
	return false
end

function this.cellIsInterior(cell)
    local cell = cell or tes3.getPlayerCell()
    if cell and
        cell.isInterior and
        (not cell.behavesAsExterior) then
        return true
    else
        return false
    end
end

-- If given a target ref, returns true if origin ref is sheltered by
-- target ref, or false otherwise. If not given a target ref, returns
-- whether origin ref is sheltered at all.
function this.isRefSheltered(options)

    local originRef = options.originRef or tes3.player
	local targetRef = options.targetRef
	local ignoreList = options.ignoreList
	local useModelCoordinates
	local useBackTriangles
	local maxDistance
	local cell = options.cell

    if this.cellIsInterior(cell) then
        return true
    end

	local height = originRef.object.boundingBox
	and originRef.object.boundingBox.max.z or 0

	-- It seems that rayTest returns more accurate results for
	-- tes3.player if using back triangles and better results for
	-- statics when using model coordinates.

	if originRef == tes3.player then
		useModelCoordinates = false
		useBackTriangles = true
		-- Max distance from the player going upwards at which
		-- the ray should stop when testing for a shelter static.
		-- This value could use some more fine-tuning but finding
		-- a goldylocks value for every possible scenario and 3D model
		-- can be rather difficult (if not impossible).
		maxDistance = 300
	else
		useModelCoordinates = true
		useBackTriangles = false
		maxDistance = 500
	end

	this.debugLog("[rayTest] Performing test on origin ref: " .. tostring(originRef))

    local hitResults = tes3.rayTest{
        position = {
            originRef.position.x,
            originRef.position.y,
            originRef.position.z + (height/2)
        },
        direction = {0, 0, 1},
        findAll = true,
        maxDistance = maxDistance,
        ignore = {originRef},
		useModelCoordinates = useModelCoordinates,
        useBackTriangles = useBackTriangles,
    }
    if hitResults then
		this.debugLog("[rayTest] Got results.")
        for _, hit in ipairs(hitResults) do
            if hit and hit.reference and hit.reference.object then
				if (hit.reference.object.objectType == tes3.objectType.static)
				or (hit.reference.object.objectType == tes3.objectType.activator) then
					if ignoreList and this.findMatch(ignoreList, hit.reference.object.id:lower()) then
						this.debugLog("[rayTest] Ignoring result -> " .. hit.reference.object.id:lower())
						goto continue
					end
					if targetRef then
						if (hit.reference.object.id:lower() == targetRef.object.id:lower()) then
							this.debugLog("[rayTest] Matched target ref -> " .. tostring(targetRef))
							return true
						else
							this.debugLog("[rayTest] Did not match target ref -> " .. tostring(targetRef))
							return false
						end
					end
					this.debugLog("[rayTest] Ref " .. tostring(originRef) .. " is sheltered by " .. hit.reference.object.id:lower())
					return true
				end
            end
			:: continue ::
        end
    end
	this.debugLog("[rayTest] Ref " .. tostring(originRef) .. " is NOT sheltered.")
	return false
end

return this
