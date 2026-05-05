local sheltersByCellKey = require("Uninstall Rain Sheltering.shelter_locations")

local function isExteriorCell(cell)
    return cell and cell.isOrBehavesAsExterior == true
end

local function hasCellShelters(cell)
	return sheltersByCellKey[cell.id] ~= nil
end

local function canCellBeSheltered(cell)
	return isExteriorCell(cell) and hasCellShelters(cell)
end

local function teleportNpcToOrigin(npc, data)
	npc.position = data.origin
	npc.facing = data.originFacing
end

local function restoreOriginBehavior(npc, data)
    if npc.mobile then
        tes3.setAIWander({
            reference = npc.mobile,
            idles = data.originIdles,
            range = data.range,
            duration = data.duration,
            time = data.time,
            reset = true
        })
    end
end

local function onCellActivated(e)
    local cell = e.cell
    if canCellBeSheltered(cell) then
        for npc in cell:iterateReferences(tes3.objectType.npc) do
            local data = npc.data.rainShelter
            if data then
                data.origin = tes3vector3.new(data.origin.x, data.origin.y, data.origin.z)
                teleportNpcToOrigin(npc, data)
	            restoreOriginBehavior(npc, data)
                npc.data.rainShelter = nil
            end
        end
    end
end
event.register("cellActivated", onCellActivated)

local function onLoaded()
    tes3.player.data.rainShelter = nil
end
event.register("loaded", onLoaded)