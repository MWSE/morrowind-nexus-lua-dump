---@class validator
local this = {}

---@param path string
---@return boolean
function this.IsValidPath(path)
    -- if needed to check extension but many patterns
    if path == nil or path:len() < 4 then -- expects 3 characters extension
        return false
    end

    -- it seems include directory
    if not tes3.getFileExists(path) then
        return false
    end
    return true
end

---@param texture niSourceTexture?
---@return boolean
function this.IsValidTextue(texture)
    if not texture then
        return false
    end
    -- How do I know it failed to load a texture?
    -- If it is an invalid path, a dialog will appear, but if binary is not valid, it will fallback to the error texture.
    -- So I check if the error texture has a resolution of less than 4x4.
    -- It is possible that it is not the error texture, but it would not make sense at that resolution.
    if texture.width <= 4 and texture.height <= 4 then
        return false
    end
    return true
end

return this
