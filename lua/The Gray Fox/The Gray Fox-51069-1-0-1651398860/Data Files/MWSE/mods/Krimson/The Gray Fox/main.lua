local tgfList = {
    "allding", "alveleg", "arantamo", "arathor", "Arver Rethul", "bacola closcius", "balan", "both gro-durug",
    "celegorn", "chirranirr", "darvam hlaren", "drarel andus", "elmussa damori", "estoril", "fandus puruseius", "fenas madach",
    "Fothyna Herothran", "Guldrise Dralor", "hecerinde", "hinald", "hreirek the lean", "Ivrosa Verethi", "ladia flarugrius", "lirielle stoine",
    "muriel sette", "natesse", "phane rielle", "raflod the braggart", "rissinia", "Sathasa Nerothren", "sottilde", "Suvryn Doves",
    "tongue_toad", "vuvil senim", "wadarkhu", "yak gro-skandar", "aengoth", "big helende", "habasi", "ahnassi"
}

local tgfCellList = {
    "Ald-ruhn, Bevene Releth: Clothier", "Ald-ruhn, Bivale Teneran: Clothier", "Ald-ruhn, Cienne Sintieve: Alchemist", "Ald-ruhn, Codus Callonus: Bookseller", "Ald-ruhn, Dandera Selaro: Smith",
    "Ald-ruhn, Daynes Redothril: Pawnbroker", "Ald-ruhn, Llether Vari: Enchanter", "Ald-ruhn, Malpenix Blonia: Trader", "Ald-ruhn, Tiras Sadus: General Merchandise", "Ald-ruhn, Tuveso Beleth: Smith",
    "Balmora, Clagius Clanler: Outfitter", "Balmora, Dorisa Darvel: Bookseller", "Balmora, Dralasa Nithryon: Pawnbroker", "Balmora, Meldor: Armorer", "Balmora, Milie Hastien: Fine Clothier",
    "Balmora, Nalcarya of White Haven: Fine Alchemist", "Balmora, Ra'Virr: Trader", "Sadrith Mora, Anis Seloth: Alchemist", "Sadrith Mora, Llaalam Madalas: Mage", "Sadrith Mora, Pierlette Rostorard: Apothecary",
    "Sadrith Mora, Thervul Serethi: Healer", "Sadrith Mora, Urtiso Faryon: Sorcerer", "Vivec, Agrippina Herennia: Clothier", "Vivec, Alusaron: Smith", "Vivec, Andilu Drothan: Alchemist",
    "Vivec, Aurane Frernis: Apothecary", "Vivec, Hlaalu Alchemist", "Vivec, Hlaalu General Goods", "Vivec, Hlaalu Pawnbroker", "Vivec, Hlaalu Weaponsmith",
    "Vivec, J'Rasha: Healer", "Vivec, Jeanne: Trader", "Vivec, Jobasha's Rare Books", "Vivec, Lucretinaus Olcinius: Trader", "Vivec, Mevel Fererus: Trader",
    "Vivec, Miun-Gei: Enchanter", "Vivec, Redoran Smith", "Vivec, Redoran Trader", "Vivec, Telvanni Alchemist", "Vivec, Telvanni Apothecary",
    "Vivec, Telvanni Enchanter", "Vivec, Telvanni Mage", "Vivec, Telvanni Sorcerer", "Vivec, Tervur Braven: Trader"
}

local cellOwnerList = {
    "Bevene Releth", "Bivale Teneran", "Cienne Sintieve", "Codus Callonus", "Dandera Selaro", "Daynes Redothril", "Llether Vari", "Malpenix Blonia", "Tiras Sadus",
    "Tuveso Beleth", "Clagius Clanler", "Dorisa Darvel", "Dralasa Nithryon", "Meldor", "Milie Hastien", "Nalcarya of White Haven", "Ra'Virr", "Anis Seloth",
    "Llaalam Madalas", "Pierlette Rostorard", "Thervul Serethi", "Urtiso Faryon", "Agrippina Herennia", "Alusaron", "Andilu Drothan", "Aurane Frernis", "Ganalyn Saram",
    "Gadayn Andarys", "Alveno Andules", "Telvon Llethan", "J'Rasha", "Jeanne", "Jobasha", "Lucretinaus Olcinius", "Mevel Fererus", "Miun-Gei",
    "Savard", "Balen Andrano", "Garas Seloth", "Galuro Belan", "Audenian Valius", "Fevyn Ralen", "Salver Lleran", "Tervur Braven"
}

