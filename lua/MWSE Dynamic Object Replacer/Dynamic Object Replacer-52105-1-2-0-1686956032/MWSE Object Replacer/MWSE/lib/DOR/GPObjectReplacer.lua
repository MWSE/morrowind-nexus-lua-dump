local OR = {
    allObjects = {},
    mergedObjects = {},
}

-- Function for parsing _OR_ config files
function OR.loadReplacer(objectsToReplace)
    -- Simple checks for incorrectly formatted files
    if (not objectsToReplace) then
        mwse.log("[Object Replacer] objectsToReplace is nil! Check your _OR_ files!")
        return
    end
    if (not objectsToReplace.objectToReplace0) then
        mwse.log("[Object Replacer] objectToReplace0 is nil! Check your _OR_ files!")
        return
    end
    if (not objectsToReplace.objectToReplace0.oldObject) then
        mwse.log("[Object Replacer] oldObject is nil! Check your _OR_ files!")
        return
    end
    local modObjects = {}
    -- Iterates through object replacers
    for _, objectToReplace in pairs(objectsToReplace) do
        -- Copies base object info to a new object
        local modObject = {}
        modObject.oldObject = objectToReplace.oldObject
        modObject.newObjects = {}
        -- Iterates through possible new objects
        for _, possibleNewObject in pairs(objectToReplace.newObjects) do
            -- Copies new object info to a new object
            local replacerObjects = {}
            local newObject = possibleNewObject.newObject
            local replaceChance = possibleNewObject.replaceChance
            local specificCell = possibleNewObject.specificCell
            local excludedCell = possibleNewObject.excludedCell
            replacerObjects.newObject = newObject
            replacerObjects.replaceChance = replaceChance
            replacerObjects.specificCell = specificCell
            replacerObjects.excludedCell = excludedCell
            -- Inserts new object into new object table
            table.insert(modObject.newObjects, replacerObjects)
        end
        -- Inserts new table into container object
        table.insert(modObjects, modObject)
    end
    -- Returns the container object for the specific config file
    return modObjects
end

-- Function for actually swapping references
function OR.swapObjects(ref, cell, newObj)
    if ref.disabled or ref.deleted then
        return
    end
    local ref_modified = ref.modified
    local cell_modified = cell.modified
    -- Creates a new ref with the same position, orientation, and scale as the old one
    local newRef = tes3.createReference({
        object = newObj.newObject,
        position = ref.position,
        orientation = ref.orientation,
        cell = cell,
        scale = ref.scale,
        itemData = ref.itemData
    })
    if ref.isDead == true then
        newRef.isDead = true
    end
    mwse.log("[Object Replacer] Swapping %s with %s", ref.baseObject.id, newRef.object.id)
    -- Disables the old ref and enables the new replacement ref
    newRef:enable()
    ref:disable()
    -- Resets modified state
    newRef.modified = false
    ref.modified = ref_modified
    cell.modified = cell_modified
end

-- Checks if current cell is in cellList
function OR.checkForCell(cellList, refCell)
    for _, cell in pairs(cellList) do
        local cellString1 = string.trim(string.upper(cell.cellName))
        local cellString2 = string.trim(string.upper(refCell))
        if ((cell.cellName and (string.find(cellString2, cellString1) or cellString2 == cellString1)) or not cell) then
            return true
        end
    end
end

-- New function to avoid scanning on cell change
function OR.onReferenceActivated(e)
    local ref = e.reference
    local attemptedReplace = false
    local actuallyReplaced = false
    local specificCell
    local excludedCell
    -- Does not swap sourceless refs
    if not ref.sourceMod then return end
    -- Iterates through object replacers for each reference
    for _, obj in pairs(OR.mergedObjects) do
        -- Checks for matching object and that this object has not already had an attempt to replace
        if (ref.baseObject.id == obj.oldObject and (not ref.data or not ref.data.GPDOR or not ref.data.GPDOR.attemptedReplace) and attemptedReplace == false) then
            -- Saves attempted flag to save file to ensure the ref will be exempt from future attempts
            if ref.supportsLuaData then
                ref.data.GPDOR = {}
                ref.data.GPDOR.attemptedReplace = true
            end
            attemptedReplace = true
            -- Iterates through possible new objects
            for _, newObj in pairs(obj.newObjects) do
                -- checks for matching cells
                if newObj.specificCell then
                    specificCell = OR.checkForCell(newObj.specificCell, ref.cell.id)
                end
                -- ends early if current cell is excluded
                if newObj.excludedCell then
                    excludedCell = OR.checkForCell(newObj.excludedCell, ref.cell.id)
                end
                if excludedCell then return end
                -- Checks for matching cell and that the object has not *actually* been replaced
                if ((specificCell or not newObj.specificCell) and (not ref.data or not ref.data.GPDOR or not ref.data.GPDOR.actuallyReplaced) and actuallyReplaced == false) then
                    -- If guaranteed replace chance, then replace
                    if (newObj.replaceChance == 1) then
                        -- Saves replaced flag to save file
                        if ref.supportsLuaData then
                            ref.data.GPDOR.actuallyReplaced = true 
                        end
                        actuallyReplaced = true
                        OR.swapObjects(ref, ref.cell, newObj)
                    -- Otherwise calculate replace with random float
                    else
                        local randChance = math.random()
                        if (randChance < newObj.replaceChance) then
                            -- Saves replaced flag to save file
                            if ref.supportsLuaData then
                                ref.data.GPDOR.actuallyReplaced = true 
                            end
                            actuallyReplaced = true
                            OR.swapObjects(ref, ref.cell, newObj)
                        end
                    end
                end
            end
        end
    end
