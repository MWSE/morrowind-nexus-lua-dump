-- ╭────────────────────────────────────────────────────────────────────────╮
-- │  Sun's Dusk - Texture Pack Loader                                      │
-- ╰────────────────────────────────────────────────────────────────────────╯

G_iconPacks = G_iconPacks or {}

-- Scan folders:
local ROOTS = {
	{ path = "textures/sunsdusk/staged/",       label = "Staged" },
	{ path = "textures/sunsdusk/transparent/",  label = "Transparent" },
}

function rebuild()
	local byNeed = {}
	
	for rootIndex = 1, #ROOTS do
		local rootConfig = ROOTS[rootIndex]
		local rootPath = rootConfig.path  -- e.g. "textures/sunsdusk/staged/"
		local label = rootConfig.label    -- e.g. "Staged"
		
		-- Collect all packs for this label
		local packSet = {}
		for filePath in vfs.pathsWithPrefix(rootPath) do
			local packId = filePath:match("^" .. rootPath .. "([^/]+)/")
			if packId and not packId:match("^%._") then
				packSet[packId] = true
			end
		end
		
		local packList = {}
		for packId in pairs(packSet) do
			table.insert(packList, packId)
		end
		table.sort(packList, function(a, b) return a:lower() < b:lower() end)
		
		-- Scan each pack
		for packIndex = 1, #packList do
			local packId = packList[packIndex]
			local packBasePath = rootPath .. packId .. "/"
			
			local packExtensions = {}
			local stagesFound = {}        -- stagesFound[needId][stageNumber] = true
			local transparentNeeds = {}   -- transparentNeeds[needId] = true
			
			-- Scan all files in this pack
			for filePath in vfs.pathsWithPrefix(packBasePath) do
				local baseName = filePath:match("([^/]+)$")
				if baseName and not baseName:match("^%._") then
					local needId, stageDigits, ext = baseName:match("^([%w_]+)_(%d+)(%.[^.]+)$")
					
					if needId and stageDigits and ext then
						-- Staged file, e.g. hunger_0.png
						local stageNumber = tonumber(stageDigits)
						if not stagesFound[needId] then
							stagesFound[needId] = {}
						end
						stagesFound[needId][stageNumber] = true
						packExtensions[ext] = (packExtensions[ext] or 0) + 1
					else
						-- Try transparent, e.g. hunger.png
						local needId2, ext2 = baseName:match("^([%w_]+)(%.[^.]+)$")
						if needId2 and ext2 and label == "Transparent" then
							transparentNeeds[needId2] = true
							packExtensions[ext2] = (packExtensions[ext2] or 0) + 1
						end
					end
				end
			end
			
			-- Determine most common file extension
			local maxCount = 0
			local packExtension = ".png"
			for ext, count in pairs(packExtensions) do
				if count > maxCount then
					maxCount = count
					packExtension = ext
				end
			end
			
			-- transparent entries
			for needId in pairs(transparentNeeds) do
				if not byNeed[needId] then
					byNeed[needId] = { availablePacks = {} }
				end
				
				local niceName = packId:gsub("^%l", string.upper) .. " (" .. label .. ")"
				
				if not byNeed[needId][niceName] then
					byNeed[needId][niceName] = {
						id        = packId,
						need      = needId,
						base      = packBasePath,
						stages    = 1,
						variant   = label,
						extension = packExtension,
					}
					table.insert(byNeed[needId].availablePacks, niceName)
				end
			end
			
			-- staged entries
			for needId, stageSet in pairs(stagesFound) do
				if stageSet[0] and stageSet[1] then
					local contiguousCount = 0
					while stageSet[contiguousCount] do
						contiguousCount = contiguousCount + 1
					end

					if contiguousCount >= 2 then
						if not byNeed[needId] then
							byNeed[needId] = { availablePacks = {} }
						end
						
						local niceName = packId:gsub("^%l", string.upper) .. " (" .. label .. ")"
						
						if not byNeed[needId][niceName] then
							byNeed[needId][niceName] = {
								id        = packId,
								need      = needId,
								base      = packBasePath,
								stages    = contiguousCount,
								variant   = label,
								extension = packExtension,
							}
							table.insert(byNeed[needId].availablePacks, niceName)
						end
					end
				end
			end
		end
	end

	-- Sort
	for _, bucket in pairs(byNeed) do
		table.sort(bucket.availablePacks, function(a, b) return a:lower() < b:lower() end)
	end
	
	G_iconPacks = byNeed
	return G_iconPacks
end

rebuild()
