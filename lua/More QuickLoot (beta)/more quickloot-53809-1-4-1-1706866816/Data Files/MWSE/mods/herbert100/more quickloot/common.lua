-- this is my attempt at gradually decluttering `mod.lua`, so that it will eventually not be so painful to look at

local defns = require("herbert100.more quickloot.defns")
local config = require("herbert100.more quickloot.config")
local log = require("herbert100.logger").new("More QuickLoot/common")
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
    if target == nil or config.take_all_distance == 0 then return end

    local obj = target.object
    local obj_type = obj.objectType

    log(logmsg_take_nearby, obj)

    local name
    if not common.take_nearby_A_list[obj_type] then
        if not common.take_nearby_B_list[obj_type] then
            return
        end
        name = obj.name
    end

    log("about to take all nearby items")

    local original_crime_victim = config.take_nearby_allow_theft and tes3.getOwner{reference=target} or nil

    tes3.playItemPickupSound{item=target.object}

    -- used for filtering references
    local tpos = target.position
    local max_xy_dist = config.take_all_distance^2
    local max_z_dist = config.advanced.v_dist
    local use_enabled_flag = tes3.actionFlag.useEnabled

    for ref in tes3.player.cell:iterateReferences(obj_type) do
        local pos = ref.position

        if (tpos.x - pos.x)^2 + (tpos.y - pos.y)^2 > max_xy_dist
        or math.abs(tpos.z - pos.z) > max_z_dist
        or ref:testActionFlag(use_enabled_flag) == false
        or (name and ref.object.name ~= name) 
        then goto next_ref end
        
        local crime_victim = tes3.getOwner{reference = ref}
        if crime_victim and crime_victim ~= original_crime_victim then goto next_ref end
    
        tes3.addItem{item=ref.object,reference=tes3.player,playSound=false,updateGUI=false,}
        if crime_victim then
            tes3.triggerCrime{victim = crime_victim, value = obj.value, type = tes3.crimeType.theft}
        end
        ref:delete()

        ::next_ref::
    end
    tes3ui.forcePlayerInventoryUpdate()
end
end
return common