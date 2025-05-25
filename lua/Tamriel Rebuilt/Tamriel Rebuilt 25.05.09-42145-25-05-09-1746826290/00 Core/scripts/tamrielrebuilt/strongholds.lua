local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')

if core.API_REVISION < 51 then
	print('Updating TR strongholds in distant land requires a newer version of OpenMW')
	return
end

local strongholds = {
	-- Nav Andaram
	{
		global = 'tr_m7_nva_buildstage',
		cells = {
			{ 8, -34 },
			{ 9, -33 },
			{ 9, -34 }
		},
		scripts = {
			{
				id = 'tr_m7_nva_stage0',
				visible = { lt = 1 }
			},
			{
				id = 'tr_m7_nva_stage1',
				visible = { eq = 1 }
			},
			{
				id = 'tr_m7_nva_stage1_2',
				visible = { gt = 0, lt = 3 }
			},
			{
				id = 'tr_m7_nva_stage1_3',
				visible = { gt = 0, lt = 4 }
			},
			{
				id = 'tr_m7_nva_stage1_4',
				visible = { gt = 0, lt = 5 }
			},
			{
				id = 'tr_m7_nva_stage1_4_np',
				visible = { gt = 0, lt = 5 }
			},
			{
				id = 'tr_m7_nva_stage2_0',
				visible = { lt = 3 }
			},
			{
				id = 'tr_m7_nva_stage2_3',
				visible = { gt = 1, lt = 4 }
			},
			{
				id = 'tr_m7_nva_stage2_persist',
				visible = { gt = 1 }
			},
			{
				id = 'tr_m7_nva_stage3',
				visible = { eq = 3 }
			},
			{
				id = 'tr_m7_nva_stage3_np',
				visible = { eq = 3 }
			},
			{
				id = 'tr_m7_nva_stage4_0',
				visible = { lt = 5 }
			},
			{
				id = 'tr_m7_nva_stage4_persist',
				visible = { gt = 3 }
			},
			{
				id = 'tr_m7_nva_stage4_persist_banner',
				visible = { gt = 3 }
			},
			{
				id = 'tr_m7_nva_stage5',
				visible = { eq = 5 }
			},
			{
				id = 'tr_m7_nva_stage5_np',
				visible = { eq = 5 }
			},
			{
				id = 'tr_m7_nva_stage6_0',
				visible = { lt = 7 }
			},
			{
				id = 'tr_m7_nva_stage6_persist',
				visible = { gt = 5 }
			},
			{
				id = 'tr_m7_nva_stage7',
				visible = { eq = 7 }
			},
			{
				id = 'tr_m7_nva_stage7_np',
				visible = { eq = 7 }
			},
			{
				id = 'tr_m7_nva_stage8_persist',
				visible = { gt = 7 }
			},
			{
				id = 'tr_m7_nva_stage9_persist',
				visible = { gt = 8 }
			}
		}
	},
	-- Omaynis, The Kwama's Scuttle
	{
		global = 'tr_m4_oma_innstage',
		cells = {
			{ -7, -16 }
		},
		scripts = {
			{
				id = 'tr_m4_omaynisinn_c2',
				visible = { eq = 2 }
			},
			{
				id = 'tr_m4_omaynisinn_d1',
				visible = { lt = 1 }
			},
			{
				id = 'tr_m4_omaynisinn_d2',
				visible = { lt = 2 }
			},
			{
				id = 'tr_m4_omaynisinn_e1',
				visible = { eq = 1 }
			},
			{
				id = 'tr_m4_omaynisinn_e2',
				visible = { gt = 1 }
			},
			{
				id = 'tr_m4_omaynisinn_e3',
				visible = { gt = 2 }
			},
			{
				id = 'tr_m4_omaynisinnbanner_script',
				visible = { gt = 2 }
			}
		}
	},
	-- Firemoth + Sulfurwatch
	{
		global = 'tr_fm_glob_state',
		cells = {
			{ -3, -14 },
			{ -8, -9 },
			{ -8, -10 },
			{ -8, -11 },
			{ -9, -11 }
		},
		scripts = {
			{
				id = 'tr_fm_stage3perm_sc',
				visible = { gt = 2 }
			},
			{
				id = 'tr_fm_stage5perm_sc',
				visible = { gt = 4 }
			},
			{
				id = 'tr_fm_stage5rubble_sc',
				visible = { lt = 5 }
			},
			{
				id = 'tr_fm_stage5scaffold_sc',
				visible = { gt = 4, lt = 7 }
			},
			{
				id = 'tr_fm_stage7perm_sc',
				visible = { gt = 6 }
			},
			{
				id = 'tr_fm_stage7rubble_sc',
				visible = { lt = 7 }
			},
			{
				id = 'tr_fm_stage8perm_sc',
				visible = { gt = 7 }
			},
			{
				id = 'tr_fm_stage8rubble_sc',
				visible = { lt = 8 }
			}
		}
	}
}

