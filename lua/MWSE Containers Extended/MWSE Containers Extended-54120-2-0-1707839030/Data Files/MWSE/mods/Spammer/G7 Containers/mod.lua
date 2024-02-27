local mod = {
    name = "Containers Extended",
    ver = "2.0",
    author = "Spammer",
}



local ids = {

    "g7_container_ALCH",
    "g7_container_AMMO",
    "g7_container_ARMO",
    "g7_container_BOOK",
    "g7_container_CLOT",
    "g7_container_INGR",
    "g7_container_KEYS",
    "g7_container_LOCK",
    "g7_container_MISC",
    "g7_container_REPA",
    "g7_container_SCRL",
    "g7_container_SOUL",
    "g7_container_WEAP",

}




mod.allowed = {
    [ids[1]] = "potion",
    [ids[2]] = "ammunition or thrown weapon",
    [ids[3]] = "armor",
    [ids[4]] = "book",
    [ids[5]] = "clothing",
    [ids[6]] = "ingredient",
    [ids[7]] = "key",
    [ids[8]] = "lockpick or probe",
    [ids[9]] = "miscellanious",
    [ids[10]] = "repair",
    [ids[11]] = "scrolls",
    [ids[12]] = "soulgems",
    [ids[13]] = "weapon",
}

mod.containers = {
    [ids[1]] = "g7_inventory_ALCH",
    [ids[2]] = "g7_inventory_AMMO",
    [ids[3]] = "g7_inventory_ARMO",
    [ids[4]] = "g7_inventory_BOOK",
    [ids[5]] = "g7_inventory_CLOT",
    [ids[6]] = "g7_inventory_INGR",
    [ids[7]] = "g7_inventory_KEYS",
    [ids[8]] = "g7_inventory_LOCK",
    [ids[9]] = "g7_inventory_MISC",
    [ids[10]] = "g7_inventory_REPA",
    [ids[11]] = "g7_inventory_SCRL",
    [ids[12]] = "g7_inventory_SOUL",
    [ids[13]] = "g7_inventory_WEAP",
}


---@param id string The container id.
---@param item tes3book|tes3misc|tes3item The Item to check stashability for.
---@return boolean|nil canStash Whether the provided item can be stashed in the given container.
function mod.itemCheck(id, item)
    local check = {
        [ids[1]] = (tes3.objectType.alchemy == item.objectType),
        [ids[2]] = (tes3.objectType.weapon == item.objectType and tes3.weaponType.marksmanThrown == item.type) or
            (tes3.objectType.ammunition == item.objectType),
        [ids[3]] = (tes3.objectType.armor == item.objectType),
        [ids[4]] = (tes3.objectType.book == item.objectType) and (tes3.bookType.book == item.type),
        [ids[5]] = (tes3.objectType.clothing == item.objectType),
        [ids[6]] = (tes3.objectType.ingredient == item.objectType),
        [ids[7]] = (tes3.objectType.miscItem == item.objectType) and item.isKey,
        [ids[8]] = (tes3.objectType.lockpick == item.objectType) or (tes3.objectType.probe == item.objectType),
        [ids[9]] = (tes3.objectType.miscItem == item.objectType) and not (item.isKey or item.isSoulGem or item.isGold),
        [ids[10]] = tes3.objectType.repairItem == item.objectType,
        [ids[11]] = (tes3.objectType.book == item.objectType) and (tes3.bookType.scroll == item.type),
        [ids[12]] = (tes3.objectType.miscItem == item.objectType) and item.isSoulGem,
        [ids[13]] = (tes3.objectType.weapon == item.objectType) and tes3.weaponType.marksmanThrown ~= item.type,
    }
    return check[id]
end

---@param id string The item baseObject id.
---@param ref tes3reference The container reference linked to the item.
---@param item tes3alchemy|nil The item to update the weight for.
function mod.updateWeight(id, ref, item)
    if not (id and mod.weight[id]) then return end
    item = item or tes3.getObject(id)
    if not (ref and item) then return end
    local mult = tes3.getGlobal("g7_container_mult")
    ref:clone()
    local calculatedWeight = mod.weight[id] + (mult * ref.object.inventory:calculateWeight())
    if item.weight ~= calculatedWeight then
        item.weight = calculatedWeight
        item.modified = true
        if tes3.mobilePlayer.object.inventory:contains(item) then
            local current = tes3.mobilePlayer.object.inventory:calculateWeight()
            local feather = tes3.getEffectMagnitude { reference = tes3.player, effect = tes3.effect.feather }
            local burden = tes3.getEffectMagnitude { reference = tes3.player, effect = tes3.effect.burden }
            tes3.setStatistic { reference = tes3.player, name = "encumbrance", current = (current + burden - feather) }
        end
    end
end



return mod
