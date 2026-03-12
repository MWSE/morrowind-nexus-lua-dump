local cf = mwse.loadConfig("Tracers", {noen = false})

local function registerModConfig() local tpl = mwse.mcm.createTemplate("Tracers")	tpl:saveOnClose("Tracers", cf)	tpl:register()		local p0 = tpl:createPage()	local var = mwse.mcm.createTableVariable
	p0:createYesNoButton{label = "Apply glow to unenchanted arrows", variable = var{id = "noen", table = cf}}
end		event.register("modConfigReady", registerModConfig)

local L = {VFXEN = {
[14] = {id = "VFX_arrow_fire", mesh = "e\\arrow_fire.nif"},
[16] = {id = "VFX_arrow_frost", mesh = "e\\arrow_frost.nif"},
[15] = {id = "VFX_arrow_shock", mesh = "e\\arrow_shock.nif"},
[27] = {id = "VFX_arrow_poison", mesh = "e\\arrow_poison.nif"},
[2] = {id = "VFX_arrow_red", mesh = "e\\arrow_red.nif"},
[3] = {id = "VFX_arrow_green", mesh = "e\\arrow_green.nif"},
[4] = {id = "VFX_arrow_blue", mesh = "e\\arrow_blue.nif"}}
}


local function mobileActivated(e)	local m = e.mobile		if m and m.firingMobile and not m.spellInstance then 	local r = e.reference	local pren = r.object.enchantment
	if cf.noen or pren then		local enef = pren and pren.effects[1]
		tes3.createVisualEffect{object = (enef and (L.VFXEN[enef.id] or L.VFXEN[enef.object.school] or L.VFXEN[4]) or L.VFXEN[14]).ob, reference = r}
	end
end end		event.register("mobileActivated", mobileActivated)


local function initialized(e)
	for i, t in pairs(L.VFXEN) do L.VFXEN[i].ob = tes3.createObject{objectType = tes3.objectType.static, id = t.id, mesh = t.mesh}		L.VFXEN[i].lm = tes3.loadMesh(t.mesh) end
end		event.register("initialized", initialized)