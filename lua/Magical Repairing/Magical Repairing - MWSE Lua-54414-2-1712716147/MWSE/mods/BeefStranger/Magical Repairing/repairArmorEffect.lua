local framework = include("OperatorJack.MagickaExpanded.magickaExpanded")

tes3.claimSpellEffectId("bsRepairArmor", 23332) --Claim the ID for the effect 2333 = Beef in t9, 2 for second effect

local bsRepairArmor     --TODO: Figure out MCM and add settings for XP gain

--Greatness7
local slotPriorities = {
    tes3.armorSlot.shield,
    tes3.armorSlot.cuirass,
    tes3.armorSlot.leftPauldron,
    tes3.armorSlot.rightPauldron,
    tes3.armorSlot.leftBracer,
    tes3.armorSlot.rightBracer,
    tes3.armorSlot.leftGauntlet,
    tes3.armorSlot.rightGauntlet,
    tes3.armorSlot.helmet,
    tes3.armorSlot.greaves,
    tes3.armorSlot.boots,
}

local function onRepairTick(e)
    local effect = framework.functions.getEffectFromEffectOnEffectEvent(e, tes3.effect.bsRepairArmor)   --Gets the effect so you can get info from it.. see next line
	local magnitude = framework.functions.getCalculatedMagnitudeFromEffect(effect)                      --THIS IS HOW YOU GET MAGNITUDE! 
    local armorerSkill = tes3.getSkill(tes3.skill.armorer)                   --Needed for adding XP to skill, add .action[1] to then modify
    local repairNothing = nil                                                --To stop it saying "There's nothing to repair." everytime its also saying its repairing

-- Code from Greatness7-halls of colossus
    for _, slot in ipairs(slotPriorities) do        --Code from Greatness7, dont fully understand- iterates through slotPriorities
        local stack = tes3.getEquippedItem({        --does what it says on the tin
            actor = tes3.player,                    --player
            objectType = tes3.objectType.armor,     --only grab armor 
            slot = slot,                            --slot is what slotPriorities puts in place 
        })

        if stack then
            local condition = stack.itemData.condition      --Get items condition
            local maxCondition = stack.object.maxCondition  --Get items max condition
            local name = stack.object.name                  --to get name could just stack.object.name in messageBox but need to get used to using variables  

            if (condition < maxCondition) then 
                stack.itemData.condition = math.clamp(magnitude + condition, 0, maxCondition)   --Repair armor by magnitude capping at maxCondition
                tes3.mobilePlayer:exerciseSkill(tes3.skill.armorer, armorerSkill.actions[1] + math.clamp(magnitude / 20, 0.05, 5))  --give armorer xp = to magnitude of spell / 20, to a max of 5
                
                tes3.messageBox(name.." - "..math.clamp(magnitude + condition, 0, maxCondition).."/"..maxCondition)   --To say how much armor has been repaired by, clamp to max so it doesnt lie and say its higher than possible
                tes3.playSound({sound = "repair"})
                
               
                repairNothing = 1 --when 1 it does not say theres nothing to repair
                break           --Adding break stopped it repairing everything at once
            end
        end
    end 

    if not repairNothing then --Has to be here to not spam everytime its also repairing, dont fully understand why
        tes3.messageBox("There's nothing to repair.")
        tes3.playSound({sound = "repair fail"})
    end 

    e.effectInstance.state = tes3.spellState.retired    --Dont remember why I needed this, maybe spell wasnt stopping?
end

local function addRepairArmor()
	bsRepairArmor = framework.effects.alteration.createBasicEffect({
		-- Base information.
		id = tes3.effect.bsRepairArmor,
		name = "Repair Armor",
		description = "Repair Equipped Armor",

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
		onTick = onRepairTick
	})
end




event.register("magicEffectsResolved", addRepairArmor)