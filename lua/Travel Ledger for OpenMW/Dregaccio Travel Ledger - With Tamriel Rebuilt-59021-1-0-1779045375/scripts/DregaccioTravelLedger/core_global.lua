-- Dregaccio Travel Ledger Core global script
local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')

local BOOK_ID = "dreg_travel_ledger"
local PRICE_HINT = 30
local VENDORS = {["adondasi sadalvel"]=true, ["ano andaram"]=true, ["aren maren"]=true, ["baleni salavel"]=true, ["basks_in_the_sun"]=true, ["dalse adren"]=true, ["daras aryon"]=true, ["darvame hleran"]=true, ["daynas darys"]=true, ["devas irano"]=true, ["dilami androm"]=true, ["emelia duronia"]=true, ["erranil"]=true, ["fendryn drelvi"]=true, ["flacassia fauseius"]=true, ["folsi thendas"]=true, ["gals arethi"]=true, ["haema farseer"]=true, ["iniel"]=true, ["masalinie merian"]=true, ["navam veran"]=true, ["nevosi hlan"]=true, ["nireli farys"]=true, ["punibi yahaz"]=true, ["s'virr"]=true, ["sedyni veran"]=true, ["seldus nerendus"]=true, ["selvil sareloth"]=true, ["talmeni drethan"]=true, ["talsi uvayn"]=true, ["tonas telvani"]=true, ["valveli arelas"]=true, ["veresa alver"]=true}
local ROUTES = {
    ["Ald-ruhn"] = {
        ["Guild Guide"] = {"Balmora", "Caldera", "Sadrith Mora", "Vivec, Foreign Quarter"},
        ["Silt Strider"] = {"Balmora", "Gnisis", "Khuul", "Maar Gan"},
    },
    ["Balmora"] = {
        ["Guild Guide"] = {"Ald-ruhn", "Caldera", "Sadrith Mora", "Vivec, Foreign Quarter"},
        ["Silt Strider"] = {"Ald-ruhn", "Seyda Neen", "Suran", "Vivec"},
    },
    ["Caldera"] = {
        ["Guild Guide"] = {"Ald-ruhn", "Balmora", "Sadrith Mora", "Vivec, Foreign Quarter"},
    },
    ["Dagon Fel"] = {
        ["Boat"] = {"Khuul", "Sadrith Mora", "Tel Aruhn", "Tel Mora"},
    },
    ["Ebonheart"] = {
        ["Boat"] = {"Hla Oad", "Sadrith Mora", "Tel Branora", "Vivec, Foreign Quarter"},
    },
    ["Fort Frostmoth"] = {
        ["Boat"] = {"Khuul", "Raven Rock"},
    },
    ["Gnaar Mok"] = {
        ["Boat"] = {"Hla Oad", "Khuul"},
    },
    ["Gnisis"] = {
        ["Silt Strider"] = {"Ald-ruhn", "Khuul", "Maar Gan", "Seyda Neen"},
    },
    ["Hla Oad"] = {
        ["Boat"] = {"Ebonheart", "Gnaar Mok", "Molag Mar", "Vivec, Foreign Quarter"},
    },
    ["Khuul"] = {
        ["Boat"] = {"Dagon Fel", "Fort Frostmoth", "Gnaar Mok"},
        ["Silt Strider"] = {"Ald-ruhn", "Gnisis", "Maar Gan"},
    },
    ["Maar Gan"] = {
        ["Silt Strider"] = {"Ald-ruhn", "Gnisis", "Khuul"},
    },
    ["Molag Mar"] = {
        ["Silt Strider"] = {"Suran", "Vivec"},
    },
    ["Raven Rock"] = {
        ["Boat"] = {"Fort Frostmoth"},
    },
    ["Sadrith Mora"] = {
        ["Boat"] = {"Dagon Fel", "Ebonheart", "Tel Branora", "Tel Mora"},
        ["Guild Guide"] = {"Ald-ruhn", "Balmora", "Caldera", "Vivec, Foreign Quarter"},
    },
    ["Seyda Neen"] = {
        ["Silt Strider"] = {"Balmora", "Gnisis", "Suran", "Vivec"},
    },
    ["Suran"] = {
        ["Silt Strider"] = {"Balmora", "Molag Mar", "Seyda Neen", "Vivec"},
    },
    ["Tel Aruhn"] = {
        ["Boat"] = {"Dagon Fel", "Tel Mora", "Vos"},
    },
    ["Tel Branora"] = {
        ["Boat"] = {"Ebonheart", "Molag Mar", "Sadrith Mora", "Vivec, Foreign Quarter"},
    },
    ["Tel Mora"] = {
        ["Boat"] = {"Dagon Fel", "Sadrith Mora", "Tel Aruhn", "Vos"},
    },
    ["Vivec"] = {
        ["Silt Strider"] = {"Balmora", "Molag Mar", "Seyda Neen", "Suran"},
    },
    ["Vivec, Arena"] = {
        ["Gondola"] = {"Vivec, Foreign Quarter", "Vivec, Hlaalu", "Vivec, Telvanni", "Vivec, Temple"},
    },
    ["Vivec, Foreign Quarter"] = {
        ["Boat"] = {"Ebonheart", "Hla Oad", "Molag Mar", "Tel Branora"},
        ["Gondola"] = {"Vivec, Arena", "Vivec, Hlaalu", "Vivec, Telvanni"},
        ["Guild Guide"] = {"Ald-ruhn", "Balmora", "Caldera", "Sadrith Mora"},
    },
    ["Vivec, Hlaalu"] = {
        ["Gondola"] = {"Vivec, Arena", "Vivec, Foreign Quarter", "Vivec, Temple"},
    },
    ["Vivec, Telvanni"] = {
        ["Gondola"] = {"Vivec, Arena", "Vivec, Foreign Quarter", "Vivec, Temple"},
    },
    ["Vivec, Temple"] = {
        ["Gondola"] = {"Vivec, Arena", "Vivec, Hlaalu", "Vivec, Telvanni"},
    },
    ["Vos"] = {
        ["Boat"] = {"Sadrith Mora", "Tel Aruhn", "Tel Mora"},
    },
}

