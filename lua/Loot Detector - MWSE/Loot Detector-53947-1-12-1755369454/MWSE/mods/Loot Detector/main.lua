--local i18n = mwse.loadTranslations('Loot Detector')
local config = require('Loot Detector.config')

local oldCell = nil
local currentDist = 0
local currentDistOwner = 0
local currentSize = 0.1
local currentSizeOwner = 0.1
local currentValue = 0
local currentValueOwner = 0
--local myTimer

local objType = {tes3.objectType.npc,tes3.objectType.creature,tes3.objectType.door,tes3.objectType.container,tes3.objectType.light,tes3.objectType.book,
				tes3.objectType.alchemy,tes3.objectType.ammunition,tes3.objectType.apparatus,tes3.objectType.armor,tes3.objectType.clothing,
				tes3.objectType.enchantment,tes3.objectType.ingredient,tes3.objectType.lockpick,tes3.objectType.miscItem,tes3.objectType.probe,
				tes3.objectType.repairItem,tes3.objectType.spell,tes3.objectType.weapon}

local function MeshAttach(Ref, meshName, confSize)	
	local Mesh = tes3.loadMesh('LD\\'..meshName..'.nif')
	local node = Mesh:clone()
	local dist = tes3.player.position:distance(Ref.position)
	local objectScale = 0
	if Ref.scale <= 1 then
		objectScale = 1 - Ref.scale 
	end	
	if (Ref.sceneNode) then	
		local node2 = Ref.sceneNode:getObjectByName(meshName)
		if (node2 == nil) then
			node.scale = dist / 100 * confSize + objectScale
			Ref.sceneNode:attachChild(node, true)	
			Ref.sceneNode:update()
		else	
			node2.scale = dist / 100 * confSize + objectScale
			Ref.sceneNode:update()
		end	
	end
end

local function MeshDetach(Ref, meshName)
	if Ref.sceneNode then
		local node = Ref.sceneNode:getObjectByName(meshName)
		if (node ~= nil) then
			node.parent:detachChild(node)
			Ref.sceneNode:update()
		end
	end
end

local function ClearPreviousCell(objectType, meshName)
	if config.ClearPreviousCell == true then
		if oldCell ~= nil then
			for Ref in oldCell:iterateReferences(objectType) do
				Ref:clone()
				MeshDetach(Ref, meshName)	
			end
		end
	end
end

local function ClearOldMesh(Ref)
	local node = Ref.sceneNode:getObjectByName('LD_Container') or Ref.sceneNode:getObjectByName('LD_ContainerOwner')
	if (node ~= nil) then
		MeshDetach(Ref, 'LD_Container') 
		MeshDetach(Ref, 'LD_ContainerOwner')
	end
end

local function AttachItemsContainer(Item, count, Weight, Ref, meshName, confValue, confSize, confGold)
	if math.round(tes3.getValue({item = Item.object.id, useDurability = false}) / Weight,0) >= confValue then
		if Item.object.objectType == tes3.objectType.light then
			if Item.object.canCarry == true then
				count = count + Item.count
				MeshAttach(Ref, meshName, confSize)
			end
		else
			if string.find(Item.object.id, '[Gg]old_0') == nil and string.find(Item.object.id, '[Gg]old_1') == nil then
				if Item.object.script ~= nil then
					if Item.object.script.id ~= 'GBG_nopickup' then
						count = count + Item.count
						MeshAttach(Ref, meshName, confSize)
					end
				else
					count = count + Item.count
					MeshAttach(Ref, meshName, confSize)
				end
			end
		end
	end	
	if string.find(Item.object.id, '[Gg]old_0') ~= nil or string.find(Item.object.id, '[Gg]old_1') ~= nil then
		if confGold == true then
			count = count + Item.count
			MeshAttach(Ref, meshName, confSize)
		else
			if math.round(tes3.getValue({item = Item.object.id, useDurability = false}) / Weight * Item.count,0) >= confValue then
				count = count + Item.count
				MeshAttach(Ref, meshName, confSize)
			end
		end
	end
	return count
end

local function CheckItemsContainer(Ref, meshName, confWeight, confValue, confSize, confGold)
	local count = 0
	for _, Item in pairs(Ref.object.inventory) do
		local Weight = 1
		if tes3.getValue({item = Item.object.id, useDurability = false}) ~= nil then
			if tes3.getValue({item = Item.object.id, useDurability = false}) > 0 then
				if confWeight == 0 then	
					count = AttachItemsContainer(Item, count, Weight, Ref, meshName, confValue, confSize, confGold)				
				else					
					if Item.object.weight > 0 then 
						Weight = Item.object.weight
					end						
					count = AttachItemsContainer(Item, count, Weight, Ref, meshName, confValue, confSize, confGold)	
				end
			else
				if config.ShowZeroValueItem == true then
					if Item.object.objectType == tes3.objectType.light then
						if Item.object.canCarry == true then
							count = count + Item.count
							MeshAttach(Ref, meshName, confSize)
						end
					else
						count = count + Item.count
						MeshAttach(Ref, meshName, confSize)
					end	
				end
			end
		end
	end
	if count == 0 then
		MeshDetach(Ref, meshName)
	end
