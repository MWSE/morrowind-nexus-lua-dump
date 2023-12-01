local cf = mwse.loadConfig("Eternal Shine", {radmult = 0.3, int = 0.3, ext = 0.5, rain = 0.75, fog = 1, storm = 1.25, mind = 10000, maxd = 20000})

local function registerModConfig()		local template = mwse.mcm.createTemplate("Eternal Shine")	template:saveOnClose("Eternal Shine", cf)	template:register()		local p0 = template:createPage()	local var = mwse.mcm.createTableVariable
p0:createDecimalSlider{label = "Ligts radius multiplier", variable = var{id = "radmult", table = cf}}
p0:createDecimalSlider{label = "Fog density for lights in interiors", variable = var{id = "int", table = cf}}
p0:createDecimalSlider{label = "Fog density for lights in exteriors (normal weather)", variable = var{id = "ext", table = cf}}
p0:createDecimalSlider{label = "Fog density for lights in rainy weather", max = 2, variable = var{id = "rain", table = cf}}
p0:createDecimalSlider{label = "Fog density for lights in foggy weather", max = 3, variable = var{id = "fog", table = cf}}
p0:createDecimalSlider{label = "Fog density for lights in snow or ash storm", max = 3, variable = var{id = "storm", table = cf}}
p0:createSlider{label = "The distance at which the light intensity becomes maximum", min = 0, max = 25000, step = 100, jump = 1000, variable = var{id = "mind", table = cf}}
p0:createSlider{label = "The distance at which the light intensity becomes 0. This value must be higher than the previous one", min = 0, max = 25000, step = 100, jump = 1000, variable = var{id = "maxd", table = cf}}
end		event.register("modConfigReady", registerModConfig)


local S1, S2, pp, wind		local L = {}
local WK = {[0] = "ext", [1] = "ext", [2] = "fog", [3] = "ext", [4] = "rain", [5] = "rain", [6] = "storm", [7] = "storm", [8] = "storm", [9] = "storm", [10] = "int"}

local OBT = {
--[tes3.objectType.static] = true,
--[tes3.objectType.container] = true,
--[tes3.objectType.creature] = true,
[tes3.objectType.light] = true,
[tes3.objectType.npc] = true}

local function referenceActivated(e) local r = e.reference	local bo = r.baseObject
	if OBT[bo.objectType] and not r.disabled and bo.mesh ~= "" then L[e.reference] = {} end
end		event.register("referenceActivated", referenceActivated)

local function referenceDeactivated(e)
	L[e.reference] = nil
end		event.register("referenceDeactivated", referenceDeactivated)


local function getLightDataFromReference(r)
	local d = {}

	local lightAttachment = r:getAttachedDynamicLight()
	d.light = lightAttachment and lightAttachment.light
	if not d.light then return end
	
	d.radius = r.object.radius
	if d.radius then d.radius = math.min(d.radius, 512)
	else local mob = r.mobile
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
	d.OnScreen = tes3.worldController.worldCamera.camera:worldPointToScreenPoint(d.pos) ~= nil
	return d
end

local function Sorter(a, b) return a.dist < b.dist end


local function simulate()	local L1 = {}	local L2 = {}			local A = {}	local B = {}
	for r, _ in pairs(L) do
		local LD = getLightDataFromReference(r)
		if LD then table.insert(LD.OnScreen and L1 or L2, LD) end
	end
	table.sort(L1, Sorter)	table.sort(L2, Sorter)	local num1 = #L1	local num2 = #L2		local num = num1 + num2		local ind	local d
	for i, ld in ipairs(L2) do L1[num1 + i] = ld end
	
	
	if num > 0 then		--tes3.messageBox("%s/%s  dist = %d / %d    wind = %.2f", num1, num, L1[num1] and L1[num1].dist or 0, L1[num] and L1[num].dist or 0, cf[WK[wind]])
		for i = 1, 25 do ind = (i-1)*8		d = L1[i]
			A[ind + 1] = d and d.pos.x or 0
			A[ind + 2] = d and d.pos.y or 0
			A[ind + 3] = d and d.pos.z or 0
			A[ind + 4] = d and d.radius * cf.radmult or 0
			A[ind + 5] = d and d.diffuse.r or 0
			A[ind + 6] = d and d.diffuse.g or 0
			A[ind + 7] = d and d.diffuse.b or 0
			A[ind + 8] = d and d.light.dimmer * cf[WK[wind]] * d.distk or 0
		end
		S1.A = A	if not S1.enabled then S1.enabled = true end
		
	if num > 25 then
		for i = 26, 50 do ind = (i-1)*8 - 200		d = L1[i]
			B[ind + 1] = d and d.pos.x or 0
			B[ind + 2] = d and d.pos.y or 0
			B[ind + 3] = d and d.pos.z or 0
			B[ind + 4] = d and d.radius * cf.radmult or 0
			B[ind + 5] = d and d.diffuse.r or 0
			B[ind + 6] = d and d.diffuse.g or 0
			B[ind + 7] = d and d.diffuse.b or 0
			B[ind + 8] = d and d.light.dimmer * cf[WK[wind]] * d.distk or 0
		end
		S2.A = B	if not S2.enabled then S2.enabled = true end
	elseif S2.enabled then S2.enabled = false end
		
	else	if S1.enabled then S1.enabled = false end	if S2.enabled then S2.enabled = false end		end

	--[[
	for i, d in ipairs(L1) do
		if i > 50 then break else
			if i < 26 then	ind = (i-1)*8
				A[ind + 1] = d.position.x
				A[ind + 2] = d.position.y
				A[ind + 3] = d.position.z
				A[ind + 4] = d.radius * cf.radmult
				A[ind + 5] = d.light.diffuse.r
				A[ind + 6] = d.light.diffuse.g
				A[ind + 7] = d.light.diffuse.b
				A[ind + 8] = d.light.dimmer * cf.ext				
			else	ind = (i-1)*8 - 200
				B[ind + 1] = d.position.x
				B[ind + 2] = d.position.y
				B[ind + 3] = d.position.z
				B[ind + 4] = d.radius * cf.radmult
				B[ind + 5] = d.light.diffuse.r
				B[ind + 6] = d.light.diffuse.g
				B[ind + 7] = d.light.diffuse.b
				B[ind + 8] = d.light.dimmer * cf.ext
			end
		end
	end
	S1.A = A	S2.A = B

	num = num > 25		if S2.enabled ~= num then S2.enabled = num end
	--]]
	
	
end		event.register("simulate", simulate)



local function cellChanged(e)
	wind = e.cell.isOrBehavesAsExterior and tes3.getCurrentWeather().index or 10
end		event.register("cellChanged", cellChanged)


local function loaded(e)	pp = tes3.player.position		S1 = mge.shaders.find{name = "Eternal Shine 1"}		S2 = mge.shaders.find{name = "Eternal Shine 2"}
	--for i, d in pairs(S.variables) do mwse.log("%s %s", i, d) end
end		event.register("loaded", loaded)