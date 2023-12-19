-- =============================================================================
-- ORGANIC LOOTING
-- =============================================================================
local hlib = require"herbert100"
local defns = require("herbert100.more quick loot.defns")
local Class, log = hlib.Class, hlib.Logger(defns)
local config = require("herbert100.more quick loot.config")
-- local base = require("herbert100.more quick loot.managers.abstract.base")
local Chance = require("herbert100.more quick loot.managers.abstract.Chance")
local Chance_Item = require("herbert100.more quick loot.Item").Chance







---@alias MQL.GH.switch
---| `0` default 
---| `1` picked 
---| `2` spoiled


-- only define the function if graphic herbalism is installed

-- the body of this function was copy-pasted from Graphic Herbalism without change, with permission from Greatness7.
-- it will be used to update how plants look after they're looted, assuming Graphic Herbalism is installed, and the relevant settings
-- are selected
-- Update and serialize the reference's HerbalismSwitch.
---@param ref tes3reference the reference of the plant to update
---@param index MQL.GH.switch the switch parameter
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

-- use graphic herbalism or destroy the plants, or do nothing, based on current config settings
local function change_plant(ref,successful)
    if config.organic.change_plants == defns.change_plants.gh then
        if successful then
            updateHerbalismSwitch(ref, 1)
        else
            updateHerbalismSwitch(ref, 2)
        end
            
    elseif config.organic.change_plants == defns.change_plants.destroy 
        and not config.organic.plants_blacklist[ref.baseObject.id:lower()]
    then
        ref:disable()
        ref:delete()
    end
end

---@class MQL.Mangers.Organic : MQL.Manager.Chance
---@field base_chance number the base chance you have of taking something 
---@field penalty_mult number the multiplier applied to the total_value of the plant 
local Organic = Class({name="Organic Manager", parents={Chance},},{loot_verb = "Harvested"})

Organic.config = config.organic ---@type MQL.config.Manager.Organic

function Organic:_initialize()
    local pm = tes3.mobilePlayer
    self.base_chance = math.min(pm.alchemy.current * 1.25, 200)
        + 0.5 * pm.intelligence.current
    self.penalty_mult = 5 * math.max(0.25, 1 - pm.security.current/150)
end

function Organic:_get_key_btn_info()
    if self.stealing_from == nil then
        return {
            take = {label = "Harvest", pos = 0.05},
            take_all = {label = "Harvest nearby", pos = 0.95}
        }
    end
    return {
        take = {label = "Steal", pos = 0.05},
        take_all = {label = "Steal nearby", pos = 0.95}
    }
end


--- calculate the chance of successfully taking this item. this is called before the UI is created.
---@param item tes3item
---@return integer take_chance the chance of successfully taking one copy of this item. should be a number between 0 and 100
function Organic:calc_item_chance(item)
    ---@diagnostic disable-next-line: undefined-field
    return math.clamp(self.base_chance - self.penalty_mult * item.value,
        self.config.min_chance, self.config.max_chance
    )

end

function Organic:on_unsuccessful_take(item, count, only_one)
    tes3.removeItem{item=item.object, count=count, reference=self.ref,updateGUI=only_one, playSound=only_one}
    -- mark it as spoiled
    change_plant(self.ref, false)
    return true
end



--- when we successfully take an item
---@param item MQL.Item.Chance
---@param count integer
---@param only_one boolean?
function Organic:on_successful_take(item, count, only_one)
    -- mark the item as stolen, transfer the item, and trigger a crime (so the player will be caught if they're not sneaking)
    tes3.transferItem{from = self.ref, to = tes3.player,
        item = item.object, count = count,
        playSound=only_one, updateGUI=only_one
    }
    
    if self.stealing_from then
        tes3.triggerCrime{type=tes3.crimeType.theft, value = item.object.value * count, victim = self.stealing_from}
    end
    local xp = math.clamp(math.sqrt(item.total_value / 10), 0.2, 3)

    tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, xp)

    if config.UI.show_msgbox then
        tes3.messageBox{ message = table.concat({self.loot_verb, count, item.object.name}," ")}
    end
    if log > 1 then
        log("ORGANIC: Successfully took " .. tostring(item))
    end
    -- if we're deleting all the things from this container
    if count == item.count then
        change_plant(self.ref, true)
    end

    return true
end

--- if the container is empty, we should update the plant if we try to take it
---@param modifier_pressed boolean was the modifier key pressed?
function Organic:take_item(modifier_pressed)
    if self.cant_loot == defns.cant_loot.empty then
        change_plant(self.ref, false)
        return true
    end
    return Chance.take_item(self, modifier_pressed)
end

