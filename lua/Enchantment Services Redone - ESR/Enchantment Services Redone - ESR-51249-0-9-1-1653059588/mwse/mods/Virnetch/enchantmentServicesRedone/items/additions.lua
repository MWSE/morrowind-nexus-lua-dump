
local common = require("Virnetch.enchantmentServicesRedone.common")

-- Load all possible item additions
local additions = {
	blankScrolls = require("Virnetch.enchantmentServicesRedone.items.additions.blankScrolls")
}

-- For each addition, check if it is enabled
local enabledAdditions = {}
for id, addition in pairs(additions) do
	if addition.enabled then
		common.log:debug("Item addition %s is enabled.", id)
		enabledAdditions[id] = addition
	else
		common.log:debug("Item addition %s is disabled.", id)
	end
end

--- @param e mobileActivatedEventData
local function onMobileActivated(e)
	for _, addition in pairs(enabledAdditions) do
		if addition.requirements(e.reference) then
			addition.addTo(e.reference)
		end
	end
end
event.register(tes3.event.mobileActivated, onMobileActivated)