local function lower(v)
    if v == nil then return nil end
    return string.lower(tostring(v))
end

local function safe(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local function hasLedger(actor)
    local inv = types.Actor.inventory(actor)
    if inv == nil then return false end
    local books = safe(function() return inv:getAll(types.Book) end) or {}
    for _, item in ipairs(books) do
        if lower(item.recordId) == BOOK_ID then return true end
    end
    return false
end

local function stockVendor(actor)
    if actor == nil or not types.NPC.objectIsInstance(actor) then return end
    if not VENDORS[lower(actor.recordId)] then return end
    if hasLedger(actor) then return end
    local item = world.createObject(BOOK_ID, 1)
    item:moveInto(types.Actor.inventory(actor))
end

local function stockActiveVendors()
    for _, actor in ipairs(world.activeActors) do
        stockVendor(actor)
    end
end

local elapsed = 4
local function stationFromCellName(name)
    if name == nil then return nil end
    local s = tostring(name)
    if ROUTES[s] ~= nil then return s end
    local rules = {
        {'Ald%-ruhn', 'Ald-ruhn'},
        {'Balmora', 'Balmora'},
        {'Caldera', 'Caldera'},
        {'Sadrith Mora', 'Sadrith Mora'},
        {'Wolverine Hall', 'Sadrith Mora'},
        {'Vivec, Foreign Quarter', 'Vivec, Foreign Quarter'},
        {'Vivec, Hlaalu', 'Vivec, Hlaalu'},
        {'Vivec, Telvanni', 'Vivec, Telvanni'},
        {'Vivec, Arena', 'Vivec, Arena'},
        {'Vivec, Temple', 'Vivec, Temple'},
        {'Vivec', 'Vivec'},
        {'Seyda Neen', 'Seyda Neen'},
        {'Suran', 'Suran'},
        {'Gnisis', 'Gnisis'},
        {'Maar Gan', 'Maar Gan'},
        {'Khuul', 'Khuul'},
        {'Molag Mar', 'Molag Mar'},
        {'Ebonheart', 'Ebonheart'},
        {'Hla Oad', 'Hla Oad'},
        {'Gnaar Mok', 'Gnaar Mok'},
        {'Dagon Fel', 'Dagon Fel'},
        {'Tel Branora', 'Tel Branora'},
        {'Tel Mora', 'Tel Mora'},
        {'Tel Aruhn', 'Tel Aruhn'},
        {'Vos', 'Vos'},
    }
    for _, rule in ipairs(rules) do
        if string.find(s, rule[1]) and ROUTES[rule[2]] ~= nil then return rule[2] end
    end
    return nil
end

local function formatRoutes(station)
    local data = ROUTES[station]
    if data == nil then return nil end
    local lines = {'Travel Ledger: ' .. station}
    local methods = {}
    for method, _ in pairs(data) do table.insert(methods, method) end
    table.sort(methods)
    for _, method in ipairs(methods) do
        table.insert(lines, method .. ': ' .. table.concat(data[method], ', '))
    end
    return table.concat(lines, '
')
end

local function onLedgerUsed(item, actor)
    if lower(item.recordId) ~= BOOK_ID then return nil end
    local cellName = nil
    pcall(function() cellName = actor.cell.name end)
    local station = stationFromCellName(cellName)
    if station ~= nil then
        actor:sendEvent('DregaccioTravelLedgerShowMessage', { text = formatRoutes(station) })
        return false
    end
    actor:sendEvent('DregaccioTravelLedgerShowMessage', { text = 'Travel Ledger: no local commercial route found here. Open the book from inventory for the complete route catalogue.' })
    return nil
end

I.ItemUsage.addHandlerForType(types.Book, onLedgerUsed)

return {
    engineHandlers = {
        onUpdate = function(dt)
            elapsed = elapsed + dt
            if elapsed >= 4 then
                elapsed = 0
                stockActiveVendors()
            end
        end,
    },
}
