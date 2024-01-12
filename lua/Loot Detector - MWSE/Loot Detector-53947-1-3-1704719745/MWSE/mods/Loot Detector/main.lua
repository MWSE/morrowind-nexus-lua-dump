--local i18n = mwse.loadTranslations('Loot Detector')
local config = require('Loot Detector.config')

local oldCell = nil

function cellChangedCallback(e)
	oldCell = e.previousCell
end
event.register(tes3.event.cellChanged, cellChangedCallback)

function MeshAttach(p1,p2,p3)	
	local Name = p2
	local Path = 'LD\\'..p2..'.nif'
	local Mesh = nil
	Mesh = tes3.loadMesh(Path)	
	if (p1.sceneNode) then
		local node = Mesh:clone()
		local boundingBox = p1.object.boundingBox
		if (boundingBox) then
			node.translation = (boundingBox.min + boundingBox.max) * 0.5
		end
		local dist = tes3.player.position:distance(p1.position)
		local objectScale = 0
		if p1.scale <= 1 then
			objectScale = 1 - p1.scale 
		end
		node.scale = dist / 100 * p3 + objectScale		
		local node2 = p1.sceneNode:getObjectByName(Name)
		if (node2 ~= nil) then
			node2.parent:detachChild(node2)
		end
		p1.sceneNode:attachChild(node, true)		
		p1.sceneNode:update()
		p1.sceneNode:updateNodeEffects()
	end
end

function MeshDetach(p1,p2)
	local Name = p2
	if (p1.sceneNode) then
		local node = p1.sceneNode:getObjectByName(Name)
		if (node ~= nil) then
			node.parent:detachChild(node)
		end
		p1.sceneNode:update()
		p1.sceneNode:updateNodeEffects()	
	end
end

function DetectLock(objectType, meshName, confOn, confSize, confDist)
	if config.ClearPreviousCell == true then
		if oldCell ~= nil then
			for Ref in oldCell:iterateReferences(objectType) do
				MeshDetach(Ref, meshName)
			end
		end
	end
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		local dist = tes3.player.position:distance(Ref.position)
		if dist <= confDist then
			if confOn == true then
				if Ref.attachments.variables ~= nil then
					if Ref.attachments.variables.requirement ~= nil then
						if Ref.attachments.variables.requirement ~= -1 then
							if tes3.getOwner({reference = Ref}).playerRank ~= nil then
								if tes3.getOwner({reference = Ref}).playerRank ~= -1 then
									if Ref.attachments.variables.requirement <= tes3.getOwner({reference = Ref}).playerRank then
										if tes3.getLocked({reference = Ref}) == true then
											MeshAttach(Ref, meshName, confSize)
										end
										if tes3.getLocked({reference = Ref}) == false then
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
					end
					if tes3.getLocked({reference = Ref}) == false then
						MeshDetach(Ref, meshName)
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

function DetectLockOwner(objectType, meshName, confOn, confSize, confDist)
	if config.ClearPreviousCell == true then
		if oldCell ~= nil then
			for Ref in oldCell:iterateReferences(objectType) do
				MeshDetach(Ref, meshName..'Owner')
			end
		end
	end
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		local dist = tes3.player.position:distance(Ref.position)
		if dist <= confDist then
			if confOn == true then
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
		else
			MeshDetach(Ref, meshName..'Owner')
		end
	end
end

function DetectContainer(objectType, meshName, confOn, confValue, confSize, confDist, confWeight)
	if config.ClearPreviousCell == true then
		if oldCell ~= nil then
			for Ref in oldCell:iterateReferences(objectType) do
				MeshDetach(Ref, meshName)
			end
		end
	end
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		if tes3.getLocked({reference = Ref}) == false then
			local count = 0
			Ref:clone()
			for _, Stack in pairs(Ref.object.inventory) do
				if string.find(Stack.object.id, '[Ll]ight') == nil then
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
				if confOn == true then
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
			else
				MeshDetach(Ref, meshName)
			end
		end
	end
end

function DetectContainerOwner(objectType, meshName, confOn, confValue, confSize, confDist, confWeight)
	if config.ClearPreviousCell == true then
		if oldCell ~= nil then
			for Ref in oldCell:iterateReferences(objectType) do
				MeshDetach(Ref, meshName..'Owner')
			end
		end
	end
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		if tes3.getLocked({reference = Ref}) == false then
			local count = 0
			Ref:clone()
			for _, Stack in pairs(Ref.object.inventory) do
				if string.find(Stack.object.id, '[Ll]ight') == nil then
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
				if confOn == true then
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
			else
				MeshDetach(Ref, meshName..'Owner')
			end
		end
	end
end

function DetectOrganic(objectType, meshName, confOn, confValue, confSize, confDist, confWeight)
	if config.ClearPreviousCell == true then
		if oldCell ~= nil then
			for Ref in oldCell:iterateReferences(objectType) do
				MeshDetach(Ref, meshName)
			end
		end
	end
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		if tes3.getLocked({reference = Ref}) == false then
			local count = 0
			Ref:clone()
			for _, Stack in pairs(Ref.object.inventory) do
				if string.find(Stack.object.id, '[Ll]ight') == nil then
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
				end
			end
			local dist = tes3.player.position:distance(Ref.position)
			if dist <= confDist then
				if confOn == true then
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
			else
				MeshDetach(Ref, meshName)
			end
		end
	end
