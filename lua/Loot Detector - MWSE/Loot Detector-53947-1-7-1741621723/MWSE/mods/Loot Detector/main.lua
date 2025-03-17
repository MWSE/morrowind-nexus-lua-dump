--local i18n = mwse.loadTranslations('Loot Detector')
local config = require('Loot Detector.config')

local oldCell = nil

function cellChangedCallback(e)
	oldCell = e.previousCell
end
event.register(tes3.event.cellChanged, cellChangedCallback)

function MeshAttach(Ref,meshName,confSize)	
	local Path = 'LD\\'..meshName..'.nif'
	local Mesh = nil
	Mesh = tes3.loadMesh(Path)	
	if (Ref.sceneNode) then
		local node = Mesh:clone()	
		local node2 = Ref.sceneNode:getObjectByName(meshName)
		if (node2 == nil) then
			Ref.sceneNode:attachChild(node, true)
			Ref.sceneNode:update()			
		else
			-- local boundingBox = Ref.object.boundingBox
			-- if (boundingBox) then
				-- node.translation = (boundingBox.min + boundingBox.max) * 0.5
			-- end	
			local dist = tes3.player.position:distance(Ref.position)
			local objectScale = 0
			if Ref.scale <= 1 then
				objectScale = 1 - Ref.scale 
			end
			node2.scale = dist / 100 * confSize + objectScale
			Ref.sceneNode:update()
		end
	end
end

function MeshDetach(Ref,meshName)
	if (Ref.sceneNode) then
		local node = Ref.sceneNode:getObjectByName(meshName)
		if (node ~= nil) then
			node.parent:detachChild(node)
			Ref.sceneNode:update()
		end
	end
end

function ClearPreviousCell(objectType, meshName)
	if config.ClearPreviousCell == true then
		if oldCell ~= nil then
			for Ref in oldCell:iterateReferences(objectType, false) do
				MeshDetach(Ref, meshName)	
			end
		end
	end
end

function DetectLock(objectType, meshName, confOn, confSize, confDist)
	if confOn == true then
		ClearPreviousCell(objectType, meshName)
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			local dist = tes3.player.position:distance(Ref.position)
			if dist <= confDist then
				if Ref.attachments.variables ~= nil then
					if Ref.attachments.variables.requirement ~= nil then
						if Ref.attachments.variables.requirement ~= -1 then
							if tes3.getOwner({reference = Ref}).playerRank ~= nil then
								if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
									if Ref.attachments.variables.requirement <= tes3.getOwner({reference = Ref}).playerRank then
										if tes3.getLocked({reference = Ref}) == true then
											MeshAttach(Ref, meshName, confSize)
										else
											MeshDetach(Ref, meshName)
										end							
									end
								end
							end
						end
					end
				end				
				if tes3.getOwner({reference = Ref}) == nil then
					if tes3.getLocked({reference = Ref}) == true then
						MeshAttach(Ref, meshName, confSize)
					else
						MeshDetach(Ref, meshName)
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

function DetectLockOwner(objectType, meshName, confOn, confSize, confDist)
	if confOn == true then
		ClearPreviousCell(objectType, meshName..'Owner')
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			local dist = tes3.player.position:distance(Ref.position)
			if dist <= confDist then		
				if tes3.getOwner({reference = Ref}) ~= nil then
					if Ref.attachments.variables ~= nil then
						if Ref.attachments.variables.requirement ~= nil then
							if Ref.attachments.variables.requirement ~= -1 then
								if tes3.getOwner({reference = Ref}).playerRank ~= nil then
									if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
										if Ref.attachments.variables.requirement > tes3.getOwner({reference = Ref}).playerRank then
											if tes3.getLocked({reference = Ref}) == true then
												MeshAttach(Ref, meshName..'Owner', confSize)
											end
											if tes3.getLocked({reference = Ref}) == false then
												MeshDetach(Ref, meshName..'Owner')
											end							
										end
									end
								end
							else
								if Ref.attachments.variables.requirement == -1 then
									if tes3.getLocked({reference = Ref}) == true then
										MeshAttach(Ref, meshName..'Owner', confSize)
									end
									if tes3.getLocked({reference = Ref}) == false then
										MeshDetach(Ref, meshName..'Owner')
									end									
								end
							end
						end				
					end
					if tes3.getLocked({reference = Ref}) == true then
						MeshAttach(Ref, meshName..'Owner', confSize)
					end
					if tes3.getLocked({reference = Ref}) == false then
						MeshDetach(Ref, meshName..'Owner')
					end
				end	
			else
				MeshDetach(Ref, meshName..'Owner')
			end
		end
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName..'Owner')
		end	
	end