end

-- Loads OR config files from data files/mwse/mods/_OR_
function OR.loadORFiles()
    -- OR.allObjects = {}
    local subDir = "data files\\mwse\\mods\\_OR_\\"
    -- Iterates through directory
    for filePath, dir, fileName in lfs.walkdir(subDir) do
        -- Checks for proper file name
        if string.find(fileName, "_OR_") then
            mwse.log("[Object Replacer] Found _OR_ file with file name: %s", fileName)
            -- Loads the config file
            local modifiedPath = string.gsub(filePath, "data files\\mwse\\mods\\", "")
            local luaFile = require(string.gsub(modifiedPath, ".lua", ""))
            local replacerObject = OR.loadReplacer(luaFile)
            -- Iterates through the config file and inserts them into allObjects
            for _, objectToReplace in pairs(replacerObject) do
                table.insert(OR.allObjects, objectToReplace)
            end
        end
    end
    OR.mergeReplacers()
end

function OR.loadORFile(filepath)
    -- Loads the config file
    local luaFile = require(filepath)
    local replacerObject = OR.loadReplacer(luaFile)
    -- Iterates through the config file and inserts them into allObjects
    for _, objectToReplace in pairs(replacerObject) do
        table.insert(OR.allObjects, objectToReplace)
    end
    OR.mergeReplacers()
end

-- Function for sorting tables by specificCell and replaceChance
function OR.compareNewObjects(newObject1, newObject2)
    if (newObject1.specificCell and not newObject2.specificCell) then
        return true
    elseif (not newObject1.specificCell and newObject2.specificCell) then
        return false
    elseif (newObject1.excludedCell and not newObject2.excludedCell) then
        return true
    elseif (not newObject1.excludedCell and newObject2.excludedCell) then
        return false
    elseif (newObject1.replaceChance and not newObject2.replaceChance) then
        return false
    elseif (not newObject1.replaceChance and newObject2.replaceChance) then
        return true
    elseif (newObject1.replaceChance and newObject2.replaceChance) then
        return (newObject1.replaceChance > newObject2.replaceChance)
    end
end

-- Function for sorting tables by alphabetical order
function OR.compareObjects(newObject1, newObject2)
    return newObject1.oldObject < newObject2.oldObject
end

-- Debug function to dump the loaded config files merged into mergedObjects
function OR.printObjects()
    for _, obj in pairs(OR.mergedObjects) do
        mwse.log("BASEOBJECT: %s", obj.oldObject)
        mwse.log("    SORTED")
        for _, newObj in pairs(obj.newObjects) do
            mwse.log("        newObject: %s", newObj.newObject)
            mwse.log("        replaceChance: %s", newObj.replaceChance)
            for _, cell in pairs(newObj.specificCell) do
                mwse.log("        specificCell: %s", cell.cellName)
            end
            for _, cell in pairs(newObj.excludedCell) do
                mwse.log("        excludedCell: %s", cell.cellName)
            end
            mwse.log("\n")
        end
    end
end

-- Merges conflicting config files into mergedObjects
function OR.mergeReplacers()
    local seenObjects = {}
    local dupes = {}
    -- Checks for seen objects in all Objects
    for _, obj in pairs(OR.allObjects) do
        if (seenObjects[obj.oldObject]) then
            table.insert(dupes, obj)
        else
            seenObjects[obj.oldObject] = obj
            table.insert(OR.mergedObjects, obj)
        end
    end
    -- Adds duplicated entries to the original
    for _, dupe in pairs(dupes) do
        for _, obj in pairs(OR.mergedObjects) do
            if (obj.oldObject == dupe.oldObject) then
                for _, newObj in pairs(dupe.newObjects) do
                    table.insert(obj.newObjects, newObj)
                end
            end
        end
    end
    -- Sorts newObjects table
    for _, obj in pairs(OR.mergedObjects) do
        local sortedObjects = {}
        for _, newObj in pairs(obj.newObjects) do
            table.insert(sortedObjects, newObj)
            table.sort(sortedObjects, OR.compareNewObjects)
        end
        obj.newObjects = sortedObjects
    end
    -- Sorts mergedObjects list
    table.sort(OR.mergedObjects, OR.compareObjects)
end

return OR