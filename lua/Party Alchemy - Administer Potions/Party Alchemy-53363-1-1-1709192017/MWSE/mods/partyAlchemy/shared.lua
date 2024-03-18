local this = {}

--- Administer the potion on the given NPC, interactively.
---
--- Player-only, the weapon/poison must be present in the player's inventory.
---
--- @param reference tes3reference
--- @param potion tes3alchemy
--- @param potionData tes3itemData|nil
function this.administerPotionInteractive(reference, potion, potionData)
    -- callback for 1-frame delay so NPC can receive item to then remove it from their inventory
    local function callback(e)
        -- administer potion to the NPC
        tes3.applyMagicSource{reference=reference, source=potion.id}
        -- this consumes the potion from NPC inventory
        tes3.removeItem{reference=reference, item=potion, itemData=potionData, playSound=false} --Sound\Fx\item\drink.wav
        tes3.playSound{
            reference = tes3.player,
            soundPath = 'Fx\\item\\drink.wav'
        }
    end
    
    --wait for item to land so it can be removed
    timer.frame.delayOneFrame(callback)
end

function this.getPersistentData()
	if (tes3.player == nil) then
		return nil
	end
	local data = tes3.player.data
	if (not data.shan) then
		data.shan = { consume = {} }
	elseif (not data.shan.consume) then
		data.shan.consume = {}
	end
	return data
end

return this