-- this one hurts to look at, its doing way too much :/
function Organic:take_all_items(modifier_pressed)

    -- if we should invert modifier key behavior, do that.
        -- we're doing it before calling the `take_item` method so that the behavior is consistent
    if self.config.mi_inv_take_all then
        modifier_pressed = not modifier_pressed
    end

    if config.take_all_distance == 0 then 
        return self:take_item(modifier_pressed)
    end


    log "ORGANIC: looting all plants."
    if self.items[1] ~= nil then 
        tes3.playItemPickupSound { item = self.items[1].object, pickup = true }
    end
    local allow_theft = (self.stealing_from ~= nil)
    local target_pos = self.ref.position
    local total_xp = 0
    local obj, owner, item, chance, count, take_stack, successful
    for ref in tes3.player.cell:iterateReferences(tes3.objectType.container) do

        do -- check if this is a valid reference, if not, move onto the next one
            obj = ref.object

            -- if it's an organic container and it's close enough to the player
            if not obj.organic
                or ref:testActionFlag(tes3.actionFlag.useEnabled) == false
                or math.abs(target_pos.x - ref.position.x) > config.take_all_distance
                or math.abs(target_pos.y - ref.position.y) > config.take_all_distance
                or math.abs(target_pos.z - ref.position.z) > config.take_all_distance
            then
                goto continue
            end

            ref:clone()
            -- log "ORGANIC: cloned the plant"
            -- find out who owns this thing
            owner = tes3.getOwner{reference=ref}
            -- if it's owned by someone and we're not stealing, don't take it
            if owner and not allow_theft then
                goto continue
            end
        end
           
        -- log("ORGANIC: now looting: " .. obj.name)
        for _, v in pairs(obj.inventory) do

            -- some weird stuff happens with `value`
            if v.object.value == nil then
                log "ORGANIC: found plant with no value... weird...";
                goto continue
            end

            successful = true
            ---@type MQL.Item.Chance
            item = Chance_Item{
                object =v.object, 
                count=v.count, 
                take_chance = self:calc_item_chance(v.object)
            }
            
            if item.count > 1 then 
                count, take_stack = self:get_num_to_take(item, modifier_pressed)
                if take_stack then
                    chance = item.total_take_chance
                else
                    chance = item.take_chance
                end
            else
                count, take_stack = 1, true
                chance = item.take_chance
            end
            
            -- don't even bother testing if the chance is >= 100%
            if chance < 100 and math.random(100) > chance and not self:luck_override(item, count) then
                tes3.removeItem{item=item.object, count=count, reference=ref,
                    playSound=false,updateGUI=false
                }
                successful = false

            else -- we can actually take the item

                tes3.transferItem{from = ref, to = tes3.player, 
                    item = item.object, count = count,
                    playSound = false, updateGUI = false
                }
                
                -- add some XP
                total_xp = total_xp +  math.clamp(math.sqrt(item.total_value / 10), .2, 3)

                
            end
            -- trigger the crime even if we failed to steal it
            if owner then
                tes3.triggerCrime{type=tes3.crimeType.theft, value = item.total_value, victim = owner}
            end
        end

        change_plant(ref, successful)
          
        ::continue::
    end
    -- after doing all that stuff, we should recalculate the items left in the plant container, because who knows what happened to it
    -- we should also update the UI
    self.items = {}
    self:_make_items()
    self.gui:make_container_items(self.items)
    self:update_container_status()
    -- only play the sound if we took an item
    if total_xp > 0 then 
        tes3ui.forcePlayerInventoryUpdate()
        tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, total_xp)
    end
    return true
end



Organic.cant_loot_actions = Chance.cant_loot_actions .. {
    ---@param self MQL.Mangers.Organic
    [defns.cant_loot.empty] = function(self)
        -- destroy the plant if we're told to
        -- if config.organic.change_plants == defns.change_plants.destroy and not config.organic.plants_blacklist[self.ref.baseObject.id:lower()] then 
        --     self:destroy_container()
        --     return
        -- end

        -- otherwise, use graphic herbalism to update the plant if appropriate, and then mark the container as empty
        -- if config.organic.change_plants == defns.change_plants.gh then 
        --     updateHerbalismSwitch(self.ref, 2)
        -- end
        self.gui:block_and_show_msg("Empty")
        if config.organic.hide_on_empty then
            self.gui:hide()
        -- else
        --     self.gui:block_and_show_msg("Empty")
        end
        -- if GH is currently installed, mark the plant as taken
        if config.compat.gh_current == defns.gh_status.currently then 
            -- apply empty flag, this was copied from `graphicHerbalism.main`
            self.ref.object.modified = false
            self.ref.object:onInventoryClose(self.ref)
            self.ref.isEmpty = true
        end
    end
}


return Organic