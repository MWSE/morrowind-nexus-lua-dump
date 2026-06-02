
local this = {}


this.data = {}


function this.get(group, id)
    if not this.data[group] then return nil end
    return this.data[group][id]
end


function this.set(group, id, value)
    if not this.data[group] then this.data[group] = {} end
    this.data[group][id] = value
end


function this.clear(group)
    if group then
        this.data[group] = nil
    else
        this.data = {}
    end
end


return this