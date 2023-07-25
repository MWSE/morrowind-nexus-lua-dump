--- asset collection for 2D
---@class CardAssetPackage
---@field assets CardAsset[]
---@field back CardAsset
local this = {}

---@param style string?
---@param styleBack string?
---@return CardAssetPackage
function this.new(style, styleBack)
    local data = require("Hanafuda.cardData")
    styleBack = styleBack or style
    ---@type CardAssetPackage
    local instance = {
        assets = data.BuildCardAsset(style),
        back = data.BuildCardBackAsset(styleBack),
    }
    setmetatable(instance, { __index = this })
    return instance
end

---@param self CardAssetPackage
---@param cardId integer
---@return CardAsset
function this.GetAsset(self, cardId)
    return self.assets[cardId]
end

---@param self CardAssetPackage
---@return CardAsset
function this.GetBackAsset(self)
    return self.back
end

return this
