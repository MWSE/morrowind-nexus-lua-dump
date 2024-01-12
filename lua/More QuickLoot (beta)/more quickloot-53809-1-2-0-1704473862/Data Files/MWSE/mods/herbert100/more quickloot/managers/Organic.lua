-- =============================================================================
-- ORGANIC LOOTING
-- =============================================================================
local hlib = require"herbert100"
local defns = require("herbert100.more quickloot.defns")
local Class, log = hlib.Class, hlib.Logger("More QuickLoot/Organic")
local config = require("herbert100.more quickloot.config")
-- local base = require("herbert100.more quickloot.managers.abstract.base")
local Chance = require("herbert100.more quickloot.managers.abstract.Chance")
local Chance_Item = require("herbert100.more quickloot.Item").Chance



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
        and not config.blacklist.organic[ref.baseObject.id:lower()]
    then
        ref:disable()
        ref:delete()
    end
end

---@class MQL.Manager.Organic : MQL.Manager.Chance
---@field base_chance number the base chance you have of taking something 
---@field penalty_mult number the multiplier applied to the total_value of the plant 
local Organic = Class({name="Organic Manager", parents={Chance},},{i18n_index = "looted.organic"})

Organic.config = config.organic ---@type MQL.config.Manager.Organic

function Organic:_initialize()
    local pm = tes3.mobilePlayer
    self.base_chance = math.min(pm.alchemy.current * 1.25, 200)
        + 0.5 * pm.intelligence.current
    self.penalty_mult = 5 * math.max(0.25, 1 - pm.security.current/150)
end

function Organic:_get_key_btn_info()
    local verb = self.stealing_from and "Steal" or "Harvest"
    return {
        take = {label = verb, pos = 0.05},
        take_all = {label = verb .. " nearby", pos = 0.95}
    }
end

function Organic:_get_iter_params()
    ---@type MQL.Item.iter_container.params
    return {
        ref = self.ref,
        search_nearby = { 
            container_filter = self.config.sn_cf,
            owned_by = {self.stealing_from},
            dist = self.config.sn_dist,
        },
        post_creation=Chance._get_iter_params(self).post_creation,
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

function Organic:award_xp(item_value, take_successful)
    local xp_config = self.config.xp
    -- if we allow xp rewards, and if (there's either no max level OR we are below the max level)
    if xp_config.award and (xp_config.max_lvl <= 5 or xp_config.max_lvl >= tes3.mobilePlayer.alchemy.base) then
        -- if we took it successfully, give xp
        if take_successful then
            local t = math.clamp(item_value/100, 0, 1)
            local xp = math.lerp(0.2, 0.75, t)
            tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, xp)
        -- if we took it unsuccessfully, but we allow xp rewards on failure, give only a quarter xp
        elseif xp_config.on_failure then
            local t = math.clamp(item_value/100, 0, 1)
            local xp = math.lerp(0.2, 0.75, t) * 0.25
            tes3.mobilePlayer:exerciseSkill(tes3.skill.alchemy, xp)
        end
    end
end

--- when we successfully take an item
---@param item MQL.Item.Chance
---@param take_stack boolean are we taking the whole stack?
---@param play_sound boolean? should we update stuff?
---@return integer|false? num_taken the number of items taken, or `false` if no items were taken
function Organic:on_successful_take(item, take_stack, play_sound)
    -- mark the item as stolen, transfer the item, and trigger a crime (so the player will be caught if they're not sneaking)

    local num_taken = item:take_from_container(take_stack, play_sound)
    if num_taken and item.status == defns.item_status.empty then
        change_plant(item.ref, true)
        if play_sound and num_taken then
            self:make_msgbox(item, num_taken)
        end
    end
    return num_taken
end

---@param item MQL.Item.Chance
---@param take_stack boolean are we taking the whole stack?
---@param play_sound boolean? should we update stuff?
---@return integer|false? num_taken the number of items taken, or `false` if no items were taken
function Organic:on_unsuccessful_take(item, take_stack, play_sound)
    local num_taken = item:remove_from_container(take_stack, play_sound)

    if num_taken then
        if item.status == defns.item_status.empty then change_plant(self.ref, false) end
        if play_sound and config.organic.show_failure_msg then
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
        if config.organic.hide_on_empty then
            self.gui:hide()
        end
        -- if GH is currently installed, mark the plant as taken
        if config.compat.gh_current == defns.misc.gh.installed then 
            -- apply empty flag, this was copied from `graphicHerbalism.main`
            self.ref.object.modified = false
            self.ref.object:onInventoryClose(self.ref)
            self.ref.isEmpty = true
        end
        if self.inventory_outdated and config.UI.update_inv_on_close then
            tes3ui.forcePlayerInventoryUpdate()
            self.inventory_outdated = false
        end
    else
        Chance.do_cant_loot_action(self)
    end
end


return Organic