end

-- local function target(e)
	-- local ref = e.current
	-- if ref and ref.object and (ref.object.objectType == tes3.objectType.creature or ref.object.objectType == tes3.objectType.npc) then
		-- for _, Stack in pairs(ref.object.inventory) do
			-- tes3.messageBox({message = 'Item: ' .. tostring(Stack.object.id) .. ', canCarry: ' .. tostring(Stack.object.canCarry), duration = 10})
		-- end
	-- end
-- end
-- event.register('activationTargetChanged', target)

function DetectContainer(objectType, meshName, confOn, confValue, confSize, confDist, confWeight)
	if confOn == true then
		ClearPreviousCell(objectType, meshName)
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			if tes3.getLocked({reference = Ref}) == false then
				local count = 0
				Ref:clone()
				for _, Stack in pairs(Ref.object.inventory) do
					if Stack.object.objectType == tes3.objectType.light then
						if Stack.object.canCarry == true then
							if Stack.object.value then
								if confWeight == 0 then
									if Stack.object.value >= confValue then
										count = count + Stack.count
									end
								else
									if math.round(Stack.object.value / Stack.object.weight,0) >= confValue then
										count = count + Stack.count
									end							
								end
							end
						end
					else
						if Stack.object.value then	
							if confWeight == 0 then
								if Stack.object.value >= confValue then
									count = count + Stack.count
								end
							else
								if math.round(Stack.object.value / Stack.object.weight,0) >= confValue then
									count = count + Stack.count
								end
							end
							if config.ShowZeroValueItem == true then
								if Stack.object.value == 0 then
									count = count + Stack.count
								end	
							end						
						end
						if string.find(Stack.object.id, '[Gg]old') ~= nil then
							count = count + Stack.count
						end				
					end
				end
				local dist = tes3.player.position:distance(Ref.position)
				if dist <= confDist then
					if Ref.attachments.variables ~= nil then
						if Ref.attachments.variables.requirement ~= nil then
							if Ref.attachments.variables.requirement ~= -1 then
								if tes3.getOwner({reference = Ref}).playerRank ~= nil then
									if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
										if Ref.attachments.variables.requirement <= tes3.getOwner({reference = Ref}).playerRank then
											if objectType == tes3.objectType.container then	
												if Ref.object.organic == false then
													if count > 0 then
														MeshAttach(Ref, meshName, confSize)
													end
													if count == 0 then
														MeshDetach(Ref, meshName)
													end							
												end
											end							
										end
									end
								end
							end
						end
					end				
					if tes3.getOwner({reference = Ref}) == nil then
						if objectType == tes3.objectType.npc or objectType == tes3.objectType.creature then
							if Ref.mobile then
								if Ref.mobile.health.current <= 0 and string.find(Ref.object.id, '[Ss]ummon') == nil then
									if count > 0 then
										MeshAttach(Ref, meshName, confSize)
									end
									if count == 0 then
										MeshDetach(Ref, meshName)
									end		
								else
									if Ref.mobile.health.current > 0 and Ref.mobile.isDead and string.find(Ref.object.id, '[Ss]ummon') == nil then
										if count > 0 then
											MeshAttach(Ref, meshName, confSize)
										end
										if count == 0 then
											MeshDetach(Ref, meshName)
										end	
									end
								end
							end	
						end
						if objectType == tes3.objectType.container then	
							if Ref.object.organic == false then
								if count > 0 then
									MeshAttach(Ref, meshName, confSize)
								end
								if count == 0 then
									MeshDetach(Ref, meshName)
								end							
							end
						end					
					end
				else
					MeshDetach(Ref, meshName)
				end
			end
		end
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName)
		end	
	end
end

