local bazaar = require("sb_bazaar.interop")

local common =
{
    ["Copper_001"] = {value = 0.10, properties = {pluralName = "Coppers", tradeOnly = true}},
    ["Bronze_001"] = {value = 0.25},
    ["Silver_001"] = {value = 0.50, properties = {stackingMeshes = {["o\\LootBag.nif"] = 4}, tradeOnly = true}},
}

--- @type {value: number, objectId: string}[]
local early =
{
    ["Quincuos_001"] = {value = 5},
    ["Decuos_001"] = {value = 10},
    ["Vigentuos_001"] = {value = 20},
    ["Centuos_001"] = {value = 100}
}

local modern =
{
    ["Remans_001"] = {value = 25, properties = {pluralName = "Remans"}},
    ["Septim_001"] = {value = 100, properties = {pluralName = "Septims"}},
}

--- @param e initializedEventData
local function initializedCallback(e)
    bazaar.registerGoldDenominations(common)
    bazaar.registerCurrency("Simos_001", "%ds", {denominations = early})
    bazaar.registerCurrency("Alessians_001", "Al %d", {denominations = modern, pluralName = "Alessians", tradeOnly = true})

    bazaar.registerMerchant("arrille", {["Simos_001"] = 50, ["Alessians_001"] = 7}, {})
    bazaar.registerMerchant("raflod the braggart", {["Simos_001"] = 12, ["Alessians_001"] = 0}, {}, false)
    bazaar.registerMerchant("ilen faveran", {["Alessians_001"] = 0}, {})
    bazaar.registerMerchant("benunius agrudilius", {["Simos_001"] = 0}, {}, false)
    bazaar.registerMerchant("llarara omayn", {["Simos_001"] = 0}, {})
    bazaar.registerMerchant("thorek", {["Simos_001"] = 0, ["Alessians_001"] = 0}, {}, false)

    --- @param ref tes3reference
    bazaar.registerComplexMerchant(function(ref)
        return ref.object.aiConfig and ref.object.aiConfig.travelDestinations and #ref.object.aiConfig.travelDestinations > 0
    end, {["Simos_001"] = 0}, {})
    --- @param ref tes3reference
    bazaar.registerComplexMerchant(function(ref)
        return ref.cell.isOrBehavesAsExterior and ref.cell.name == "Seyda Neen"
    end, {["Simos_001"] = 0, ["Alessians_001"] = 0}, {})

    bazaar.registerBank("Vedam Dren", {["Simos_001"] = 240, ["Alessians_001"] = 400}, {})

    --- @param ref tes3reference
    bazaar.registerComplexBank(function(ref)
        return ref.cell.name == "Balmora, Hlaalu Council Manor"
    end, {["Simos_001"] = 0, ["Alessians_001"] = 0}, {["Silver_001"] = 35, ["Decuos_001"] = 20, ["Vigentuos_001"] = 5, ["Remans_001"] = 11, ["Septim_001"] = 8}, false)
end
event.register(tes3.event.initialized, initializedCallback)