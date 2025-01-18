local common = require("mer.midnightOil.common")
local logger = common.createLogger("dungeon")
local config = require("mer.midnightOil.config").getConfig()

local Dungeon = {}

---@param cell tes3cell
function Dungeon.cellIsDungeon(cell)
    --A dungeon is an interior cell
    if not cell.isInterior then
        logger:debug("Cell %s is not an interior cell", cell.id)
        return false
    end
    --A dungeon has no NPCs
    for ref in cell:iterateReferences(tes3.objectType.npc) do
        if not (ref.isDead or ref.disabled) then
            logger:debug("Cell %s has NPCs", cell.id)
            return false
        end
    end
    return true
end

---@param cell tes3cell
function Dungeon:new(cell)
    logger:debug("Attempting to create dungeon for cell %s", cell.id)
    if common.cellIsBlacklisted(cell) then
        logger:debug("Cell %s is blacklisted", cell.id)
        return nil
    end
    if not Dungeon.cellIsDungeon(cell) then
        logger:debug("Cell %s is not a dungeon", cell.id)
        return nil
    end
    logger:debug("Cell %s is a dungeon", cell.id)
    local dungeon = {
        cell = cell,
    }
    setmetatable(dungeon, self)
    self.__index = self
    return dungeon
end

function Dungeon:isProcessed()
    local isProcessed = tes3.player.data.tmo_processedDungeons
        and tes3.player.data.tmo_processedDungeons[self.cell.id]
    logger:debug("Dungeon %s has been processed: %s", self.cell.id, isProcessed)
    return isProcessed
end

function Dungeon:setProcessed()
    logger:debug("Setting dungeon %s as processed", self.cell.id)
    if not tes3.player.data.tmo_processedDungeons then
        logger:debug("Creating tmo_processedDungeons table")
        tes3.player.data.tmo_processedDungeons = {}
    end
    tes3.player.data.tmo_processedDungeons[self.cell.id] = true
end

function Dungeon:isValidLight(reference)
    return common.canProcessLight(reference)
end

function Dungeon:processLights()
    logger:debug("Processing dungeon %s", self.cell.id)
    if self:isProcessed() then
        logger:debug("Dungeon %s has already been processed", self.cell.id)
        return
    end
    for reference in self.cell:iterateReferences(tes3.objectType.light) do
        if self:isValidLight(reference) then
            logger:debug("Removing light %s", reference.object.id)
            common.removeLight(reference)
        end
    end
    logger:debug("Dungeon %s has been processed", self.cell.id)
    self:setProcessed()
end



return Dungeon