end

local function AttachItem(Weight, Ref, meshName, confValue, confSize, confGold)
	if math.round(tes3.getValue({reference = Ref, useDurability = false}) / Weight,0) >= confValue then							
		if Ref.object.objectType == tes3.objectType.light then
			if Ref.object.canCarry == true then
				MeshAttach(Ref, meshName, confSize)
			end
		else
			if string.find(Ref.object.id, '[Gg]old_0') == nil and string.find(Ref.object.id, '[Gg]old_1') == nil then
				MeshAttach(Ref, meshName, confSize)
			end
		end
	else
		MeshDetach(Ref, meshName)
	end
	if string.find(Ref.object.id, '[Gg]old_0') ~= nil or string.find(Ref.object.id, '[Gg]old_1') ~= nil then
		if confGold == true then
			MeshAttach(Ref, meshName, confSize)
		else
			if math.round(tes3.getValue({reference = Ref, useDurability = false}) / Weight * 1,0) >= confValue then
				MeshAttach(Ref, meshName, confSize)
			else
				MeshDetach(Ref, meshName)
			end
		end
	end
end

local function CheckItem(Ref, meshName, confWeight, confValue, confSize, confGold)
	local Weight = 1
	if tes3.getValue({reference = Ref, useDurability = false}) ~= nil then
		if tes3.getValue({reference = Ref, useDurability = false}) > 0 then
			if confWeight == 0 then
				AttachItem(Weight, Ref, meshName, confValue, confSize, confGold)
			else
				if Ref.object.weight > 0 then 
					Weight = Ref.object.weight
				end		
				AttachItem(Weight, Ref, meshName, confValue, confSize, confGold)
			end
		else
			if config.ShowZeroValueItem == true then
				if Ref.object.objectType == tes3.objectType.light then
					if Ref.object.canCarry == true then
						MeshAttach(Ref, meshName, confSize)
					end
				else
					MeshAttach(Ref, meshName, confSize)
				end
			else
				MeshDetach(Ref, meshName)
			end
		end
	end
end

local function PlayerRankVariant(Ref, meshName, confWeight, confValue, confSize, Var, confGold)
	if Var == 0 then
		ClearOldMesh(Ref)
		MeshAttach(Ref, meshName, confSize)
	end
	if Var == 1 then
		CheckItemsContainer(Ref, meshName, confWeight, confValue, confSize, confGold)
	end
	if Var == 2 then
		CheckItem(Ref, meshName, confWeight, confValue, confSize, confGold)
	end
end

local function CheckPlayerRank(Ref, meshName, confWeight, confValue, confSize, Var, confGold)
	if tes3.getOwner({reference = Ref}).playerRank ~= nil then
		if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
			if Ref.attachments.variables.requirement <= tes3.getOwner({reference = Ref}).playerRank then
				PlayerRankVariant(Ref, meshName, confWeight, confValue, confSize, Var, confGold)			
			end
		end
	end		
end

local function CheckPlayerRankOwner(Ref, meshName, confWeight, confValue, confSize, Var, confGold)
	if tes3.getOwner({reference = Ref}).playerRank ~= nil then
		if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
			if Ref.attachments.variables.requirement > tes3.getOwner({reference = Ref}).playerRank then
				PlayerRankVariant(Ref, meshName, confWeight, confValue, confSize, Var, confGold)	
			end
		else
			PlayerRankVariant(Ref, meshName, confWeight, confValue, confSize, Var, confGold)	
		end
	end									
end

local function ContainerVariant(objectType, meshName, confValue, confSize, confDist, confWeight, Tr, confGold)
	ClearPreviousCell(objectType, meshName)
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		Ref:clone()			
		local dist = tes3.player.position:distance(Ref.position)
		if dist <= confDist then
			if tes3.getLocked({reference = Ref}) == Tr then
				if tes3.getOwner({reference = Ref}) ~= nil then
					if Ref.attachments.variables ~= nil then
						if Ref.attachments.variables.requirement ~= nil then
							if Ref.object.objectType == tes3.objectType.container then	
								if Ref.object.organic == false then
									if Ref.attachments.variables.requirement ~= -1 then
										CheckPlayerRank(Ref, meshName, confWeight, confValue, confSize, 1, confGold)
									else
										CheckPlayerRank(Ref, meshName, confWeight, confValue, confSize, 1, confGold)
									end
								end
							end
						end
					end
				else					
					if Ref.object.objectType == tes3.objectType.npc or Ref.object.objectType == tes3.objectType.creature then
						if Ref.mobile then
							if Ref.mobile.health.current <= 0 and string.find(Ref.object.id, '[Ss]ummon') == nil then
								CheckItemsContainer(Ref, meshName, confWeight, confValue, confSize, confGold)		
							else
								if Ref.mobile.health.current > 0 and Ref.mobile.isDead and string.find(Ref.object.id, '[Ss]ummon') == nil then
									CheckItemsContainer(Ref, meshName, confWeight, confValue, confSize, confGold)	
								end
							end
						end	
					end
					if Ref.object.objectType == tes3.objectType.container then	
						if Ref.object.organic == false then
							CheckItemsContainer(Ref, meshName, confWeight, confValue, confSize, confGold)								
						end
					end					
				end
			else
				MeshDetach(Ref, meshName)
			end
		else
			MeshDetach(Ref, meshName)
		end
	end	
