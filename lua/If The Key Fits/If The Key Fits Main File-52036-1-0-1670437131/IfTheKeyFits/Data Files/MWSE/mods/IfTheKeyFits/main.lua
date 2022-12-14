local function addTooltip(tooltip)
    local label = tooltip:findChild(tes3ui.registerID("HelpMenu_locked"))
    label.text = label.text .. " (Use Key)"

end

local function onTooltip(e)
	local ref = e.reference
	if e.object.objectType == tes3.objectType.container then
		local keyData = ref.lockNode
		if(keyData ~= nil) then
			if(keyData.locked == true and keyData.key ~= nil) then
				local count = tes3.getItemCount({reference = tes3.mobilePlayer, item = keyData.key})
				if(count > 0) then
					addTooltip(e.tooltip)
				end
			end
		end
    end
	if e.object.objectType == tes3.objectType.door then

		local keyData = ref.lockNode
		if(keyData ~= nil) then
			if(keyData.locked == true and keyData.key ~= nil) then
				local count = tes3.getItemCount({reference = tes3.mobilePlayer, item = keyData.key})
				if(count > 0) then
					addTooltip(e.tooltip)
				end
			end
		end
    end
end
event.register("uiObjectTooltip", onTooltip)