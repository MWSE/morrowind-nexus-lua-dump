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


-- Per-ref raycast cache: re-ray only when the ref has moved more than
-- MOVE_THRESHOLD units since the last successful lookup. Also covers the
-- original "slip through wood-beam gaps" hack -- if a fresh raycast misses
-- we fall back to the last cached texture for the same ref.
local MOVE_THRESHOLD_SQ = 32 * 32

local cacheByRef = setmetatable({}, { __mode = "k" })

local function getFloorTextureHack(ref, ignoreList)
	local pos = ref.position
	local entry = cacheByRef[ref]
	if entry then
		local dx = pos.x - entry.x
		local dy = pos.y - entry.y
		local dz = pos.z - entry.z
		if dx*dx + dy*dy + dz*dz < MOVE_THRESHOLD_SQ then
			return entry.texture
		end
	end

	local result = getFloorTexture(ref, ignoreList)
	if result then
		if entry then
			entry.x, entry.y, entry.z = pos.x, pos.y, pos.z
			entry.texture = result
		else
			cacheByRef[ref] = { x = pos.x, y = pos.y, z = pos.z, texture = result }
		end
		return result
	elseif entry then
		return entry.texture
	end
end


return getFloorTextureHack
