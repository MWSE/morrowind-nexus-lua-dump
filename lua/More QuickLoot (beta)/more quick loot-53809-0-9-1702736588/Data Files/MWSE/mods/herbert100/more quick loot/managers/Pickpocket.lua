
local hlib = require"herbert100"
local Class, log = hlib.Class, hlib.Logger(require("herbert100.more quick loot.defns"))
local config = require("herbert100.more quick loot.config") ---@type MQL.config
local Living = require("herbert100.more quick loot.managers.abstract.Living")
local Chance = require("herbert100.more quick loot.managers.abstract.Chance")


---@class MQL.Manager.Pickpocket : MQL.Manager.Chance
---@field base_chance number the base chance you have of stealing an item 
---@field penalty_mult number the number to multiply the penalty by
---@field is_detected boolean whether or not the player was detected last frame
local Pickpocket = Class({name="Pickpocket Manager", parents={Chance, Living}}, {loot_verb = "Stole"})


Pickpocket.config = config.pickpocket ---@type MQL.config.Manager.Pickpocket

-- this function does the initial calculations that will be used later when pickpocketing stuff.
function Pickpocket:_initialize()
    self.is_detected = self.ref.mobile.isPlayerDetected

    local npc_mobile = self.ref.mobile
    local pm = tes3.mobilePlayer

    local sneak_weight, agility_weight = 1.5, 1
    -- sneak and agility affect your base chance
    -- security affects your nimbleness, making it easier to steal more expensive items
    self.base_chance = math.min(150, pm.sneak.current * sneak_weight) + math.min(200, pm.agility.current * agility_weight)
    self.penalty_mult =  math.max(0.3, 1 - pm.security.current/150)

    if npc_mobile then
        self.base_chance = self.base_chance - math.min(75, npc_mobile.sneak.current * sneak_weight * 0.5)
                            - math.min(100, npc_mobile.agility.current * sneak_weight * 0.5)
    end
end

-- this function sets the label for the quickloot menu
function Pickpocket:_get_container_label()
    -- only show the detection status if the setting is enabled
    if config.pickpocket.show_detection_status == false then
        return self.ref.object.name
    end
    
    if self.is_detected == false then 
        return self.ref.object.name .. " (undetected)"
    else
        return self.ref.object.name .. " (detected)"
    end
end

-- this formats the button prompts displayed by the GUI
---@return MQL.GUI.key_btn_info
function Pickpocket:_get_key_btn_info()
    local key_btn_info = Living._get_key_btn_info(self)
    key_btn_info.take.label = "Steal"
    key_btn_info.take_all.label = "Steal All"
    return key_btn_info
end


--- calculate the chance of successfully taking this item. this is called before the UI is created.
---@param item tes3item
---@return integer take_chance the chance of successfully taking one copy of this item. should be a number between 0 and 100
function Pickpocket:calc_item_chance(item)
    ---@diagnostic disable-next-line: undefined-field
    local penalty = item.value * self.penalty_mult
        -- set the chance of taking the item
    -- much harder to pickpocket when detected
    local chance = config.pickpocket.chance_mult * (self.base_chance - penalty)

    if self.is_detected then
        if log.level > 1 then log "PICKPOCKET: we're detected, so applying the detection multiplier" end
        chance = chance * config.pickpocket.detection_mult
    end

    return math.clamp(chance, config.pickpocket.min_chance, config.pickpocket.max_chance)

end

-- what happens when we fail to take an item
function Pickpocket:on_unsuccessful_take(item, count, only_one)
    tes3.triggerCrime{type=tes3.crimeType.pickpocket,value=item.total_value, victim=self.ref.mobile, forceDetection=true}
    return false
end



-- what happens when we successfully take an item
function Pickpocket:on_successful_take(item, count, only_one)
    -- mark the item as stolen, transfer the item, and trigger a crime (so the player will be caught if they're not sneaking)
    tes3.setItemIsStolen{item = item.object, from = self.ref.object, stolen = true }
    tes3.transferItem{from = self.ref, to = tes3.player, 
        item = item.object, count=count,
        playSound= only_one, updateGUI = only_one
    }
    -- if we're detected, we always trigger a crime.
    -- if we're not detected, we only trigger a crime if `trigger_crime_undetected == false`
    if (self.is_detected or config.pickpocket.trigger_crime_undetected == false) then
        tes3.triggerCrime{type = tes3.crimeType.pickpocket, victim = self.stealing_from, value = item.object.value * count}
    end
    local xp = math.clamp(math.sqrt(item.total_value / 20), 0.3, 5)

    tes3.mobilePlayer:exerciseSkill(tes3.skill.security, xp)
    tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, xp)

    -- if config.pickpocket.show_msgbox then 
    --     tes3.messageBox{ message = table.concat({self.loot_verb, o.count, o.item.name}, " ")}
    -- end

    if log > 1 then
        log:debug("PICKPOCKET: successfully took item: " .. table.concat({self.loot_verb, count, item.object.name}," "))
    end
    return true

end


-- something that happens every frame when the manager is active
--- called every frame to update item chances and make sure the menu should still be open.
---@return boolean keep_going `true` if the manager is still in a valid state, `false` if it's not (and thus should be destroyed)
function Pickpocket:on_simulate()
    -- we should stop updating each frame if: 
    -- *) the person we're pickpocketing doesn't exist,
    -- *) the person we're pickpocketing is dead, or 
    -- *) we aren't sneaking anymore
    if self.ref == nil or self.ref.isDead == true or not tes3.mobilePlayer.isSneaking then 
        return false 
    end

    -- if we can't loot (ie we looked away for a bit, or we just took an item) then 
    --    we should update our detection status and move to the next frame
    if self.cant_loot then 
        self.is_detected = self.ref.mobile.isPlayerDetected
        return true
    end

    -- our detection status last frame, used to make sure we only recompute stuff and update the UI when the detection status actually changes 
    local old_is_detected = self.is_detected
    self.is_detected = self.ref.mobile.isPlayerDetected

    -- only update labels if the detection status has changed
    if old_is_detected ~= self.is_detected then
        if log.level > 1 then log "PICKPOCKET: detection status changed. updating labels" end
        self.gui:update_name_label(self:_get_container_label()) -- update the name of the container
        self:update_item_chances() -- this will update the item chances and labels, taking into account our new detection status
    end
    return true
end

return Pickpocket