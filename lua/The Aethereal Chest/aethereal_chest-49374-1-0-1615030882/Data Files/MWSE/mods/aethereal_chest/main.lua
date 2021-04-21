
local function aethereal_chest(e)
	-- We only care if the PC is activating something.
	if (e.activator ~= tes3.player) then
		return
	end
	
	
	if (e.target.object.id == "LA_populate" or e.target.object.id == "LA_SaveChest") then
	--	for key,_ in pairs(tes3ui) do
	--		mwse.log("Key: "..key)
	--	end
	--	mwse.log(mwse.version
	
		local chest=tes3.getReference("de_p_chest_02_aetherial")
		local stuff=chest.object.inventory
		
		local ath_chest={}
		local inner_chest={}
		local outer_chest={}

		
		if (e.target.object.id == "LA_populate") then
			ath_chest=json.loadfile("chest_save")
			if (ath_chest == nil or ath_chest["outer"]["N"]==0) then
				tes3.messageBox("No saved chest")
				return
			end
			
			tes3.messageBox("Populating chest with saved items...")
	--		for _,tes3iteratorNode in pairs(stuff) do
	--			mwse.log("id: %s N: %s", tes3iteratorNode.object.id, tes3iteratorNode.count)
	--			mwscript.removeItem({reference=chest,item=tes3iteratorNode.object.id,count=tes3iteratorNode.count})					
	--		end
			
			
			for key,val in pairs(ath_chest["inner"]) do
				mwse.log(key.." "..val["item"].." "..val["count"])
				mwscript.addItem({reference=chest,item=val["item"],count=val["count"]})
			end
	--		tes3ui.updateInventorySelectTiles()
			tes3ui.forcePlayerInventoryUpdate()
		else
			i=0
			for _,tes3iteratorNode in pairs(stuff) do
				mwse.log("id: %s N: %s", tes3iteratorNode.object.id, tes3iteratorNode.count)
				inner_chest[i]={item=tes3iteratorNode.object.id,count=tes3iteratorNode.count}
				i=i+1
			end
			
			outer_chest["N"]=i
			outer_chest["player"]="stubb"
			ath_chest={inner=inner_chest,outer=outer_chest}
			
			if (i==0) then
				tes3.messageBox("Chest is empty.")
			else
				tes3.messageBox("Saving current contents of chest...")
				json.savefile("chest_save",ath_chest)
			end
		end
	end
end


local function initialized()
	event.register("activate",aethereal_chest)
	print("Starting aethereal_chest script.")
end

event.register("initialized", initialized)