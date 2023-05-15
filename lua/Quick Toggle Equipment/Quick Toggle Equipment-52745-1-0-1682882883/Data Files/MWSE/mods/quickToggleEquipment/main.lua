-- Made by Petethegoat. Thanks to ActuallyUlysses for the idea, and Cyprinus for the name.
local versionString = "1.0"

--- @param bind integer
local function bindingToSlot(bind)
	return bind - 21
end

--- @diagnostic disable: param-type-mismatch
--- @param e keybindTestedEventData
local function onTestUse(e)
	if not e.result then return end

	local quick = tes3.getQuickKey{ slot = bindingToSlot(e.keybind) }
	if quick.type == tes3.quickKeyType.item then
		local player = tes3.player.object
		if ( quick.itemData and player:hasItemEquipped(quick.item, quick.itemData) )
		or ( not quick.itemData and player:hasItemEquipped(quick.item) ) then
			e.block = true
			tes3.mobilePlayer:unequip{item = quick.item, itemData = quick.itemData}
		end
	end
end
--- @diagnostic enable: param-type-mismatch

event.register(tes3.event.keybindTested, onTestUse, { filter = tes3.keybind.quick1 })
event.register(tes3.event.keybindTested, onTestUse, { filter = tes3.keybind.quick2 })
event.register(tes3.event.keybindTested, onTestUse, { filter = tes3.keybind.quick3 })
event.register(tes3.event.keybindTested, onTestUse, { filter = tes3.keybind.quick4 })
event.register(tes3.event.keybindTested, onTestUse, { filter = tes3.keybind.quick5 })
event.register(tes3.event.keybindTested, onTestUse, { filter = tes3.keybind.quick6 })
event.register(tes3.event.keybindTested, onTestUse, { filter = tes3.keybind.quick7 })
event.register(tes3.event.keybindTested, onTestUse, { filter = tes3.keybind.quick8 })
event.register(tes3.event.keybindTested, onTestUse, { filter = tes3.keybind.quick9 })

event.register(tes3.event.modConfigReady, function()
	mwse.log("[Quick Toggle Equipment] " .. versionString .. " loaded successfully.")
end)