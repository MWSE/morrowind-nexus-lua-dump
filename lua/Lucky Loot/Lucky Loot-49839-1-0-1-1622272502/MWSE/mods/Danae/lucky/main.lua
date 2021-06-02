-- Ensure that the player has the necessary MWSE version.
if (mwse.buildDate == nil or mwse.buildDate < 20205028) then
    mwse.log("[Lucky Loot] Build date of %s does not meet minimum build date of 2020-05-28. Please run MWSE-Update.", mwse.buildDate)
    return
end

-- Replacement function for getting the player's level.
-- Takes luck into account for a bonus of up to 100 levels at 550 luck.
local function getLeveledItemPlayerLevel()
    return tes3.player.object.level + math.clamp((tes3.mobilePlayer.luck.current - 50) / 5, 0, 100)
end

-- Before:
--    4D0CD5 call    tes3worldController.getMobilePlayer
--    4D0CDA mov     ecx, [eax+tes3playerMobile.object]
--    4D0CE0 mov     edx, [ecx]
--    4D0CE2 call    [edx+tes3npc.getLevel]
-- After:
--    4D0CD5 call    getLeveledItemPlayerLevel
--    4D0CDA nop
--    ...
--    4D0CE4 nop
mwse.memory.writeFunctionCall{
    address = 0x4D0CD5,
    length = 0x10,
    signature = { returns = "int" },
    call = getLeveledItemPlayerLevel,
}