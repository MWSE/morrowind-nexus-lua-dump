local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("bsRepairWeapon", 23333)--Claim the ID for the effect 2333 = Beef in t9, 3 for third effect

local bsRepairWeapon

local function onWeaponTick(e)
    local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.bsRepairWeapon)
    local magnitude = framework.functions.getCalculatedMagnitudeFromEffect(effect)
    local armorerSkill = tes3.getSkill(tes3.skill.armorer)
    local equippedWeapon = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.weapon})

    if (equippedWeapon) then
        local condition = equippedWeapon.itemData.condition      --Get items condition
        local maxCondition = equippedWeapon.object.maxCondition  --Get items max condition
        local name = equippedWeapon.object.name 
        
        if (condition < maxCondition) then
            equippedWeapon.itemData.condition = math.clamp(magnitude + condition, 0, maxCondition)
            tes3.messageBox(name.." - "..math.clamp(magnitude + condition, 0, maxCondition).."/"..maxCondition)
            tes3.mobilePlayer:exerciseSkill(tes3.skill.armorer, armorerSkill.actions[1] + math.clamp(magnitude / 20, 0.05, 5))  --give armorer xp = to magnitude of spell / 20, to a max of 5
            tes3.playSound({sound = "repair"})
        else
            tes3.messageBox("%s is already repaired.", name)
            tes3.playSound({sound = "repair fail"})
        end
    else
        tes3.messageBox("I don't have a weapon equipped.")
    end
    e.effectInstance.state = tes3.spellState.retired    --Dont remember why I needed this, maybe spell wasnt stopping?
end


local function addRepairWeapon()
	bsRepairWeapon = framework.effects.alteration.createBasicEffect({
		-- Base information.
		id = tes3.effect.bsRepairWeapon,
		name = "Repair Weapon",
		description = "Repair Equipped Weapon",

		-- Basic dials.
		baseCost = 10,

		-- Flags
        allowSpellmaking = true,
		appliesOnce = true,
		canCastTarget = false,
        canCastSelf = true,
        hasNoDuration = true,
		

		-- Graphics / sounds.
		icon = "bs\\bs_Repair_Alteration.dds",
		particleTexture = "vfx_particle064.tga",
		lighting = { 206 / 255, 237 / 255, 255 / 255 },

		-- Callbacks
		onTick = onWeaponTick
	})
end

event.register("magicEffectsResolved", addRepairWeapon)