local types = require("openmw.types")
local vfs = require("openmw.vfs")

local matModel, M = {}
for i in vfs.pathsWithPrefix("scripts/ImpactEffects/interop/materialModel/") do
    if i:find(".lua$") then
        i = string.gsub(i, ".lua", "")
        i = string.gsub(i, "/", ".")
        M = require(i)
        for k, v in pairs(M) do matModel[k:lower()] = v            end
    end
end

local matFallback = require("scripts.ImpactEffects.materialFallback")
local matCreature = require("scripts.ImpactEffects.materialCreature")
local pathFilter = { {"^meshes/"}, {"^tr/"}, {"^sky/"}, {"^pc/"}, {"^hr/"}, {"^oaab/"},
        {"/tr_", "/"}, {"/sky_", "/"}, {"/pc_", "/"} }

local matByTypes = {
    a = {
        [types.Potion] = "Glass",
        [types.Book] = "Paper",
        [types.Clothing] = "Fabric",
        [types.Ingredient] = "Organic",
        [types.Repair] = "Metal",
    },
    b = {
        [types.Apparatus] = "Ceramic",
        [types.Container] = "Wood",
        [types.Door] = "Wood",
        [types.Static] = "Stone",
        [types.Weapon] = "Metal",
        [types.Armor] = "Metal",
    }
}

local function getObjectMat(o, path, model)
    local mat = matByTypes.a[o.type]
    if not mat then
        local pattern = matFallback
        for i = 1, #pathFilter do
            local v = pathFilter[i]
            path = string.gsub(path, v[1], v[2] or "", 1)
        end
        for i = 1, #pattern do
            local k, v = table.unpack(pattern[i])
            if debug then print(k)    end
            if path:find(k) then mat = v break    end
        end
    end
    if not mat then mat = matByTypes.b[o.type] or "Unknown"    end

    matModel[model] = mat
    return mat
end

return {
    version = 107,
    getMaterialByObject = function(o)
        if types.Actor.objectIsInstance(o) then    return "Unknown"    end
        local path, model = o.type.records[o.recordId].model:lower()
        path = string.gsub(path, "\\", "/")
        local i, j = string.find(path, "/[^/]*$")
        local model = string.sub(path, i+1, j)
        if not model or model == "" then    return "Unknown"    end
        return matModel[model] or getObjectMat(o, path, model)
    end,
    registerModelMaterial = function(model, mat)
        assert(type(model) == "string" and type(mat) == "string",
            "model and material must be strings")
        matModel[model] = mat
    end,
    registerFallback = function(pattern, mat)
    	assert(type(pattern) == "string" and type(mat) == "string",
            "pattern and material must be strings")
    	for i in ipairs(matFallback) do
            if i == pattern then        return        end
        end
        table.insert(matFallback, {pattern, mat})
    end,
}
