local mod = {
    name = "Ingot Converter",
    ver = "1.0.0",
    author = "Shanjaq",
}

local common_ingot_types = {

    "iron",
    "steel",
    "silver",
    "glass",
    "ebony",
    "gold",

}

local common_ingot_names = {

    "ingot",
    "bar",
    "malleable",

}

--- @param item tes3item
local function isIngot(item)
    if item.objectType == tes3.objectType.ingredient or item.objectType == tes3.objectType.miscItem then
      for _, name in ipairs(common_ingot_names) do
          if string.lower(item.name):find(name) then
              return true
          end
      end
    end

    return false
end

--- @param nameFilter string[]
--- @param typeFilter tes3.objectType[]|nil
--- @param plainFilter boolean
local function getObjectsWithName(nameFilter, typeFilter, plainFilter)
    local results = {}
    for object in tes3.iterateObjects(typeFilter) do
        for _, name in ipairs(nameFilter) do
            if (object.name and string.lower(object.name):find(string.lower(name), nil, plainFilter)) then
                table.insert(results, object)
                break
            end
        end
    end
    return results
end
local all_ingots = {}


local function filterIngots(e)
    local item = e.item
    return true
end

local function showIngotSelectionMenu(ref, current_ingots)
    local keys = table.keys(current_ingots)
    if #keys > 0 then
        local ingot_type = keys[1]
        tes3ui.showInventorySelectMenu({
            reference = ref,
            title = "Alternative Ingots: " .. string.upper(string.sub(ingot_type, 1, 1)) .. string.sub(ingot_type, 2),
            noResultsText = "No alternatives found.",
            filter = function(e)
                if isIngot(e.item) and string.lower(e.item.name):find(ingot_type) then
                    return true
                else
                    return false
                end
            end,
            callback = function(ee)
                if ee.item then

                    --remove ingot_type sample ingots
                    for _, ingot in ipairs(all_ingots) do
                        if string.lower(ingot.name):find(ingot_type) and ingot.id ~= ee.item.id then
                            tes3.removeItem{reference = ref, item = ingot.id, count = 1, playSound = false}
                        end
                    end

                    --add current_ingots[ingot_type].count of selected ee.item.id
                    if current_ingots[ingot_type].count > 1 then
                        tes3.addItem{reference=ref, item=ee.item.id, count=current_ingots[ingot_type].count - 1, playSound=false, updateGUI=false}
                    end
                    
                    current_ingots[ingot_type] = nil
                    
                    timer.delayOneFrame(function()
                        showIngotSelectionMenu(ref, current_ingots)
                    end)
                else
                    --cancelled; cleanup and re-add ingots remaining to process
                    for i, key in ipairs(table.keys(current_ingots)) do

                        --remove all remaining sample ingots
                        for j, ingot in ipairs(all_ingots) do
                            if string.lower(ingot.name):find(key) then
                                tes3.removeItem{reference = ref, item = ingot.id, count = 1, playSound = false}
                            end
                        end
                    end


                    --re-add saved ingots one frame later
                    timer.delayOneFrame(function()
                        for key, value in pairs(current_ingots) do
                            for _, ingot in ipairs(value.ingots) do
                                tes3.addItem{reference=ref, item=ingot.id, count=ingot.count, playSound=false, updateGUI=false}
                            end
                        end
                    end)
                end
            end,
        })
    end
    return
end

---@param e startGlobalScriptEventData
local function onStartGlobalScript(e)
    if e.script.id == "shan_convertIngots" then
        local context = e.script.context
        local ref = e.reference
        local inventory = ref.object.inventory.items
        
        if #all_ingots == 0 then
            all_ingots = getObjectsWithName(common_ingot_names, { tes3.objectType.miscItem, tes3.objectType.ingredient }, true)
        end
        
        --combine available "common" "ingots" and store to current_ingots
        local current_ingots = {}
        for i, stack in ipairs(inventory) do
            for j, common_ingot_type in ipairs(common_ingot_types) do
                if string.lower(stack.object.name):find(common_ingot_type) and isIngot(stack.object) then
                    if current_ingots[common_ingot_type] == nil then
                      current_ingots[common_ingot_type] = { count = 0, ingots = {} }
                    end
                    table.insert(current_ingots[common_ingot_type].ingots, { id = stack.object.id, count = stack.count })
                    current_ingots[common_ingot_type].count = current_ingots[common_ingot_type].count + stack.count

                    --remove available "common" "ingots"
                    tes3.removeItem{reference = ref, item = stack.object.id, count = stack.count, playSound = false}
                end
            end
        end

        --add one sample of each "common" "ingot" from all_ingots
        for ingot_type, current_ingot in pairs(current_ingots) do
            for _, ingot in ipairs(all_ingots) do
                if string.lower(ingot.name):find(ingot_type) then
                    tes3.addItem{reference=ref, item=ingot.id, count=1, playSound=false, updateGUI=false}
                end
            end
        end
        
        --show selection menu
        showIngotSelectionMenu(ref, current_ingots)
        return false
    end
end
event.register(tes3.event.startGlobalScript, onStartGlobalScript)