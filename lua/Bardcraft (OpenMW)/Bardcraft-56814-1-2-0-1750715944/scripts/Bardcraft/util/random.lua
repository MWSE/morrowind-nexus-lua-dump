local function hashStringToUnitFloat(seed, str)
	local hash = seed or 0
	for i = 1, #str do
		local c = str:byte(i)
		hash = (hash * 31 + c) % 4294967296 -- keep it in 32-bit range
	end
	-- Convert the hash to a float between 0 and 1
	return (hash % 1000000) / 1000000
end

return {
	hashStringToUnitFloat = hashStringToUnitFloat
}