end

function DetectOrganicOwner(objectType, meshName, confOn, confValue, confSize, confDist, confWeight)
	if config.ClearPreviousCell == true then
		if oldCell ~= nil then
			for Ref in oldCell:iterateReferences(objectType) do
				MeshDetach(Ref, meshName..'Owner')
			end
		end
	end
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		if tes3.getLocked({reference = Ref}) == false then
			local count = 0
			Ref:clone()
			for _, Stack in pairs(Ref.object.inventory) do
				if string.find(Stack.object.id, '[Ll]ight') == nil then
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
				end
			end
			local dist = tes3.player.position:distance(Ref.position)
			if dist <= confDist then
				if confOn == true then
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
			else
				MeshDetach(Ref, meshName..'Owner')
			end
		end
	end
end

function DetectItem(objectType, meshName, lightCarry, confOn, confValue, confSize, confDist, confWeight)
	if config.ClearPreviousCell == true then
		if oldCell ~= nil then
			for Ref in oldCell:iterateReferences(objectType) do
				MeshDetach(Ref, meshName)
			end
		end
	end
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		local dist = tes3.player.position:distance(Ref.position)
		if dist <= confDist then
			if confOn == true then
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
		else
			MeshDetach(Ref, meshName)
		end
	end
end

function DetectItemOwner(objectType, meshName, lightCarry, confOn, confValue, confSize, confDist, confWeight)
	if config.ClearPreviousCell == true then
		if oldCell ~= nil then
			for Ref in oldCell:iterateReferences(objectType) do
				MeshDetach(Ref, meshName..'Owner')
			end
		end
	end
	for Ref in tes3.player.cell:iterateReferences(objectType) do
		local dist = tes3.player.position:distance(Ref.position)
		if dist <= confDist then
			if confOn == true then
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
		else
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
		config.ClosedDoorDist = config.AllDist
		config.ClosedContainerDist = config.AllDist
		config.ContainerDist = config.AllDist
		config.OrganicDist = config.AllDist
		config.NpcDist = config.AllDist
		config.CreatureDist = config.AllDist
		config.ItemLightDist = config.AllDist
		config.ItemBookDist = config.AllDist
		config.ItemAlchemyDist = config.AllDist
		config.ItemAmmunitionDist = config.AllDist
		config.ItemApparatusDist = config.AllDist
		config.ItemArmorDist = config.AllDist
		config.ItemClothingDist = config.AllDist
		config.ItemEnchantmentDist = config.AllDist
		config.ItemIngredientDist = config.AllDist
		config.ItemLockpickDist = config.AllDist
		config.ItemMiscItemDist = config.AllDist
		config.ItemProbeDist = config.AllDist
		config.ItemRepairItemDist = config.AllDist
		config.ItemSpellDist = config.AllDist
		config.ItemWeaponDist = config.AllDist
		currentDist = newDist
	end	
	local newDistOwner = config.AllDistOwner
	if currentDistOwner ~= newDistOwner then
		config.ClosedDoorOwnerDist = config.AllDistOwner
		config.ClosedContainerOwnerDist = config.AllDistOwner
		config.ContainerOwnerDist = config.AllDistOwner
		config.OrganicOwnerDist = config.AllDistOwner
		config.NpcOwnerDist = config.AllDistOwner
		config.CreatureOwnerDist = config.AllDistOwner
		config.ItemLightOwnerDist = config.AllDistOwner
		config.ItemBookOwnerDist = config.AllDistOwner
		config.ItemAlchemyOwnerDist = config.AllDistOwner
		config.ItemAmmunitionOwnerDist = config.AllDistOwner
		config.ItemApparatusOwnerDist = config.AllDistOwner
		config.ItemArmorOwnerDist = config.AllDistOwner
		config.ItemClothingOwnerDist = config.AllDistOwner
		config.ItemEnchantmentOwnerDist = config.AllDistOwner
		config.ItemIngredientOwnerDist = config.AllDistOwner
		config.ItemLockpickOwnerDist = config.AllDistOwner
		config.ItemMiscItemOwnerDist = config.AllDistOwner
		config.ItemProbeOwnerDist = config.AllDistOwner
		config.ItemRepairItemOwnerDist = config.AllDistOwner
		config.ItemSpellOwnerDist = config.AllDistOwner
		config.ItemWeaponOwnerDist = config.AllDistOwner
		currentDistOwner = newDistOwner
	end		
	local newSize = config.AllSize
	if currentSize ~= newSize then
		config.ClosedDoorSize = config.AllSize
		config.ClosedContainerSize = config.AllSize
		config.ContainerSize = config.AllSize
		config.OrganicSize = config.AllSize
		config.NpcSize = config.AllSize
		config.CreatureSize = config.AllSize
		config.ItemLightSize = config.AllSize
		config.ItemBookSize = config.AllSize
		config.ItemAlchemySize = config.AllSize
		config.ItemAmmunitionSize = config.AllSize
		config.ItemApparatusSize = config.AllSize
		config.ItemArmorSize = config.AllSize
		config.ItemClothingSize = config.AllSize
		config.ItemEnchantmentSize = config.AllSize
		config.ItemIngredientSize = config.AllSize
		config.ItemLockpickSize = config.AllSize
		config.ItemMiscItemSize = config.AllSize
		config.ItemProbeSize = config.AllSize
		config.ItemRepairItemSize = config.AllSize
		config.ItemSpellSize = config.AllSize
		config.ItemWeaponSize = config.AllSize
		currentSize = newSize
	end	
	local newSizeOwner = config.AllSizeOwner
	if currentSizeOwner ~= newSizeOwner then
		config.ClosedDoorOwnerSize = config.AllSizeOwner
		config.ClosedContainerOwnerSize = config.AllSizeOwner
		config.ContainerOwnerSize = config.AllSizeOwner
		config.OrganicOwnerSize = config.AllSizeOwner
		config.ItemLightOwnerSize = config.AllSizeOwner
		config.ItemBookOwnerSize = config.AllSizeOwner
		config.ItemAlchemyOwnerSize = config.AllSizeOwner
		config.ItemAmmunitionOwnerSize = config.AllSizeOwner
		config.ItemApparatusOwnerSize = config.AllSizeOwner
		config.ItemArmorOwnerSize = config.AllSizeOwner
		config.ItemClothingOwnerSize = config.AllSizeOwner
		config.ItemEnchantmentOwnerSize = config.AllSizeOwner
		config.ItemIngredientOwnerSize = config.AllSizeOwner
		config.ItemLockpickOwnerSize = config.AllSizeOwner
		config.ItemMiscItemOwnerSize = config.AllSizeOwner
		config.ItemProbeOwnerSize = config.AllSizeOwner
		config.ItemRepairItemOwnerSize = config.AllSizeOwner
		config.ItemSpellOwnerSize = config.AllSizeOwner
		config.ItemWeaponOwnerSize = config.AllSizeOwner
		currentSizeOwner = newSizeOwner
	end
	local newValue = config.AllValue
	if currentValue ~= newValue then
		config.ContainerValue = config.AllValue
		config.OrganicValue = config.AllValue
		config.NpcValue = config.AllValue
		config.CreatureValue = config.AllValue
		config.ItemLightValue = config.AllValue
		config.ItemBookValue = config.AllValue
		config.ItemAlchemyValue = config.AllValue
		config.ItemAmmunitionValue = config.AllValue
		config.ItemApparatusValue = config.AllValue
		config.ItemArmorValue = config.AllValue
		config.ItemClothingValue = config.AllValue
		config.ItemEnchantmentValue = config.AllValue
		config.ItemIngredientValue = config.AllValue
		config.ItemLockpickValue = config.AllValue
		config.ItemMiscItemValue = config.AllValue
		config.ItemProbeValue = config.AllValue
		config.ItemRepairItemValue = config.AllValue
		config.ItemSpellValue = config.AllValue
		config.ItemWeaponValue = config.AllValue
		currentValue = newValue
	end	
	local newValueOwner = config.AllValueOwner
	if currentValueOwner ~= newValueOwner then
		config.ContainerOwnerValue = config.AllValueOwner
		config.OrganicOwnerValue = config.AllValueOwner
		config.ItemLightOwnerValue = config.AllValueOwner
		config.ItemBookOwnerValue = config.AllValueOwner
		config.ItemAlchemyOwnerValue = config.AllValueOwner
		config.ItemAmmunitionOwnerValue = config.AllValueOwner
		config.ItemApparatusOwnerValue = config.AllValueOwner
		config.ItemArmorOwnerValue = config.AllValueOwner
		config.ItemClothingOwnerValue = config.AllValueOwner
		config.ItemEnchantmentOwnerValue = config.AllValueOwner
		config.ItemIngredientOwnerValue = config.AllValueOwner
		config.ItemLockpickOwnerValue = config.AllValueOwner
		config.ItemMiscItemOwnerValue = config.AllValueOwner
		config.ItemProbeOwnerValue = config.AllValueOwner
		config.ItemRepairItemOwnerValue = config.AllValueOwner
		config.ItemSpellOwnerValue = config.AllValueOwner
		config.ItemWeaponOwnerValue = config.AllValueOwner
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
  
	timer.start({duration = config.UpdateSpeed, callback = Detect})
end

function onLoaded()
	currentDist = config.AllDist
	currentDistOwner = config.AllDistOwner
	currentSize = config.AllSize
	currentSizeOwner = config.AllSizeOwner
	currentValue = config.AllValue
	currentValueOwner = config.AllValueOwner
	Detect()
end

function DetectWait(e)
    if e.waiting then
        Detect()
    end
end

function Init()
	mwse.log('[Loot Detector] lua script loaded')
    event.register("calcRestInterrupt", DetectWait)
    event.register("loaded", onLoaded)	
end
event.register('initialized', Init)

event.register('modConfigReady', function() require('Loot Detector.mcm') end)