function DetectContainerOwner(objectType, meshName, confOn, confValue, confSize, confDist, confWeight)
	if confOn == true then
		ClearPreviousCell(objectType, meshName..'Owner')
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			if tes3.getLocked({reference = Ref}) == false then
				local count = 0
				Ref:clone()
				for _, Stack in pairs(Ref.object.inventory) do
					if Stack.object.objectType == tes3.objectType.light then
						if Stack.object.canCarry == true then
							if Stack.object.value then
								if confWeight == 0 then
									if Stack.object.value >= confValue then
										count = count + Stack.count
									end
								else
									if math.round(Stack.object.value / Stack.object.weight,0) >= confValue then
										count = count + Stack.count
									end							
								end
							end
						end
					else
						if Stack.object.value then	
							if confWeight == 0 then
								if Stack.object.value >= confValue then
									count = count + Stack.count
								end
							else
								if math.round(Stack.object.value / Stack.object.weight,0) >= confValue then
									count = count + Stack.count
								end
							end
							if config.ShowZeroValueItem == true then
								if Stack.object.value == 0 then
									count = count + Stack.count
								end	
							end						
						end
						if string.find(Stack.object.id, '[Gg]old') ~= nil then
							count = count + Stack.count
						end				
					end
				end
				local dist = tes3.player.position:distance(Ref.position)
				if dist <= confDist then
					if tes3.getOwner({reference = Ref}) ~= nil then
						if Ref.attachments.variables ~= nil then
							if Ref.attachments.variables.requirement ~= nil then
								if Ref.attachments.variables.requirement ~= -1 then
									if tes3.getOwner({reference = Ref}).playerRank ~= nil then
										if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
											if Ref.attachments.variables.requirement > tes3.getOwner({reference = Ref}).playerRank then
												if objectType == tes3.objectType.container then	
													if Ref.object.organic == false then
														if count > 0 then
															MeshAttach(Ref, meshName..'Owner', confSize)
														end
														if count == 0 then
															MeshDetach(Ref, meshName..'Owner')
														end							
													end
												end							
											end
										end
									end
								else
									if Ref.attachments.variables.requirement == -1 then
										if objectType == tes3.objectType.container then	
											if Ref.object.organic == false then
												if count > 0 then
													MeshAttach(Ref, meshName..'Owner', confSize)
												end
												if count == 0 then
													MeshDetach(Ref, meshName..'Owner')
												end							
											end
										end									
									end
								end
							end
						end
						if objectType == tes3.objectType.container then	
							if Ref.object.organic == false then
								if count > 0 then
									MeshAttach(Ref, meshName..'Owner', confSize)
								end
								if count == 0 then
									MeshDetach(Ref, meshName..'Owner')
								end							
							end
						end	
					end
				else
					MeshDetach(Ref, meshName..'Owner')
				end
			end
		end
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName..'Owner')
		end	
	end	
end

function DetectOrganic(objectType, meshName, confOn, confValue, confSize, confDist, confWeight)
	if confOn == true then
		ClearPreviousCell(objectType, meshName)
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			if tes3.getLocked({reference = Ref}) == false then
				local count = 0
				Ref:clone()
				for _, Stack in pairs(Ref.object.inventory) do
					if Stack.object.objectType == tes3.objectType.light then
						if Stack.object.canCarry == true then
							if Stack.object.value then
								if confWeight == 0 then
									if Stack.object.value >= confValue then
										count = count + Stack.count
									end
								else
									if math.round(Stack.object.value / Stack.object.weight,0) >= confValue then
										count = count + Stack.count
									end							
								end
							end
						end
					else
						if Stack.object.value then	
							if confWeight == 0 then
								if Stack.object.value >= confValue then
									count = count + Stack.count
								end
							else
								if math.round(Stack.object.value / Stack.object.weight,0) >= confValue then
									count = count + Stack.count
								end
							end
							if config.ShowZeroValueItem == true then
								if Stack.object.value == 0 then
									count = count + Stack.count
								end	
							end						
						end
						if string.find(Stack.object.id, '[Gg]old') ~= nil then
							count = count + Stack.count
						end				
					end
				end
				local dist = tes3.player.position:distance(Ref.position)
				if dist <= confDist then				
					if Ref.attachments.variables ~= nil then
						if Ref.attachments.variables.requirement ~= nil then
							if Ref.attachments.variables.requirement ~= -1 then
								if tes3.getOwner({reference = Ref}).playerRank ~= nil then
									if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
										if Ref.attachments.variables.requirement <= tes3.getOwner({reference = Ref}).playerRank then
											if Ref.object.organic == true then
												if count > 0 then
													MeshAttach(Ref, meshName, confSize)
												end
												if count == 0 then
													MeshDetach(Ref, meshName)
												end							
											end								
										end
									end
								end
							end
						end
					end
					if tes3.getOwner({reference = Ref}) == nil then
						if Ref.object.organic == true then
							if count > 0 then
								MeshAttach(Ref, meshName, confSize)
							end
							if count == 0 then
								MeshDetach(Ref, meshName)
							end							
						end
					end
				else
					MeshDetach(Ref, meshName)
				end
			end
		end	
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName)
		end	
	end		
