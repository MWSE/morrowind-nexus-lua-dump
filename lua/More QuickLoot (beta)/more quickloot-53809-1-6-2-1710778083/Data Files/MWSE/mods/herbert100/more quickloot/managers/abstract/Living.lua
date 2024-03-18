---@diagnostic disable: undefined-field
local base = require("herbert100.more quickloot.managers.abstract.base")
local defns = require "herbert100.more quickloot.defns"
local log = Herbert_Logger()
-- local log = require("herbert100.logger") ("More QuickLoot/Living")
---@class MQL.Managers.Living : MQL.Manager
---@field allow_equipped table<tes3.objectType, boolean>? whether certain object types should be shown if equipped
---@field allow_equipped_slots table<tes3.clothingSlot, boolean>? whether things equipped in certain item slots should be allowed
local Living = Herbert_Class.new{name="Living", parents={base}}

-- we should stop updating each frame if: 
-- 1) the person we're looking at doesn't exist,
-- 2) the person we're looking at is not alive, or 
-- 3) we are sneaking
function Living:on_simulate()
    return self.ref ~= nil                          -- container exists
        and self.ref.isDead == false                -- target is alive
        and tes3.mobilePlayer ~= nil                -- player mobile exists
        and tes3.mobilePlayer.isSneaking ~= true    -- player is not sneaking
end



---@param equipped_cfg MQL.config.equipped
---@return MQL.Manager.obj_filter_fun
function Living:make_equipped_filter(equipped_cfg)
    local cfg = equipped_cfg or self.config.equipped
    if not cfg then
        log:error("self.config.equipped is nil. why is this happening.... using barter config as a fallback")
        cfg = require("herbert100.more quickloot.config").barter.equipped
    end
    local weapon, clothing, armor = tes3.objectType.weapon, tes3.objectType.clothing, tes3.objectType.armor

    ---@type table<tes3.clothingSlot, boolean>
    local cs = {
        [tes3.clothingSlot.leftGlove] = cfg.accessories,
        [tes3.clothingSlot.rightGlove] = cfg.accessories,
        [tes3.clothingSlot.belt] = cfg.accessories,
        [tes3.clothingSlot.ring] = cfg.jewelry,
        [tes3.clothingSlot.amulet] = cfg.jewelry,
    }
    
    ---@type table<tes3.armorSlot, boolean>
    local as = {
        [tes3.armorSlot.shield] = cfg.shield,
        [tes3.armorSlot.leftGauntlet] = cfg.accessories,
        [tes3.armorSlot.rightGauntlet] = cfg.accessories,
    }
    ---@type table<tes3.weaponType, boolean>
    local wt = {
        [tes3.weaponType.shortBladeOneHand] = cfg.small_wpn,
        [tes3.weaponType.arrow] = cfg.ammo,
        [tes3.weaponType.bolt] = cfg.ammo,
        [tes3.weaponType.marksmanThrown] = cfg.small_wpn,
        [tes3.weaponType.bluntOneHand] = cfg.medium_wpn,
        [tes3.weaponType.axeOneHand] = cfg.medium_wpn,
        [tes3.weaponType.longBladeOneHand] = cfg.medium_wpn,
    }

    -- local is_ok = defns.item_status.ok
    local is_equipped = defns.item_status.unavailable
    local equipped_reason = defns.unavailable_reason.equipped
    ---@param obj tes3weapon|tes3armor|tes3clothing
    return function(obj)
        local obj_type = obj.objectType ---@type tes3.objectType
        -- we're splitting this up into a bunch of if statements for better branch control
        if obj_type == weapon then
            if wt[obj.type] or cfg.weapons then return true end
        elseif obj_type == armor then
            if as[obj.slot] or cfg.armor then return true end
        elseif obj_type == clothing then
            if cs[obj.slot] or cfg.clothing then return true end
        end

        if cfg.show then
            return true, is_equipped, equipped_reason
        else
            return false
        end
    end
end

---@class MQL.Manager.Living.add_npc_items.params : MQL.Manager.add_items.params
---@field equipped_cfg MQL.config.equipped?

---@param p MQL.Manager.Living.add_npc_items.params
function Living:add_npc_items(p)
    local from = p.ref or self.ref
    local to = p.to or tes3.player
    from:clone()


    local relref = p.related_ref or tes3.player
    local obj_filter = p.obj_filter
    local cls = self.item_type

    local equipped_filter = self:make_equipped_filter(p.equipped_cfg)
    
    local equipped_count = {} ---@type table<tes3item, integer> a table recording how many copies of an item an npc has equipped
    
    for _, stack in pairs(from.object.equipment) do
        local id = stack.object.id
        equipped_count[id] = (equipped_count[id] or 0) + 1
    end
    
    local obj, count, ec

    local eqf_yield, eqf_status, eqf_reason

    for _, stack in ipairs(from.object.inventory.items or from.object.inventory) do ---@cast stack tes3itemStack
        obj = stack.object
        
        if obj.canCarry == false then goto next_stack end

        local yield, status, reason = true, nil, nil

        if obj_filter ~= nil then
            yield, status, reason = obj_filter(stack.object)
            if not yield then goto next_stack end
        end

        -- Account for restocking items, since their count is negative
        count = math.abs(stack.count)
        
        -- first yield stacks with custom data
        if stack.variables then
            ec = equipped_count[obj.id]
            eqf_yield, eqf_status, eqf_reason = equipped_filter(obj)

            log:trace("checking variables for stack of %s", obj.name)
            for _, data in pairs(stack.variables) do
                -- you would think i don't need this if statement, but trust me, i do
                if data then
                    count = count - 1
                    if ec then
                        ec = ec - 1
                        equipped_count[obj.id] = ec > 0 and ec or nil
                        if eqf_yield then
                            table.insert(self.items, cls.new{from=from, to=to, object=obj, related_ref=relref,
                                data=data, count=1, 
                                status=eqf_status, unavailable_reason=eqf_reason,
                            })
                        end
                    else
                        table.insert(self.items, cls.new{from=from, to=to, object=obj, related_ref=relref,
                            data = data, count=1, status=status, unavailable_reason=reason
                        })
                    end
                end
            end
        end
        -- if there are items to add, add them
        if count > 0 then
            table.insert(self.items, cls.new{from=from, to=to, object=obj, related_ref=relref, 
                count=count, status=status, unavailable_reason=reason
            })
        end
        ::next_stack::
    end
end

return Living