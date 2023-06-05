local tatau = require("sb_tatau.interop")
local mer = require("mer.characterBackgrounds.interop")

local tattoo =
{
    id     = "sb_dragon",
    slot   = tatau.slots.torso,
    mPaths = { [""] = "sb_dragon_of_prophecy\\sb_dojima.tga", ["Argonian"] = "sb_dragon_of_prophecy\\sb_dojima_arg.tga" },
    fPaths = { [""] = "sb_dragon_of_prophecy\\sb_dojima_f.tga", ["Khajiit"] = "sb_dragon_of_prophecy\\sb_dojima.tga" }
}

local function onInitialized()
    tatau:register(tattoo)
    tatau:registerAll()

    mer.addBackground {
        id = "sb_dragon",
        name = "Dragon of Prophecy",
        description =
        "Orphaned at a young age and taken in by various groups over the years, you've honed your hand-to-hand combat. Your enemies are intimidated by the presence of the dragon tattoo on your back, and you gain confidence from fighting shirtless.\n\nx1.25 ~ x1.5 hand-to-hand damage\nx0.50 ~ x0.75 enemy attack damage",
        doOnce = function()
        end,
        callback = function()
        end
    }
end
event.register("initialized", onInitialized)

--- @param e bodyPartsUpdatedEventData
local function bodyPartsUpdatedCallback(e)
    if (e.reference == tes3.player and mer.getCurrentBackground() and mer.getCurrentBackground():getName() == "Dragon of Prophecy") then
        tatau:prepare(tes3.player)
        tatau:applyTattoo(tes3.player, tattoo.id)
    end
end
event.register(tes3.event.bodyPartsUpdated, bodyPartsUpdatedCallback)

--- @param e referenceDeactivatedEventData
local function referenceDeactivatedCallback(e)
    if (e.reference == tes3.player and mer.getCurrentBackground() and mer.getCurrentBackground():getName() == "Dragon of Prophecy") then
        tatau:removeTattoo(tes3.player, tattoo.id)
    end
end
event.register(tes3.event.referenceDeactivated, referenceDeactivatedCallback)

--- --- ---

-- --- @param e attackStartEventData
-- local function attackStartCallback(e)
--     if (e.mobile.actionData.target == tes3.player and mer.getCurrentBackground() and mer.getCurrentBackground():getName() == "Dragon of Prophecy") then
--         if (tes3.getEquippedItem { actor = tes3.player, slot = tes3.armorSlot["cuirass"] } == nil and tes3.getEquippedItem { actor =
--                 tes3.player, slot = tes3.clothingSlot["shirt"] } == nil) then
--             e.attackSpeed = e.attackSpeed * math.random(0.5, 0.75)
--         end
--     end
-- end
-- event.register(tes3.event.attackStart, attackStartCallback)

--- @param e damageEventData
local function damageCallback(e)
    if (e.attackerReference and e.attackerReference.mobile.readiedWeapon == nil and mer.getCurrentBackground() and mer.getCurrentBackground():getName() == "Dragon of Prophecy") then
        if (tes3.getEquippedItem { actor = e.attackerReference, slot = tes3.armorSlot["cuirass"] } == nil and tes3.getEquippedItem { actor =
                e.attackerReference, slot = tes3.clothingSlot["shirt"] } == nil) then
            e.damage = e.damage * math.random(1.25, 1.5)
        end
    end
end
event.register(tes3.event.damage, damageCallback)

--- @param e damageHandToHandEventData
local function damageHandToHandCallback(e)
    if (tes3.getEquippedItem { actor = e.attackerReference, slot = tes3.armorSlot["cuirass"] } == nil and
        tes3.getEquippedItem { actor = e.attackerReference, slot = tes3.clothingSlot["shirt"] } == nil and
        mer.getCurrentBackground() and mer.getCurrentBackground():getName() == "Dragon of Prophecy") then
        if (e.attackerReference == tes3.player) then
            e.fatigueDamage = e.fatigueDamage * math.random(1.25, 1.5)
        elseif (e.attackerReference ~= tes3.player and e.reference == tes3.player) then
            e.fatigueDamage = e.fatigueDamage * math.random(0.5, 0.75)
        end
    end
end
event.register(tes3.event.damageHandToHand, damageHandToHandCallback)
