local this = {}

this.locations = {}

---@param locationTable table
function this:registerLocation(locationTable)
    table.insert(this.locations, locationTable)
end


return this