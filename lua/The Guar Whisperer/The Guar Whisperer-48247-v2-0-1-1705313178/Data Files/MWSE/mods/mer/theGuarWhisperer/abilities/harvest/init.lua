

--[[
 Code taken from:
Graphic Herbalism
By Greatness7

modified by Merlord
--]]
local common = require("mer.theGuarWhisperer.common")
local logger = common.createLogger("Harvest")

---@class GuarWhisperer.Harvest
local Harvest = {}

local config = include("graphicHerbalism.config") or {
    whitelist = {},
    blacklist = {}
}


function Harvest.canHarvest(reference)
    return reference
        and not reference.isEmpty
        and Harvest.isHerb(reference)
end

-- Detect if the reference is a valid herbalism subject.
function Harvest.isHerb(ref)
    if not ref then
        logger:trace("isHerb: ref is nil")
        return false
    end

    if not ref.object.organic then
        logger:trace("isHerb: ref is not organic")
        return false
    end

    local id = ref.baseObject.id:lower()

    if config.blacklist[id] then
        logger:trace("isHerb: ref is blacklisted")
        return false
    end

    if config.whitelist[id] then
        logger:trace("isHerb: ref is whitelisted, is a herb")
        return true
    end

    if ref.object.script then
        logger:trace("isHerb: ref has a script")
        return false
    end

    logger:trace("isHerb: ref is a herb")
    return true
end


-- Update and serialize the reference's HerbalismSwitch.
local function updateHerbalismSwitch(ref, index)
    -- valid indices are: 0=default, 1=picked, 2=spoiled

    local sceneNode = ref.sceneNode
    if not sceneNode then return end

    local switchNode = sceneNode:getObjectByName("HerbalismSwitch")
    if not switchNode then return end

    -- bounds check in case mesh does not implement a spoiled state
    index = math.min(index, #switchNode.children - 1)
    switchNode.switchIndex = index

    -- only serialize if non-zero state (e.g. if picked or spoiled)
    ref.data.GH = (index > 0) and index or nil
end


-- Calls "updateHerbalismSwitch" on appropriate references.
local function updateHerbReferences(cell)
    for ref in cell:iterateReferences(tes3.objectType.container) do
        if Harvest.isHerb(ref) then
            if not ref.isEmpty then
                updateHerbalismSwitch(ref, 0)
            else -- either picked or spoiled
                updateHerbalismSwitch(ref, math.max(ref.data.GH or 1, 1))
            end
        end
    end
end


-- Calls "updateHerbReferences" when a new cell is loaded.
local currentCells
local function onCellChanged()
    local cells = tes3.getActiveCells()
    local today = tes3.getGlobal("DaysPassed")

    for _, cell in ipairs(cells) do
        local day = currentCells[cell]
        if today > (day or 0) then
            updateHerbReferences(cell)
            ---@diagnostic disable-next-line
            cells[cell] = today
        else -- cell is already loaded
            cells[cell] = day
        end
    end

    currentCells = cells
end
event.register("cellChanged", onCellChanged)
event.register("calcRestInterrupt", onCellChanged)
event.register("loaded", function() currentCells = {}; onCellChanged() end)


-- Called when activating a herb, loot all contents and update switch node.
function Harvest.harvest(reference, target, playSound)
    logger:debug("harvest: %s", reference.object.id)

    if playSound == nil then
        playSound = true
    end

    -- skip non-ingred
    if not Harvest.isHerb(target) then
        logger:debug("harvest: Not a herb")
        return
    end

    -- skip pre-picked
    if target.data.GH then
        logger:debug("harvest: Already picked")
        return false
    end

    -- resolve contents
    target:clone()

    -- total gold value
    local value = 1


    local itemsTaken = {}
    -- transfer ingreds
    if #target.object.inventory == 0 then
        tes3.playSound{reference=target, sound="Item Ammo Down", volume=config.volume, pitch=0.9}
        updateHerbalismSwitch(target, 2)
    else
        for _, stack in pairs(target.object.inventory) do
            if stack.object.canCarry ~= false then
                local count = stack.count
                if not stack.count or stack.count <1 then
                    count = 1
                end
                tes3.transferItem{from=target, to=reference, item=stack.object, count=count, playSound=false}
                table.insert(itemsTaken, { name = stack.object.name, id = stack.object.id, count = count })
            end
        end
        if playSound then
            tes3.playSound{reference=target, sound="Item Ingredient Up", volume=config.volume, pitch=1.0}
        end
        updateHerbalismSwitch(target, 1)
    end

    -- handle ownership
    if not tes3.hasOwnershipAccess{target=target} then
        tes3.triggerCrime{type=tes3.crimeType.theft, victim=tes3.getOwner(target), value=value}
    end

    -- apply empty flag
    target.object.modified = false
    target.object:onInventoryClose(target)
    target.isEmpty = true

    -- claim Harvest event
    return itemsTaken
end


-- Iterate over an inventory's ingredients, including inside leveled lists.
local function getIngredients(inventory)
    local function ingredsIterator(list)
        for _, node in pairs(list or inventory) do
            if node.object.objectType == tes3.objectType.leveledItem then
                ingredsIterator(node.object.list)
            elseif node.object.objectType == tes3.objectType.ingredient then
                coroutine.yield(node.object)
            end
        end
    end
    return coroutine.wrap(ingredsIterator)
end



-- Autodetect blacklist candidates. Not perfect, but is better than nothing.
local function updateBlacklist()
    for obj in tes3.iterateObjects(tes3.objectType.container) do
        ---@cast obj any
        local id = obj.id:lower()
        if (obj.organic
            and obj.script == nil
            and #obj.inventory > 0
            and config.blacklist[id] == nil
            and config.whitelist[id] == nil
            )
        then
            if (id:find("barrel")
                or id:find("basket")
                or id:find("box")
                or id:find("chest")
                or id:find("crate")
                or id:find("nom_")
                or id:find("sack")
                or id:find("trader")
                or getIngredients(obj.inventory)() == nil
                )
            then
                config.blacklist[id] = true
            end
        end
    end
end
event.register("initialized", updateBlacklist)

return Harvest

