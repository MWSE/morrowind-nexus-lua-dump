local cf = mwse.loadConfig("Eternal Shine", {N = 80, pl = false, radmult = 0.3, int = 0.3, ext = 0.5, rain = 0.75, fog = 1, storm = 1.25, mind = 10000, maxd = 20000})

local function registerModConfig() local tpl = mwse.mcm.createTemplate("Eternal Shine")	tpl:saveOnClose("Eternal Shine", cf)	tpl:register()		local p0 = tpl:createPage()	local var = mwse.mcm.createTableVariable
p0:createSlider{label = "Maximum light sources (reduce if there is a fps drop)", min = 0, max = 80, step = 1, jump = 5, variable = var{id = "N", table = cf}}
p0:createDecimalSlider{label = "Ligts radius multiplier", variable = var{id = "radmult", table = cf}}
p0:createDecimalSlider{label = "Fog density for lights in interiors", variable = var{id = "int", table = cf}}
p0:createDecimalSlider{label = "Fog density for lights in exteriors (normal weather)", variable = var{id = "ext", table = cf}}
p0:createDecimalSlider{label = "Fog density for lights in rainy or snowy weather", max = 2, variable = var{id = "rain", table = cf}}
p0:createDecimalSlider{label = "Fog density for lights in foggy weather", max = 3, variable = var{id = "fog", table = cf}}
p0:createDecimalSlider{label = "Fog density for lights in snow or ash storm", max = 3, variable = var{id = "storm", table = cf}}
--p0:createSlider{label = "The distance at which the light intensity becomes maximum", min = 0, max = 25000, step = 100, jump = 1000, variable = var{id = "mind", table = cf}}
--p0:createSlider{label = "The distance at which the light intensity becomes 0. This value must be higher than the previous one", min = 0, max = 25000, step = 100, jump = 1000, variable = var{id = "maxd", table = cf}}
p0:createYesNoButton{label = "Affect player's lights", variable = var{id = "pl", table = cf}}
end		event.register("modConfigReady", registerModConfig)


local S, p, pp, wind, Cam, wc		local R = {}		local V0 = tes3vector4.new()		--local Tim = timer
local WK = {[0] = "ext", [1] = "ext", [2] = "fog", [3] = "ext", [4] = "rain", [5] = "rain", [6] = "storm", [7] = "storm", [8] = "rain", [9] = "storm", [10] = "int"}

local OBT = {
--[tes3.objectType.static] = true,
--[tes3.objectType.container] = true,
--[tes3.objectType.creature] = true,
[tes3.objectType.light] = true,
[tes3.objectType.npc] = true
}

local function referenceActivated(e) local r = e.reference	local ob = r.object
	if OBT[ob.objectType] and not r.disabled and ob.mesh ~= "" then
		local lig = r:getAttachedDynamicLight()		
		if lig then
			lig = lig.light
			local pos = lig.worldTransform.translation
			local diffuse = lig.diffuse
			local rad = ob.radius
			if rad then
				if ob.value ~= 40000 then
					R[r] = {lig = lig, pos = pos, v1 = tes3vector4.new(pos.x, pos.y, pos.z, math.min(rad,1000) * cf.radmult), v2 = tes3vector4.new(diffuse.r, diffuse.g, diffuse.b, 0), tim = wc.systemTime}
				end
			--	tes3.messageBox("ACT  %s   rad = %s   value = %s", r, ob.radius, ob.value)
			else	local stack = tes3.getEquippedItem{actor = r, objectType = tes3.objectType.light}
				if stack then
					R[r] = {lig = lig, pos = pos, mob = true, v1 = tes3vector4.new(0, 0, 0, math.min(stack.object.radius,1000) * cf.radmult), v2 = tes3vector4.new(diffuse.r, diffuse.g, diffuse.b, 0), tim = wc.systemTime}
				--	tes3.messageBox("ACT  %s   rad = %s", r, stack.object.radius)
				end
			end
		end
	end
end		event.register("referenceActivated", referenceActivated)

local function referenceDeactivated(e)
	R[e.reference] = nil
end		event.register("referenceDeactivated", referenceDeactivated)


local function equipped(e) local ob = e.item		if ob.objectType == tes3.objectType.light then	local r = e.reference	if cf.pl or r ~= p then
	local lig = r:getAttachedDynamicLight()
	if lig then
		lig = lig.light
		local pos = lig.worldTransform.translation
		local diffuse = lig.diffuse
		R[r] = {lig = lig, pos = pos, mob = true, v1 = tes3vector4.new(0, 0, 0, math.min(ob.radius,1000) * cf.radmult), v2 = tes3vector4.new(diffuse.r, diffuse.g, diffuse.b, 0), tim = wc.systemTime}
		
	--	tes3.messageBox("EQIP  %s   rad = %s ", r, ob.radius)
	end
end end end		event.register("equipped", equipped)