end

local function ContainerVariantOwner(objectType, meshName, confValue, confSize, confDist, confWeight, Tr, confGold)
	ClearPreviousCell(objectType, meshName)
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		Ref:clone()			
		local dist = tes3.player.position:distance(Ref.position)
		if dist <= confDist then
			if tes3.getLocked({reference = Ref}) == Tr then
				if tes3.getOwner({reference = Ref}) ~= nil then
					if Ref.attachments.variables ~= nil then
						if Ref.attachments.variables.requirement ~= nil then
							if Ref.object.objectType == tes3.objectType.container then	
								if Ref.object.organic == false then
									if Ref.attachments.variables.requirement ~= -1 then
										CheckPlayerRankOwner(Ref, meshName, confWeight, confValue, confSize, 1, confGold)
									else
										CheckPlayerRankOwner(Ref, meshName, confWeight, confValue, confSize, 1, confGold)												
									end
								end
							end
						end
					end
					if tes3.getOwner({reference = Ref}).objectType == tes3.objectType.npc then
						if Ref.object.objectType == tes3.objectType.npc or Ref.object.objectType == tes3.objectType.creature then
							if Ref.mobile then
								if Ref.mobile.health.current <= 0 and string.find(Ref.object.id, '[Ss]ummon') == nil then
									CheckItemsContainer(Ref, meshName, confWeight, confValue, confSize, confGold)		
								else
									if Ref.mobile.health.current > 0 and Ref.mobile.isDead and string.find(Ref.object.id, '[Ss]ummon') == nil then
										CheckItemsContainer(Ref, meshName, confWeight, confValue, confSize, confGold)	
									end
								end
							end	
						end
						if Ref.object.objectType == tes3.objectType.container then	
							if Ref.object.organic == false then
								CheckItemsContainer(Ref, meshName, confWeight, confValue, confSize, confGold)								
							end
						end
					end				
				end
			else
				MeshDetach(Ref, meshName)
			end
		else
			MeshDetach(Ref, meshName)
		end
	end
end

local function DetectLockVariant(objectType, meshName, confValue, confSize, confDist, confWeight, confGold)
	ClearPreviousCell(objectType, meshName)
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		Ref:clone()
		local dist = tes3.player.position:distance(Ref.position)
		if dist <= confDist then
			if tes3.getLocked({reference = Ref}) == true then
				if tes3.getOwner({reference = Ref}) ~= nil then
					if Ref.attachments.variables ~= nil then
						if Ref.attachments.variables.requirement ~= nil then
							if Ref.attachments.variables.requirement ~= -1 then
								CheckPlayerRank(Ref, meshName, nil, nil, confSize, 0, confGold)
							else
								CheckPlayerRank(Ref, meshName, nil, nil, confSize, 0, confGold)							
							end
						end
					end
				else
					ClearOldMesh(Ref)
					MeshAttach(Ref, meshName, confSize)	
				end
			else
				MeshDetach(Ref, meshName)	
			end
		else
			MeshDetach(Ref, meshName)		
		end
	end
end

local function DetectLockVariantOwner(objectType, meshName, confValue, confSize, confDist, confWeight, confGold)
	ClearPreviousCell(objectType, meshName)
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		Ref:clone()
		local dist = tes3.player.position:distance(Ref.position)
		if dist <= confDist then
			if tes3.getLocked({reference = Ref}) == true then
				if tes3.getOwner({reference = Ref}) ~= nil then
					if Ref.attachments.variables ~= nil then
						if Ref.attachments.variables.requirement ~= nil then
							if Ref.attachments.variables.requirement ~= -1 then
								CheckPlayerRankOwner(Ref, meshName, nil, nil, confSize, 0, confGold)
							else
								CheckPlayerRankOwner(Ref, meshName, nil, nil, confSize, 0, confGold)
							end
						end
					end
					if tes3.getOwner({reference = Ref}).objectType == tes3.objectType.npc then
						ClearOldMesh(Ref)
						MeshAttach(Ref, meshName, confSize)
					end
				end
			else
				MeshDetach(Ref, meshName)	
			end
		else
			MeshDetach(Ref, meshName)		
		end
	end
end

local function DetectLockDoor(objectType, meshName, confOn, confValue, confSize, confDist, confWeight, confGold)
	if confOn == true then
		DetectLockVariant(objectType, meshName, confValue, confSize, confDist, confWeight, confGold)
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName)
		end
	end
end

local function DetectLockContainer(objectType, meshName, confOn, confValue, confSize, confDist, confWeight, confGold)
	if config.LockContainerValue == true then
		ContainerVariant(objectType, meshName, confValue, confSize, confDist, confWeight, true, confGold)
	else
		if confOn == true then
			DetectLockVariant(objectType, meshName, confValue, confSize, confDist, confWeight, confGold)
		else
			for Ref in tes3.player.cell:iterateReferences(objectType) do
				MeshDetach(Ref, meshName)
			end
		end
	end
end

