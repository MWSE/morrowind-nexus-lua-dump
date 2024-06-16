local lib = require("Flin.lib")

-- card slot class
--- @class CardSlot
--- @field card Card?
--- @field handle mwseSafeObjectHandle?
--- @field position tes3vector3
--- @field orientation tes3vector3
local CardSlot = {
    card = nil,
    handle = nil
}

-- constructor
--- @param position tes3vector3
--- @param orientation tes3vector3
--- @return CardSlot
function CardSlot:new(position, orientation)
    ---@type CardSlot
    local newObj = {
        position = position,
        orientation = orientation
    }
    setmetatable(newObj, self)
    self.__index = self
    return newObj
end

---@param card Card
function CardSlot:AddCardToSlot(card)
    self.card = card
    self.handle = tes3.makeSafeObjectHandle(
        tes3.createReference({
            object = lib.GetCardActivatorName(card.suit, card.value),
            position = self.position,
            orientation = self.orientation,
            cell = tes3.player.cell
        })
    )
end

---@param refId string
function CardSlot:AddRefToSlot(refId)
    local ref = tes3.createReference({
        object = refId,
        position = self.position,
        orientation = self.orientation,
        cell = tes3.player.cell
    })

    self.handle = tes3.makeSafeObjectHandle(ref)
end

function CardSlot:RemoveRef()
    if self.handle then
        if self.handle:valid() then
            self.handle:getObject():delete()
        end
        self.handle = nil
    end
end

---@return Card?
function CardSlot:RemoveCardFromSlot()
    if self.handle then
        if self.handle:valid() then
            self.handle:getObject():delete()
        end
        self.handle = nil
    end

    local card_ = self.card
    self.card = nil

    return card_
end

---@param z number
function CardSlot:MoveUp(z)
    local offset = tes3vector3.new(0, 0, z)
    -- move the reference up
    if self.handle then
        local ref = self.handle:valid() and self.handle:getObject()
        if ref then
            ref.position = ref.position + offset
        end
    end
end

return CardSlot