local tgfRaceList = {
    "Argonian", "Breton", "Dark Elf", "High Elf", "Imperial", "Khajiit", "Nord", "Orc", "Redguard", "Wood Elf"
}

local tgfIndex
local tgfNPC = table.choice(tgfList)
local cellRace = table.choice(tgfCellList)
local cellSex = table.choice(tgfCellList)

local function cellTimer()

    local tgfObj = tes3.getObject(tgfNPC)
    local cellOwner
    local pcCell = tes3.getPlayerCell()
    local tgfRace = tgfObj.race.id
    local tgfSex

    if tgfObj.female == true then
        tgfSex = "female"
    elseif tgfObj.female == false then
        tgfSex = "male"
    end

    if cellRace == pcCell.id then

        for cellOwnerIndex, cellOwnerString in pairs(cellOwnerList) do
            if tes3.getGlobal("Krimson_tgfCellRace") == cellOwnerIndex then
                cellOwner = cellOwnerString
            end
        end

        for tgfRaceIndex, tgfRaceString in pairs(tgfRaceList) do
            if tgfRace == tgfRaceString then
                tes3.setGlobal("Krimson_tgfRace", tgfRaceIndex)
            end
        end

        if tes3.getGlobal("Krimson_tgfSex") > 0 then
            tes3.setJournalIndex({ id = "Krimson_findTGF", index = 50, showMessage = true })
            if tgfRace == "Argonian" then
                tes3.addJournalEntry({ text = string.format("Judging by the hairs you found around %s's shop.\nIt seems The Gray Fox is probably an %s\nNow knowing The Gray Fox should be a %s %s, I should be able to figure out who it is.", cellOwner, tgfRace, tgfSex, tgfRace) })
            elseif tgfRace == "Imperial" then
                tes3.addJournalEntry({ text = string.format("Judging by the hairs you found around %s's shop.\nIt seems The Gray Fox is probably an %s\nNow knowing The Gray Fox should be a %s %s, I should be able to figure out who it is.", cellOwner, tgfRace, tgfSex, tgfRace) })
            elseif tgfRace == "Orc" then
                tes3.addJournalEntry({ text = string.format("Judging by the hairs you found around %s's shop.\nIt seems The Gray Fox is probably an %s\nNow knowing The Gray Fox should be a %s %s, I should be able to figure out who it is.", cellOwner, tgfRace, tgfSex, tgfRace) })
            else
                tes3.addJournalEntry({ text = string.format("Judging by the hairs you found around %s's shop.\nIt seems The Gray Fox is probably a %s\nNow knowing The Gray Fox should be a %s %s, I should be able to figure out who it is.", cellOwner, tgfRace, tgfSex, tgfRace) })
            end
        else
            tes3.setJournalIndex({ id = "Krimson_findTGF", index = 25, showMessage = true })
            if tgfRace == "Argonian" then
                tes3.addJournalEntry({ text = string.format("Judging by the hairs you found around %s's shop.\nIt seems The Gray Fox is probably an\n%s", cellOwner, tgfRace) })
            elseif tgfRace == "Imperial" then
                tes3.addJournalEntry({ text = string.format("Judging by the hairs you found around %s's shop.\nIt seems The Gray Fox is probably an\n%s", cellOwner, tgfRace) })
            elseif tgfRace == "Orc" then
                tes3.addJournalEntry({ text = string.format("Judging by the hairs you found around %s's shop.\nIt seems The Gray Fox is probably an\n%s", cellOwner, tgfRace) })
            else
                tes3.addJournalEntry({ text = string.format("Judging by the hairs you found around %s's shop.\nIt seems The Gray Fox is probably a\n%s", cellOwner, tgfRace) })
            end
        end
    end

    if cellSex == pcCell.id then

        for cellOwnerIndex, cellOwnerString in pairs(cellOwnerList) do
            if tes3.getGlobal("Krimson_tgfCellSex") == cellOwnerIndex then
                cellOwner = cellOwnerString
            end
        end

        if tgfObj.female == true then
            tes3.setGlobal("Krimson_tgfSex", 1)
        elseif tgfObj.female == false then
            tes3.setGlobal("Krimson_tgfSex", 2)
        end

        if tes3.getGlobal("Krimson_tgfRace") > 0 then
            tes3.setJournalIndex({ id = "Krimson_findTGF", index = 50, showMessage = true })
            tes3.addJournalEntry({ text = string.format("By the looks of the footprints you found in %s's shop.\nThe Gray Fox is more than likely a %s\nNow knowing The Gray Fox should be a %s %s, I should be able to figure out who it is.", cellOwner, tgfSex, tgfSex, tgfRace) })
        else
            tes3.setJournalIndex({ id = "Krimson_findTGF", index = 25, showMessage = true })
            tes3.addJournalEntry({ text = string.format("By the looks of the footprints you found in %s's shop.\nThe Gray Fox is more than likely a\n%s", cellOwner, tgfSex) })
        end
    end
