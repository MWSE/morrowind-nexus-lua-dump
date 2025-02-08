local config = {
    attributes = { "strength", "intelligence", "willpower", "agility", "speed", "endurance", "personality", "luck" },
}

local function AttributeIncrease()
    local mobilePlayer = tes3.mobilePlayer

    for _, attribute in ipairs(config.attributes) do
        local currentAttribute = mobilePlayer[attribute]
        
        if currentAttribute.base < 100 then
            currentAttribute.base = currentAttribute.base + 1
        end
		
		if currentAttribute.current < currentAttribute.base then
			currentAttribute.current = currentAttribute.base
		end
    end
end

local function AAPPL()
    AttributeIncrease()
    tes3.messageBox("AAPPL executed")
end

event.register("preLevelUp", AAPPL)

event.register("initialized", function()
    tes3.messageBox("AAPPL loaded")
end)
