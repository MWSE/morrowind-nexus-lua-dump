local cf = mwse.loadConfig("Buff Bars", {slx = 1905, sly = 7, BBred = 5, BBgr = 30, BBhor = true, BBreo = true, nomic = false})
local L = {}	local M = {BB = {}}		local p, mp

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Buff Bars")	tpl:saveOnClose("Buff Bars", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Position X", min = 0, max = 1920, step = 1, jump = 10, variable = var{id = "slx", table = cf}}
p0:createSlider{label = "Position Y", min = 0, max = 1080, step = 1, jump = 10, variable = var{id = "sly", table = cf}}
p0:createSlider{label = "Red time", min = 1, max = 30, step = 1, jump = 5, variable = var{id = "BBred", table = cf}}
p0:createSlider{label = "Green time", min = 10, max = 300, step = 1, jump = 5, variable = var{id = "BBgr", table = cf}}
p0:createYesNoButton{label = "Horizontal arrangement", variable = var{id = "BBhor", table = cf}}
p0:createYesNoButton{label = "Filling from right to left", variable = var{id = "BBreo", table = cf}}
p0:createYesNoButton{label = "Hide small magic effect icons", variable = var{id = "nomic", table = cf}}
end		event.register("modConfigReady", registerModConfig)

L.NoBorder = function(el, x) el.contentPath = "meshes\\menu_thin_border_0.nif"	if not x then el:findChild("PartFillbar_colorbar_ptr").borderAllSides = 0 end end

L.NewBB = function(id, ic, dur, sn)		local B = M.BB[id]
	if not B then M.BB[id] = {}		B = M.BB[id]
		B.bl = M.BBM:createBlock{}	B.bl.autoHeight = true	B.bl.autoWidth = true	B.bl.flowDirection = "top_to_bottom"	if cf.BBreo then M.BBM:reorderChildren(0, B.bl, 1) end
		B.ic = B.bl:createImage{path = "icons\\" .. ic}		B.ic.borderAllSides = 3
	end	
	B[sn] = B.bl:createFillBar{current = dur, max = dur}	local bar = B[sn]	bar.width = 38	bar.height = 5	bar.borderBottom = 1	local bw = bar.widget	bw.showText = false		L.NoBorder(bar)
	local N = math.remap(dur, cf.BBred, cf.BBgr, 0, 1)		bw.fillColor = {2-N*2, N*2, N-1}
end

local function spellResist(e)	if e.target == p then	local ef = e.effect		local dur = ef.duration	if dur > 1 and e.resistedPercent < 100 then
	L.NewBB(ef.id, ef.object.bigIcon, dur, e.sourceInstance.serialNumber * 10 + e.effectIndex)
end end	end		event.register("spellResist", spellResist, {priority = -1000})

local function magicEffectRemoved(e) if e.reference == p then	local id = e.effect.id		local B = M.BB[id]	local sn = e.sourceInstance.serialNumber * 10 + e.effectIndex
	if B and B[sn] then B[sn]:destroy()	B[sn] = nil		if table.size(B) == 2 then	B.bl:destroy()	M.BB[id] = nil end end
end end		event.register("magicEffectRemoved", magicEffectRemoved)

local function loaded(e)	p = tes3.player		mp = tes3.mobilePlayer		M.BB = {}	local MU = tes3ui.findMenu("MenuMulti")		local dur
if cf.nomic then MU:findChild("MenuMulti_magic_icons_layout").visible = false end
M.BBM = MU:createBlock{}	if not cf.BBhor then M.BBM.flowDirection = "top_to_bottom" end
M.BBM.autoWidth = true		M.BBM.autoHeight = true		M.BBM.absolutePosAlignX = cf.slx/1920		M.BBM.absolutePosAlignY = cf.sly/1080		M.BBM.borderAllSides = 7
for _, aef in pairs(mp:getActiveMagicEffects{}) do dur = aef.duration	if dur > 1 and aef.effectInstance.timeActive < dur then
L.NewBB(aef.effectId, tes3.getMagicEffect(aef.effectId).bigIcon, dur, aef.serial * 10 + aef.effectIndex) end end

timer.start{duration = 1, iterations = -1, callback = function() if table.size(M.BB) > 0 then local N	for _, aef in pairs(mp:getActiveMagicEffects{}) do	local B = M.BB[aef.effectId]	if B then
	local bar = B[aef.serial * 10 + aef.effectIndex]
	if bar then local bw = bar.widget	bw.current = bw.max - aef.effectInstance.timeActive		N = math.remap(bw.current, cf.BBred, cf.BBgr, 0, 1)		bw.fillColor = {2-N*2, N*2, N-1} end
end end end end}
end		event.register("loaded", loaded)