end

local function onCellActivate(e)

    if tes3.getGlobal("Krimson_tgfKnown") > 0 then
        return
    end

    if tes3.getGlobal("Krimson_tgfDead") > 0 then
        return
    end

    tgfIndex = tes3.getJournalIndex({ id = "Krimson_findTGF" })

    if tgfIndex == 0 or tgfIndex >= 75 then
        return
    end

    if e.cell.id == cellRace then
        if tes3.getGlobal("Krimson_tgfRace") == 0 then
            timer.register("Krimson_tfg:cellTimer", cellTimer)
            timer.start({type = timer.simulate, persist = true, iterations = 1, duration = 10, callback = "Krimson_tfg:cellTimer"})
        end
    end

    if e.cell.id == cellSex then
        if tes3.getGlobal("Krimson_tgfSex") == 0 then
            timer.register("Krimson_tfg:cellTimer", cellTimer)
            timer.start({type = timer.simulate, persist = true, iterations = 1, duration = 10, callback = "Krimson_tfg:cellTimer"})
        end
    end
end

local function tgfDeath(e)

    if tes3.getGlobal("Krimson_tgfDead") > 0 then
        return
    end

    tgfIndex = tes3.getJournalIndex({ id = "Krimson_findTGF" })
    if tgfIndex == 0 or tgfIndex >= 75 then
        return
    end

    local tgfRef = tes3.getReference(tgfNPC)
    local tgfName = tes3.getObject(tgfNPC)

    if e.reference == tgfRef then
        tes3.messageBox("The Gray Fox was %s all along", tgfName.name)
        tes3.addItem({ reference = tgfNPC, item = "Krimson_tgf_cowl", reevaluateEquipment = false })
        tes3.setGlobal("Krimson_tgfDead", 1)
    end
end

local function saveTGFInfo()

    if tes3.getGlobal("Krimson_tgfKnown") > 0 then
        return
    end

    if tes3.getGlobal("Krimson_tgfDead") > 0 then
        return
    end

    tgfIndex = tes3.getJournalIndex({ id = "Krimson_findTGF" })

    if tgfIndex >= 75 then
        return
    end

    if tes3.getGlobal("Krimson_tgfNPC") == 0 then
        tes3.runLegacyScript({command = 'AddTopic "The Gray Fox"'})
        for tgfListIndex, tgfListString in pairs(tgfList) do
            if tgfListString == tgfNPC then
                tes3.setGlobal("Krimson_tgfNPC", tgfListIndex)
            end
        end
    elseif tes3.getGlobal("Krimson_tgfNPC") > 0 then
        for tgfNPCGlobal, tgfNPCString in pairs(tgfList) do
            if tes3.getGlobal("Krimson_tgfNPC") == tgfNPCGlobal then
                tgfNPC = tgfNPCString
            end
        end
    end

    if tes3.getGlobal("Krimson_tgfCellRace") == 0 then
        for tgfRaceIndex, tgfRaceString in pairs(tgfCellList) do
            if tgfRaceString == cellRace then
                tes3.setGlobal("Krimson_tgfCellRace", tgfRaceIndex)
            end
        end
    elseif tes3.getGlobal("Krimson_tgfCellRace") > 0 then
        for tgfCellRaceGlobal, tgfCellRaceString in pairs(tgfCellList) do
            if tes3.getGlobal("Krimson_tgfCellRace") == tgfCellRaceGlobal then
                cellRace = tgfCellRaceString
            end
        end
    end

    if tes3.getGlobal("Krimson_tgfCellSex") == 0 then
        for tgfSexIndex, tgfSexString in pairs(tgfCellList) do
            if tgfSexString == cellSex then
                tes3.setGlobal("Krimson_tgfCellSex", tgfSexIndex)
            end
        end
    elseif tes3.getGlobal("Krimson_tgfCellSex") > 0 then
        for tgfCellSexGlobal, tgfCellSexString in pairs(tgfCellList) do
            if tes3.getGlobal("Krimson_tgfCellSex") == tgfCellSexGlobal then
                cellSex = tgfCellSexString
            end
        end
    end

    event.unregister("simulate", saveTGFInfo)
