local isInMournhold = false

local function checkIsInMournhold(currentCell)
    if currentCell.isInterior then
        isInMournhold = currentCell.id:find("Mournhold", 1, true) ~= nil
    end
end

local function onCellChanged()
    local currentCell = tes3.getPlayerCell()
    checkIsInMournhold(currentCell)
end
event.register("cellChanged", onCellChanged)

-- нужен геттер, т.к isInMournhold - простой тип
local function getIsInMournhold()
    return isInMournhold
end

return getIsInMournhold