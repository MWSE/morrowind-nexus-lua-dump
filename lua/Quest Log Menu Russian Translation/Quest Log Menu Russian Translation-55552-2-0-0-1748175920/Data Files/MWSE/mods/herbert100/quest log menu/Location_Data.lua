--[[Stores:
1. the `tes3cell` this actor is in
2. the first exterior `tes3cell` for the cell in `1`
]]

local hlib = require("herbert100")
local tbl_ext = hlib.tbl_ext
local log = Herbert_Logger()

-- we will add the relevant functions to `common` in this file
local common = hlib.import("common") ---@type herbert.QLM.common


-- so that switching to livecoding is easier
local register_event = event.register
local fmt = string.format


-- a bunch of occupations, e.g. "Healer", "Bookseller", "Enchanter", etc.
-- doing it programatically means it will play more nicely with translations
local occupations = common.actor_occupations

log("reloaded location data")

-- table that keeps track of which actors are in which cell
-- gets reset on cell change
-- this cache is kept to reduce the calls to `tes3.getReference`,
-- which can cumulatively add 0.1 seconds (!!!) to the menu load time
---@type table<string, herbert.QLM.Location_Data>
local actor_id_loc_cache = {}

-- keeps track of the shortened names of a location. gets reset whenever the MCM is closed
---@type table<herbert.QLM.Location_Data, string>
local location_str_cache = {}


register_event(tes3.event.cellChanged, function()
    actor_id_loc_cache = {}
end)

-- Cache that keeps track of the location data for a given cell
-- This is not reset
---@type table<string, herbert.QLM.Location_Data>
local cell_id_loc_cache = {}

local cell_id_str_cache = {}

---@class herbert.QLM.Location_Data
---@field path tes3cell[] path we took to get to the exterior
---@field owner_info nil|{npc: tes3npc?, cell_prefix: string} Is this cell owned by somebody. e.g. "Dirty Muriel's Cornerclub"
---@field path_parts herbert.Extended_Table|((string[]|herbert.Extended_Table)[]) The various different parts of the interior cell name. 
-- e.g. ""Ahemmusa Camp, Wise Woman's Yurt" has parts ["Wise Woman's Yurt", "Ahemmusa Camp"]
---@field purged_ext_parts herbert.Extended_Table|((string[]|herbert.Extended_Table)[]) these are the `ext_parts` 
-- that got removed from `ext_parts` because they appeared too early in `int_parts`
---@field private first_parts_repeated {[1]: integer, [2]: integer}[][]
-- This keeps track of when `path_parts[i][1]` gets trimmed to remove a duplicate that happened in `path_parts[j][1]`,
-- for `i < j`.
-- The field is structured as follows: `first_parts_repeated[j]` is an array containing tuples of the form `{i, n}`,
-- where a tuple `{i, n}` means `path_parts[j][1]` got repeated in `path_parts[i][1]` with severity `n`.
-- The severity is described as follows:
-- `1` means it was partially repeated (i.e., the string obtained by `path_parts[i][1]:gsub(path_parts[j][1])` has length `> 0`).
-- `2` means it was fully repeated (i.e., the string obtained by `path_parts[i][1]:gsub(path_parts[j][1])` has length `== 0`).
--      in this case, the corresponding part is removed from `path_parts[i]`.
---@field class_name string? If not `nil`, then `int_parts[1]` used to be the `class.name` of the `actor` who owns this cell
local Location_Data = {}

local Location_Data_meta = {
    __index = Location_Data,
    __tostring = function(self) ---@param self herbert.QLM.Location_Data
        local first_parts_repated_fmtted = {}
        ---@diagnostic disable-next-line: invisible
        for j, rep_data_for_j in ipairs(self.first_parts_repeated) do
            local pretty_data = {}
            first_parts_repated_fmtted[j] = pretty_data
            -- first_parts_repated_fmtted[self.path[j].id] = pretty_data
            for _, rep_occurence in ipairs(rep_data_for_j) do
                local i, severity = table.unpack(rep_occurence)
                local i_txt = self.path_parts[i][1]
                local j_txt
                if severity == 2 then
                    j_txt = i_txt
                else
                    j_txt = fmt("%s %s", i_txt, self.path_parts[j][1])
                end
                local str = fmt("'%s' was repeated in '%s'", i_txt, j_txt)
                table.insert(pretty_data, str)
            end
        end
        return fmt(
            'QLM:Location_Data(\n\t\t\z
                path = %s, \n\t\t\z
                path_parts = %s, \n\t\t\z
                first_parts_repeated = %s, \z
                class_name = %s, \z
            \n\t)\n',
            json.encode(tbl_ext.map(self.path, function (v) return v.id end)),
            json.encode(self.path_parts),
            json.encode(first_parts_repated_fmtted),
            self.class_name and fmt('"%s"', self.class_name)
        )
    end
}



