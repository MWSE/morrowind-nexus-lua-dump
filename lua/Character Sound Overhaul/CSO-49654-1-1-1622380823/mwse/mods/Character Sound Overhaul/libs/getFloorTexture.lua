-- raycast adjustments, relative to the calling actor
local OFFSET = tes3vector3.new(0, 0, 64)
local DOWN = tes3vector3.new(0, 0, -1)


-- Sanitize a texture name so it can be consistently identified.
--
-- The engine is rather forgiving with textures, they can:
-- 1. Be relative to "textures" or "data files/textures".
-- 2. Have various different file extensions.
-- 3. Have arbitrary usage of front/back slashes.
-- 4. Have arbitrary mixture of character casing.
--
-- This function attempts to normalize those properties.
local cache = {}
local function sanitize(fileName)
	local result = cache[fileName]

	if not result then
		result = fileName:lower():gsub("/", "\\")
		if result:find("^textures\\") then
			result = result:sub(10, -5)
		elseif result:find("^data files\\textures\\") then
			result = result:sub(21, -5)
		else
			result = result:sub(1, -5)
		end
		cache[fileName] = result
	end

	return result
end


local function getFloorTexture(ref, ignoreList)
	local rayhit = tes3.rayTest{
		position = ref.position + OFFSET,
		direction = DOWN,
		-- allow the raycast to go an extra 12 units below foot level
		-- to account for floating due to inaccurate collision meshes
		maxDistance = 64+12,
		ignore = {ref}
	}
	if rayhit then
        -- ignore actors and anything with mesh in ignoreList
        if rayhit.reference then
            local mesh = rayhit.reference.object.mesh:lower()
            if rayhit.reference.mobile or ignoreList[mesh] then
                return
            end
        end

        local texturingProperty = rayhit.object:getProperty(0x4)
        if texturingProperty then
            local baseMap = texturingProperty.maps[1]
            local texture = baseMap and baseMap.texture
            if texture and texture.fileName then
                return sanitize(texture.fileName)
            end
        end
	end
end


-- Ugly hack for player footstep sounds.

-- The problem: When walking across wooden docks and such the raycast may
-- slip between the wood beams and exceed the maximum distance. This causes
-- us to fallback to vanilla footstep sounds and can be quite jarring.

-- The solution: Store the last valid texture for the player reference and
-- re-use it if the current operation failed to find a new valid texture.
local playerLastTexture
local function getFloorTextureHack(ref, ignoreList)
	local result = getFloorTexture(ref, ignoreList)
	if ref == tes3.player then
		if result then
			playerLastTexture = result
		else
			result = playerLastTexture
		end
	end
	return result
end


return getFloorTextureHack