local function DetectLockDoorOwner(objectType, meshName, confOn, confValue, confSize, confDist, confWeight, confGold)
	if confOn == true then	
		DetectLockVariantOwner(objectType, meshName, confValue, confSize, confDist, confWeight, confGold)
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName)
		end
	end
end

local function DetectLockContainerOwner(objectType, meshName, confOn, confValue, confSize, confDist, confWeight, confGold)
	if config.LockContainerValueOwner == true then
		ContainerVariantOwner(objectType, meshName, confValue, confSize, confDist, confWeight, true, confGold)
	else
		if confOn == true then	
			DetectLockVariantOwner(objectType, meshName, confValue, confSize, confDist, confWeight, confGold)
		else
			for Ref in tes3.player.cell:iterateReferences(objectType) do
				MeshDetach(Ref, meshName)
			end
		end
	end
end

local function DetectContainer(objectType, meshName, confOn, confValue, confSize, confDist, confWeight, confGold)
	if confOn == true then
		ContainerVariant(objectType, meshName, confValue, confSize, confDist, confWeight, false, confGold)
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName)
		end	
	end
end

local function DetectContainerOwner(objectType, meshName, confOn, confValue, confSize, confDist, confWeight, confGold)
	if confOn == true then
		ContainerVariantOwner(objectType, meshName, confValue, confSize, confDist, confWeight, false, confGold)
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName)
		end	
	end
end

local function DetectOrganic(objectType, meshName, confOn, confValue, confSize, confDist, confWeight, confGold)
	if confOn == true then
		ClearPreviousCell(objectType, meshName)
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			Ref:clone()
			local dist = tes3.player.position:distance(Ref.position)
			if dist <= confDist then
				if tes3.getLocked({reference = Ref}) == false then
					if tes3.getOwner({reference = Ref}) ~= nil then
						if Ref.attachments.variables ~= nil then
							if Ref.attachments.variables.requirement ~= nil then
								if Ref.object.organic == true then
									if Ref.attachments.variables.requirement ~= -1 then
										CheckPlayerRank(Ref, meshName, confWeight, confValue, confSize, 1, confGold)
									else
										CheckPlayerRank(Ref, meshName, confWeight, confValue, confSize, 1, confGold)
									end
								end
							end
						end
					else
						if Ref.object.organic == true then
							CheckItemsContainer(Ref, meshName, confWeight, confValue, confSize, confGold)						
						end
					end
				else
					MeshDetach(Ref, meshName)	
				end
			else
				MeshDetach(Ref, meshName)
			end
		end	
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName)
		end	
	end		
end

local function DetectOrganicOwner(objectType, meshName, confOn, confValue, confSize, confDist, confWeight, confGold)
	if confOn == true then
		ClearPreviousCell(objectType, meshName)
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			Ref:clone()
			local dist = tes3.player.position:distance(Ref.position)
			if dist <= confDist then
				if tes3.getLocked({reference = Ref}) == false then
					if tes3.getOwner({reference = Ref}) ~= nil then
						if Ref.attachments.variables ~= nil then
							if Ref.attachments.variables.requirement ~= nil then
								if Ref.object.organic == true then
									if Ref.attachments.variables.requirement ~= -1 then
										CheckPlayerRankOwner(Ref, meshName, confWeight, confValue, confSize, 1, confGold)
									else
										CheckPlayerRankOwner(Ref, meshName, confWeight, confValue, confSize, 1, confGold)												
									end
								end
							end		
						end
						if tes3.getOwner({reference = Ref}).objectType == tes3.objectType.npc then
							if Ref.object.organic == true then
								CheckItemsContainer(Ref, meshName, confWeight, confValue, confSize, confGold)							
							end
						end
					end
				else
					MeshDetach(Ref, meshName)	
				end
			else
				MeshDetach(Ref, meshName)
			end
		end
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName)
		end	
	end		
end

local function DetectItem(objectType, meshName, confOn, confValue, confSize, confDist, confWeight, confGold)
	if confOn == true then
		ClearPreviousCell(objectType, meshName)
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			Ref:clone()
			local dist = tes3.player.position:distance(Ref.position)
			if dist <= confDist then
				if tes3.getOwner({reference = Ref}) ~= nil then
					if Ref.attachments.variables ~= nil then
						if Ref.attachments.variables.requirement ~= nil then
							if Ref.attachments.variables.requirement ~= -1 then
								CheckPlayerRank(Ref, meshName, confWeight, confValue, confSize, 2, confGold)
							else
								CheckPlayerRank(Ref, meshName, confWeight, confValue, confSize, 2, confGold)
							end
						end
					end
				else
					CheckItem(Ref, meshName, confWeight, confValue, confSize, confGold)	
				end	
			else
				MeshDetach(Ref, meshName)
			end
		end
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName)
		end	
	end		
end