---@param int_cell tes3cell
function Location_Data.new(int_cell)
    if not int_cell then return end
    local self = cell_id_loc_cache[int_cell.id]

    if not self then
        local path = common.get_first_exterior_cell(int_cell)
        if path then
            ---@diagnostic disable-next-line: missing-fields
            self = {int_cell = path[1], ext_cell = path[#path], path=path}
            setmetatable(self, Location_Data_meta)
            self:generate_parts()
            cell_id_loc_cache[int_cell.id] = self
            
        end
    end

    return self
end

---@param actor tes3actor|string
function Location_Data.new_from_actor(actor)
    local actor_id = type(actor) == "string" and actor or actor.id
    
    local self = actor_id_loc_cache[actor_id]

    if not self then
        local ref = tes3.getReference(actor_id)
        self = Location_Data.new(ref and ref.cell)
        actor_id_loc_cache[actor_id] = self
    end
    return self
end

---@private
function Location_Data:generate_parts()
    if #self.path == 0 then return end

    local path_parts = tbl_ext.new{} ---@type (string[]|herbert.Extended_Table)[]|herbert.Extended_Table
    self.path_parts = path_parts
    local first_parts_repeated = tbl_ext.new{}
    self.first_parts_repeated = first_parts_repeated

    for i, cell in ipairs(self.path) do
        local name = cell.displayName
        
        -- блок перевода названия ячейки на русский язык.
        if tes3.isLuaModActive("Pirate.CelDataModule") then
            name = CellNameTranslations[name] or name
        end
        name = name:gsub(":", ",")
        --конец блока
        local parts = tbl_ext.new{}
        do -- make the parts, in the reverse order
            local last_comma_pos = -1
            while true do
                local new_comma_pos = name:find(", ", last_comma_pos + 2, true)
                if not new_comma_pos then break end

                local new_part = name:sub(last_comma_pos + 2, new_comma_pos - 1)
                parts:insert(new_part)
                last_comma_pos = new_comma_pos
            end
            parts:insert(name:sub(last_comma_pos + 2))
        end

        local rev_parts = tbl_ext.new{}
        do -- reverse the parts so they're in the proper order
            local num_parts = #parts
            for j = 1, num_parts do
                rev_parts[j] = parts[num_parts - j + 1]
            end
        end
        path_parts[i] = rev_parts
        first_parts_repeated[i] = tbl_ext.new{}

    end
    -- remove duplicate parts from the path stubs
    for i = #path_parts, 2, -1 do
        local parts = path_parts[i]
        local pattern = table.concat{"^", parts[1], ",?%s?"}
        for j = 1, i - 1 do
            local prev_parts = path_parts[j]
            local _, fp_rep_end = prev_parts[1]:find(pattern)
            if fp_rep_end then
                if fp_rep_end == prev_parts[1]:len() then
                    -- remove it
                    table.remove(prev_parts, 1)
                    table.insert(first_parts_repeated[j], {i, 2})
                else 
                    -- trim it
                    prev_parts[1] = prev_parts[1]:sub(fp_rep_end + 1)
                    table.insert(first_parts_repeated[j], {i, 1})
                end
            end
        end
    end

    -- make sure `int_name` isn't the occupation of an npc's shop
    -- e.g., "Simine Fralinie, Bookseller"

    local int_cell_parts = path_parts[1]
    local first = int_cell_parts[1]
    if first and occupations[first] then
        self.class_name = int_cell_parts:remove(1)
        log:trace("\t\tpdated int_parts = %s", json.encode, int_cell_parts)
    end

    -- update guild names
    -- e.g. `"Mage's Guild"` instead of `"Guild of Mages"
    for i = 1, #path_parts - 1 do
        local parts = path_parts[i]
        local guild_name, rest = parts[1]:match("^Guild of ([%w]+)s(%.*)$")
        if guild_name then
            local old_name = parts[1]
            parts[1] = fmt("%s's Guild%s", guild_name, rest)
            log:trace("updated interior name from %q to %q", old_name, parts[1])
        end
    end
    self.purged_ext_parts = tbl_ext.new{}

    -- get rid of duplicate parts that show up out of order
    for i = 2, #path_parts do
        local parts = path_parts[i]
        local prev_parts = path_parts[i - 1] ---@type herbert.Extended_Table|string[]
        self.purged_ext_parts[i - 1] = tbl_ext.new{}
        while #parts > 0 do
            local last_part_index = table.find(prev_parts, parts[#parts])
            if not last_part_index or last_part_index == #prev_parts then
                break
            end
            self.purged_ext_parts[i - 1]:insert(parts:remove(#parts))
            -- ext_parts[#ext_parts] = nil
        end
    end
    log:trace("\tupdated parts of %s", self)
end


---@return (string[]|herbert.Extended_Table)[]|herbert.Extended_Table
function Location_Data:get_filtered_path_parts()
    
    local num_cells = #self.path
    local sets = {}
    for i = 2, num_cells do
        local set = {}
        sets[i] = set
        for _, part in ipairs(self.path_parts[i]) do
            set[part] = true
        end
    end
    
    local filtered_parts = tbl_ext.new{}
    for i = 1, num_cells - 1 do
        local filtered = tbl_ext.new()
        filtered_parts[i] = filtered

        local parts = self.path_parts[i]
        for _, part in ipairs(parts) do
            local is_new_part = true

            for k = i + 1, num_cells do
                if sets[k][part] then
                    is_new_part = false
                    break
                end
            end
            if is_new_part then
                table.insert(filtered, part)
            end
        end
    end
    filtered_parts[num_cells] = tbl_ext.new{}
    for _, part in ipairs(self.path_parts[num_cells]) do
        table.insert(filtered_parts[num_cells], part)
    end
    return filtered_parts
end
---@return string[]|herbert.Extended_Table
function Location_Data:get_flattened_and_filtered_parts()

    local filtered = self:get_filtered_path_parts()
    local flattened = tbl_ext.new{}
    for _, arr in ipairs(filtered) do
        for _, part in ipairs(arr) do
            flattened:insert(part)
        end
    end
    return flattened
end


---@param include_region boolean? Should the name of the region be appended to the end?. Default: `false`
---@return string
function Location_Data:format_as_address(include_region)

    local path, path_size = self.path, #self.path
    
    local int_cell = path[1]
    local ext_cell = path[path_size]
    local region_name = ext_cell.region and ext_cell.region.name

    -- this means we couldn't find a path to an exterior cell
    if not region_name then
        return path[1].displayName
    end
    
    -- sometimes the cells display name is the same as the region name
    -- we won't cache anything in this case
    if int_cell.displayName == region_name then
        return region_name
    end

    local ret_str = location_str_cache[int_cell.id]

    if not ret_str then
        local flattened = self:get_flattened_and_filtered_parts()
        log:trace("flattened path = %s", json.encode, flattened)
        
        -- lol
        -- if path_size >= 4 then
        --     if ext_cell.id:startswith("Vivec") then
        --         if table.find(flattened, "Canalworks") then
        --             table.removevalue(flattened, "Waistworks")
        --         end
        --     elseif path[path_size - 1].id == "Ald-ruhn, Manor District" then
        --         local flat_len = #flattened
        --         if flat_len >= 3 and flattened[flat_len - 2]:endswith("Entrance") then
        --             table.remove(flattened, flat_len - 2)
        --         end
        --     end
        -- end

        if self.class_name then
            flattened[1] = fmt("%s (%s)", flattened[1], self.class_name)
        end

        ret_str = flattened:concat(", ")

        log:trace("formatting address:\n\tdata = %s\n\taddress = \"%s\"", self, ret_str)
        -- cache it without the region name for consistency
        location_str_cache[int_cell.id] = ret_str
    end

    -- add the region to the end if we were told to, and if it's not already there
    if include_region and not ret_str:endswith(region_name) then
        log:trace("wanted region name for %q.\n\t\z
            path = %s\n\t\z
            parts = %s", 
            function() return ret_str, json.encode(path), json.encode(self.path_parts) end
        )
        ret_str = fmt("%s (%s)", ret_str, region_name)
    end

    return ret_str
end

---@return string[]|herbert.Extended_Table
function Location_Data:make_filtered_int_parts()
    local ext_parts = self.path_parts[#self.path_parts]
    local filtered = tbl_ext.new{}
    for _, v in ipairs(self.path_parts[1]) do
        if not ext_parts:contains(v) then
            filtered:insert(v)
        end
    end
    return filtered
end

function Location_Data:generate_owner_info()
    if self.owner_info then return end
    local int_parts = self.path_parts[1]
    self.owner_info = {}
    local _, e, owner_name = int_parts[1]:find("^([%w%s]+)'s?%s*")
    if not owner_name then return end

    self.owner_info.cell_prefix = owner_name

    local patterns = {owner_name, owner_name:match("([^%s]+)$")}

    for ref in self.path[1]:iterateReferences(tes3.objectType.npc) do
        if ref.object.name:multifind(patterns, 1, true) then
            self.owner_info.npc = ref.object
            return
        end
    end
end

---@param actor tes3actor|string The actor to find the location of. Can be `tes3actor` or that actors `id`.
---@return herbert.QLM.Location_Data
function common.get_actor_location_data(actor)
    return Location_Data.new_from_actor(actor)
end


---@param cell tes3cell|string either a cell, or the cells id
---@return string?
function common.format_cell_name_as_address(cell)
    local loc_data = Location_Data.new(cell)
    return loc_data and loc_data:format_as_address()
end

return Location_Data