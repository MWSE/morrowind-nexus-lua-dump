local JustDropIt = include("mer.justDropIt")
if not JustDropIt then return end

local registeredDropItems = {
    { id = "misc_inkwell", maxSteepness = 10}
}

event.register(tes3.event.initialized, function()
    for _, data in ipairs(registeredDropItems) do
        if JustDropIt.registerItem then
            JustDropIt.registerItem(data)
        end
    end
end)