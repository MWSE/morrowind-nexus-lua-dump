local SkillsHP = {"unarmored", "lightArmor", "mediumArmor", "heavyArmor", "athletics"}
local SkillsAR = {"unarmored", "lightArmor", "mediumArmor", "heavyArmor", "block"}

local function onLoaded()

local basehp = tes3.mobilePlayer.endurance.base/2 + tes3.mobilePlayer.strength.base/4 + tes3.mobilePlayer.willpower.base/4		local perk = 0		local AR = 0
for _, skill in pairs(SkillsHP) do if tes3.mobilePlayer[skill].base >= 100 then perk = perk + 10 elseif tes3.mobilePlayer[skill].base >= 75 then perk = perk + 6 elseif tes3.mobilePlayer[skill].base >= 50 then perk = perk + 3 end end

if tes3.isAffectedBy{reference = tes3.player, effect = 80} == false and tes3.mobilePlayer.health.base == tes3.mobilePlayer.health.current then
	tes3.setStatistic{reference = tes3.player, name = "health", value = (basehp + perk)}
	--tes3.messageBox("???????? ???????????.  ??????? = %s  ??????? = %s  ?? ?????? = %s  ?? ?????? = %s", tes3.mobilePlayer.health.current, tes3.mobilePlayer.health.base, basehp, perk)
end

if tes3.isAffectedBy{reference = tes3.player, effect = 3} == false then
	for _, skill in pairs(SkillsAR) do if tes3.mobilePlayer[skill].base >= 100 then AR = AR + 4 elseif tes3.mobilePlayer[skill].base >= 75 then AR = AR + 2 elseif tes3.mobilePlayer[skill].base >= 50 then AR = AR + 1 end end
	tes3.mobilePlayer.shield = AR
	--tes3.messageBox("????? ???????????. ??????? = %s   ?????? ???? = %s", tes3.mobilePlayer.shield, AR)
end

end


local function initialized(e)

tes3.findGMST("fRestMagicMult").value = 0.3
tes3.findGMST("fSpellMakingValueMult").value = 10
tes3.findGMST("fEnchantmentValueMult").value = 100

tes3.findGMST("fEncumberedMoveEffect").value = 0.8
tes3.findGMST("fBaseRunMultiplier").value = 2
tes3.findGMST("fSwimRunBase").value = 0.3
tes3.findGMST("fSwimRunAthleticsMult").value = 0.2
tes3.findGMST("fHoldBreathTime").value = 60
tes3.findGMST("fSuffocationDamage").value = 10

tes3.findGMST("fJumpAcrobaticsBase").value = 278
tes3.findGMST("fJumpEncumbranceBase").value = 0
tes3.findGMST("fJumpEncumbranceMultiplier").value = 0.5
tes3.findGMST("fFallDistanceMult").value = 0.1
tes3.findGMST("fFallAcroBase").value = 0.5

tes3.findGMST("fUnarmoredBase2").value = 0.03
tes3.findGMST("iBaseArmorSkill").value = 50
tes3.findGMST("fSwingBlockMult").value = 2
tes3.findGMST("fDamageStrengthBase").value = 1

tes3.findGMST("fFatigueBase").value = 1.5
tes3.findGMST("fFatigueReturnBase").value = 0
tes3.findGMST("fFatigueReturnMult").value = 0.1
tes3.findGMST("fFatigueAttackBase").value = 5
tes3.findGMST("fFatigueAttackMult").value = 15
tes3.findGMST("fWeaponFatigueMult").value = 1
tes3.findGMST("fFatigueBlockBase").value = 5
tes3.findGMST("fFatigueBlockMult").value = 5
tes3.findGMST("fWeaponFatigueBlockMult").value = 3
tes3.findGMST("fFatigueRunMult").value = 20
tes3.findGMST("fFatigueJumpBase").value = 10
tes3.findGMST("fFatigueJumpMult").value = 40
tes3.findGMST("fFatigueSwimWalkBase").value = 5
tes3.findGMST("fFatigueSwimRunBase").value = 10
tes3.findGMST("fFatigueSwimWalkMult").value = 20
tes3.findGMST("fFatigueSwimRunMult").value = 40
tes3.findGMST("fFatigueSneakBase").value = 0
tes3.findGMST("fFatigueSneakMult").value = 10

tes3.findGMST("fMinHandToHandMult").value = 0.04
tes3.findGMST("fMaxHandToHandMult").value = 0.2
tes3.findGMST("fHandtoHandHealthPer").value = 0.2
tes3.findGMST("fCombatInvisoMult").value = 0.5
tes3.findGMST("fCombatCriticalStrikeMult").value = 2
tes3.findGMST("iBlockMaxChance").value = 90

tes3.findGMST("fLevelUpHealthEndMult").value = 0
tes3.findGMST("fFatigueSpellMult").value = 1
tes3.findGMST("fPotionT1MagMult").value = 10
tes3.findGMST("fPotionT1DurMult").value = 2

tes3.findGMST("fNPCbaseMagickaMult").value = 3
tes3.findGMST("fAutoSpellChance").value = 75
tes3.findGMST("iAutoSpellTimesCanCast").value = 5
tes3.findGMST("iAutoSpellConjurationMax").value = 3
tes3.findGMST("iAutoSpellDestructionMax").value = 15

tes3.findGMST("fBarterGoldResetDelay").value = 12
tes3.findGMST("fEnchantmentConstantChanceMult").value = 1

tes3.findGMST("fKnockDownMult").value = 0.8
tes3.findGMST("iKnockDownOddsBase").value = 0
tes3.findGMST("iKnockDownOddsMult").value = 80
tes3.findGMST("fCombatArmorMinMult").value = 0.1
tes3.findGMST("fHandToHandReach").value = 0.5

tes3.findGMST("fProjectileMinSpeed").value = 1000
tes3.findGMST("fProjectileMaxSpeed").value = 5000
tes3.findGMST("fThrownWeaponMinSpeed").value = 1000
tes3.findGMST("fThrownWeaponMaxSpeed").value = 3000
tes3.findGMST("fTargetSpellMaxSpeed").value = 2000
tes3.findGMST("fProjectileThrownStoreChance").value = 100

tes3.findGMST("iTrainingMod").value = 5
tes3.findGMST("iAlchemyMod").value = 0

tes3.findGMST("fMajorSkillBonus").value = 0.5
tes3.findGMST("fMinorSkillBonus").value = 0.75
tes3.findGMST("fMiscSkillBonus").value = 1

tes3.findGMST("fSneakViewMult").value = 2

tes3.findGMST("fCombatBlockLeftAngle").value = -0.666
tes3.findGMST("fCombatBlockRightAngle").value = 0.333

tes3.findGMST("fCombatDelayCreature").value = -0.4
tes3.findGMST("fCombatDelayNPC").value = -0.4
tes3.findGMST("fMagicCreatureCastDelay").value = 0
tes3.findGMST("fAIFleeHealthMult").value = 50
tes3.findGMST("fAIFleeFleeMult").value = 1.5
tes3.findGMST("fFleeDistance").value = 5000

tes3.findGMST("fDiseaseXferChance").value = 5
tes3.findGMST("fElementalShieldMult").value = 1


event.register("loaded", onLoaded)
end
event.register("initialized", initialized)