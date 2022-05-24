local this = {}

event.register("uiObjectTooltip", function(e)
    local name = e.itemData and e.itemData.data.jamrockRename
    local label = e.tooltip:findChild("HelpMenu_name")
    if label and name then
        label.text = name
    end
end)


function this.addItemAsName(item, name, recipient, count)

	count = count or 1

	local item = tes3.getObject(item)


	tes3.addItem{
		reference = recipient,
		item = item,
		count = 1,
	}
	
	tes3.addItemData({to = recipient, item = item})
	
	item.itemData.data.jamrockRename = name
	
	tes3ui.refreshTooltip()
	
	return

end

function this.renameItem(item, name, ref)

	if not item.itemData then
		item.itemData = tes3.addItemData({to = ref, item = item})
	end
	item.itemData.data.jamrockRename = name
	
	tes3ui.refreshTooltip()

end

return this