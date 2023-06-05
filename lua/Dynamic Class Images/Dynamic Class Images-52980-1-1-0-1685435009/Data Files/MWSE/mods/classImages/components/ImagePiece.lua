local common = require("classImages.common")
local logger = common.createLogger("ImagePiece")

---@alias ClassImages.ImagePiece.slot
---| `"Background_Left"`
---| `"Background_Middle"`
---| `"Background_Right"`
---| `"Midground_Left"`
---| `"Midground_Middle"`
---| `"Midground_Right"`
---| `"Foreground_Left"`
---| `"Foreground_Middle"`
---| `"Foreground_Right"`
---| `"Below_Left"`
---| `"Below_Middle"`
---| `"Below_Right"`
---| `"Above_Left"`
---| `"Above_Middle"`
---| `"Above_Right"`

---@alias ClassImages.ImagePiece.shieldState
---| `"none"` # Doesn't care if shield is active
---| `"isShield"` # Counts as a shield
---| `"requiresShield"` # Requires a shield to be active
---| `"noShield"` # Requires a shield to be inactive



---@class ClassImages.ImagePiece.SkillRequirement
---@field type tes3.skill
---@field major boolean? # If true, must be a major skill
---@field minor boolean? # If true, must be a minor skill
---@field negative boolean? # If true, must NOT have this skill

---@class ClassImages.ImagePiece.AttributeRequirement
---@field type tes3.attribute
---@field negative boolean? # If true, must NOT have this attribute

---@class ClassImages.ImagePiece.Specialisation
---@field type tes3.specialization
---@field negative boolean? # If true, must NOT have this specialisation

---@class ClassImages.ImagePiece.ClassRequirement
---@field type string

---@class ClassImages.ImagePiece.config
---@field texture string
---@field priority number
---@field slots ClassImages.ImagePiece.slot[] # Slots that this piece can be used in
---@field excludedPieces number[]? # `Default: {}` Pieces that this piece cannot be used with
---@field shieldState ClassImages.ImagePiece.shieldState? `Default: "none"`
---@field isGold boolean # `Default: false` If true, this piece will be used for gold
---@field isFiller boolean? # `Default: false` If true, this piece will be used to fill in empty slots
---@field skillRequirements ClassImages.ImagePiece.SkillRequirement[]? `Default: {}`
---@field attributeRequirements ClassImages.ImagePiece.AttributeRequirement[]? `Default: {}`
---@field specialisationRequirements ClassImages.ImagePiece.Specialisation[]? `Default: {}`
---@field classRequirements ClassImages.ImagePiece.ClassRequirement[]? `Default: {}`
---@field isOr boolean # If true, any one of the requirements for a given stat will count

---@class ClassImages.ImagePiece : ClassImages.ImagePiece.config
local ImagePiece = {
    ---@type table<number, ClassImages.ImagePiece> key: priority
    registeredPieces = {}
}

---@param e ClassImages.ImagePiece
function ImagePiece.register(e)
    --validate
    logger:assert(type(e.texture) == "string", "ImagePiece texture must be a string")
    logger:assert(type(e.priority) == "number", "ImagePiece priority must be a number")
    logger:assert(type(e.slots) == "table", "ImagePiece slots must be a table")
    --set defaults
    ---@type ClassImages.ImagePiece
    local imagePiece = {
        texture = e.texture,
        priority = e.priority,
        slots = e.slots,
        excludedPieces = e.excludedPieces or {},
        shieldState = e.shieldState or "none",
        isGold = e.isGold or false,
        isFiller = e.isFiller or false,
        skillRequirements = e.skillRequirements or {},
        attributeRequirements = e.attributeRequirements or {},
        specialisationRequirements = e.specialisationRequirements or {},
        classRequirements = e.classRequirements or {},
        isOr = e.isOr or false
    }
    logger:assert(type(imagePiece.priority) == "number", "ImagePiece priority must be a number")
    logger:debug("registering %s - %s", imagePiece.texture, imagePiece.priority)
    table.insert(ImagePiece.registeredPieces, imagePiece)
end

function ImagePiece:getRegisteredPieces()
    table.sort(ImagePiece.registeredPieces, function(a, b)
        return a.priority < b.priority
    end)
    return ImagePiece.registeredPieces
end

return ImagePiece