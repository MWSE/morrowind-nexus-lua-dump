local messages
local reftarget
local refsource
local wid
local cost


local function onEquipped(e)
	if e.reference == tes3.player and e.item.objectType == tes3.objectType.weapon then
		if e.item.enchantment and e.item.type < 11 and e.item.enchantment.castType == 1 then
			local ind = 0	local sp = tes3.getObject("4nm_spell_enchantstrike")	cost = 0
			for i, eff in ipairs(sp.effects) do eff.id = -1 end
			for i, eff in ipairs(e.item.enchantment.effects) do if eff.rangeType == 2 then
				ind = ind + 1
				sp.effects[ind].id = eff.id
				sp.effects[ind].min = eff.min
				sp.effects[ind].max = eff.max
				sp.effects[ind].duration = eff.duration
				sp.effects[ind].radius = eff.radius
				sp.effects[ind].rangeType = tes3.effectRange.target
			end end
			if sp.effects[1].id > 0 then
				wid = e.item.id
				cost = e.item.enchantment.chargeCost
				if messages then tes3.messageBox("%s Equipped. Charge cost = %.1f", wid, cost) end
			end
		else wid = nil end
	end
end


local function onUnequipped(e)
	if e.reference == tes3.player and e.item.id == wid then wid = nil	if messages then tes3.messageBox("%s Unequipped", e.item.id) end end
end


local function onAttack(e)
	if e.reference == tes3.player and tes3.mobilePlayer.readiedWeapon and tes3.mobilePlayer.readiedWeapon.object.id == wid and tes3.mobilePlayer.readiedWeapon.variables.charge > cost then
		local newcost = cost * (1 - tes3.mobilePlayer.enchant.current / 200)
		local pos = tes3.player.position:copy()		local post = tes3.player.position:copy()		local vect = tes3.getPlayerEyeVector()
		pos.x = pos.x + vect.x * 90		pos.y = pos.y + vect.y * 90		pos.z = 90 + pos.z + vect.z * 90
		post.x = post.x + vect.x * 300	post.y = post.y + vect.y * 300	post.z = 27 + post.z + vect.z * 300
		refsource = tes3.createReference({object = "4nm_enchant", position = pos, orientation = vect, cell = tes3.player.cell})
		reftarget = tes3.createReference({object = "4nm_target", position = post, cell = tes3.player.cell})
		tes3.cast({reference = refsource, spell = "4nm_spell_enchantstrike", target = reftarget})
		tes3.mobilePlayer.readiedWeapon.variables.charge = tes3.mobilePlayer.readiedWeapon.variables.charge - newcost
		if messages then tes3.messageBox("Charge cost = %.1f  Source = %s  Target = %s", newcost, refsource.id, reftarget.id) end
		reftarget:disable()		refsource:disable()
		timer.start({ duration = 0.2, callback = function() mwscript.setDelete({reference = reftarget})		mwscript.setDelete({reference = refsource})		if messages then tes3.messageBox("All deleted") end end })
		--refsource:disable()		timer.start({ duration = 0.2, callback = function() mwscript.setDelete({reference = refsource}) tes3.messageBox("Sourse deleted") end })
	end
end


local function onSpellResist(e)
	if e.source.id == "4nm_spell_enchantstrike" and e.effect.object.isHarmful and e.target.mobile.inCombat == false then
		local gocombat = 1
		for actor in tes3.iterate(tes3.mobilePlayer.friendlyActors) do if actor.reference == e.target then gocombat = 0		break end end
		if gocombat == 1 then mwscript.startCombat{reference = e.target, target = tes3.player} end
	end
end


local function onSaved(e)
	if reftarget and reftarget.disabled == false then
		reftarget:disable()		refsource:disable()
		timer.start({ duration = 0.2, callback = function() mwscript.setDelete({reference = reftarget})		mwscript.setDelete({reference = refsource})		if messages then tes3.messageBox("All deleted") end end })
	end
end


local function initialized(e)
	event.register("attack", onAttack)
	event.register("equipped", onEquipped)
	event.register("unequipped", onUnequipped)
	event.register("saved", onSaved)
	event.register("spellResist", onSpellResist)
end
event.register("initialized", initialized)