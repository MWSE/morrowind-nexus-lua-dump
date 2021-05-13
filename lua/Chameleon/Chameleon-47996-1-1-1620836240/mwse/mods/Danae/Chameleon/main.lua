mwse.memory.writeFunctionCall({
    address = 0x460D1C,
    previousCall = 0x542030,
    call = function()
        -- Do nothing!
    end,
    signature = {
        this = "uint",
        arguments = { "float" },
    }
})
-- Sneak tweak unnecessary as Mort's mod Stealh Improved addresses the issue better
--mwse.memory.writeNoOperation({ address = 0x530A76, length = 0x6 })
--mwse.memory.writeNoOperation({ address = 0x530A83, length = 0x6 })
