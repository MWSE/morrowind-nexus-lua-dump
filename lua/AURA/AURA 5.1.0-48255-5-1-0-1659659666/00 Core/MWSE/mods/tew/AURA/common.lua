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
}

-- String bit to match against window object ids --
this.windows = {
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

return this
