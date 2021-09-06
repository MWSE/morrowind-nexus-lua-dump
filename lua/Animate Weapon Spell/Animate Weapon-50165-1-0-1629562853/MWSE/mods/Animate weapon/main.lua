local cf = mwse.loadConfig("Animate weapon", {inv = true})		
local p

local function spellResist(e) if e.target == p and e.effect.id == 711 and e.resistedPercent < 100 then	local s = e.source
	if s.weight == 0 and s.name == "*Animate weapon" then	e.resistedPercent = 0
		timer.delayOneFrame(function() local ei = e.sourceInstance:getEffectInstance(e.effectIndex, p)	if ei and ei.createdData then local ref = ei.createdData.object
			tes3ui.showInventorySelectMenu{title = "Choose weapon for animation", noResultsText = "No weapons", noResultsCallback = function() ei.state = 6 end,
			filter = function(ed) local W = ed.item		return W.objectType == tes3.objectType.weapon and W.type ~= 11 and W.weight ~= 0 and (not ed.itemData or ed.itemData.condition > 0) end,
			callback = function(ed) local W = ed.item	if W then
				tes3.transferItem{from = p, to = ref, item = W, itemData = ed.itemData, count = 1, playSound = false, limitCapacity = false}		--ref.mobile:equip{item = W}
				mwscript.equip{reference = ref, item = W}
				tes3.setStatistic{reference = ref, name = "health", value = W.maxCondition/5}		ref.mobile.shield = 100		--ref.mobile.levitate = 30
				--tes3.applyMagicSource{reference = ref, name = "4nm", effects = {{id = 10, min = 50, max = 50, duration = 60000}}}
				ref.sceneNode:getObjectByName("Weapon Bone"):attachChild(tes3.loadMesh("kurp\\animate_weapon_glow.nif"):clone())
				if cf.inv then local stnod = ref.sceneNode:getObjectByName("Bip01 AttachWeapon")	if stnod then stnod.appCulled = true end
					ref.sceneNode:getObjectByName("Weapon Bone"):attachChild(tes3.loadMesh(W.mesh):clone())
				end
			else ei.state = 6 end end}
		end end)
	else tes3.applyMagicSource{reference = p, name = "*Animate weapon", effects = {{id = e.effect.id, duration = e.effect.duration}}}		e.resistedPercent = 100		return end
end	end		event.register("spellResist", spellResist)

--[[
local function weaponUnreadied(e)
	if e.reference.baseObject.id == "Animated_weapon" then tes3.messageBox("NOOOOOOOO!!!!!!!")
		timer.start{duration = 1, callback = function() e.reference.mobile.weaponDrawn = true end}
	end
	
	if (not mob.weaponDrawn) then mob.actionData.animationAttackState = tes3.animationState.readyingWeap end
	
end		event.register("weaponUnreadied", weaponUnreadied)
--]]

local function LOADED(e)	 p = tes3.player
	local s = tes3.createObject{objectType = tes3.objectType.spell, id = "Animate weapon"}		s.name = "Animate weapon"	s.magickaCost = 15		s = s.effects[1]	s.rangeType = 0		s.id = 711	s.duration = 180
	tes3.getObject("marayn dren").spells:add("Animate weapon")
end		event.register("loaded", LOADED)

local function initialized(e)	tes3.findGMST("sMagicPCResisted").value = ""
tes3.claimSpellEffectId("animatedWeapon", 711)	tes3.addMagicEffect{id = 711, name = "Animate weapon", baseCost = 1, school = 1,
description = "You donate chosen weapon to Oblivion, and in return, it is temporarily animated by a Daedric soul. When the effect expires, the weapon is sent to Oblivion.",
allowEnchanting = true, allowSpellmaking = true, canCastSelf = true, canCastTarget = false, canCastTouch = false, isHarmful = false, hasNoDuration = false, hasNoMagnitude = true,
nonRecastable = false, hasContinuousVFX = false, appliesOnce = true, unreflectable = false, casterLinked = false, illegalDaedra = false, targetsAttributes = false, targetsSkills = false, usesNegativeLighting = false,
castVFX = "VFX_AnimWCast", boltVFX = "VFX_ConjureBolt", hitVFX = "VFX_DefaultHit", areaVFX = "VFX_ConjureArea", particleTexture = "kurp\\animw\\handpc.dds",
icon = "s\\tx_s_bd_lngswd.dds", speed = 1, size = 1, sizeCap = 50, lighting = {1,1,0}, onTick = function(e) e:triggerSummon("Animate_weapon") end}
end		event.register("initialized", initialized)

local function registerModConfig()	local tpl = mwse.mcm.createTemplate("Animate weapon")	tpl:saveOnClose("Animate weapon", cf)	tpl:register()	local var = mwse.mcm.createTableVariable	local p0 = tpl:createPage()
p0:createYesNoButton{label = "Remove the scabbard of the animated weapon", variable = var{id = "inv", table = cf}}
end		event.register("modConfigReady", registerModConfig)