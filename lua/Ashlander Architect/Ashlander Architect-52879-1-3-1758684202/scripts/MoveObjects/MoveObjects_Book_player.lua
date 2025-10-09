local ui = require("openmw.ui")
local I = require("openmw.interfaces")

local v2 = require("openmw.util").vector2
local v3 = require("openmw.util").vector3
local util = require("openmw.util")
local cam = require("openmw.interfaces").Camera
local core = require("openmw.core")
local self = require("openmw.self")
local nearby = require("openmw.nearby")
local types = require("openmw.types")
local storage = require("openmw.storage")
local camera = require("openmw.camera")
local input = require("openmw.input")
local ui = require("openmw.ui")
local async = require("openmw.async")
local bookcaseData = {
    {
        recordId = "furn_com_r_bookshelf_01",
        model = "meshes\\f\\Furn_Com_Bookshelf_01.NIF",
        twoSided = false,
        zRotOffset = -90,
        shelfZOffset={-80,-42,0,42},
        shelfMaxHeight = {45,45,45,0}
    },
    {
        recordId = "furn_de_r_bookshelf_02",
        model = "meshes\\f\\Furn_De_Bookshelf_02.NIF",
        twoSided = true,
        zRotOffset = -90,
        shelfZOffset={-53,-4,44},
        shelfMaxHeight = {45,45,0}
    },
    {
        recordId = "furn_de_r_shelf_01",
        model = "meshes\\f\\Furn_De_Bookshelf_02.NIF",
        twoSided = false,
        zRotOffset = -90,
        shelfZOffset={-10},
        shelfMaxHeight = {0}
    }
}
local function getBookcaseData(object)
    -- if (object.recordId == nil or object.type == nil or object.type.record == nil or object.record(object) == nil) then
    --     return nil
    --  end
    for index, data in ipairs(bookcaseData) do
        if (data.recordId == object.recordId or object.type.record(object).model == data.model) then
            return data
        end
    end
    return nil
end
local function isBookCase(object)
    if (getBookcaseData(object)) then
        return true
    else
        return false
    end
end

local function getRotationForCase(book, case, teleport)
    local data = getBookcaseData(case)
    if (data == nil) then
        return nil
    end
    local zRot = data.zRotOffset
    local ret = util.vector3(math.rad(270), case.rotation.z + math.rad(zRot), 0)
    if (teleport) then
        I.DaisyUtilsAA.teleportItem(book, book.position, util.vector)
    end
    return ret
end
local function getPosOnShelf(bkOb, shelfOb, closePos)

end

return {
    interfaceName = "MoveObjects_Book",
    interface = {
        version = 1,
        getPosOnShelf = getPosOnShelf,
        getBookcaseData = getBookcaseData,
        isBookCase = isBookCase,
        getRotationForCase = getRotationForCase,
    },
    eventHandlers = {
    },
    engineHandlers = {
    }
}