end

function DetectOrganicOwner(objectType, meshName, confOn, confValue, confSize, confDist, confWeight)
	if confOn == true then
		ClearPreviousCell(objectType, meshName..'Owner')
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			if tes3.getLocked({reference = Ref}) == false then
				local count = 0
				Ref:clone()
				for _, Stack in pairs(Ref.object.inventory) do
					if Stack.object.objectType == tes3.objectType.light then
						if Stack.object.canCarry == true then
							if Stack.object.value then
								if confWeight == 0 then
									if Stack.object.value >= confValue then
										count = count + Stack.count
									end
								else
									if math.round(Stack.object.value / Stack.object.weight,0) >= confValue then
										count = count + Stack.count
									end							
								end
							end
						end
					else
						if Stack.object.value then	
							if confWeight == 0 then
								if Stack.object.value >= confValue then
									count = count + Stack.count
								end
							else
								if math.round(Stack.object.value / Stack.object.weight,0) >= confValue then
									count = count + Stack.count
								end
							end
							if config.ShowZeroValueItem == true then
								if Stack.object.value == 0 then
									count = count + Stack.count
								end	
							end						
						end
						if string.find(Stack.object.id, '[Gg]old') ~= nil then
							count = count + Stack.count
						end				
					end
				end
				local dist = tes3.player.position:distance(Ref.position)
				if dist <= confDist then
					if tes3.getOwner({reference = Ref}) ~= nil then
						if Ref.attachments.variables ~= nil then
							if Ref.attachments.variables.requirement ~= nil then
								if Ref.attachments.variables.requirement ~= -1 then
									if tes3.getOwner({reference = Ref}).playerRank ~= nil then
										if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
											if Ref.attachments.variables.requirement > tes3.getOwner({reference = Ref}).playerRank then
												if Ref.object.organic == true then
													if count > 0 then
														MeshAttach(Ref, meshName..'Owner', confSize)
													end
													if count == 0 then
														MeshDetach(Ref, meshName..'Owner')
													end							
												end								
											end
										end
									end
								else
									if Ref.attachments.variables.requirement == -1 then
										if Ref.object.organic == true then
											if count > 0 then
												MeshAttach(Ref, meshName..'Owner', confSize)
											end
											if count == 0 then
												MeshDetach(Ref, meshName..'Owner')
											end							
										end									
									end
								end
							end		
						end
						if Ref.object.organic == true then
							if count > 0 then
								MeshAttach(Ref, meshName..'Owner', confSize)
							end
							if count == 0 then
								MeshDetach(Ref, meshName..'Owner')
							end							
						end						
					end
				else
					MeshDetach(Ref, meshName..'Owner')
				end
			end
		end
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName..'Owner')
		end	
	end		
end

function DetectItem(objectType, meshName, lightCarry, confOn, confValue, confSize, confDist, confWeight)
	if confOn == true then
		ClearPreviousCell(objectType, meshName)
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			local dist = tes3.player.position:distance(Ref.position)
			if dist <= confDist then
				if Ref.attachments.variables ~= nil then
					if Ref.attachments.variables.requirement ~= nil then
						if Ref.attachments.variables.requirement ~= -1 then
							if tes3.getOwner({reference = Ref}).playerRank ~= nil then
								if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
									if Ref.attachments.variables.requirement <= tes3.getOwner({reference = Ref}).playerRank then
										if lightCarry == 1 then
											if Ref.object.canCarry then
												if Ref.object.value then
													if confWeight == 0 then								
														if Ref.object.value >= confValue then
															MeshAttach(Ref, meshName, confSize)
														else
															MeshDetach(Ref, meshName)
														end
													else
														if math.round(Ref.object.value / Ref.object.weight,0) >= confValue then
															MeshAttach(Ref, meshName, confSize)
														else
															MeshDetach(Ref, meshName)									
														end
													end
													if config.ShowZeroValueItem == true then
														if Ref.object.value == 0 then
															MeshAttach(Ref, meshName, confSize)
														end	
													end								
												end
											end
										else
											if Ref.object.value then	
												if confWeight == 0 then
													if Ref.object.value >= confValue then
														MeshAttach(Ref, meshName, confSize)
													else
														MeshDetach(Ref, meshName)
													end
												else
													if math.round(Ref.object.value / Ref.object.weight,0) >= confValue then
														MeshAttach(Ref, meshName, confSize)
													else
														MeshDetach(Ref, meshName)									
													end
												end
												if config.ShowZeroValueItem == true then
													if Ref.object.value == 0 then
														MeshAttach(Ref, meshName, confSize)
													end	
												end
											end	
										end												
									end
								end
							end
						end
					end
				end			
				if tes3.getOwner({reference = Ref}) == nil then
					if lightCarry == 1 then
						if Ref.object.canCarry then
							if Ref.object.value then
								if confWeight == 0 then								
									if Ref.object.value >= confValue then
										MeshAttach(Ref, meshName, confSize)
									else
										MeshDetach(Ref, meshName)
									end
								else
									if math.round(Ref.object.value / Ref.object.weight,0) >= confValue then
										MeshAttach(Ref, meshName, confSize)
									else
										MeshDetach(Ref, meshName)									
									end
								end
								if config.ShowZeroValueItem == true then
									if Ref.object.value == 0 then
										MeshAttach(Ref, meshName, confSize)
									end	
								end								
							end
						end
					else
						if Ref.object.value then	
							if confWeight == 0 then
								if Ref.object.value >= confValue then
									MeshAttach(Ref, meshName, confSize)
								else
									MeshDetach(Ref, meshName)
								end
							else
								if math.round(Ref.object.value / Ref.object.weight,0) >= confValue then
									MeshAttach(Ref, meshName, confSize)
								else
									MeshDetach(Ref, meshName)									
								end
							end
							if config.ShowZeroValueItem == true then
								if Ref.object.value == 0 then
									MeshAttach(Ref, meshName, confSize)
								end	
							end
						end	
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

