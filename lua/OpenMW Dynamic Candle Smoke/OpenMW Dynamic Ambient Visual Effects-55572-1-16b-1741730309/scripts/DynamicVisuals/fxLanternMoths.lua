local common = common
local types = common.openmw.types
local core = common.openmw.core
local world = common.openmw.world

local vectors = require("scripts.DynamicVisuals.configLanternMoths")
local targets = {}		local opt = { useAmbientLight=false }

local self = { common = common }
local devMode = common.devMode		local player = common.player
local debug = common.debug

function self.onPlayerAdded(e)		player = e		end

function self.onObjectActive(o)
	local r = o.type.records[o.recordId]
	if r.isOffByDefault then return			end
	if not o.cell.isExterior and not o.cell:hasTag("QuasiExterior") then	return		end
	local model = r.model or ""

	-- bugfix for OMW versions before Nov 19 2024
	model = model:lower()		model = string.gsub(model, "\\", "/")

	local i, j = string.find(model, "/[^/]*$")
	if i then model = string.sub(model, i+1, j)		end

	local vec = vectors[model]
	if not vec then		return			end

	local new = true
	for i = 1, #targets do
		if targets[i].ref == o then
			new = false
			-- print("SKIPPED", o)
		end
	end
	if not new then		return		end

	local position = o.position	position = position + o.rotation:apply(vec * o.scale)
	targets[#targets + 1] = { ref=o, timer=1, pos=position }
--	debug("MOTH REG "..o.recordId)

end

function self.updateNearby(list)
	if #targets == 0 then		return		end
--	print("MOTHS updateNearby "..(#targets))
	local active = {}
	for i = 1, #list do	active[list[i].id] = true		end
	for i = #targets, 1, -1 do
		local v = targets[i]
		if not active[v.ref.id] then
			debug("REMOVE "..v.ref.recordId)
			table.remove(targets, i)
		end
	end
end

function self.refreshVfx(list)
	targets = {}		if not list then	return		end
	for i = 1, #list do	self.onObjectActive(list[i])		end
end

function self.listVfx()
	for _, v in ipairs(targets) do print(v.ref.recordId) end
end

local timer = 0			local phase = 1			local chance = 50

function self.onUpdate(dt)
	if not player or #targets == 0 then	return		end

	local doVfx = common.isNight and common.weather < 4
	timer = timer + dt		local reScan
	for _, v in ipairs(targets) do
		local cell = v.ref.cell
		if not cell:isInSameSpace(player) then
			reScan = true
			break
		end
		if doVfx then v.timer = v.timer - 1			end
		if doVfx and v.timer < 1 then
			v.timer = 60
--			chance = chance + common.mothChance
--			if chance > 50 then
			if math.random(100) < common.mothChance then
				world.vfx.spawn(common.mothLod .. phase .. ".nif", v.pos, opt)
				phase = phase + 1	if phase > 3 then phase = 1	end
				debug("MOTHS "..v.ref.recordId)
--				chance =  chance - 100
			end
		end
	end
	if timer < 10 then timer = 0			end
	if not reScan then 		return		end
	debug("GETNEARBY moths "..(#targets))
	player:sendEvent("dcsGetNearby", "lightsMoths")
end


return self
