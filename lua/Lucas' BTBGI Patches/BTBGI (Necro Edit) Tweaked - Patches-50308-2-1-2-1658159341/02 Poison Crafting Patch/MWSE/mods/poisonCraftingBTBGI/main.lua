local newBaseCosts = {
    [tes3.effect.burden] = 1,
    [tes3.effect.drainAttribute] = 1,
    [tes3.effect.drainHealth] = 4,
    [tes3.effect.drainFatigue] = 2,
    [tes3.effect.damageAttribute] = 8,
    [tes3.effect.damageMagicka] = 8,
    [tes3.effect.damageFatigue] = 4,
    [tes3.effect.poison] = 9,
    [tes3.effect.paralyze] = 40,
    [tes3.effect.silence] = 40,
    [tes3.effect.blind] = 1,
    [tes3.effect.sound] = 3,
}

local initBaseCosts = {}

local function onBrewSkillCheck()
    for effect, newCost in pairs(newBaseCosts) do
        local magicEffect = tes3.getMagicEffect(effect)
        magicEffect.baseMagickaCost = newCost
    end

    timer.frame.delayOneFrame(function()
        for effect, initCost in pairs(initBaseCosts) do
            local magicEffect = tes3.getMagicEffect(effect)
            magicEffect.baseMagickaCost = initCost
        end
    end)
end

event.register("potionBrewSkillCheck", onBrewSkillCheck, { priority = -1000 })

local function onInitialized()

	-- Saving magic effect costs
	-- Go through all magic effects and save its costs in the table.
    for effect, _ in pairs(newBaseCosts) do
        local magicEffect = tes3.getMagicEffect(effect)
        initBaseCosts[effect] = magicEffect.baseMagickaCost
    end

    mwse.log(string.format("Poison Crafting BTBGI Patch Initialized."))

end

event.register("initialized", onInitialized)