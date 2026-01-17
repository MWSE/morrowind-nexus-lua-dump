local common = require("mer.bardicInspiration.common")

---@class BardicInspiration.Publican
local Publican = {}

local cachedPublican

function Publican.set(publicanRef)
    tes3.player.data.bardicInspiration_currentPublican = publicanRef.id
    cachedPublican = tes3.makeSafeObjectHandle(publicanRef)
end

---@return tes3reference?
function Publican.get()
    if not tes3.player.data.bardicInspiration_currentPublican then return nil end
    if cachedPublican and cachedPublican:valid() then
        return cachedPublican:getObject()
    end
    local ref = tes3.getReference(tes3.player.data.bardicInspiration_currentPublican)
    if ref then
        cachedPublican = tes3.makeSafeObjectHandle(ref)
        return ref
    end
end


return Publican