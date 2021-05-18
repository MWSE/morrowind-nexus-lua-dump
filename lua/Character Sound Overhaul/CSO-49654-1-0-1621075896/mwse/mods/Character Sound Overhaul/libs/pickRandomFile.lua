local cache = {}

local function collectFiles(dir)
	local files = {}

	for file in lfs.dir(dir) do
		file = file:lower()
		if file:endswith("wav") then
			table.insert(files, file)
		end
	end

	return files
end

local function pickRandomFile(dir)
	dir = dir:lower()

	local files = cache[dir]
	if not files then
		files = collectFiles(dir)
		cache[dir] = files
	end

	return files[math.random(#files)]
end

return pickRandomFile
