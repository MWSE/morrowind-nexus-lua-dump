
local hlib = require"herbert100"
local Class, log = hlib.Class, hlib.Logger("More QuickLoot/Pickpocket")
local defns = require("herbert100.more quickloot.defns")
local cfg = require("herbert100.more quickloot.config").pickpocket ---@type MQL.config.Manager.Pickpocket
local Living = require("herbert100.more quickloot.managers.abstract.Living")
local Chance = require("herbert100.more quickloot.managers.abstract.Chance")


local is_ok, is_unavailable = defns.item_status.ok, defns.item_status.unavailable_temp
local reason = defns.unavailable_reason.chance_sucks

local SNEAK_WEIGHT = 3/100
local AGILITY_WEIGHT = 2/100
local SECURITY_WEIGHT = 1.5/100

---@class MQL.Manager.Pickpocket : MQL.Manager.Chance, MQL.Managers.Living
---@field base_chance number the base chance you have of stealing an item 
---@field penalty_mult number the number to multiply the penalty by
---@field show_chances_skill_id tes3.skill
---@field is_detected boolean whether or not the player was detected last frame
local Pickpocket = Class.new{name="Pickpocket Manager", parents={Chance, Living}, 
    {"i18n_index", default ="looted.pickpocket"},
    {"base_chance"},
    {"penalty_mult"},
    {"is_detected"},
    {"show_chances_skill_id", default=tes3.skill.security, tostring=false},
    ---@param self MQL.Manager.Pickpocket
    ---@param ref tes3reference
    init = function(self, ref)
        self.ref = ref
        ref:clone()
        self.is_detected = self.ref.mobile.isPlayerDetected
        local pm = tes3.mobilePlayer

        local s = math.max(pm.sneak.current, 0)

        self.penalty_mult = 0.35 + 0.65 * 2^(-(0.0002 * s^2 + 0.009 * s))

        self.base_chance = 0.01 * (
            2.00 * math.max(0, pm.agility.current) +
            0.75 * math.max(0, pm.security.current)
        )

        log("set base chance to %s and penalty mult to %s", self.base_chance, self.penalty_mult)
    end
}

--- calculate the chance of successfully taking this item. this is called before the UI is created.
---@param item tes3item|MQL.Item.Chance
---@return integer take_chance the chance of successfully taking one copy of this item. should be a number between 0 and 100
function Pickpocket:calc_item_chance(item)
    local penalty = 0.05 * item.weight
    if item.value >= 1 then
        penalty = penalty + 0.044 * math.log(item.value)^2.3
    end
    
    local chance = cfg.chance_mult * (self.base_chance - self.penalty_mult * penalty)
    
    log("calculating take chance for %s:\n\tchance: %s\n\tpenalty: %s", item, chance, penalty)

    if self.is_detected then
        log "we're detected, so applying the detection multiplier"
        chance = chance * cfg.detection_mult
    end

    return math.clamp(chance, cfg.min_chance, cfg.max_chance)

end

Pickpocket.config = cfg ---@type MQL.config.Manager.Pickpocket



function Pickpocket:_make_items()
    self:add_npc_items{equipped_cfg=cfg.equipped}
    self:update_item_chances()
end


function Pickpocket:update_item_chances()
    ---@diagnostic disable-next-line: undefined-field
    if cfg.determinism == false then 
        Chance.update_item_chances(self)
        return
    end

    local cutoff = cfg.determinism_cutoff
    for _, item in ipairs(self.items) do
        item.chance = self:calc_item_chance(item)
        item.show_chance = false
        if item.status >= is_unavailable then
            if item.chance >= cutoff then
                item.chance = 1
                item.status = is_ok
                item.unavailable_reason = nil
            else
                item.status = is_unavailable; item.unavailable_reason = reason
            end
        end
    end
    
end

function Pickpocket:_get_status_text()
    if cfg.show_detection_status then
        return self.is_detected and "DETECTED" or "UNDETECTED"
    end
end

-- this formats the button prompts displayed by the GUI
---@return MQL.GUI.Key_Label.keybinds
function Pickpocket:get_keylabels() return {take="Steal", take_all="Steal All", open="Open"} end




-- what happens when we fail to take an item
---@param item MQL.Item
---@param take_stack boolean are we taking the whole stack?
---@param update_stuff boolean? should we update stuff?
---@return integer|false? num_taken the number of items taken, or `false` if no items were taken
function Pickpocket:on_unsuccessful_take(item, take_stack, update_stuff)
    local crime_value = item:get_value(take_stack)
    self:do_crime(crime_value,false)
    return false
end


---@param item MQL.Item.Chance
---@param take_stack boolean are we taking the whole stack?
---@param update_stuff boolean? should we play the sound?
---@return integer|false? num_taken the number of items taken, or `false` if no items were taken
function Pickpocket:on_successful_take(item, take_stack, update_stuff)
    -- mark the item as stolen, transfer the item, and trigger a crime (so the player will be caught if they're not sneaking)
    tes3.setItemIsStolen{item = item.object, from = self.ref.baseObject }
    local num_taken = item:take(take_stack, update_stuff)
    if update_stuff and num_taken > 0 then
        self:make_msgbox(item, num_taken)
    end
    return num_taken
end

function Pickpocket:award_xp(item_value, take_successful)
    if not take_successful then return end

    local t = math.clamp(math.sqrt(item_value)/50, 0, 1) -- max xp given to items worth 2,500 gold
    local xp = math.lerp(t, 0.1, 2)
    tes3.mobilePlayer:exerciseSkill(tes3.skill.security, xp)
    tes3.mobilePlayer:exerciseSkill(tes3.skill.sneak, xp)
end
--- do the crime
---@param crime_value integer value of the crime
---@param successful boolean? did we succeed in taking any/all items?
function Pickpocket:do_crime(crime_value, successful)
    if successful then
        if self.is_detected or cfg.trigger_crime_undetected then
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
        self:update_item_chances()
        self.gui:update_all_item_labels()
    end
    return true
end

return Pickpocket