function DetectItemOwner(objectType, meshName, lightCarry, confOn, confValue, confSize, confDist, confWeight)
	if confOn == true then
		ClearPreviousCell(objectType, meshName..'Owner')
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			local dist = tes3.player.position:distance(Ref.position)
			if dist <= confDist then
				if tes3.getOwner({reference = Ref}) ~= nil then
					if Ref.attachments.variables ~= nil then
						if Ref.attachments.variables.requirement ~= nil then
							if Ref.attachments.variables.requirement ~= -1 then
								if tes3.getOwner({reference = Ref}).playerRank ~= nil then
									if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
										if Ref.attachments.variables.requirement > tes3.getOwner({reference = Ref}).playerRank then
											if lightCarry == 1 then
												if Ref.object.canCarry then
													if Ref.object.value then
														if confWeight == 0 then								
															if Ref.object.value >= confValue then
																MeshAttach(Ref, meshName..'Owner', confSize)
															else
																MeshDetach(Ref, meshName..'Owner')
															end
														else
															if math.round(Ref.object.value / Ref.object.weight,0) >= confValue then
																MeshAttach(Ref, meshName..'Owner', confSize)
															else
																MeshDetach(Ref, meshName..'Owner')									
															end
														end
														if config.ShowZeroValueItem == true then
															if Ref.object.value == 0 then
																MeshAttach(Ref, meshName..'Owner', confSize)
															end	
														end								
													end
												end
											else
												if Ref.object.value then	
													if confWeight == 0 then
														if Ref.object.value >= confValue then
															MeshAttach(Ref, meshName..'Owner', confSize)
														else
															MeshDetach(Ref, meshName..'Owner')
														end
													else
														if math.round(Ref.object.value / Ref.object.weight,0) >= confValue then
															MeshAttach(Ref, meshName..'Owner', confSize)
														else
															MeshDetach(Ref, meshName..'Owner')									
														end
													end
													if config.ShowZeroValueItem == true then
														if Ref.object.value == 0 then
															MeshAttach(Ref, meshName..'Owner', confSize)
														end	
													end
												end	
											end												
										end
									end
								end
								if Ref.attachments.variables.requirement == -1 then
									if lightCarry == 1 then
										if Ref.object.canCarry then
											if Ref.object.value then
												if confWeight == 0 then								
													if Ref.object.value >= confValue then
														MeshAttach(Ref, meshName..'Owner', confSize)
													else
														MeshDetach(Ref, meshName..'Owner')
													end
												else
													if math.round(Ref.object.value / Ref.object.weight,0) >= confValue then
														MeshAttach(Ref, meshName..'Owner', confSize)
													else
														MeshDetach(Ref, meshName..'Owner')									
													end
												end
												if config.ShowZeroValueItem == true then
													if Ref.object.value == 0 then
														MeshAttach(Ref, meshName..'Owner', confSize)
													end	
												end								
											end
										end
									else
										if Ref.object.value then	
											if confWeight == 0 then
												if Ref.object.value >= confValue then
													MeshAttach(Ref, meshName..'Owner', confSize)
												else
													MeshDetach(Ref, meshName..'Owner')
												end
											else
												if math.round(Ref.object.value / Ref.object.weight,0) >= confValue then
													MeshAttach(Ref, meshName..'Owner', confSize)
												else
													MeshDetach(Ref, meshName..'Owner')									
												end
											end
											if config.ShowZeroValueItem == true then
												if Ref.object.value == 0 then
													MeshAttach(Ref, meshName..'Owner', confSize)
												end	
											end
										end	
									end								
								end
							end
						end				
					end
					if lightCarry == 1 then
						if Ref.object.canCarry then
							if Ref.object.value then	
								if confWeight == 0 then
									if Ref.object.value >= confValue then
										MeshAttach(Ref, meshName..'Owner', confSize)
									else
										MeshDetach(Ref, meshName..'Owner')
									end
								else
									if math.round(Ref.object.value / Ref.object.weight,0) >= confValue then
										MeshAttach(Ref, meshName..'Owner', confSize)
									else
										MeshDetach(Ref, meshName..'Owner')									
									end
								end
								if Ref.object.value == 0 then
									MeshAttach(Ref, meshName..'Owner', confSize)
								end
							end
						end
					else
						if Ref.object.value then	
							if confWeight == 0 then
								if Ref.object.value >= confValue then
									MeshAttach(Ref, meshName..'Owner', confSize)
								else
									MeshDetach(Ref, meshName..'Owner')
								end
							else
								if math.round(Ref.object.value / Ref.object.weight,0) >= confValue then
									MeshAttach(Ref, meshName..'Owner', confSize)
								else
									MeshDetach(Ref, meshName..'Owner')									
								end
							end
							if Ref.object.value == 0 then
								MeshAttach(Ref, meshName..'Owner', confSize)
							end							
						end	
					end					
				end	
			else
				MeshDetach(Ref, meshName..'Owner')
			end
		end
	else
		for Ref in tes3.player.cell:iterateReferences(objectType) do
			MeshDetach(Ref, meshName..'Owner')
		end	
	end		
