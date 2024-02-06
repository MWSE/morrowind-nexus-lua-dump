local function initialized(e)
	for book in tes3.iterateObjects(tes3.objectType.book) do
		if book.type == 1 and book.enchantment then
			book.icon = "scrolls\\tx_scroll_" .. book.enchantment.effects[1].id .. ".dds"
		end
	end
end
event.register("initialized", initialized)