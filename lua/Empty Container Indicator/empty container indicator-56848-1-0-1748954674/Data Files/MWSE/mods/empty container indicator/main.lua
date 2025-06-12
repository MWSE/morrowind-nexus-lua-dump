-- Mod name: Empty container indicator
-- Author: skmrSharma
-- Description: Adds "(empty)" text to the tooltip if the barrel/chest/crate/any other container is empty.

local function uiObjectTooltipCallback(e)
	if tes3.menuMode() then
		return
	end
	if e.object.objectType ~= tes3.objectType.container then
		return
	end

	-- isEmpty is set to true only after player empties the container
	if #e.object.inventory == 0 or e.reference.isEmpty then
		local element = e.tooltip:getContentElement()
		local container_label = element:findChild(tes3ui.registerID("HelpMenu_name"))
		container_label.text = container_label.text .. " (empty)"
	end
end

local function onInitialized()
	event.register("uiObjectTooltip", uiObjectTooltipCallback)
	print("[Empty Container Indicator] initialized")
end
event.register("initialized", onInitialized)
