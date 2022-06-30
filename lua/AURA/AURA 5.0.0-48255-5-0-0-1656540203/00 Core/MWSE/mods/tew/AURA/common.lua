local this={}

local config = require("tew.AURA.config")
local debugLogOn = config.debugLogOn
local modversion = require("tew.AURA.version")
local version = modversion.version

function this.debugLog(string)
    if debugLogOn then
        local info = debug.getinfo(2, "Sl")
        local module = info.short_src:match("^.+\\(.+).lua$")
        local prepend = ("[AURA.%s.%s:%s]:"):format(version, module, info.currentline)
        local aligned = ("%-36s"):format(prepend)
        mwse.log(aligned.." -- "..string.format("%s", string))
    end
end

this.thunArray={
	"Thunder0",
	"Thunder1",
	"Thunder2",
	"Thunder3",
	"ThunderClap"
}

this.cellTypesSmall={
	"in_de_shack_",
	"s12_v_plaza",
	"rp_v_arena",
	"in_nord_house_04",
	"in_nord_house_02",
	"t_rea_set_i_house_"
}

this.cellTypesTent={
	"in_ashl_tent_0",
	"drs_tnt",
}

--[[this.cellTypesCaves={
"cave",
"sewer",
"grotto",
}]]

this.windows={
	"_win_",
	"window",
	"cwin",
	"wincover",
	"swin",
	"palacewin",
	"triwin",
	"_windowin_"
}

-- Getting region on loaded save in interior. Taken from Provincial Music --
function this.getInteriorRegion(cell)
	for ref in cell:iterateReferences(tes3.objectType.door) do
		if (ref.destination) then
			if (ref.destination.cell.region) then
				return ref.destination.cell.region.name
			end
		end
	end
end

function this.checkCellDiff(cell, cellLast)
	if (cellLast==nil) then return true end
	if (cell.isInterior) and (not cellLast.isInterior)
	or (cell.isInterior) and (cellLast.isInterior)
	or (not cell.isInterior) and (cellLast.isInterior)
	or (cell.isInterior) and (cellLast.behavesAsExterior)
	or (cell.behavesAsExterior) and (not cellLast.behavesAsExterior) then
		return true
	end
	--[[if cell.name ~= nil then
	for _, name in pairs(this.cellTypesCaves) do
		if string.find(cell.name:lower(), name) then
			return true
		end
	end
end]]
return false
end

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
	
	if #windoors == 0 then
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

function this.getDistance(v0, v1)
	local dx=v1.x-v0.x
	local dy=v1.y-v0.y
	local dz=v1.z-v0.z
	return math.sqrt(dx*dx+dy*dy+dz*dz)
end

return this