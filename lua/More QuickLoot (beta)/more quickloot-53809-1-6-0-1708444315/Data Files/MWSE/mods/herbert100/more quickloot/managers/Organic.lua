-- =============================================================================
-- ORGANIC LOOTING
-- =============================================================================
local hlib = require"herbert100"
local defns = require("herbert100.more quickloot.defns")
local Class = hlib.Class
local log =  hlib.Logger("More QuickLoot/Organic")


local cfg = require("herbert100.more quickloot.config").organic
local organic_blacklist = require("herbert100.more quickloot.config").blacklist.organic

-- local config = require("herbert100.more quickloot.config")
-- local base = require("herbert100.more quickloot.managers.abstract.base")
local Chance = require("herbert100.more quickloot.managers.abstract.Chance")

local gh_installed = require("herbert100.more quickloot.config").compat.gh_current == defns.misc.gh.installed
local UI_cfg = require("herbert100.more quickloot.config").UI

local super = Class.super ---@cast super fun(cls: MQL.Manager): MQL.Manager.Chance

---@alias MQL.GH.switch
---|0 default 
---|1 picked 
---|2 spoiled


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
    log("updated herbalism switch on %s to %s", ref, ref.data.GH)
    
end

-- use graphic herbalism or destroy the plants, or do nothing, based on current config settings
---@param ref tes3reference reference to the plant to change
---@param successful boolean if we looted the plant successfully
local function change_plant(ref, successful)
    log("changing plant %s with successful = %s", ref, successful)
    if cfg.change_plants == defns.change_plants.gh then
        updateHerbalismSwitch(ref, successful and 1 or 2) 
    elseif cfg.change_plants == defns.change_plants.destroy then
        if next(organic_blacklist) == nil or not organic_blacklist[ref.baseObject.id:lower()] then
            ref:disable()
        end
    end
end


---@class MQL.Manager.Organic : MQL.Manager.Chance
---@field base_chance number the base chance you have of taking something 
---@field penalty_mult number the multiplier applied to the total_value of the plant 
local Organic = Class.new{name="Organic Manager", parents={Chance},
    {"i18n_index", default="looted.organic"},
    {"base_chance"},
    {"penalty_mult"},

    init = function(self, ref)
        self.ref = ref
        ref:clone()
        self:_update_stealing_from()
        local pm = tes3.mobilePlayer
        local s = math.max(pm.alchemy.current, 0)

        self.penalty_mult = 0.15 + 0.85 * 2^(-(0.0002 * s^2 + 0.009 * s))
        self.base_chance = 0.01 * (
            1.00 * math.max(0, pm.intelligence.current) + 
            0.50 * math.max(0, pm.agility.current) +
            0.25 * math.max(0, pm.security.current)
        )
    end,
    -- ---@param self MQL.Manager.Chance
    -- post_init = function (self)
    --     Chance.__secrets.post_init(self)
    --     self.gui.key_label.take.absolutePosAlignX = 0.43
    --     self.gui.m_key_label.take.absolutePosAlignX = 0.43
    -- end
}



--- calculate the chance of successfully taking this item. this is called before the UI is created.
---@param item MQL.Item.Chance|tes3item
---@return integer take_chance the chance of successfully taking one copy of this item. should be a number between 0 and 100
function Organic:calc_item_chance(item)
    local penalty = 0.14 * item.weight

    if item.value >= 1 then
        penalty = penalty + 0.063 * math.log(item.value)^1.5
    end
    
    local chance = cfg.chance_mult * (self.base_chance - self.penalty_mult * penalty)
    
    log("calculating take chance for %s:\n\tchance: %s\n\tpenalty: %s", item, chance, penalty)

    return math.clamp(chance, cfg.min_chance, cfg.max_chance)
end


Organic.config = cfg ---@type MQL.config.Manager.Organic
Organic.show_chances_skill_id = tes3.skill.alchemy

-- function Organic:get_keylabels()
--     if self.stealing_from then
--         return { open = "Open", take="Steal", take_all="Steal All"}
--     end
--     return { open = "Open", take="Harvest", take_all="Harvest All"}
-- end

function Organic:_make_items()
    self:add_items()
    self:add_nearby_items{dist=cfg.sn_dist, container_filter=cfg.sn_cf, owner=self.stealing_from}
    self:update_item_chances()
end


function Organic:award_xp(item_value, take_successful)
    local xp_config = cfg.xp
    -- if we allow xp rewards, and if (there's either no max level OR we are below the max level)
    if xp_config.award and (xp_config.max_lvl <= 5 or xp_config.max_lvl >= tes3.mobilePlayer.alchemy.base) then
        -- if we took it successfully, give xp
        if take_successful then
            local t = math.clamp(item_value/100, 0, 1)
            local xp = math.lerp(0.2, 0.5, t)
            tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, xp)
        -- if we took it unsuccessfully, but we allow xp rewards on failure, give only a quarter xp
        elseif xp_config.on_failure then
            local t = math.clamp(item_value/100, 0, 1)
            local xp = math.lerp(0.2, 0.5, t) * 0.25
            tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, xp)
        end
    end
end

--- when we successfully take an item
---@param item MQL.Item.Chance
---@param take_stack boolean are we taking the whole stack?
---@param update_stuff boolean? should we update stuff?
---@return integer num_taken the number of items taken, or `false` if no items were taken
function Organic:on_successful_take(item, take_stack, update_stuff)
    -- mark the item as stolen, transfer the item, and trigger a crime (so the player will be caught if they're not sneaking)

    local num_taken = item:take(take_stack, update_stuff)
    if num_taken > 0 and item.status == defns.item_status.empty then
        change_plant(item.from, true)
        if update_stuff then self:make_msgbox(item, num_taken) end
    end
    return num_taken
end

---@param item MQL.Item.Chance
---@param take_stack boolean are we taking the whole stack?
---@param update_stuff boolean? should we update stuff?
---@return integer num_taken the number of items taken, or `false` if no items were taken
function Organic:on_unsuccessful_take(item, take_stack, update_stuff)
    local num_taken = item:remove_from_container(take_stack, update_stuff)

    if num_taken > 0 then
        if item.status == defns.item_status.empty then change_plant(self.ref, false) end
        if update_stuff and cfg.show_failure_msg then
            self:make_i18n_msgbox("looted.organic_failure",nil,true)
            -- self:make_msgbox(item, 0)
        end
    end
    return num_taken
end

--- if the container is empty, we should update the plant if we try to take it
---@param modifier_pressed boolean was the modifier key pressed?
---@return boolean should_block should the event be blocked?
function Organic:take_item(modifier_pressed)
    if self.cant_loot == defns.cant_loot.empty then
        change_plant(self.ref, false)
        return true
    end
    return Chance.take_item(self, modifier_pressed)
end


function Organic:do_cant_loot_action()
    if self.cant_loot == defns.cant_loot.empty then
        self.gui:block_and_show_msg("Empty")
        if cfg.hide_on_empty then
            self.gui:hide()
        end
        -- if GH is currently installed, mark the plant as taken
        if gh_installed then 
            -- apply empty flag, this was copied from `graphicHerbalism.main`
            self.ref.object.modified = false
            self.ref.object:onInventoryClose(self.ref)
            self.ref.isEmpty = true
        end
        if self.inventory_outdated and UI_cfg.update_inv_on_close then
            tes3ui.forcePlayerInventoryUpdate()
            self.inventory_outdated = false
        end
    else
        super(self).do_cant_loot_action(self)
    end
end


return Organic