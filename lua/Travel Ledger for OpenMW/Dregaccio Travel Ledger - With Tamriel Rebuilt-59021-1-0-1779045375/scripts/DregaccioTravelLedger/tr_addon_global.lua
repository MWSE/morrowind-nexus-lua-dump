-- Dregaccio Travel Ledger TR Addon global script
local core = require('openmw.core')
local types = require('openmw.types')
local world = require('openmw.world')
local I = require('openmw.interfaces')

local BOOK_ID = "dreg_travel_ledger_tr"
local PRICE_HINT = 30
local VENDORS = {["tr_fm_garon thiralas"]=true, ["tr_fm_surshanabi hluvur"]=true, ["tr_m0_anedhil"]=true, ["tr_m0_domiah"]=true, ["tr_m0_gindrala nethri"]=true, ["tr_m0_ohmonir"]=true, ["tr_m0_ysmund"]=true, ["tr_m1_aamunos_rolvar"]=true, ["tr_m1_dagmund"]=true, ["tr_m1_dedave_atherayn"]=true, ["tr_m1_dolmse_andala"]=true, ["tr_m1_dunveri_rodran"]=true, ["tr_m1_erendas_senatam"]=true, ["tr_m1_gadam_tiren"]=true, ["tr_m1_ilnori_pelelius"]=true, ["tr_m1_marthen redri"]=true, ["tr_m1_milara_selenoth"]=true, ["tr_m1_mordinara_valethi"]=true, ["tr_m1_nuleno_nethri"]=true, ["tr_m1_soril"]=true, ["tr_m1_tandryen_reyas"]=true, ["tr_m1_varusha caril"]=true, ["tr_m1_virevar_tilvayn"]=true, ["tr_m1_yugil_nethri"]=true, ["tr_m2_derana llenam"]=true, ["tr_m2_dravil bradyn"]=true, ["tr_m2_garath benaque"]=true, ["tr_m2_hlavora_gilnith"]=true, ["tr_m2_masalmalu_mendas"]=true, ["tr_m2_mjara"]=true, ["tr_m2_orvano tralen"]=true, ["tr_m2_selothril llana"]=true, ["tr_m2_sera bavan"]=true, ["tr_m2_tedril nothro"]=true, ["tr_m2_valna sippusoti"]=true, ["tr_m2_vernis drethan"]=true, ["tr_m3_aeta the spear"]=true, ["tr_m3_barabus inclodios"]=true, ["tr_m3_dovres salvi"]=true, ["tr_m3_elvilde"]=true, ["tr_m3_fathusa_balvel"]=true, ["tr_m3_garrick usald"]=true, ["tr_m3_hlor_gonav"]=true, ["tr_m3_ieva llori"]=true, ["tr_m3_illor mavos"]=true, ["tr_m3_ivrea llothro"]=true, ["tr_m3_laga_gra-shogar"]=true, ["tr_m3_lleres sarando"]=true, ["tr_m3_ralis nalor"]=true, ["tr_m3_rellus delano"]=true, ["tr_m3_riltse helandil"]=true, ["tr_m3_suvala beran"]=true, ["tr_m4_alvur_nirano"]=true, ["tr_m4_didilu-edinu"]=true, ["tr_m4_ervyna_saran"]=true, ["tr_m4_galotha sareloth"]=true, ["tr_m4_gols_ulven"]=true, ["tr_m4_ja'hadra"]=true, ["tr_m4_llehra sarani"]=true, ["tr_m4_maros_sadryon"]=true, ["tr_m4_nol"]=true, ["tr_m4_othrys rorivel"]=true, ["tr_m4_pien vene"]=true, ["tr_m7_adairan llerayn"]=true, ["tr_m7_arvs themyn"]=true, ["tr_m7_bolvin virenith"]=true, ["tr_m7_darane sadralo"]=true, ["tr_m7_davas_hler"]=true, ["tr_m7_delmus dalis"]=true, ["tr_m7_derara ildram"]=true, ["tr_m7_eno malvayn"]=true, ["tr_m7_fathalas romalen"]=true, ["tr_m7_galis urvyon"]=true, ["tr_m7_galu feldrayn"]=true, ["tr_m7_gilsi aryn"]=true, ["tr_m7_idula_sadri"]=true, ["tr_m7_irva famori"]=true, ["tr_m7_komira"]=true, ["tr_m7_lissinia bax"]=true, ["tr_m7_llanel adrano"]=true, ["tr_m7_llerar valaai"]=true, ["tr_m7_nevama_ryon"]=true, ["tr_m7_orille sochand"]=true, ["tr_m7_ravos_andrelo"]=true, ["tr_m7_relenu drolan"]=true, ["tr_m7_rylara karaleth"]=true, ["tr_m7_ulath-bael"]=true, ["tr_m7_vunal ralvayn"]=true, ["tr_m7_zarasni-sa"]=true}
local ROUTES = {
    ["Aimrah"] = {
        ["Boat"] = {"Maar-Bani Crossing"},
        ["Silt Strider"] = {"Almas Thirr", "Vhul"},
    },
    ["Akamora"] = {
        ["Guild Guide"] = {"Bal Foyen", "Old Ebonheart"},
        ["Silt Strider"] = {"Necrom", "Sailen", "Wilderness"},
    },
    ["Ald Iuval"] = {
        ["Boat"] = {"Hlerynhul", "Narsis, Old Quarter", "Othmura", "Sadrathim"},
        ["Silt Strider"] = {"Ald Marak"},
    },
    ["Ald Marak"] = {
        ["Silt Strider"] = {"Ald Iuval"},
    },
    ["Almas Thirr"] = {
        ["Boat"] = {"Bal Foyen, Docks", "Hlan Oek", "Maar-Bani Crossing", "Narsis, Old Quarter", "Old Ebonheart, Docks"},
        ["Guild Guide"] = {"Akamora", "Bal Foyen", "Old Ebonheart"},
        ["Silt Strider"] = {"Aimrah", "Vhul"},
    },
    ["Alt Bosara"] = {
        ["Boat"] = {"Llothanis", "Necrom, Waterfront"},
        ["River Strider"] = {"Llothanis", "Tel Mothrivra"},
    },
    ["Arvud"] = {
        ["Silt Strider"] = {"Hlan Oek", "Menaan"},
    },
    ["Bahrammu"] = {
        ["Boat"] = {"Bal Oyra", "Nivalis"},
    },
    ["Bal Foyen"] = {
        ["Guild Guide"] = {"Akamora", "Old Ebonheart"},
        ["Silt Strider"] = {"Hlan Oek", "Menaan", "Omaynis"},
    },
    ["Bal Foyen, Docks"] = {
        ["Boat"] = {"Almas Thirr", "Old Ebonheart, Docks", "Teyn", "Vivec, Foreign Quarter"},
    },
    ["Bal Oyra"] = {
        ["Boat"] = {"Bahrammu", "Nivalis", "Tel Ouada"},
    },
    ["Bodrum"] = {
        ["Silt Strider"] = {"Omaynis"},
    },
    ["Bosmora"] = {
        ["Silt Strider"] = {"Sailen"},
    },
    ["Dagon Fel"] = {
        ["Boat"] = {"Firewatch", "Nivalis"},
    },
    ["Darvonis"] = {
        ["Boat"] = {"Helnim", "Marog", "Old Ebonheart, Docks", "Vivec, Foreign Quarter"},
    },
    ["Ebonheart"] = {
        ["Boat"] = {"Old Ebonheart, Docks", "Teyn"},
    },
    ["Enamor Dayn"] = {
        ["Boat"] = {"Gorne", "Necrom, Waterfront"},
    },
    ["Firewatch"] = {
        ["Boat"] = {"Dagon Fel", "Helnim", "Nivalis", "Old Ebonheart, Docks", "Sadrith Mora"},
        ["Guild Guide"] = {"Helnim", "Nivalis, Icebreaker Keep Outpost"},
    },
    ["Gah Sadrith"] = {
        ["Boat"] = {"Llothanis"},
        ["River Strider"] = {"Port Telvannis"},
    },
    ["Gorne"] = {
        ["Boat"] = {"Enamor Dayn"},
    },
    ["Helnim"] = {
        ["Boat"] = {"Darvonis", "Firewatch", "Marog", "Sadrith Mora"},
        ["Guild Guide"] = {"Firewatch", "Nivalis, Icebreaker Keep Outpost"},
    },
    ["Hlan Oek"] = {
        ["Boat"] = {"Almas Thirr", "Idathren", "Maar-Bani Crossing"},
        ["Silt Strider"] = {"Arvud", "Bal Foyen", "Hlerynhul"},
    },
    ["Hlerynhul"] = {
        ["Boat"] = {"Ald Iuval", "Narsis, Old Quarter", "Othmura", "Sadrathim"},
        ["Silt Strider"] = {"Hlan Oek", "Narsis, Foreign Quarter", "Shipal-Sharai"},
    },
    ["Idathren"] = {
        ["Boat"] = {"Hlan Oek", "Maar-Bani Crossing"},
    },
    ["Llothanis"] = {
        ["Boat"] = {"Alt Bosara", "Gah Sadrith"},
        ["River Strider"] = {"Alt Bosara", "Port Telvannis", "Tel Ouada"},
    },
    ["Maar-Bani Crossing"] = {
        ["Boat"] = {"Almas Thirr", "Hlan Oek", "Idathren", "Othmura"},
        ["Gondola"] = {"Aimrah"},
    },
    ["Marog"] = {
        ["Boat"] = {"Darvonis", "Helnim", "Sadrith Mora"},
    },
    ["Menaan"] = {
        ["Silt Strider"] = {"Arvud", "Bal Foyen"},
    },
    ["Mundrethi Plantation, Slave Market"] = {
        ["Gondola"] = {"Oran Plantation"},
    },
    ["Narsis, Foreign Quarter"] = {
        ["Gondola"] = {"Narsis, Market Quarter", "Narsis, Waterfront", "Wilderness"},
        ["Silt Strider"] = {"Hlerynhul"},
    },
    ["Narsis, Market Quarter"] = {
        ["Gondola"] = {"Narsis, Foreign Quarter", "Narsis, Waterfront", "Wilderness"},
        ["Silt Strider"] = {"Shipal-Sharai", "Stormgate Pass"},
    },
    ["Narsis, Old Quarter"] = {
        ["Boat"] = {"Ald Iuval", "Almas Thirr", "Hlerynhul", "Othmura", "Sadrathim"},
    },
    ["Narsis, Waterfront"] = {
        ["Gondola"] = {"Narsis, Foreign Quarter", "Narsis, Market Quarter", "Wilderness"},
    },
    ["Narsis: Commons"] = {
        ["Guild Guide"] = {"Firewatch", "Old Ebonheart", "Othmura", "Vivec, Foreign Quarter"},
    },
    ["Necrom"] = {
        ["Silt Strider"] = {"Akamora", "Sailen"},
    },
    ["Necrom, Waterfront"] = {
        ["Boat"] = {"Alt Bosara", "Enamor Dayn"},
    },
    ["Nivalis"] = {
        ["Boat"] = {"Bahrammu", "Bal Oyra", "Dagon Fel", "Firewatch"},
    },
    ["Nivalis, Icebreaker Keep Outpost"] = {
        ["Guild Guide"] = {"Firewatch", "Helnim"},
    },
    ["Old Ebonheart"] = {
        ["Guild Guide"] = {"Akamora", "Bal Foyen", "Firewatch", "Narsis: Commons", "Vivec, Foreign Quarter"},
    },
    ["Old Ebonheart, Docks"] = {
        ["Boat"] = {"Almas Thirr", "Bal Foyen, Docks", "Darvonis", "Ebonheart", "Firewatch", "Vivec, Foreign Quarter"},
    },
    ["Omaynis"] = {
        ["Silt Strider"] = {"Bal Foyen", "Bodrum"},
    },
    ["Oran Plantation"] = {
        ["Gondola"] = {"Mundrethi Plantation, Slave Market"},
    },
    ["Othmura"] = {
        ["Boat"] = {"Ald Iuval", "Hlerynhul", "Maar-Bani Crossing", "Sadrathim"},
        ["Guild Guide"] = {"Narsis: Commons"},
    },
    ["Port Telvannis"] = {
        ["River Strider"] = {"Gah Sadrith", "Llothanis", "Sadas Plantation", "Tel Ouada"},
    },
    ["Ranyon-ruhn"] = {
        ["Silt Strider"] = {"Tel Gilan", "Tel Ouada"},
    },
    ["Roa Dyr"] = {
        ["Fisherman Boat"] = {"Wilderness"},
    },
    ["Sadas Plantation"] = {
        ["River Strider"] = {"Port Telvannis"},
    },
    ["Sadrathim"] = {
        ["Boat"] = {"Ald Iuval", "Hlerynhul", "Narsis, Old Quarter", "Othmura"},
    },
    ["Sadrith Mora"] = {
        ["Boat"] = {"Firewatch", "Helnim", "Marog"},
    },
    ["Sailen"] = {
        ["Silt Strider"] = {"Akamora", "Bosmora", "Necrom"},
    },
    ["Septim's Gate Pass"] = {
        ["Silt Strider"] = {"Shipal-Sharai"},
    },
    ["Shipal-Sharai"] = {
        ["Silt Strider"] = {"Hlerynhul", "Narsis, Market Quarter", "Septim's Gate Pass"},
    },
    ["Stormgate Pass"] = {
        ["Silt Strider"] = {"Narsis, Market Quarter"},
    },
    ["Sulfurwatch Keep"] = {
        ["Boat"] = {"Wilderness"},
    },
    ["Tel Gilan"] = {
        ["Silt Strider"] = {"Ranyon-ruhn", "Wilderness"},
    },
    ["Tel Mothrivra"] = {
        ["River Strider"] = {"Alt Bosara"},
    },
    ["Tel Ouada"] = {
        ["Boat"] = {"Bal Oyra"},
        ["River Strider"] = {"Llothanis", "Port Telvannis"},
        ["Silt Strider"] = {"Ranyon-ruhn"},
    },
    ["Teyn"] = {
        ["Boat"] = {"Bal Foyen, Docks", "Ebonheart"},
    },
    ["Ushu-Kur"] = {
        ["Silt Strider"] = {"Arvud"},
    },
    ["Vhul"] = {
        ["Silt Strider"] = {"Aimrah", "Almas Thirr"},
    },
    ["Vivec, Foreign Quarter"] = {
        ["Boat"] = {"Bal Foyen, Docks", "Darvonis", "Old Ebonheart, Docks"},
        ["Guild Guide"] = {"Firewatch", "Narsis: Commons", "Old Ebonheart"},
    },
    ["Wilderness"] = {
        ["Boat"] = {"Sulfurwatch Keep"},
        ["Fisherman Boat"] = {"Roa Dyr"},
        ["Gondola"] = {"Narsis, Foreign Quarter", "Narsis, Market Quarter", "Narsis, Waterfront"},
        ["Silt Strider"] = {"Akamora", "Tel Gilan"},
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
