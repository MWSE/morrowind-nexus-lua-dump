local function onMenuStat(e)
	if not e.newlyCreated then
		return
	end

	do	--Moving Birthsign
		local label = e.element:findChild(tes3ui.registerID("MenuStat_birth_layout"))
		label.visible = false
		local sign = e.element:findChild(tes3ui.registerID("birth"))
		sign.visible = false

		--Hide divider
		for i, child in ipairs(label.parent.children) do
			if child == label then
				label.parent.children[i - 1].visible = false
				break
			end
		end

		local birthBlock = e.element:findChild(tes3ui.registerID("MenuStat_class_layout")).parent:createBlock{}
		birthBlock.widthProportional = 1
		birthBlock.autoHeight = true
		birthBlock.childAlignX = -1

		local newLabel = birthBlock:createLabel{text = label.text}
		newLabel.color = label.color
		birthBlock:createLabel{text = sign.text}

		birthBlock:register("help", function()
			sign:triggerEvent("help")
		end)
	end
end
event.register("uiActivated", onMenuStat, {filter = "MenuStat", priority = 1})
--Priority 1 to make sure we're faster than the notoriously slow Merlord and his Character Backgrounds mod.