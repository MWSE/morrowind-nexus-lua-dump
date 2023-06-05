local common = require("classImages.common")
local config = require("classImages.config")
local logger = common.createLogger("Requirements")
local inspect = require("inspect")
local FakeClass = require("classImages.components.FakeClass")

---@class ClassImages.Requirements
local Requirements = {}

---@param piece ClassImages.ImagePiece
---@param class tes3class
function Requirements.checkClassRequirements(piece, class)
    logger:debug("    checking %d class reqs", table.size(piece.classRequirements))
    if table.size(piece.classRequirements) > 0 then
        for _, classRequirement in ipairs(piece.classRequirements) do
            logger:debug("    checking %s", classRequirement.type)
            if classRequirement.type:lower() == class.id:lower() then
                logger:debug("    PASSED (class id)")
                return true
            else
                logger:debug("    %s FAILED - missing class requirement %s", piece.texture, classRequirement.type)
                return false
            end
        end
    end
end

---@param piece ClassImages.ImagePiece
---@param class tes3class
function Requirements.checkSkillRequirements(piece, class)
    logger:debug("    1. checking %d skill reqs", table.size(piece.skillRequirements))
    local majorSkills = table.invert(class.majorSkills)
    local minorSkills = table.invert(class.minorSkills)
    local allSkills = table.copy(majorSkills, table.copy(minorSkills))
    local hasOne = false
    for _, skillRequirement in ipairs(piece.skillRequirements) do
        local skillname = table.find(tes3.skill, skillRequirement.type)
        logger:debug("    checking %s", skillname)
        local skillsTable
        if skillRequirement.major == true then
            logger:debug("    - major")
            skillsTable = majorSkills
        elseif skillRequirement.minor == true then
            logger:debug("    - minor")
            skillsTable = minorSkills
        else
            skillsTable = allSkills
        end

        if piece.isOr then
            logger:debug("    is OR")
            if skillRequirement.negative then
                logger:debug("    - negative")
                if skillsTable[skillRequirement.type] then
                    hasOne = true
                end
            else
                logger:debug("    - positive")
                if skillsTable[skillRequirement.type] then
                    hasOne = true
                end
            end
        else
            logger:debug("    is AND")
            if skillRequirement.negative then
                logger:debug("    - negative")
                if skillsTable[skillRequirement.type] then
                    logger:debug("    %s FAILED - has negative skill requirement %s", piece.texture, skillname)
                    return false
                end
            else
                logger:debug("    - positive")
                if not skillsTable[skillRequirement.type] then
                    logger:debug("    %s FAILED - missing positive skill requirement %s", piece.texture, skillname)
                    return false
                end
            end
        end
    end

    if piece.isOr == true and not hasOne then
        logger:debug("    %s FAILED - No skill requirements met (isOr=true)", piece.texture)
        return false
    end

    return true
end

---@param piece ClassImages.ImagePiece
---@param class tes3class
function Requirements.checkAttributeRequirements(piece, class)
    local attributes = class.attributes
    logger:debug("    2. checking %d attribute reqs", table.size(piece.attributeRequirements))
    for _, attributeRequirement in ipairs(piece.attributeRequirements) do
        local attrName = table.find(tes3.attribute, attributeRequirement.type)
        logger:debug("    checking %s", attrName)
        if attributeRequirement.negative then
            logger:debug("    - negative")
            if attributes[1] == attributeRequirement.type
                or attributes[2] == attributeRequirement.type
            then
                logger:debug("    %s FAILED - has negative attr requirement %s", piece.texture, attrName)
                return false
            end
        else
            logger:debug("    - positive")
            if attributes[1] ~= attributeRequirement.type
                and attributes[2] ~= attributeRequirement.type
            then
                logger:debug("    %s FAILED - missing positive attr requirement %s", piece.texture, attrName)
                return false
            end
        end
    end

    return true
end

