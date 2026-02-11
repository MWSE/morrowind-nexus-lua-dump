--[[
╭──────────────────────────────────────────────────────────────────────╮
│  Sun's Dusk - Texture Pack Loader									   │
│  Staged + Transparent												   │
╰──────────────────────────────────────────────────────────────────────╯
]]

-- Public table
iconPacks = iconPacks or {}

-- Roots to scan
local ROOTS = {
	{ path = "textures/sunsdusk/staged/",	  label = "Staged" },
	{ path = "textures/sunsdusk/transparent/", label = "Transparent" },
}

-- Find most common extension from a count table

function rebuild()
	local byNeed = {}

	for rootIndex = 1, #ROOTS do
		local rootConfig = ROOTS[rootIndex]
		local rootPath = rootConfig.path
		local variantLabel = rootConfig.label

		-- Collect pack ids directly under this root
		local packSet = {}
		for filePath in vfs.pathsWithPrefix(rootPath) do
			local packId = filePath:match("^" .. rootPath .. "([^/]+)/")
			if packId and not packId:match("^%._") then
				packSet[packId] = true
			end
		end

		-- Stable list of packs
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
			local stagesFound = {}	  -- needId -> {stage indices}
			local transparentNeeds = {} -- needId -> true

			-- Scan all files in this pack
			for filePath in vfs.pathsWithPrefix(packBasePath) do
				local baseName = filePath:match("([^/]+)$")
				if baseName and not baseName:match("^%._") then
					local needId, stageDigits, ext = baseName:match("^([%w_]+)_(%d+)(%.[^.]+)$")
					
					if needId and stageDigits and ext then
						-- Staged file: hunger_0.png
						local stageNumber = tonumber(stageDigits)
						if not stagesFound[needId] then
							stagesFound[needId] = {}
						end
						stagesFound[needId][stageNumber] = true
						packExtensions[ext] = (packExtensions[ext] or 0) + 1
					else
						-- Try transparent: hunger.png
						local needId2, ext2 = baseName:match("^([%w_]+)(%.[^.]+)$")
						if needId2 and ext2 and variantLabel == "Transparent" then
							transparentNeeds[needId2] = true
							packExtensions[ext2] = (packExtensions[ext2] or 0) + 1
						end
					end
				end
			end
			
			-- Determine most common extension of this pack
			local maxCount = 0
			local packExtension = ".png"
			for ext, count in pairs(packExtensions) do
				if count > maxCount then
					maxCount = count
					packExtension = ext
				end
			end

			-- Add transparent entries
			for needId in pairs(transparentNeeds) do
				if not byNeed[needId] then
					byNeed[needId] = { availablePacks = {} }
				end
				
				local niceName = packId:gsub("^%l", string.upper) .. " (" .. variantLabel .. ")"
				
				if not byNeed[needId][niceName] then
					byNeed[needId][niceName] = {
						id		= packId,
						need	  = needId,
						base	  = packBasePath,
						stages	= 1,
						variant   = variantLabel,
						extension = packExtension,
					}
					table.insert(byNeed[needId].availablePacks, niceName)
				end
			end

			-- Add staged entries (requires contiguous stages starting at 0)
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
						
						local niceName = packId:gsub("^%l", string.upper) .. " (" .. variantLabel .. ")"
						
						if not byNeed[needId][niceName] then
							byNeed[needId][niceName] = {
								id		= packId,
								need	  = needId,
								base	  = packBasePath,
								stages	= contiguousCount,
								variant   = variantLabel,
								extension = packExtension,
							}
							table.insert(byNeed[needId].availablePacks, niceName)
						end
					end
				end
			end
		end
	end

	-- Stable sort within each need
	for _, bucket in pairs(byNeed) do
		table.sort(bucket.availablePacks, function(a, b) return a:lower() < b:lower() end)
	end

	iconPacks = byNeed
	return iconPacks
end

rebuild()
