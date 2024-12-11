local Class = require("herbert100.Class")
local function sp(...) print(string.format(...)) end

---@class herbert.Path
---@field new fun(p:string|{[integer]:string,["stem"|"name"|"suffix"]:string}|nil):herbert.Path make a new path
local Path = {}

Class.new({
    ---@param self_or_str string|{[integer]:string,["stem"|"name"|"suffix"]:string}|nil
    new_obj_func=function(self_or_str)
        if not self_or_str then
            return {parts = lfs.currentdir():split("\\/")}
        elseif type(self_or_str) == "string" then
            return {parts = self_or_str:split("\\/")}
        elseif Class.is_instance_of(self_or_str, Path) then
            return self_or_str
        else
            return {parts = self_or_str}
        end
    end,
    init = function (self, ...)
        self.path = table.concat(self.parts, "\\")
        local n = #self.parts
        self.stub = self.parts[n]
        sp("self.parts = %s", json.encode(self.parts))
        print("self.stub = %s", self.stub)
        self.parent = self.parts[n-1]
        local s, e = self.stub:find("%.%w+$")
        if s then
            self.suffix = self.stub:sub(s)
            self.name = self.stub:sub(1, e-1)
        else
            self.name = self.stub
        end
    end,
    obj_metatable = {
        __div = function(self, other)
            local tbl
            if type(other) == "string" then
                tbl = other:split("/\\")
            elseif Class.is_instance_of(other, Path) then
                tbl = other.parts
            else
                tbl = other
            end
            local parts = table.copy(self.parts)
            sp("div: tbl = %s. parts = %s", json.encode(tbl), json.encode(parts))
            for _, part in ipairs(tbl) do
                table.insert(parts, part)
            end
            return Path.new(parts)
        end,
        __tostring = function(self) return self.path end,
        __concat = function (self, other)
            local tbl
            local parts = table.copy(self.parts)
            if Class.is_instance_of(other, Path) then
                tbl = other.parts
            else
                tbl = other
                if tbl.stem then
                    parts[#parts] = tbl.stem
                elseif tbl.name or tbl.suffix then
                    parts[#parts] = string.format("%s.%s", tbl.name or self.name, tbl.suffix or self.suffix)
                end
            end
            for _, part in ipairs(tbl) do
                table.insert(parts, part)
            end

            return Path.new(parts)
        end
    }
}, Path)


function Path:with_stem(stem) return self .. {stem=stem} end

---@param p {["stem"|"name"|"suffix"]:string}
function Path:with(p) return self .. p end


function Path:get_parent()
    local parts = table.copy(self.parts)
    parts[#parts] = nil
    return Path.new(parts)
end

return Path