function Requirements.checkSpecialization(piece, class)
    local specialisation = class.specialization
    logger:debug("    3. checking %d specialisation reqs", table.size(piece.specialisationRequirements))
    for _, specialisationRequirement in ipairs(piece.specialisationRequirements) do
        local specName = table.find(tes3.specialization, specialisationRequirement.type)
        logger:debug("    checking %s", specName)
        if specialisationRequirement.negative then
            logger:debug("    - negative")
            if specialisation == specialisationRequirement.type then
                logger:debug("    %s FAILED - has negative spec requirement %s", piece.texture, specName)
                return false
            end
        else
            if specialisation ~= specialisationRequirement.type then
                logger:debug("    %s FAILED - missing positive spec requirement %s", piece.texture, specName)
                return false
            end
        end
    end

    return true
end

function Requirements.hasFreeSlot(slots, piece)
    logger:debug("    checking slots")
    for _, slot in ipairs(piece.slots) do
        if slots[slot] then
            logger:debug("    %s FAILED - slot %s is filled", piece.texture, slot)
            return false
        end
    end
    logger:debug("    slots PASSED")
    return true
end

---@param piecesAdded table<string, number>
---@param piece ClassImages.ImagePiece
function Requirements.checkExclusions(piecesAdded, piece)
    logger:debug("    checking exclusions")
    for _, exclusion in ipairs(piece.excludedPieces) do
        logger:debug("     - checking %s against  exclusions - %s", exclusion, inspect(table.keys(piecesAdded)))
        if piecesAdded[exclusion] then
            logger:debug(    "%s FAILED - exclusion %s is filled", piece.texture, exclusion)
            return false
        end
    end
    logger:debug("    exclusions PASSED")
    return true
end

---@param piece ClassImages.ImagePiece
function Requirements.validForClass(piece)
    local class = FakeClass()
    logger:debug("    checking %s is valid for class %s", piece.texture, class.name)

    ----------------------------------
    -- Class
    -- Unlike the other checks, this one returns if true (matches expected class)
    -- or false (does not match expected class). If nil, there is no class
    -- requirement so continue checking.
    ----------------------------------
    local classRequirement = Requirements.checkClassRequirements(piece, class)
    if classRequirement ~= nil then
        return classRequirement
    end
    logger:debug("    class PASSED")

    ----------------------------------
    -- Skills
    ----------------------------------
    if not Requirements.checkSkillRequirements(piece, class) then
        return false
    end
    logger:debug("    skills PASSED")

    ----------------------------------
    -- Attributes
    ----------------------------------
    if not Requirements.checkAttributeRequirements(piece, class) then
        return false
    end
    logger:debug("    attributes PASSED")

    ----------------------------------
    -- Specialisation
    ----------------------------------
    if not Requirements.checkSpecialization(piece, class) then
        return false
    end

    logger:debug("    specialisation PASSED")
    return true
end

---@param hasShield boolean
---@param piece ClassImages.ImagePiece
function Requirements.checkShieldState(hasShield, piece)
    logger:debug("    checking shield state. hasShield=%s, state=%s", hasShield, piece.shieldState)
    if piece.shieldState == "requiresShield" then
        if not hasShield then
            logger:debug("    %s FAILED - requires shield", piece.texture)
            return false
        end
    elseif piece.shieldState == "noShield" then
        if hasShield then
            logger:debug("    %s FAILED - requires no shield", piece.texture)
            return false
        end
    end
    logger:debug("    shield state PASSED")
    return true
end

---@param piece ClassImages.ImagePiece
function Requirements.checkIsFiller(piece)
    if piece.isFiller then
        return true
    end
    return false
end

---Onyl one gold piece allowed
---@param hasGold boolean
---@param piece ClassImages.ImagePiece
function Requirements.checkGold(hasGold, piece)
    if hasGold == true and piece.isGold == true then
        logger:debug("%s FAILED - gold already present", piece.texture)
        return false
    end
    return true
end

return Requirements