local function DetectItemOwner(objectType, meshName, confOn, confValue, confSize, confDist, confWeight, confGold)
	if confOn == true then
		ClearPreviousCell(objectType, meshName)
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			Ref:clone()
			local dist = tes3.player.position:distance(Ref.position)
			if dist <= confDist then
				if tes3.getOwner({reference = Ref}) ~= nil then
					if Ref.attachments.variables ~= nil then
						if Ref.attachments.variables.requirement ~= nil then
							if Ref.attachments.variables.requirement ~= -1 then
								CheckPlayerRankOwner(Ref, meshName, confWeight, confValue, confSize, 2, confGold)
							else
								CheckPlayerRankOwner(Ref, meshName, confWeight, confValue, confSize, 2, confGold)
							end
						end				
					end
					if tes3.getOwner({reference = Ref}).objectType == tes3.objectType.npc then
						CheckItem(Ref, meshName, confWeight, confValue, confSize, confGold)
					end
				end	
			else
				MeshDetach(Ref, meshName)
			end
		end
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName)
		end	
	end		
end

local function Detect()
	local newDist = config.AllDist
	if currentDist ~= newDist then
		config.ClosedDoorDist = newDist
		config.ClosedContainerDist = newDist
		config.ContainerDist = newDist
		config.OrganicDist = newDist
		config.NpcDist = newDist
		config.CreatureDist = newDist
		config.ItemLightDist = newDist
		config.ItemBookDist = newDist
		config.ItemAlchemyDist = newDist
		config.ItemAmmunitionDist = newDist
		config.ItemApparatusDist = newDist
		config.ItemArmorDist = newDist
		config.ItemClothingDist = newDist
		config.ItemEnchantmentDist = newDist
		config.ItemIngredientDist = newDist
		config.ItemLockpickDist = newDist
		config.ItemMiscItemDist = newDist
		config.ItemProbeDist = newDist
		config.ItemRepairItemDist = newDist
		config.ItemSpellDist = newDist
		config.ItemWeaponDist = newDist
		currentDist = newDist
	end	
	local newDistOwner = config.AllDistOwner
	if currentDistOwner ~= newDistOwner then
		config.ClosedDoorOwnerDist = newDistOwner
		config.ClosedContainerOwnerDist = newDistOwner
		config.ContainerOwnerDist = newDistOwner
		config.OrganicOwnerDist = newDistOwner
		config.NpcOwnerDist = newDistOwner
		config.CreatureOwnerDist = newDistOwner
		config.ItemLightOwnerDist = newDistOwner
		config.ItemBookOwnerDist = newDistOwner
		config.ItemAlchemyOwnerDist = newDistOwner
		config.ItemAmmunitionOwnerDist = newDistOwner
		config.ItemApparatusOwnerDist = newDistOwner
		config.ItemArmorOwnerDist = newDistOwner
		config.ItemClothingOwnerDist = newDistOwner
		config.ItemEnchantmentOwnerDist = newDistOwner
		config.ItemIngredientOwnerDist = newDistOwner
		config.ItemLockpickOwnerDist = newDistOwner
		config.ItemMiscItemOwnerDist = newDistOwner
		config.ItemProbeOwnerDist = newDistOwner
		config.ItemRepairItemOwnerDist = newDistOwner
		config.ItemSpellOwnerDist = newDistOwner
		config.ItemWeaponOwnerDist = newDistOwner
		currentDistOwner = newDistOwner
	end		
	local newSize = config.AllSize
	if currentSize ~= newSize then
		config.ClosedDoorSize = newSize
		config.ClosedContainerSize = newSize
		config.ContainerSize = newSize
		config.OrganicSize = newSize
		config.NpcSize = newSize
		config.CreatureSize = newSize
		config.ItemLightSize = newSize
		config.ItemBookSize = newSize
		config.ItemAlchemySize = newSize
		config.ItemAmmunitionSize = newSize
		config.ItemApparatusSize = newSize
		config.ItemArmorSize = newSize
		config.ItemClothingSize = newSize
		config.ItemEnchantmentSize = newSize
		config.ItemIngredientSize = newSize
		config.ItemLockpickSize = newSize
		config.ItemMiscItemSize = newSize
		config.ItemProbeSize = newSize
		config.ItemRepairItemSize = newSize
		config.ItemSpellSize = newSize
		config.ItemWeaponSize = newSize
		currentSize = newSize
	end	
	local newSizeOwner = config.AllSizeOwner
	if currentSizeOwner ~= newSizeOwner then
		config.ClosedDoorOwnerSize = newSizeOwner
		config.ClosedContainerOwnerSize = newSizeOwner
		config.ContainerOwnerSize = newSizeOwner
		config.OrganicOwnerSize = newSizeOwner
		config.ItemLightOwnerSize = newSizeOwner
		config.ItemBookOwnerSize = newSizeOwner
		config.ItemAlchemyOwnerSize = newSizeOwner
		config.ItemAmmunitionOwnerSize = newSizeOwner
		config.ItemApparatusOwnerSize = newSizeOwner
		config.ItemArmorOwnerSize = newSizeOwner
		config.ItemClothingOwnerSize = newSizeOwner
		config.ItemEnchantmentOwnerSize = newSizeOwner
		config.ItemIngredientOwnerSize = newSizeOwner
		config.ItemLockpickOwnerSize = newSizeOwner
		config.ItemMiscItemOwnerSize = newSizeOwner
		config.ItemProbeOwnerSize = newSizeOwner
		config.ItemRepairItemOwnerSize = newSizeOwner
		config.ItemSpellOwnerSize = newSizeOwner
		config.ItemWeaponOwnerSize = newSizeOwner
		currentSizeOwner = newSizeOwner
	end
	local newValue = config.AllValue
	if currentValue ~= newValue then
		config.ContainerValue = newValue
		config.OrganicValue = newValue
		config.NpcValue = newValue
		config.CreatureValue = newValue
		config.ItemLightValue = newValue
		config.ItemBookValue = newValue
		config.ItemAlchemyValue = newValue
		config.ItemAmmunitionValue = newValue
		config.ItemApparatusValue = newValue
		config.ItemArmorValue = newValue
		config.ItemClothingValue = newValue
		config.ItemEnchantmentValue = newValue
		config.ItemIngredientValue = newValue
		config.ItemLockpickValue = newValue
		config.ItemMiscItemValue = newValue
		config.ItemProbeValue = newValue
		config.ItemRepairItemValue = newValue
		config.ItemSpellValue = newValue
		config.ItemWeaponValue = newValue
		currentValue = newValue
	end	
	local newValueOwner = config.AllValueOwner
	if currentValueOwner ~= newValueOwner then
		config.ContainerOwnerValue = newValueOwner
		config.OrganicOwnerValue = newValueOwner
		config.ItemLightOwnerValue = newValueOwner
		config.ItemBookOwnerValue = newValueOwner
		config.ItemAlchemyOwnerValue = newValueOwner
		config.ItemAmmunitionOwnerValue = newValueOwner
		config.ItemApparatusOwnerValue = newValueOwner
		config.ItemArmorOwnerValue = newValueOwner
		config.ItemClothingOwnerValue = newValueOwner
		config.ItemEnchantmentOwnerValue = newValueOwner
		config.ItemIngredientOwnerValue = newValueOwner
		config.ItemLockpickOwnerValue = newValueOwner
		config.ItemMiscItemOwnerValue = newValueOwner
		config.ItemProbeOwnerValue = newValueOwner
		config.ItemRepairItemOwnerValue = newValueOwner
		config.ItemSpellOwnerValue = newValueOwner
		config.ItemWeaponOwnerValue = newValueOwner
		currentValueOwner = newValueOwner
	end	

	local cell = tes3.getPlayerCell()
	if not config.CellsBL[cell.id:lower()] then
		DetectLockDoor(tes3.objectType.door, 'LD_Lock', config.ClosedDoorOn, nil, config.ClosedDoorSize, config.ClosedDoorDist, nil, config.GoldWithoutValue)
		DetectLockContainer(tes3.objectType.container, 'LD_Lock', config.ClosedContainerOn, config.ContainerValue, config.ClosedContainerSize, config.ClosedContainerDist, config.ContainerValueConf, config.GoldWithoutValue)	
		DetectContainer(tes3.objectType.container, 'LD_Container', config.ContainerOn, config.ContainerValue, config.ContainerSize, config.ContainerDist, config.ContainerValueConf, config.GoldWithoutValue)
		DetectContainer(tes3.objectType.npc, 'LD_Container', config.NpcOn, config.NpcValue, config.NpcSize, config.NpcDist, config.NpcValueConf, config.GoldWithoutValue)
		DetectContainer(tes3.objectType.creature, 'LD_Container', config.CreatureOn, config.CreatureValue, config.CreatureSize, config.CreatureDist, config.CreatureValueConf, config.GoldWithoutValue)
		DetectOrganic(tes3.objectType.container, 'LD_Organic', config.OrganicOn, config.OrganicValue, config.OrganicSize, config.OrganicDist, config.OrganicValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.light, 'LD_Take', config.ItemLightOn, config.ItemLightValue, config.ItemLightSize, config.ItemLightDist, config.ItemLightValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.book, 'LD_Take', config.ItemBookOn, config.ItemBookValue, config.ItemBookSize, config.ItemBookDist, config.ItemBookValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.alchemy, 'LD_Take', config.ItemAlchemyOn, config.ItemAlchemyValue, config.ItemAlchemySize, config.ItemAlchemyDist, config.ItemAlchemyValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.ammunition, 'LD_Take', config.ItemAmmunitionOn, config.ItemAmmunitionValue, config.ItemAmmunitionSize, config.ItemAmmunitionDist, config.ItemAmmunitionValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.apparatus, 'LD_Take', config.ItemApparatusOn, config.ItemApparatusValue, config.ItemApparatusSize, config.ItemApparatusDist, config.ItemApparatusValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.armor, 'LD_Take', config.ItemArmorOn, config.ItemArmorValue, config.ItemArmorSize, config.ItemArmorDist, config.ItemArmorValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.clothing, 'LD_Take', config.ItemClothingOn, config.ItemClothingValue, config.ItemClothingSize, config.ItemClothingDist, config.ItemClothingValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.enchantment, 'LD_Take', config.ItemEnchantmentOn, config.ItemEnchantmentValue, config.ItemEnchantmentSize, config.ItemEnchantmentDist, config.ItemEnchantmentValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.ingredient, 'LD_Take', config.ItemIngredientOn, config.ItemIngredientValue, config.ItemIngredientSize, config.ItemIngredientDist, config.ItemIngredientValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.lockpick, 'LD_Take', config.ItemLockpickOn, config.ItemLockpickValue, config.ItemLockpickSize, config.ItemLockpickDist, config.ItemLockpickValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.miscItem, 'LD_Take', config.ItemMiscItemOn, config.ItemMiscItemValue, config.ItemMiscItemSize, config.ItemMiscItemDist, config.ItemMiscItemValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.probe, 'LD_Take', config.ItemProbeOn, config.ItemProbeValue, config.ItemProbeSize, config.ItemProbeDist, config.ItemProbeValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.repairItem, 'LD_Take', config.ItemRepairItemOn, config.ItemRepairItemValue, config.ItemRepairItemSize, config.ItemRepairItemDist, config.ItemRepairItemValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.spell, 'LD_Take', config.ItemSpellOn, config.ItemSpellValue, config.ItemSpellSize, config.ItemSpellDist, config.ItemSpellValueConf, config.GoldWithoutValue)
		DetectItem(tes3.objectType.weapon, 'LD_Take', config.ItemWeaponOn, config.ItemWeaponValue, config.ItemWeaponSize, config.ItemWeaponDist, config.ItemWeaponValueConf, config.GoldWithoutValue)
		
		DetectLockDoorOwner(tes3.objectType.door, 'LD_LockOwner', config.ClosedDoorOwner, nil, config.ClosedDoorOwnerSize, config.ClosedDoorOwnerDist, nil, config.GoldWithoutValueOwner)	
		DetectLockContainerOwner(tes3.objectType.container, 'LD_LockOwner', config.ClosedContainerOwner, config.ContainerOwnerValue, config.ClosedContainerOwnerSize, config.ClosedContainerOwnerDist, config.ContainerOwnerValueConf, config.GoldWithoutValueOwner)
		DetectContainerOwner(tes3.objectType.container, 'LD_ContainerOwner', config.ContainerOwner, config.ContainerOwnerValue, config.ContainerOwnerSize, config.ContainerOwnerDist, config.ContainerOwnerValueConf, config.GoldWithoutValueOwner)	
		DetectOrganicOwner(tes3.objectType.container, 'LD_OrganicOwner', config.OrganicOwner, config.OrganicOwnerValue, config.OrganicOwnerSize, config.OrganicOwnerDist, config.OrganicOwnerValueConf, config.GoldWithoutValueOwner)
		DetectItemOwner(tes3.objectType.light, 'LD_TakeOwner', config.ItemLightOwner, config.ItemLightOwnerValue, config.ItemLightOwnerSize, config.ItemLightOwnerDist, config.ItemLightOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.book, 'LD_TakeOwner', config.ItemBookOwner, config.ItemBookOwnerValue, config.ItemBookOwnerSize, config.ItemBookOwnerDist, config.ItemBookOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.alchemy, 'LD_TakeOwner', config.ItemAlchemyOwner, config.ItemAlchemyOwnerValue, config.ItemAlchemyOwnerSize, config.ItemAlchemyOwnerDist, config.ItemAlchemyOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.ammunition, 'LD_TakeOwner', config.ItemAmmunitionOwner, config.ItemAmmunitionOwnerValue, config.ItemAmmunitionOwnerSize, config.ItemAmmunitionOwnerDist, config.ItemAmmunitionOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.apparatus, 'LD_TakeOwner', config.ItemApparatusOwner, config.ItemApparatusOwnerValue, config.ItemApparatusOwnerSize, config.ItemApparatusOwnerDist, config.ItemApparatusOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.armor, 'LD_TakeOwner', config.ItemArmorOwner, config.ItemArmorOwnerValue, config.ItemArmorOwnerSize, config.ItemArmorOwnerDist, config.ItemArmorOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.clothing, 'LD_TakeOwner', config.ItemClothingOwner, config.ItemClothingOwnerValue, config.ItemClothingOwnerSize, config.ItemClothingOwnerDist, config.ItemClothingOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.enchantment, 'LD_TakeOwner', config.ItemEnchantmentOwner, config.ItemEnchantmentOwnerValue, config.ItemEnchantmentOwnerSize, config.ItemEnchantmentOwnerDist, config.ItemEnchantmentOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.ingredient, 'LD_TakeOwner', config.ItemIngredientOwner, config.ItemIngredientOwnerValue, config.ItemIngredientOwnerSize, config.ItemIngredientOwnerDist, config.ItemIngredientOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.lockpick, 'LD_TakeOwner', config.ItemLockpickOwner, config.ItemLockpickOwnerValue, config.ItemLockpickOwnerSize, config.ItemLockpickOwnerDist, config.ItemLockpickOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.miscItem, 'LD_TakeOwner', config.ItemMiscItemOwner, config.ItemMiscItemOwnerValue, config.ItemMiscItemOwnerSize, config.ItemMiscItemOwnerDist, config.ItemMiscItemOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.probe, 'LD_TakeOwner', config.ItemProbeOwner, config.ItemProbeOwnerValue, config.ItemProbeOwnerSize, config.ItemProbeOwnerDist, config.ItemProbeOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.repairItem, 'LD_TakeOwner', config.ItemRepairItemOwner, config.ItemRepairItemOwnerValue, config.ItemRepairItemOwnerSize, config.ItemRepairItemOwnerDist, config.ItemRepairItemOwnerValueConf, config.GoldWithoutValueOwner)		
		DetectItemOwner(tes3.objectType.spell, 'LD_TakeOwner', config.ItemSpellOwner, config.ItemSpellOwnerValue, config.ItemSpellOwnerSize, config.ItemSpellOwnerDist, config.ItemSpellOwnerValueConf, config.GoldWithoutValueOwner)				
		DetectItemOwner(tes3.objectType.weapon, 'LD_TakeOwner', config.ItemWeaponOwner, config.ItemWeaponOwnerValue, config.ItemWeaponOwnerSize, config.ItemWeaponOwnerDist, config.ItemWeaponOwnerValueConf, config.GoldWithoutValueOwner)	
	else
		if tes3.player ~= nil then
			for Ref in tes3.player.cell:iterateReferences(objType) do
				MeshDetach(Ref, 'LD_Lock')
				MeshDetach(Ref, 'LD_Container')
				MeshDetach(Ref, 'LD_Organic')
				MeshDetach(Ref, 'LD_Take')
				MeshDetach(Ref, 'LD_LockOwner')
				MeshDetach(Ref, 'LD_ContainerOwner')
				MeshDetach(Ref, 'LD_OrganicOwner')			
				MeshDetach(Ref, 'LD_TakeOwner')
			end
		end
	end
	myTimer = timer.start({duration = config.UpdateSpeed, callback = Detect})
