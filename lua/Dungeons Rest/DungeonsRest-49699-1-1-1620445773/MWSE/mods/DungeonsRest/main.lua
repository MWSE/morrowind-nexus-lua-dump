local function refCheck(ref)
    local mobile = ref.mobile

    if not mobile then
        return
    end

    if mobile.fight < 80 then
        return
    end

    local animState = mobile.actionData.animationAttackState

    if animState == tes3.animationState.dying
    or animState == tes3.animationState.dead then
        return
    end

    local maxHealth = mobile.health.base
    local currentHealth = mobile.health.current
    local maxMagicka = mobile.magicka.base
    local currentMagicka = mobile.magicka.current
    local maxFatigue = mobile.fatigue.base
    local currentFatigue = mobile.fatigue.current

    if currentHealth < maxHealth then
        tes3.setStatistic{
            reference = mobile,
            name = "health",
            current = maxHealth
        }
    end

    if currentMagicka < maxMagicka then
        tes3.setStatistic{
            reference = mobile,
            name = "magicka",
            current = maxMagicka
        }
    end

    if currentFatigue < maxFatigue then
        tes3.setStatistic{
            reference = mobile,
            name = "fatigue",
            current = maxFatigue
        }
    end
end

local function onCellChanged()
    local playerCell = tes3.getPlayerCell()

    if not playerCell.isInterior then
        return
    end

    if playerCell.behavesAsExterior then
        return
    end

    for ref in playerCell:iterateReferences(tes3.objectType.npc) do
        refCheck(ref)
    end

    for ref in playerCell:iterateReferences(tes3.objectType.creature) do
        refCheck(ref)
    end
end

event.register("cellChanged", onCellChanged)