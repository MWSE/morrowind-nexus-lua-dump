mwse.log("[tw_i and i] Loaded successfully.")

-- Function to remove items from the current cell upon the death of an NPC
local function OnNPCDeathremovestatics(e)
    -- Get the current cell
---------------------------------------------------
mwse.log("====== dead %s", e.reference.object.id )
	if string.sub(e.reference.object.id, 1, 8)  == "ii_fatsu" then 
		-- Check if the current cell exists
		local currentCell = tes3.getPlayerCell()
;mwse.log("====== cel %s", currentCell.id:lower() )		
		if currentCell and currentCell.id:lower() == "iiar_illusion_tunnel" then
			-- Iterate through all static references in the current cell
			for ref in currentCell:iterateReferences(tes3.objectType.static) do
mwse.log("====== ref  %s", ref )			
				if string.sub( ref.object.id:lower(), 1, 9 ) ==  "ii_zs_ec1" or string.sub(ref.object.id:lower(), 1, 9 )  == "ii_zs_ic1"  then  
				--  9
					-- Delete the static reference
					--tes3.disable(ref)
					ref:disable()
				end 
			end
		end
	end
end

-- Register the function to be called on the death of an NPC
event.register(tes3.event.death, OnNPCDeathremovestatics)