end

local function cellChangedCallback(e)
	oldCell = e.previousCell
end
event.register(tes3.event.cellChanged, cellChangedCallback)

local function BlacklistCells()
 	if tes3ui.menuMode() then
        return
    end
    local cell = tes3.getPlayerCell()
    if not config.CellsBL[cell.id:lower()] then
        config.CellsBL[cell.id:lower()] = true
        tes3.messageBox(string.format("%s added to Blacklist", cell.name))
		mwse.saveConfig("Loot Detector", config)
    else
        config.CellsBL[cell.id:lower()] = nil
        tes3.messageBox(string.format("%s removed from Blacklist", cell.name))
		mwse.saveConfig("Loot Detector", config)
    end
end
event.register("keyDown", BlacklistCells, {filter = config.keyBL.keyCode})

local function ShowHiheIcons()
	if tes3ui.menuMode() then
        return
    end
	local data = tes3.getPlayerRef().data
	if data.loot_detector_sh == 0 then
		if tes3.player ~= nil then
			for Ref in tes3.player.cell:iterateReferences(objType) do
				MeshDetach(Ref, 'LD_Lock')
				MeshDetach(Ref, 'LD_Container')
				MeshDetach(Ref, 'LD_Organic')
				MeshDetach(Ref, 'LD_Take')
				MeshDetach(Ref, 'LD_LockOwner')
				MeshDetach(Ref, 'LD_ContainerOwner')
				MeshDetach(Ref, 'LD_OrganicOwner')			
				MeshDetach(Ref, 'LD_TakeOwner')
			end
		end
		myTimer:pause()
		tes3.messageBox({message = 'Icons hide', duration = 3})
		data.loot_detector_sh = 1
	else
		myTimer:resume()
		tes3.messageBox({message = 'Icons show', duration = 3})
		data.loot_detector_sh = 0
	end	