end

local currentDist = 0
local currentDistOwner = 0
local currentSize = 0.1
local currentSizeOwner = 0.1
local currentValue = 0
local currentValueOwner = 0

function Detect()
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

	DetectLock(tes3.objectType.door, 'LD_Lock', config.ClosedDoorOn, config.ClosedDoorSize, config.ClosedDoorDist)
	DetectLock(tes3.objectType.container, 'LD_Lock', config.ClosedContainerOn, config.ClosedContainerSize, config.ClosedContainerDist)
	DetectContainer(tes3.objectType.container, 'LD_Container', config.ContainerOn, config.ContainerValue, config.ContainerSize, config.ContainerDist, config.ContainerValueConf)
	DetectContainer(tes3.objectType.npc, 'LD_Container', config.NpcOn, config.NpcValue, config.NpcSize, config.NpcDist, config.NpcValueConf)
	DetectContainer(tes3.objectType.creature, 'LD_Container', config.CreatureOn, config.CreatureValue, config.CreatureSize, config.CreatureDist, config.CreatureValueConf)
	DetectOrganic(tes3.objectType.container, 'LD_Organic', config.OrganicOn, config.OrganicValue, config.OrganicSize, config.OrganicDist, config.OrganicValueConf)
	DetectItem(tes3.objectType.light, 'LD_Take', 1, config.ItemLightOn, config.ItemLightValue, config.ItemLightSize, config.ItemLightDist, config.ItemLightValueConf)
	DetectItem(tes3.objectType.book, 'LD_Take', 0, config.ItemBookOn, config.ItemBookValue, config.ItemBookSize, config.ItemBookDist, config.ItemBookValueConf)	
	DetectItem(tes3.objectType.alchemy, 'LD_Take', 0, config.ItemAlchemyOn, config.ItemAlchemyValue, config.ItemAlchemySize, config.ItemAlchemyDist, config.ItemAlchemyValueConf)
	DetectItem(tes3.objectType.ammunition, 'LD_Take', 0, config.ItemAmmunitionOn, config.ItemAmmunitionValue, config.ItemAmmunitionSize, config.ItemAmmunitionDist, config.ItemAmmunitionValueConf)
	DetectItem(tes3.objectType.apparatus, 'LD_Take', 0, config.ItemApparatusOn, config.ItemApparatusValue, config.ItemApparatusSize, config.ItemApparatusDist, config.ItemApparatusValueConf)
	DetectItem(tes3.objectType.armor, 'LD_Take', 0, config.ItemArmorOn, config.ItemArmorValue, config.ItemArmorSize, config.ItemArmorDist, config.ItemArmorValueConf)
	DetectItem(tes3.objectType.clothing, 'LD_Take', 0, config.ItemClothingOn, config.ItemClothingValue, config.ItemClothingSize, config.ItemClothingDist, config.ItemClothingValueConf)
	DetectItem(tes3.objectType.enchantment, 'LD_Take', 0, config.ItemEnchantmentOn, config.ItemEnchantmentValue, config.ItemEnchantmentSize, config.ItemEnchantmentDist, config.ItemEnchantmentValueConf)
	DetectItem(tes3.objectType.ingredient, 'LD_Take', 0, config.ItemIngredientOn, config.ItemIngredientValue, config.ItemIngredientSize, config.ItemIngredientDist, config.ItemIngredientValueConf)
	DetectItem(tes3.objectType.lockpick, 'LD_Take', 0, config.ItemLockpickOn, config.ItemLockpickValue, config.ItemLockpickSize, config.ItemLockpickDist, config.ItemLockpickValueConf)
	DetectItem(tes3.objectType.miscItem, 'LD_Take', 0, config.ItemMiscItemOn, config.ItemMiscItemValue, config.ItemMiscItemSize, config.ItemMiscItemDist, config.ItemMiscItemValueConf)
	DetectItem(tes3.objectType.probe, 'LD_Take', 0, config.ItemProbeOn, config.ItemProbeValue, config.ItemProbeSize, config.ItemProbeDist, config.ItemProbeValueConf)
	DetectItem(tes3.objectType.repairItem, 'LD_Take', 0, config.ItemRepairItemOn, config.ItemRepairItemValue, config.ItemRepairItemSize, config.ItemRepairItemDist, config.ItemRepairItemValueConf)
	DetectItem(tes3.objectType.spell, 'LD_Take', 0, config.ItemSpellOn, config.ItemSpellValue, config.ItemSpellSize, config.ItemSpellDist, config.ItemSpellValueConf)
	DetectItem(tes3.objectType.weapon, 'LD_Take', 0, config.ItemWeaponOn, config.ItemWeaponValue, config.ItemWeaponSize, config.ItemWeaponDist, config.ItemWeaponValueConf)
	
	DetectLockOwner(tes3.objectType.door, 'LD_Lock', config.ClosedDoorOwner, config.ClosedDoorOwnerSize, config.ClosedDoorOwnerDist)
	DetectLockOwner(tes3.objectType.container, 'LD_Lock', config.ClosedContainerOwner, config.ClosedContainerOwnerSize, config.ClosedContainerOwnerDist)	
	DetectContainerOwner(tes3.objectType.container, 'LD_Container', config.ContainerOwner, config.ContainerOwnerValue, config.ContainerOwnerSize, config.ContainerOwnerDist, config.ContainerOwnerValueConf)	
	DetectOrganicOwner(tes3.objectType.container, 'LD_Organic', config.OrganicOwner, config.OrganicOwnerValue, config.OrganicOwnerSize, config.OrganicOwnerDist, config.OrganicOwnerValueConf)
	DetectItemOwner(tes3.objectType.light, 'LD_Take', 1, config.ItemLightOwner, config.ItemLightOwnerValue, config.ItemLightOwnerSize, config.ItemLightOwnerDist, config.ItemLightOwnerValueConf)
	DetectItemOwner(tes3.objectType.book, 'LD_Take', 0, config.ItemBookOwner, config.ItemBookOwnerValue, config.ItemBookOwnerSize, config.ItemBookOwnerDist, config.ItemBookOwnerValueConf)	
	DetectItemOwner(tes3.objectType.alchemy, 'LD_Take', 0, config.ItemAlchemyOwner, config.ItemAlchemyOwnerValue, config.ItemAlchemyOwnerSize, config.ItemAlchemyOwnerDist, config.ItemAlchemyOwnerValueConf)	
	DetectItemOwner(tes3.objectType.ammunition, 'LD_Take', 0, config.ItemAmmunitionOwner, config.ItemAmmunitionOwnerValue, config.ItemAmmunitionOwnerSize, config.ItemAmmunitionOwnerDist, config.ItemAmmunitionOwnerValueConf)	
	DetectItemOwner(tes3.objectType.apparatus, 'LD_Take', 0, config.ItemApparatusOwner, config.ItemApparatusOwnerValue, config.ItemApparatusOwnerSize, config.ItemApparatusOwnerDist, config.ItemApparatusOwnerValueConf)	
	DetectItemOwner(tes3.objectType.armor, 'LD_Take', 0, config.ItemArmorOwner, config.ItemArmorOwnerValue, config.ItemArmorOwnerSize, config.ItemArmorOwnerDist, config.ItemArmorOwnerValueConf)	
	DetectItemOwner(tes3.objectType.clothing, 'LD_Take', 0, config.ItemClothingOwner, config.ItemClothingOwnerValue, config.ItemClothingOwnerSize, config.ItemClothingOwnerDist, config.ItemClothingOwnerValueConf)	
	DetectItemOwner(tes3.objectType.enchantment, 'LD_Take', 0, config.ItemEnchantmentOwner, config.ItemEnchantmentOwnerValue, config.ItemEnchantmentOwnerSize, config.ItemEnchantmentOwnerDist, config.ItemEnchantmentOwnerValueConf)	
	DetectItemOwner(tes3.objectType.ingredient, 'LD_Take', 0, config.ItemIngredientOwner, config.ItemIngredientOwnerValue, config.ItemIngredientOwnerSize, config.ItemIngredientOwnerDist, config.ItemIngredientOwnerValueConf)	
	DetectItemOwner(tes3.objectType.lockpick, 'LD_Take', 0, config.ItemLockpickOwner, config.ItemLockpickOwnerValue, config.ItemLockpickOwnerSize, config.ItemLockpickOwnerDist, config.ItemLockpickOwnerValueConf)	
	DetectItemOwner(tes3.objectType.miscItem, 'LD_Take', 0, config.ItemMiscItemOwner, config.ItemMiscItemOwnerValue, config.ItemMiscItemOwnerSize, config.ItemMiscItemOwnerDist, config.ItemMiscItemOwnerValueConf)	
	DetectItemOwner(tes3.objectType.probe, 'LD_Take', 0, config.ItemProbeOwner, config.ItemProbeOwnerValue, config.ItemProbeOwnerSize, config.ItemProbeOwnerDist, config.ItemProbeOwnerValueConf)	
	DetectItemOwner(tes3.objectType.repairItem, 'LD_Take', 0, config.ItemRepairItemOwner, config.ItemRepairItemOwnerValue, config.ItemRepairItemOwnerSize, config.ItemRepairItemOwnerDist, config.ItemRepairItemOwnerValueConf)	
	DetectItemOwner(tes3.objectType.spell, 'LD_Take', 0, config.ItemSpellOwner, config.ItemSpellOwnerValue, config.ItemSpellOwnerSize, config.ItemSpellOwnerDist, config.ItemSpellOwnerValueConf)	
	DetectItemOwner(tes3.objectType.weapon, 'LD_Take', 0, config.ItemWeaponOwner, config.ItemWeaponOwnerValue, config.ItemWeaponOwnerSize, config.ItemWeaponOwnerDist, config.ItemWeaponOwnerValueConf)	
  
	myTimer = timer.start({duration = config.UpdateSpeed, callback = Detect})
end

local function onCommand(e)
	if tes3ui.menuMode() then
        return
    end
	if e.keyCode ~= config.key.keyCode then return end
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
event.register(tes3.event.keyDown, onCommand)

local function NewGame(e)
	if e.newGame then
		local data = tes3.getPlayerRef().data
		data.loot_detector_sh = 0
	end
end
event.register('load', NewGame)

function onLoaded()
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

-- function DetectWait(e)
    -- if e.waiting then
		-- Detect()
    -- end
-- end

local objType = {tes3.objectType.door,tes3.objectType.container,tes3.objectType.light,tes3.objectType.book,tes3.objectType.alchemy,
				tes3.objectType.ammunition,tes3.objectType.apparatus,tes3.objectType.armor,tes3.objectType.clothing,tes3.objectType.enchantment,
				tes3.objectType.ingredient,tes3.objectType.lockpick,tes3.objectType.miscItem,tes3.objectType.probe,tes3.objectType.repairItem,
				tes3.objectType.spell,tes3.objectType.weapon}
				
function Init()
	mwse.log('[Loot Detector] lua script loaded')
    --event.register("calcRestInterrupt", DetectWait)
end
event.register('initialized', Init)

event.register('modConfigReady', function() require('Loot Detector.mcm') end)