local function unequipped(e) local ob = e.item
	if ob.objectType == tes3.objectType.light then R[e.reference] = nil 
	--	tes3.messageBox("UNEQ   %s   rad = %s", e.reference, ob.radius)
	end
end		event.register("unequipped", unequipped)



--[[
local function getLightDataFromReference(r)
	local d = {}

	local lat = r:getAttachedDynamicLight()
	d.light = lat and lat.light
	if not d.light then return end
	
	d.radius = r.object.radius
	if d.radius then d.radius = math.min(d.radius, 512)
	else local mob = not r.disabled and r.mobile
		if mob then
			local stack = tes3.getEquippedItem{actor = mob, objectType = tes3.objectType.light}
			if stack then d.radius = stack.object.radius end
		end
	end
	if not d.radius then return end
	
	d.pos = d.light.worldTransform.translation
	d.dist = d.pos:distance(pp)
	d.distk = math.clamp(math.remap(d.dist, cf.maxd, cf.mind, 0, 1), 0, 1)		if d.distk == 0 then return end
	d.diffuse = d.light.diffuse
	d.OnScreen = not r.sceneNode:isFrustumCulled(Cam)		--(tes3.worldController.worldCamera.camera:worldPointToScreenPoint(d.pos) ~= nil)		8080 предел дистанции для фрустума
	return d
end

local function Sorter(a, b) return a.dist < b.dist end
--]]


local function simulate()	local L1 = {}	local L2 = {}		local lig		local fog = cf[WK[wind]] --* (1 - (Tim.timeLeft or 0)/2)			
local tim = wc.systemTime
--	if cf.N == 0 then return end
	for r, t in pairs(R) do if not r.disabled then	lig = r:getAttachedDynamicLight()
		if lig then t.lig = lig.light
			if t.mob then
				t.pos = t.lig.worldTransform.translation
				t.v1.x = t.pos.x		t.v1.y = t.pos.y		t.v1.z = t.pos.z 
			end

		--	t.dist = t.pos:distance(pp)
		--	t.distk = math.clamp(math.remap(t.dist, cf.maxd, cf.mind, 0, 1), 0, 1)	
			
		--	if t.distk > 0 then
		--		t.v2.w = t.lig.dimmer * fog * t.distk
				t.v2.w = t.lig.dimmer * fog * math.min((tim - t.tim)/3000, 1)
			--	table.insert(r.sceneNode:isFrustumCulled(Cam) and L2 or L1, t)		-- Предельная дальность 8080
				table.insert(Cam:worldPointToScreenPoint(t.pos) and L1 or L2, t)
		--	end
		end
	end end
	local num1 = #L1	local num2 = #L2	local num = num1 + num2 				--	table.sort(L1, Sorter)	table.sort(L2, Sorter)	
	if num > 0 then		local n = math.min(math.ceil(num/4), cf.N)
		for i, ld in ipairs(L2) do L1[num1 + i] = ld end
		if n*4 > num then for i = 1, n*4 - num do L1[num+i] = {v1 = V0, v2 = V0} end end
		
		--tes3.messageBox("%s/%s  dist = %d / %d    wind = %.2f", num1, num, L1[num1] and L1[num1].dist or 0, L1[num] and L1[num].dist or 0, fog)
		--tes3.messageBox("%s / %s   n = %s    wind = %.2f", num1, num, n, fog)
		
		local A1 = {}	local B1 = {}	local A2 = {}	local B2 = {}	local A3 = {}	local B3 = {}	local A4 = {}	local B4 = {}
		for i, d in ipairs(L1) do
			if i <= n then			A1[i] = d.v1		B1[i] = d.v2
			elseif i <= n*2 then	A2[i-n] = d.v1		B2[i-n] = d.v2		
			elseif i <= n*3 then	A3[i-n*2] = d.v1	B3[i-n*2] = d.v2
			else					A4[i-n*3] = d.v1	B4[i-n*3] = d.v2 end
		end
		S.D = n		S.POS1 = A1		S.COL1 = B1		S.POS2 = A2		S.COL2 = B2		S.POS3 = A3		S.COL3 = B3		S.POS4 = A4		S.COL4 = B4
		if not S.enabled then S.enabled = true end
	elseif S.enabled then S.enabled = false end
end		event.register("simulate", simulate)



local function cellChanged(e)
	wind = e.cell.isOrBehavesAsExterior and tes3.getCurrentWeather().index or 10
--	if e.previousCell then Tim:reset() end
end		event.register("cellChanged", cellChanged)


local function loaded(e)	p = tes3.player		pp = p.position		S = mge.shaders.find{name = "Eternal Shine"}	Cam = tes3.getCamera()
	--Tim = timer.start{duration = 2, callback = function() end}		Tim:cancel()
	--for i, d in pairs(S.variables) do mwse.log("%s %s", i, d) end
end		event.register("loaded", loaded)

local function initialized(e)	wc = tes3.worldController
end		event.register("initialized", initialized)