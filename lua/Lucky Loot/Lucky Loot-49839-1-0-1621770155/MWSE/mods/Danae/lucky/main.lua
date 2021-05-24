local function getLeveledItemPlayerLevel()
    return tes3.player.object.level + math.clamp((tes3.mobilePlayer.luck.current - 50) / 5, 0, 100)
end

mwse.memory.writeFunctionCall{
    address = 0x4D0CD5,
    length = 0x10,
    signature = { returns = "int" },
    call = getLeveledItemPlayerLevel,
}