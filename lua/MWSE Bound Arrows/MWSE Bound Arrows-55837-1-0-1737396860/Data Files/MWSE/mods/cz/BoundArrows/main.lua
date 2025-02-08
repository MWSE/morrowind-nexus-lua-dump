local BOUND_ARROW_ID = "bound_arrow"
local BOUND_ARROW_ENCH_ID = "bound_arrow_en"
local boundArrow = tes3.getObject(BOUND_ARROW_ID)
local boundArrowEnch = tes3.getObject(BOUND_ARROW_ENCH_ID)

local function createBoundArrow()
    if boundArrow then return end
    if not boundArrowEnch then
        boundArrowEnch = tes3.createObject({
            objectType = tes3.objectType.enchantment,
            id = BOUND_ARROW_ENCH_ID,
            castType = tes3.enchantmentType.onStrike,
            chargeCost = 3,
            maxCharge = 30,
            effects = {
                {
                    id = tes3.effect.absorbHealth,
                    min = 2,
                    max = 5,
                    duration = 5,
                    rangeType = tes3.effectRange.touch
                }
            }
        })
    end
    boundArrow = tes3.createObject({
        objectType = tes3.objectType.ammunition,
        type = tes3.weaponType.arrow,
        id = BOUND_ARROW_ID,
        name = "Bound Arrow",
        mesh = "w\\W_daedric_Arrow.NIF",
        icon = "w\\tx_arrow_daedric.tga",
        weight = 0,
        value = 0,
        enchantCapacity = 0,
        enchantment = boundArrowEnch,
        chopMin = 10,
        chopMax = 15,
        ignoresNormalWeaponResistance = true,
    })
end


local function removeBoundArrow(target)
    local count = tes3.getItemCount({reference = target, item = boundArrow})
    if count == 0 then return end
    tes3.removeItem({
        reference = target,
        item = boundArrow,
        count = count,
        playSound = false
    })
end

local function onSpellEffect(e)
    if e.effect.id == tes3.effect.boundLongbow then
        if e.effectInstance.state == tes3.spellState.working then
            if tes3.getItemCount({reference = e.target, item = boundArrow}) ~= 1 then
                tes3.equip({reference = e.target, item = boundArrow, addItem = true, playSound = false})
            end
        elseif e.effectInstance.state == tes3.spellState.ending then
            removeBoundArrow(e.target)
        end
    end
end

local function noDropping(e)
    if e.reference.object == boundArrow then
        tes3reference.delete(e.reference)
        tes3.messageBox("You cannot drop summoned items!")
    end
end

local function noEquip(e)
    if e.item == boundArrow and tes3.getItemCount({reference = e.reference, item = tes3.getObject("bound_longbow")}) < 1 then
        removeBoundArrow(e.reference)
    end
end

local function onInitialized()
    createBoundArrow()
    event.register("spellTick", onSpellEffect)
    event.register("itemDropped", noDropping)
    event.register("equipped", noEquip)
    mwse.log("[Bound Arrows] Initialized.")
end

event.register("initialized", onInitialized)