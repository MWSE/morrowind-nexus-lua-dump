local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("bsRepairTarget", 23331)

local bsRepairTarget


local function onRepairCollision(e)   --When the spell collides
	if e.collision then
        local target = tes3.getPlayerTarget().object.objectType --to make if statement cleaner
        local targetInfo = tes3.getPlayerTarget() --get the target to grab info from

        if target == nil then                  -- do nothing if theres nothing targeted
            tes3.messageBox("This can't be repaired.")
            tes3.playSound({sound = "repair fail"})
            return
        end

        local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.bsRepairTarget) --Get Effect data for magnitude
        local magnitude = framework.functions.getCalculatedMagnitudeFromEffect(effect) --Magnitude
        local armorerSkill = tes3.getSkill(tes3.skill.armorer)  --Get armorer skill to modify
        local targetArmor = tes3.objectType.armor   --Make sure target is Armor
        local targetWeapon = tes3.objectType.weapon --Or Weapon

        if (target == targetArmor or target == targetWeapon) then   --if the target is armor/weapon 
            if targetInfo then  --if targetInfo has gotten a target
                local condition = nil       --variable for condition below
                local maxCondition =  nil   --maxCondition below
                local name = targetInfo.object.name 

                    if targetInfo.itemData then -- itemData.condition gives error at maxCondition so check if it actually has itemData before trying
                        condition = targetInfo.itemData.condition    --Get items condition, if the item even has itemData
                        maxCondition = targetInfo.object.maxCondition --Get items max condition
                    end

                    if condition and condition < maxCondition then
                        tes3.messageBox(name.." - "..math.clamp(magnitude + condition, 0, maxCondition).."/"..maxCondition)
                        targetInfo.itemData.condition = math.clamp(magnitude + condition, 0, maxCondition)
                        tes3.mobilePlayer:exerciseSkill(tes3.skill.armorer, armorerSkill.actions[1] + math.clamp(magnitude / 20, 0.05, 5))
                        tes3.playSound({sound = "repair"})
                    elseif not condition or condition >= maxCondition then
                        tes3.messageBox("This item doesn't need repairing.") --debug message
                        tes3.playSound({sound = "repair fail"})
                    end
                end
        else
            tes3.messageBox("This can't be repaired.")
            tes3.playSound({sound = "repair fail"})
        end
    end
end

local function addRepairEffect()
	bsRepairTarget = framework.effects.alteration.createBasicEffect({
		-- Base information.
		id = tes3.effect.bsRepairTarget,
		name = "Repair Target",
		description = "Repairs Weapons and Armor",

		-- Basic dials.
		baseCost = 10.0,
		speed = 3.0,

		-- Flags
        -- allowSpellmaking = true, --wont work, only lets touch spell be made 
		appliesOnce = true,
		canCastTarget = true,
		hasNoDuration = true,
		canCastSelf = false,
        canCastTouch = false,

		-- Graphics / sounds.
		icon = "bs\\bs_Repair_Alteration.dds",
		particleTexture = "vfx_particle064.tga",
		lighting = { 206 / 255, 237 / 255, 255 / 255 },

		-- Callbacks
		onCollision = onRepairCollision
	})
end

event.register("magicEffectsResolved", addRepairEffect)