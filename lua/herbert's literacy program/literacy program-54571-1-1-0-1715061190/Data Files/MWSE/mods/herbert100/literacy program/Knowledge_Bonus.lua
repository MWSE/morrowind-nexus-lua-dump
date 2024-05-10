local hlib = require("herbert100")

local log = hlib.Logger()

---@class herbert.HLP.Knowledge_Bonus.new_params
---@field name string name of this knowledge bonus
---@field id string? id of this knowledge bonus. one will be generated if not provided.
---@field skill_ids tes3.skill[]|tes3.skill skill ids that are used by this knowledge bonus
---@field calculate_bonus nil|fun(knowledge: number, skill_id: tes3.skill?): number how to calculate the bonus, given how much we know about the skill. If not specified, the default formula will be used.
---@field event_id tes3.event id of the event to register the callback to
---@field event_callback fun(self: herbert.HLP.Knowledge_Bonus, e): boolean? callback for the event
---@field event_priority number? priority of the event
---@field event_filter number? filter for the event
---@field sort_priority number? used when sorting bonuses. overrides alphabetical sorting. default = 0. higher is better 
---@field get_display_string nil|(fun(self: herbert.HLP.Knowledge_Bonus, skill_id: tes3.skill): string|nil) gets the display string for the current value of a bonus

---@class herbert.HLP.Knowledge_Bonus : herbert.HLP.Knowledge_Bonus.new_params, herbert.Class
---@field id string id of this knowledge bonus.
---@field skill_ids herbert.Extended_Table|tes3.skill[]
---@field calculate_bonus fun(knowledge: number, skill_id: tes3.skill?): number how to calculate the bonus, given how much we know about the skill
---@field private _callback fun(e): boolean? actual callback for the event. stored so that it can be unregistered later if necessary
---@field protected bonuses herbert.Extended_Table|table<tes3.skill, number> cached bonuses. used so we dont have to recompute everything all the time
---@field new fun(p: herbert.HLP.Knowledge_Bonus.new_params): herbert.HLP.Knowledge_Bonus make a new knowledge bonus
local KB = Herbert_Class.new{
    fields={
        {"name"},
        {"sort_priority", default=0, eq=true, comp=function (v) return -v end}, 
        {"id", eq=true, comp=true, ---@param self herbert.HLP.Knowledge_Bonus
            factory=function(self) return self.name:gsub("%s+", "_"):gsub("[^%w_]", ""):lower() end 
        },
        {"bonuses", factory=function() return hlib.tbl_ext.new() end, tostring=function(bonuses)
            local tbl = {}
            for k, v in pairs(bonuses) do
                tbl[tes3.skillName[k]] = v
            end
            return json.encode(tbl)
        end},
        {"description"},
        {"event_id"},
        {"skill_ids", 
            converter=function(v) 
                return hlib.tbl_ext.new(type(v) == "number" and {v} or v)
            end,
            tostring=function(v) return json.encode(hlib.tbl_ext.map(v, tes3.getSkillName))  end
        },
        {"_callback", tostring=false,
            -- i am a good programmer
            factory=function(self) return (function(e) self:event_callback(e) end) end -- make sure each object has its own callback function
        }
    },
}


function KB.calculate_bonus(k)
    return 0.6 * 0.52 * (1 - 2^( -0.00004 * (0.001 * k^2 + 75 * k) ))
end

function KB:update_registration()
    return hlib.update_registration{
        callback = self._callback,
        event = self.event_id,
        filter = self.event_filter,
        priority = self.event_priority,
        register = hlib.tbl_ext.any(self.bonuses, function(v) return v ~= 0 end) ~= nil
    }
end

---@param knowledge_by_skill herbert.Extended_Table|table<tes3.skill, number>
function KB:update_bonuses(knowledge_by_skill)
    for _, skill_id in pairs(self.skill_ids) do
        self.bonuses[skill_id] = self.calculate_bonus(knowledge_by_skill[skill_id], skill_id)
    end
end

---@param skill_id tes3.skill? defaults to first skill id
---@return number
function KB:get_bonus(skill_id)
    return self.bonuses[skill_id or self.skill_ids[1]]
end


---@param knowledge_by_skill herbert.Extended_Table|table<tes3.skill, number>
---@return boolean registered_event true if the event was registered, false if it wasn't
function KB:update(knowledge_by_skill)
    self:update_bonuses(knowledge_by_skill)
    log:trace("updated bonuses: %s", self)
    return self:update_registration()
end


---@param skill_id tes3.skill
---@return string? str if we have a bonus. otherwise, nil
function KB:get_display_string(skill_id)
    local bonus_val = self:get_bonus(skill_id)
    log:trace("getting bonus display string for %s", self)
    if not bonus_val then return end
    local str = "%s: +%s%%"
    if bonus_val < 0 then
        str = "%s: -%s%%"
        bonus_val = -bonus_val
    end
    bonus_val = math.round(100 * bonus_val, 1)
    return bonus_val ~= 0 and str:format(self.name, bonus_val) or nil
end

---@cast KB herbert.HLP.Knowledge_Bonus

return KB