end
event.register("keyDown", ShowHiheIcons, {filter = config.key.keyCode})

local function NewGame(e)
	if e.newGame then
		local data = tes3.getPlayerRef().data
		data.loot_detector_sh = 0
	end
end
event.register('load', NewGame)

local function onLoaded()
	local data = tes3.getPlayerRef().data
	if data.loot_detector_sh == nil then
		data.loot_detector_sh = 0
	end
	currentDist = config.AllDist
	currentDistOwner = config.AllDistOwner
	currentSize = config.AllSize
	currentSizeOwner = config.AllSizeOwner
	currentValue = config.AllValue
	currentValueOwner = config.AllValueOwner
	Detect()
	if data.loot_detector_sh == 1 then
		if tes3.player ~= nil then
			for Ref in tes3.player.cell:iterateReferences(objType) do
				MeshDetach(Ref, 'LD_Lock')
				MeshDetach(Ref, 'LD_Container')
				MeshDetach(Ref, 'LD_Organic')
				MeshDetach(Ref, 'LD_Take')
				MeshDetach(Ref, 'LD_LockOwner')
				MeshDetach(Ref, 'LD_ContainerOwner')
				MeshDetach(Ref, 'LD_OrganicOwner')			
				MeshDetach(Ref, 'LD_TakeOwner')
			end
		end
		myTimer:pause()
		tes3.messageBox({message = 'Icons hide', duration = 3})
	else
		myTimer:resume()
		tes3.messageBox({message = 'Icons show', duration = 3})
	end	
end
event.register('loaded', onLoaded)
				
local function Init()
	mwse.log('[Loot Detector] lua script loaded')
    --event.register("calcRestInterrupt", DetectWait)
end
event.register('initialized', Init)

event.register('modConfigReady', function() require('Loot Detector.mcm') end)