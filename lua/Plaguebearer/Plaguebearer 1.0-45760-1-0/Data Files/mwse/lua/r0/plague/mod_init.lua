local function getDiseases(ref)
    local diseases = {}

	--print(ref.object.id)
    for spell in tes3.iterate(ref.object.spells.iterator) do
        if (spell.castType == tes3.spellType.disease)
        or (spell.castType == tes3.spellType.blight) then
			--print(spell.id)
			--print(spell)
			if not (spell.id == 'corprus') then
				diseases[spell.id] = spell.castType
			end
        end
    end

    return diseases
end

local function onAttack(e)
	--print("[r0-vector]===============================")

	if e.mobile.actionData.physicalDamage == 0 then return end
	--print("[r0-vector]Dealt damage, proceeding")

	if not (e.reference == tes3.getPlayerRef()) then return end
	--print("[r0-vector]Attacker is Player, proceeding.")
	
	local target = e.targetReference
	if not target.object.isInstance then return end
	--print("[r0-vector]Target is an instance, proceeding.")

	local weapon = e.mobile.readiedWeapon
	if weapon and (weapon.object.type > 8) then return end
	--print("[r0-vector]Melee weapon, proceeding.")

	local sourceDiseases = getDiseases(e.reference)
	if not next(sourceDiseases) then return end
	--print("[r0-vector]Attacker is diseased, proceeding.")
	
	local xferChance = (tes3.getGMST("fDiseaseXferChance").value)
	--mwse.log("[r0-vector]Disease Transfer Chance: %f", xferChance)

	local targetDiseases = getDiseases(target)

    for disease, diseaseType in pairs(sourceDiseases) do
        if not targetDiseases[disease] then
            local resist
            if (diseaseType == tes3.spellType.blight) then
                resist = target.attachments.actor.resistBlightDisease 
            else
                resist = target.attachments.actor.resistCommonDisease
            end
			local rollTarget = (1 - xferChance / 100 * (1 - resist / 100))
			local roll = math.random()
			--mwse.log("[r0-vector]Target Resist: %s.", resist)
			--mwse.log("[r0-vector]Roll target: %s.", rollTarget)
			--mwse.log("[r0-vector]Roll: %s.", roll)
        	if roll >= rollTarget then
            	mwse.log("[r0-vector]Successfully infected %s with %s.", target, disease)
	            mwscript.addSpell{reference=target, spell=disease}
	            break
            end
        end
    end
end

local function initialized(e)
    if tes3.isModActive("Plaguebearer.ESP") then
        event.register("attack", onAttack)
    end
end
event.register("initialized", initialized)