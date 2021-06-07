local function onGoldDropped(e)
	if math.random(2) == 1 and ( e.reference.id == "Gold_001" or string.match(e.reference.id, "Coin") or string.match(e.reference.id, "coin") ) then
		e.reference.orientation = {
			e.reference.orientation.x,
			e.reference.orientation.y + math.pi,
			e.reference.orientation.z + math.pi,
		}
		e.reference.position = {
			e.reference.position.x,
			e.reference.position.y,
			e.reference.position.z + 0.45,
		}
		-- tes3.messageBox("Tails!")
	end
end
-- Low priority so the coin flip will be applied after any adjustments made by another mod such as Just Drop It! by Merlord
event.register("itemDropped", onGoldDropped, { priority = -10})