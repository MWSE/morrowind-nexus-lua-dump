local common = require("StormAtronach.TT.common")
local config = common.config
local dodge = {
    name = "Dodge",
    cooldown = false,
    active = false,
    window = nil,
}
-- Logging stuff
local log = mwse.Logger.new({
	name = config.name,
	level = config.log_level,
})


local function resetDodgeCooldown ()
    dodge.cooldown = false
end

function dodge.onJump()
    -- First, let us check the acrobatics skill level
    local acrobaticsSkill       = tes3.mobilePlayer:getSkillValue(tes3.skill.acrobatics)
    log:trace(string.format("Dodge started. Acrobatics skill %s", acrobaticsSkill))
    local acrobaticsLevel        = math.clamp(math.floor(acrobaticsSkill/25),0,4)
    log:trace(string.format("Dodge started. Acrobatics level %s", acrobaticsLevel))
    local acrobaticsContribution = 0.1 + acrobaticsLevel/10
    
    -- Then, let us check the chestplate worn
    local chestItem         = tes3.getEquippedItem({actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.cuirass})
    local armorWeightClass  = nil
    if chestItem then
        armorWeightClass = chestItem.object.weightClass
    end
    log:trace(string.format("Dodge started. Armor weight class: %s", armorWeightClass))
    
    -- Now, let us calculate the dodge window contribution from the armor weight class
    local armorContribution = 0
    
    if not armorWeightClass then
        armorContribution = 0.5
    elseif armorWeightClass == tes3.armorWeightClass.light then
        armorContribution = 0.35
    elseif armorWeightClass == tes3.armorWeightClass.medium then
        armorContribution = 0.2
    elseif armorWeightClass == tes3.armorWeightClass.heavy then
        armorContribution = 0 -- I know it is redundant, but it is easier to read
    end
    
    -- Now, let us calculate the dodge window
    local dodgeDuration     = math.max(0.1, math.min(acrobaticsContribution + armorContribution, 1))
    log:trace(string.format("Dodge started. Dodge duration %s", dodgeDuration))

    -- Then. let us trigger the cooldown
    dodge.cooldown = true
    timer.start({duration = math.max(config.dodge_cool_down_time,1), callback = resetDodgeCooldown, type = timer.simulate}) 
    
    -- And finally the dodge
    tes3.applyMagicSource({
        reference = tes3.player,
        bypassResistances = true,
        effects = { { id = tes3.effect.sanctuary, min = 100, max = 100, duration = dodgeDuration } },
        name = "Dodging",
    })
    return dodgeDuration
end

return dodge