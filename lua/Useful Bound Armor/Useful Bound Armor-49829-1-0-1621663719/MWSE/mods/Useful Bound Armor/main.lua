local mod = "Useful Bound Armor"
local version = "1.0"

local function onCalcArmorRating(e)
    local mobile = e.mobile

    if not mobile then
        return
    end

    local armor = e.armor

    -- Bound armor is weightless.
    if armor.weight ~= 0 then
        return
    end

    -- In vanilla this GMST is 30.
    local baseArmorSkill = tes3.findGMST(tes3.gmst.iBaseArmorSkill).value

    local lightArmorSkill = mobile:getSkillValue(tes3.skill.lightArmor)

    -- Identical to the vanilla AR formula.
    e.armorRating = armor.armorRating * lightArmorSkill / baseArmorSkill

    -- Needed to prevent the game from overriding what we just did.
    e.block = true
end

local function onInitialized()
    event.register("calcArmorRating", onCalcArmorRating)
    mwse.log("[%s %s] Initialized.", mod, version)
end

event.register("initialized", onInitialized)