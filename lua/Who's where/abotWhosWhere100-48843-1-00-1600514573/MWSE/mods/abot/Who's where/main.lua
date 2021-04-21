-- Interesting actors you talked to and where you encountered them

local author = 'abot'
local modName = "Who's where"
local mcmName = author .. "'s " .. modName

local function getActors()
	local actor, ref, cell, lcId, actorName, cellName
	local keys = {}
	local actors = {}
	local count = 0
	for dialogue in tes3.iterate(tes3.mobilePlayer.dialogueList) do
		for info in tes3.iterate(dialogue.info) do
			actor = info.firstHeardFrom
			if actor then
				if actor.cloneCount == 1 then
					lcId = actor.id:lower()
					if not keys[lcId] then
						actorName = actor.name
						ref = tes3.getReference(lcId)
						if ref then
							cell = ref.cell
							if cell then
								cellName = cell.name
								if cellName then
									if not cell.isInterior then
										cellName = string.format("%s (%s, %s)", cellName, cell.gridX, cell.gridY)
									end
									keys[lcId] = true
									count = count + 1
									actors[count] = {name = actorName, cell = cellName, cellAndName = cellName .. ': ' .. actorName}
									---mwse.log("%s at %s", actorName, cellName)
								end -- if cellName
							end -- if ref.cell
						end -- if ref
					end -- if not keys[lcId]
				end -- if actor.cloneCount
				break
			end -- if actor
		end -- for info
	end -- for dialogue
	return actors
end

local function modConfigReady()
	local actors
	local template = mwse.mcm:createTemplate(mcmName)
	template:register()
	local page = template:createPage({})

	local noneYet = 'None yet'

	local category1 = page:createCategory("Who's where (by name):")
	category1:createInfo({
		text = '',
		---inGameOnly = true,
		postCreate = function(self)
			local s = noneYet
			if tes3.player then
				actors = getActors()
				if #actors > 0 then
					table.sort(actors, function(a,b) return a.name < b.name end)
					s = ''
					for _, v in pairs(actors) do
						s = string.format("%s%s at %s\n", s, v.name, v.cell)
					end
				end
			end
			self.elements.info.text = s
		end
	})

	local category2 = page:createCategory("Who's where (by place, name):")
	category2:createInfo({
		text = '',
		---inGameOnly = true,
		postCreate = function(self)
			local s = noneYet
			if tes3.player then
				if not actors then
					actors = getActors()
				end
				if #actors > 0 then
					table.sort(actors, function(a,b) return a.cellAndName < b.cellAndName end)
					s = ''
					for _, v in pairs(actors) do
						s = string.format("%s%s\n", s, v.cellAndName)
					end
				end
				actors = nil
			end
			self.elements.info.text = s
		end
	})
end
event.register('modConfigReady', modConfigReady)
