local this = {}

---Calculates mobile's resistance to leech effects
---@param ref tes3mobileCreature|tes3mobileNPC|tes3mobilePlayer
---@return number
this.getRes = function (ref)
    return math.min(100, ref.resistMagicka)/100
end

return this
