local G = {}	local COL = {}	local MPR = {}
local p, mp, pp

local function SPELLRESIST(e)	local sn = e.sourceInstance.serialNumber	local Mpr = MPR[sn]
	if Mpr and e.effect.radius > 3 then		local t = e.target	local m = t.mobile
		if not Mpr[t] then
			if t == p then Mpr[t] = (tes3.testLineOfSight{position1 = COL[sn], position2 = pp, height2 = G.mph*0.5} or tes3.testLineOfSight{position1 = COL[sn], position2 = pp, height2 = G.mph*0.9}) and 1 or 0
			else Mpr[t] = tes3.testLineOfSight{position1 = COL[sn], position2 = t.position, height2 = m.height*0.7} and 1 or 0 end
			--tes3.messageBox("Spell resist   %s   %s", t, Mpr[t])
		end
		if Mpr[t] == 0 then e.resistedPercent = 100		if tes3.getCurrentAIPackageId(m) == 3 then m.friendlyFireHitCount = math.max(m.friendlyFireHitCount - 1, 0) end		return end
	end
end		event.register("spellResist", SPELLRESIST)


local function MOBILEACTIVATED(e) local m = e.mobile	if m then	local si = m.spellInstance
	if si then MPR[si.serialNumber] = {} end
end end		event.register("mobileActivated", MOBILEACTIVATED)


local function PROJECTILEEXPIRE(e) local pm = e.mobile	local si = pm.spellInstance
	if si then COL[si.serialNumber] = pm.position:copy() end
end		event.register("projectileExpire", PROJECTILEEXPIRE)


local function loaded(e) p = tes3.player	 mp = tes3.mobilePlayer		pp = p.position		G.mph = mp.height		COL = {}	MPR = {}
	tes3.findGMST("sMagicPCResisted").value = ""	tes3.findGMST("sMagicTargetResisted").value = ""
end		event.register("loaded", loaded)