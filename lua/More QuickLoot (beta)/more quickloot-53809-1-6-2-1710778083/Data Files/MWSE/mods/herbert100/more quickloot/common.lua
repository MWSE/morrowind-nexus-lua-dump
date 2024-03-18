-- this is my attempt at gradually decluttering `mod.lua`, so that it will eventually not be so painful to look at

local defns = require("herbert100.more quickloot.defns")
local config = require("herbert100.more quickloot.config")
local log = Herbert_Logger()
-- common utility functions used by the mod
---@class MQL.common
local common = {
    -- sourced from "Hide the Skooma" by Necrolesian. credit to them for compiling this list.
    skooma_dialogue_ids = { 
        ["2350820932343717228"] = true, 
        ["27431251821030328588"] = true, 
        ["745815156108126115"] = true, 
        ["1094918899840230767"] = true, 
        ["170686103927626649"] = true, 
        ["437731057154051750"] = true, 
        ["2456544071464426424"] = true, 
        ["781926249198433643"] = true, 
        ["27861296403221528233"] = true, 
        ["287378702993122269"] = true, 
        ["29036265711176618107"] = true, 
        ["2821782961190224094"] = true, 
        ["3576191201815529709"] = true, 
        ["3034922702178419782"] = true, 
        ["277125218205084722"] = true, 
        ["2797025664259225507"] = true, 
    },
    -- checks if a container is scripted
    --- @param ref tes3reference reference to a container
    ---@return boolean is_scripted
    is_container_scripted = function (ref)
        return ref:testActionFlag(tes3.actionFlag.useEnabled) == false
        
    end
}

do -- define function to check if a container is organic
    -- check if a container is organic
    local gh_config

    if config.compat.gh_current > defns.misc.gh.never then
        gh_config = include("graphicHerbalism.config") or mwse.loadConfig("graphicHerbalism", {blacklist = {}, whitelist={}})
    end

    --- this is a modified version of the `isHerb` function from `graphicHerbalism.main`, copied with permission
    -- we're assuming this is only called on references that aren't `nil`
    -- if the relevant settings are enabled, it will use Graphic Herbalism logic to detect whether something is a plant, in addition to our blacklist
    ---@param ref tes3reference
    ---@return boolean result
    function common.is_organic(ref)
        if not ref.object.organic then return false end

        -- if everything organic is a plant, return `true` before doing anything further
        if config.organic.not_plants_src == defns.not_plants_src.everything_plant then return true end

        -- at this point, we have `config.organic.not_plants_src > defns.not_plants_src.everything_plant`
        local id = ref.baseObject.id:lower()

        if config.blacklist.organic[id] then return false end

        -- past this point, the `blacklist.organic` didn't catch it

        -- if the relevant config setting is enabled, we should ask Graphic Herbalism for its opinion
        if config.organic.not_plants_src == defns.not_plants_src.gh and gh_config then
            if gh_config.blacklist[id] then return false end
            if gh_config.whitelist[id] then return true end

            return (ref.object.script == nil)
        end
        -- past this point, Graphic Herbalism didn't catch it, so it's probably a plant

        return true
    end
end

do -- define function for taking all objects of a similar type

    common.take_nearby_A_list = { 
        [tes3.objectType.ingredient] = true, 
        [tes3.objectType.alchemy] = true, 
        [tes3.objectType.lockpick] = true, 
        [tes3.objectType.probe] = true, 
        [tes3.objectType.apparatus] = true, 
        [tes3.objectType.ammunition] = true, 
        [tes3.objectType.book] = true,
    }
    common.take_nearby_B_list = {
        [tes3.objectType.miscItem] = true,  
        [tes3.objectType.weapon] = true, 
        [tes3.objectType.clothing] = true, 
        [tes3.objectType.armor] = true, 
    }
    
---@param obj tes3clothing
local function logmsg_take_nearby(obj)
    return "targeting %s. obj_type = %s. Seeing if it's possible to grab everything.", 
        obj.name, table.find(tes3.objectType, obj.objectType)
end


--- takes all objects of a certain type
---@param target tes3reference target object. we'll look for items close to this object
function common.take_nearby_items(target)

     -- otherwise, take all the items, if we're allowed
        -- only take all stuff if the distance is bigger than 0
    if target == nil or (config.take_nearby_dist and config.take_nearby_dist <= 5) then return end

    local obj = target.object
    local obj_type = obj.objectType

    log(logmsg_take_nearby, obj)

    local sg_check = false
    local name
    -- if it's a B_lister, needs to pass a name check, unless it's a soul gem
    if common.take_nearby_B_list[obj_type] then 
        if obj_type == tes3.objectType.miscItem and obj.isSoulGem then
            sg_check = true
        else
            name = obj.name
        end
    else
        -- if this object is not an A-lister or a B-lister, skip it
        if not common.take_nearby_A_list[obj_type] then return end
    end

    log("about to take all nearby items")

    local original_crime_victim = config.take_nearby_allow_theft and tes3.getOwner{reference=target} or nil

    tes3.playItemPickupSound{item=target.object}

    -- used for filtering references
    local tpos = target.position
    local dist = config.take_nearby_dist
    local v_dist = config.advanced.v_dist
    local use_enabled_flag = tes3.actionFlag.useEnabled
    local activate_flag = tes3.actionFlag.onActivate
    for ref in tes3.player.cell:iterateReferences(obj_type) do
        -- reference checks
        if tpos:distanceXY(ref.position) > dist
        or tpos:heightDifference(ref.position) > v_dist
        or not ref:testActionFlag(use_enabled_flag)
        then goto next_ref end

        local obj2 = ref.object
        -- object specific checks
        if name then
            if obj2.name ~= name then goto next_ref end
        elseif sg_check then
            if not obj2.isSoulGem then goto next_ref end
        end

        if obj2.script then
            log("skipping %q because it had a script: %q", obj2, obj2.script)
            goto next_ref
        end
        
        local data = ref.itemData
        local crime_victim = tes3.getOwner{reference = ref}
        if crime_victim then
            if crime_victim ~= original_crime_victim then goto next_ref end
            tes3.triggerCrime{victim = crime_victim, value = obj2.value, type = tes3.crimeType.theft}
        end

        tes3.addItem{ reference=tes3.player, item=obj2, count=ref.stackSize,
            itemData=ref.stackSize == 1 and data or nil, updateGUI=false,  playSound=false,
        }
        -- tes3.gmst.site
        
        ref.itemData = nil
        ref:disable()
        ref:delete()
        -- tes3.player:activate(ref)
        -- local num = tes3.addItem{item=ref.object, reference=tes3.player, playSound=false, updateGUI=false, itemData=ref.itemData}
        ::next_ref::
    end
    tes3.removeEffects{reference=tes3.player, effect=tes3.effect.invisibility}
    tes3ui.forcePlayerInventoryUpdate()
end
end

---@param code tes3.scanCode
function common.get_key_name(code)
    -- taken from https://github.com/MWSE/MWSE/pull/498
    return tes3.findGMST(tes3.gmst[string.format("sKeyName_%02X", code)]).value
end
return common