-- Scripted types that show up in distant land
local scriptedTypes = {
	types.Activator, types.Container, types.Door
}

local function isActive(x, y)
	for _, player in pairs(world.players) do
		if player.cell.isExterior then
			local dX = math.abs(player.cell.gridX - x)
			local dY = math.abs(player.cell.gridY - y)
			if dX <= 1 and dY <= 1 then
				return true
			end
		end
	end
	return false
end

local function updateCell(coords, visibility)
	if isActive(coords[1], coords[2]) then
		return false
	end
	local cell = world.getExteriorCell(coords[1], coords[2])
	for _, t in pairs(scriptedTypes) do
		for _, object in pairs(cell:getAll(t)) do
			local scriptId = t.record(object).mwscript
			local visible = visibility[scriptId]
			if visible ~= nil and visible ~= object.enabled then
				object.enabled = visible
			end
		end
	end
	return true
end

local function isVisible(rules, value)
	if rules.eq ~= nil and value ~= rules.eq then
		return false
	end
	if rules.lt ~= nil and value >= rules.lt then
		return false
	end
	if rules.gt ~= nil and value <= rules.gt then
		return false
	end
	return true
end

local function updateStronghold(stronghold, currentValue)
	-- Always finish any pending coroutines to maintain consistency
	if stronghold.coroutine ~= nil and coroutine.status(stronghold.coroutine) ~= 'dead' then
		local status, err = coroutine.resume(stronghold.coroutine)
		if status == false then
			print(err)
			return false
		end
		return true
	end
	if currentValue ~= stronghold.value then
		-- Create a new coroutine that will start execution on the next frame
		stronghold.coroutine = coroutine.create(function()
			local visibility = {}
			for _, script in pairs(stronghold.scripts) do
				visibility[script.id] = isVisible(script.visible, currentValue)
			end
			local done = false
			while done ~= true do
				coroutine.yield()
				done = true
				for _, coords in pairs(stronghold.cells) do
					if updateCell(coords, visibility) then
						coroutine.yield()
					else
						done = false
					end
				end
			end
			stronghold.value = currentValue
		end)
	end
	return false
end

local function updateStrongholds()
	-- Stronghold construction states should be shared between all players,
	-- as such we use the first player's globals and assume they match the others'
	local globals = world.mwscript.getGlobalVariables(world.players[1])
	for _, stronghold in pairs(strongholds) do
		local currentValue = globals[stronghold.global]
		local stop = updateStronghold(stronghold, currentValue)
		if stop then
			return -- Update at most one stronghold per frame
		end
	end
end

local function saveState()
	local out = {}
	for _, stronghold in pairs(strongholds) do
		out[stronghold.global] = stronghold.value
	end
	return out
end

local function loadState(saved)
	if saved == nil then
		return
	end
	for global, value in pairs(saved) do
		for _, stronghold in pairs(strongholds) do
			if stronghold.global == global then
				stronghold.value = value
				break
			end
		end
	end
end

return {
	engineHandlers = {
		onSave = saveState,
		onLoad = loadState,
		onUpdate = updateStrongholds
	}
}