-- Utility functions

local utility = {}

utility.getNecromanticSpellBonus = function (spell, shade)
	if not spell then return 0 end
    for _, effect in ipairs(spell.effects) do
        -- Spells with corrupt soulgem effects do not work at all without the Shade of the Revenant
        if not shade then
            if effect.id == 670 then
                return -99999999
            end
        -- Necromantic spells are easier to cast during the Shade of the Revenant
        elseif effect.id > 656 and effect.id < 674 then
            if shade then
                return spell.magickaCost*0.6
            end
        end
    end
	return 0
end

utility.isShade = function()
    if tes3.worldController.daysPassed.value%8 ~= 0 then
        return false
    end
	return (tes3.worldController.hour.value <= 6 or tes3.worldController.hour.value >= 21)
end

utility.safeDelete = function(reference)
    reference:disable()
    timer.delayOneFrame(function()
        reference:delete()
    end)
end

utility.disposeCorpse = function(reference)
	local controlPressed = tes3.worldController.inputController:isKeyDown(tes3.scanCode.lCtrl) 
	if not tes3.hasCodePatchFeature(107) or not controlPressed then
		local inventory =  reference.object.inventory
		for _, stack in pairs(inventory) do
			local item = stack.object.id
			tes3.transferItem{from = reference, to = tes3.mobilePlayer, count = stack.count, item = item, limitCapacity=false}
		end
	end
	utility.safeDelete(reference)
end

utility.logMinions = function()
	local minions = tes3.player.data.necroCraft.minions
	mwse.log("\nMINIONS:")
	for name, arr in pairs(minions) do
		mwse.log("\n%s:", name)
		for minion_id, __ in pairs(arr) do
			mwse.log(minion_id)
		end
	end
end


utility.replace = function(old, new, cell)
	new = tes3.createReference{object=new, position=old.position, orientation=old.orientation, cell=cell}
	new.scale = old.scale
	new.stackSize = old.stackSize
	if old.data and old.data.necroCraft then
		new.data.necroCraft = old.data.necroCraft
		new.data.necroCraft.isBeingRaised = nil
	end

	local owner = tes3.getOwner(old)

	if owner then
		tes3.setOwner({
			reference = new,
			owner = owner,
		})
	end

	if old.object.inventory then
		for _, stack in pairs(old.object.inventory) do
			tes3.transferItem{from=old, to=new, item=stack.object, count=stack.count, playSound=false}
		end
	end
	utility.safeDelete(old)
	return new
end

utility.placeInFront = function(reference, object, distance)
	local vec = tes3vector3.new(0,1,0)
	local mat = reference.sceneNode.worldTransform.rotation
	local position = reference.position + (mat * vec * distance)
	return tes3.createReference{object = object, count = 1, position = position, orientation = {0,0,0}, cell = tes3.getPlayerCell()}
end

local function applyReplacer(params)
	local object = params.object
	local mesh = params.mesh
	local replacer = params.replacer
	if type(object) == "string" then
		object = tes3.getObject(object)
	end
	if not mesh then
		if type(replacer) == "string" then
			replacer = tes3.getObject(replacer)
		end
		mesh = replacer.mesh
	end
	object.mesh = mesh
end

utility.ashPitReplacer = function()
	applyReplacer({object = "nc_ashpit_01", replacer = "in_velothi_ashpit_01"})
	applyReplacer({object = "nc_ashpit_02", replacer = "in_velothi_ashpit_02"})
	applyReplacer({object = "nc_ashpit_r_01", replacer = "in_redoran_ashpit_01"})
	applyReplacer({object = "nc_ashpit_r_01", replacer = "in_redoran_ashpit_01"})
end

utility.skeletonReplacer = function()
	applyReplacer{object = "skeleton_weak", replacer = "NC_skeleton_weak"}
	local oldMesh = tes3.getObject("skeleton").mesh
	for creature in tes3.iterateObjects(tes3.objectType.creature) do
		if creature.mesh == oldMesh then
			applyReplacer{object = creature, replacer = "NC_skeleton_war"}
		end
	end
end

return utility