local adv = {}
local types = require("openmw.types")
local async = require("openmw.async")


adv.mwscript = {
    ["bill_marksdaedrasummon"] = { done = 1 },
    --[""] = {}, -- items without any mwscript can be considered cursed
}

adv.types = {

}

for typename, type in pairs(types) do
    --if typename == "Ingredient" then
    adv.types[type] = true
    --end
end

return adv
