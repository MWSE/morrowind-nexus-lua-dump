
local hlib = require"herbert100"
local Class, log = hlib.Class, hlib.Logger("More QuickLoot/Pickpocket")
local config = require("herbert100.more quickloot.config") ---@type MQL.config
local Living = require("herbert100.more quickloot.managers.abstract.Living")
local Chance = require("herbert100.more quickloot.managers.abstract.Chance")
local Chance_Item = require "herbert100.more quickloot.Item".Chance

---@class MQL.Manager.Pickpocket : MQL.Manager.Chance, MQL.Managers.Living
---@field base_chance number the base chance you have of stealing an item 
---@field penalty_mult number the number to multiply the penalty by
---@field is_detected boolean whether or not the player was detected last frame
local Pickpocket = Class({name="Pickpocket Manager", parents={Chance, Living}}, {i18n_index = "looted.pickpocket"})

---@return MQL.Item.iter_container.params
function Pickpocket:_get_iter_params()
    ---@type MQL.Item.iter_container.params
    return {
        ref=self.ref, 
        check_equipped=true,
        ---@param item MQL.Item.Chance
        post_creation=function(item)
            self:do_equipped_check(item)
            Chance._get_iter_params(self).post_creation(item)
        end,
    }
end

Pickpocket.config = config.pickpocket ---@type MQL.config.Manager.Pickpocket

-- this function does the initial calculations that will be used later when pickpocketing stuff.
function Pickpocket:_initialize()
    self.is_detected = self.ref.mobile.isPlayerDetected

    local npc_mobile = self.ref.mobile
    local pm = tes3.mobilePlayer

    local sneak_weight, agility_weight = 2, 1.5
    -- sneak and agility affect your base chance
    -- security affects your nimbleness, making it easier to steal more expensive items
    self.base_chance = math.min(200, pm.sneak.current * sneak_weight) + math.min(200, pm.agility.current * agility_weight)
    self.penalty_mult =  0.2 * math.lerp(0.35, 1, math.clamp(pm.sneak.current, 0, 100)/100)

    if npc_mobile then
        self.base_chance = self.base_chance 
            - math.min(75, npc_mobile.sneak.current * sneak_weight * 0.3)
            - math.min(100, npc_mobile.agility.current * sneak_weight * 0.3)
    end
end



function Pickpocket:_get_status_text()
    if config.pickpocket.show_detection_status == false then return end

    if self.is_detected then return "DETECTED" end

    return "UNDETECTED"
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
---@param item tes3item|MQL.Item
---@return integer take_chance the chance of successfully taking one copy of this item. should be a number between 0 and 100
function Pickpocket:calc_item_chance(item)
    ---@diagnostic disable-next-line: undefined-field
    local penalty = item.value * self.penalty_mult
        -- set the chance of taking the item
    -- much harder to pickpocket when detected
    local chance = config.pickpocket.chance_mult * (self.base_chance - penalty)

    if self.is_detected then
        if log.level > 3 then log "we're detected, so applying the detection multiplier" end
        chance = chance * config.pickpocket.detection_mult
    end

    return math.clamp(chance, config.pickpocket.min_chance, config.pickpocket.max_chance)

end

-- what happens when we fail to take an item
---@param item MQL.Item
---@param take_stack boolean are we taking the whole stack?
---@param play_sound boolean? should we update stuff?
---@return integer|false? num_taken the number of items taken, or `false` if no items were taken
function Pickpocket:on_unsuccessful_take(item, take_stack, play_sound)
    local crime_value = (take_stack and item.total_value) or item.value
    self:do_crime(crime_value,false)
    return false
end


---@param item MQL.Item.Chance
---@param take_stack boolean are we taking the whole stack?
---@param play_sound boolean? should we play the sound?
---@return integer|false? num_taken the number of items taken, or `false` if no items were taken
function Pickpocket:on_successful_take(item, take_stack, play_sound)
    -- mark the item as stolen, transfer the item, and trigger a crime (so the player will be caught if they're not sneaking)
    tes3.setItemIsStolen{item = item.object, from = self.ref.baseObject }
    local num_taken = item:take_from_container(take_stack, play_sound)
    if play_sound and num_taken then
        self:make_msgbox(item, num_taken)
    end
    return num_taken
end

function Pickpocket:award_xp(item_value, take_successful)
    if not take_successful then return end

    local t = math.clamp(math.sqrt(item_value)/50, 0, 1) -- max xp given to items worth 2,500 gold
    local xp = math.lerp(t, 0.25, 6)
    tes3.mobilePlayer:exerciseSkill(tes3.skill.security, xp)
    tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, xp)
end
--- do the crime
---@param crime_value integer value of the crime
---@param successful boolean? did we succeed in taking any/all items?
function Pickpocket:do_crime(crime_value, successful)
    if successful then
        if self.is_detected or config.pickpocket.trigger_crime_undetected then
            tes3.triggerCrime{type = tes3.crimeType.pickpocket, victim = self.ref.object, value = crime_value}
        end
    else
        tes3.triggerCrime{type = tes3.crimeType.pickpocket, victim = self.ref.object, value = crime_value, forceDetection=true}
    end
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
        if log.level > 3 then log "detection status changed. updating labels" end
        self:update_status_label() -- update the name of the container
        self:update_item_chances() -- this will update the item chances and labels, taking into account our new detection status
    end
    return true
end

return Pickpocket