end

local function cowlEquip(e)

    if tes3.getGlobal("Krimson_tgfKnown") > 0 then
        return
    end

    if e.reference ~= tes3.player then
        return
    end

    if e.item ~= tes3.getObject("Krimson_tgf_cowl") then
        return
    end

    tes3.setGlobal("Krimson_tgfPCRep", tes3.player.object.reputation)
    tes3.player.object.reputation = tes3.getGlobal("Krimson_tgfGFRep")
    tes3.setGlobal("Krimson_tgfPCBounty", tes3.mobilePlayer.bounty)
    tes3.mobilePlayer.bounty = tes3.getGlobal("Krimson_tgfGFBounty")
end

local function cowlUnequip(e)

    if tes3.getGlobal("Krimson_tgfKnown") > 0 then
        return
    end

    if e.reference ~= tes3.player then
        return
    end

    if e.item ~= tes3.getObject("Krimson_tgf_cowl") then
        return
    end

    tes3.setGlobal("Krimson_tgfGFRep", tes3.player.object.reputation)
    tes3.player.object.reputation = tes3.getGlobal("Krimson_tgfPCRep")
    tes3.setGlobal("Krimson_tgfGFBounty", tes3.mobilePlayer.bounty)
    tes3.mobilePlayer.bounty = tes3.getGlobal("Krimson_tgfPCBounty")
end

local function onSeenEquip(e)

    if tes3.getGlobal("Krimson_tgfKnown") > 0 then
        return
    end

    if e.reference ~= tes3.player then
        return
    end

    if e.item ~= tes3.getObject("Krimson_tgf_cowl") then
        return
    end

    local pcCell = tes3.getPlayerCell()
    local npcList = pcCell.actors
    local once = 0

    for _, npc in pairs(npcList) do

        local inLOS = tes3.testLineOfSight({reference1 = npc, reference2 = tes3.player})

        if inLOS then

            if npc.mobile.playerDistance <= 1024 then

                tes3.worldController.mobController.processManager:detectPresence(tes3.mobilePlayer, true)

                if npc.mobile.isPlayerDetected == true then

                    if once == 0 then

                        tes3.setGlobal("Krimson_tgfKnown", 1)
                        tes3.player.object.reputation = tes3.getGlobal("Krimson_tgfPCRep") + tes3.getGlobal("Krimson_tgfGFRep")
                        tes3.mobilePlayer.bounty = tes3.getGlobal("Krimson_tgfPCBounty") + tes3.getGlobal("Krimson_tgfGFBounty")
                        tes3.messageBox ({message = "You are now known to be The Gray Fox"})
                        tes3.triggerCrime({type = tes3.crimeType.killing})
                        once = 1
                    end
                end
            end
        end
    end
end

local function tgfNameChange(e)

    if tes3.getGlobal("Krimson_tgfKnown") > 0 then

        local newText = string.gsub(e:loadOriginalText(), "%%PCName", "The Gray Fox")
        e.text = newText
    end

    if tes3.player.object:hasItemEquipped("Krimson_tgf_cowl") then

        local newText = string.gsub(e:loadOriginalText(), "%%PCName", "The Gray Fox")
        e.text = newText
    end
end

local function onInitialized()

    if tes3.isModActive("TheGrayFox.ESP") then

        event.register("simulate", saveTGFInfo)
        event.register("cellActivated", onCellActivate)
        event.register("death", tgfDeath)
        event.register("unequipped", cowlUnequip)
        event.register("equipped", cowlEquip)
        event.register("unequipped", onSeenEquip)
        event.register("equipped", onSeenEquip)
        event.register("infoGetText", tgfNameChange)
        mwse.log("[Krimson] The Gray Fox Initialized")
    else
        mwse.log("TheGrayFox.ESP is not active")
    end
end

event.register("initialized", onInitialized)