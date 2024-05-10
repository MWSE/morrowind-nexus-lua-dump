local cf = mwse.loadConfig("Rag n'wahs", {ragang = -45, mult = 1, minimp = 500, maximp = 1500})
local L = {
AG = {[34] = "KO", [35] = "KO"},
}
local p, mp

local WT = {
[3]={s=4,impm=2},
[4]={s=4,impm=2},
[5]= {s=4,impm=2},
[6]={s=7,impm=1.5},
[7]={s=6,impm=1.5},
[8]={s=6,impm=1.5}
}

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Rag n'wahs")	tpl:saveOnClose("Rag n'wahs", cf)	tpl:register()		local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createSlider{label = "Minimum impulse", min = 200, max = 500, step = 50, jump = 100, variable = var{id = "minimp", table = cf}}
p0:createSlider{label = "Maximum impulse", min = 500, max = 3000, step = 100, jump = 500, variable = var{id = "maximp", table = cf}}
p0:createDecimalSlider{label = "Impulse multiplier based on damage", min = 0.2, max = 5, variable = var{id = "mult", table = cf}}
p0:createSlider{label = "Slash strikes impulse angle (minus = left, plus = right, 0 = straight). Requires loading a save", min = -60, max = 60, step = 5, jump = 15, variable = var{id = "ragang", table = cf}}
end		event.register("modConfigReady", registerModConfig)


local function DAMAGE(e) if e.source == "attack" then	local t = e.mobile	local DMG = e.damage
	if t.health.current - DMG < 1 then
		if not L.AG[t.actionData.currentAnimationGroup] then
			local a = e.attacker	local ar = e.attackerReference	local tr = e.reference
			local rw = a.readiedWeapon		local pr = e.projectile	
			local w = pr and pr.firingWeapon or (rw and rw.object)	local wt = w and w.type or -1			
			
			local hgt = (t.actorType ~= 0 or t.object.biped) and 100 or math.max(t.height, 50)
			local pow = math.clamp(DMG * cf.mult * 1000 * (WT[wt] and WT[wt].impm or 1) / hgt, cf.minimp, cf.maximp)
			local vdir = pr and pr.velocity:copy() or tr.position - ar.position		--tr.position - (pr or ar).position
			if pow > 501 and a.actionData.physicalAttackType == 1 and cf.ragang ~= 0 then vdir = L.MatrRag * vdir end
			vdir.z = 0		vdir = vdir:normalized()		vdir.z = 0.3
			t:doJump{velocity = vdir * pow, applyFatigueCost = false, allowMidairJumping = true}
		
		--	tes3.messageBox("hgt = %s, pow = %s", hgt, pow)
		end
	end
end end		event.register("damage", DAMAGE, {priority = 90000})


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer
	L.MatrRag = tes3matrix33.new() 	L.MatrRag:toRotationZ(math.rad(cf.ragang))
end		event.register("loaded", loaded)