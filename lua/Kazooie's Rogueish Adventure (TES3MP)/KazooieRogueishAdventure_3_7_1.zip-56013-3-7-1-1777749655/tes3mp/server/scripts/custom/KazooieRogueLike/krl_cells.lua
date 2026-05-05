local CUSTOM_CELL_DATA = {}

KRL_ROOM_TYPE_NORMAL = "Normal"
KRL_ROOM_TYPE_BOSS = "Boss"
KRL_ROOM_TYPE_SPECIAL = "Special"

local function addCustomCellData(cellName, level, description, enterPos, enterAngle, roomType)
    local cellNames = cellName

    if type(cellName) == "string" then
        cellNames = {cellName}
    end

    CUSTOM_CELL_DATA[cellNames[1]] = {
        cellNames = cellNames,
        description = description or cellName,
        enterPos = enterPos or KRL_Vector(0, 0, 0),
        enterAngle = enterAngle or KRL_Angle(0, 0),
        level = level or 0,
        roomType = roomType or "Normal"
    }
end

KRL_START_CELL = "Kazooie, Start"
KRL_DEATH_CELL = "Kazooie, Death"
KRL_INN_CELL = "Kazooie, Inn"
KRL_INVALID_CELL = "Kazooie, Invalid"
KRL_SHOP_CELL = "Kazooie, Tartarian Island"
KRL_SHOP_CELL_GUNS = "Kazooie, Gun Shop"
KRL_SHOP_CELL_STORAGE = "Azerjin Merchandise Storage"
KRL_SHOP_CELL_EXCHANGE = "Azerjin, Foreign Exchange"
KRL_SHOP_CELL_MAGIC = "Azerjin, Magic Club"
KRL_DEBUG_CELL = "Kazooie, Debug"
KRL_DEBUFFS_CELL = "Kazooie, Debuffs"
KRL_BUFFS_CELL = "Kazooie, Buffs"
KRL_VENGEANCE_CELL = "Kazooie, Vengeance"
KRL_ALDRUHN = "-2, 6"

local SHOP_CELLS = {
    KRL_SHOP_CELL, 
    KRL_SHOP_CELL_GUNS, 
    KRL_INN_CELL, 
    KRL_SHOP_CELL_STORAGE, 
    KRL_SHOP_CELL_EXCHANGE, 
    KRL_SHOP_CELL_MAGIC
}

local MOUSE_CELL = "Kazooie, 1_1"
local CAVE_CELL = "Kazooie, 1_2"
local ICARIAN_CELL = "-3, -8"
local KEY_CELL = "Kazooie, 1_3"
local BAR_CELL = "Kazooie, 1_4"
local FIRST_BOSS_CELL = "Kazooie, Boss_1"
local PIRATE_CELLS = {"-15, 17", "Kazooie, Skeleton Ship", "Kazooie, Rat Ship"}

local ARGUMENT_CELLS = {"Kazooie, 2_1_1", "Kazooie, 2_1_2", "1, -10"}
local TOMB_CELL = "Samarys Ancestral Tomb"
local NIXHOUND_CELL = "Balmora, Tyravel Manor"
local MUSHROOM_CELL = "0, -5"
local HIGHWAY_CELL = "-1, -2"
local SAFETY_CELL = "Kazooie, Square"
local SECOND_BOSS_CELL = {
    "Arkngthand, Hall of Centrifuge",
    "Arkngthand, Cells of Hollow Hand",
    "Arkngthand, Heaven's Gallery",
    "Arkngthand, Weepingbell Hall",
    "Arkngthand, Deep Ore Passage",
    "Arkngthand, Land's Blood Gallery",
}

local FALL_TOMB = "Tharys Ancestral Tomb"
local BROTHEL_CELL = "Dagon Fel, End of the World Renter Rooms"
local PARKOUR_CELL = "Kazooie, Parkour"
local RATFESTATION_CELL = "Balmora, Nine Toes' House"
local WHISTLE_CELL = "-2, 1"
local FATH_CELL = "Caldera, Governor's Hall"
local LIBRARY_CELL = "Kazooie, Library"
local THIRD_BOSS_CELL = "-2, -1"

local DRUGS_CELLS = {"Balmora, Morag Tong Guild", "-4, -2", "-3, -2", "-2, -2", "Balmora, Caius Cosades' House", "Kazooie, Fork Store"}
local GREED_TOMB = "Indalen Ancestral Tomb"
local FARGOTH_CELL = "-2, -9"
local ULIZ_CELL = "Suran, Oran Manor"
local MONSTER_SEWER_CELLS = {"Vivec, Telvanni Underworks", "Kazooie, Muta Vault"}
local FOURTH_BOSS_CELL = "Kazooie, Boss_4"

local RAT_BOY_CAVE = "Zainsipilu"
local BONELORD_CELL = "Beran Ancestral Tomb"
local HLORMAREN_CELL = "Hlormaren, Keep, Top Level"
local DODGE_CELL = "Kazooie, 5_1"
local PEMENIE_CELL = "-4, 3"
local CAFE_CELL = "Kazooie, Cafe"
KRL_FIFTH_BOSS_CELL = "Kazooie, Boss_5"

local ASSARNUD_CELL = "Assarnud"
local LAVA_CELL = "Sandas Ancestral Tomb"
local KUSH_CELL = "Kushtashpi, Shrine"
local BONES_CELL = "Ald-ruhn, Guild of Mages"
local AZAVIUV_CELL = "Kazooie, Azaviuv"
local MALFUNCTION_CELL = "Arkngthunch-Sturdumz"
local IMPOSTERS_CELL = "Kazooie, Imposters"
local SIXTH_BOSS_CELL = "Hlormaren, Dome"

local BTHANCHEND_CELL = "Bthanchend"
local KUDANAT_CELL = "Kudanat"
local TRAPS_CELL = "Verelnim Ancestral Tomb"
local FORK_TOMB_CELL = "Veloth Ancestral Tomb"
local MOUSETRAP_CELL = "Kazooie, Mousetrap"
local SURPRISE_CELL = "Kazooie, Surprise"
local SEVENTH_BOSS_CELL = "Marandus, Dome"

local KUNIRAI_CELL = "Kunirai"
local GINGERBREAD_CELL = "Ministry of Truth, Hall of Processing"
local BATS_CELL = "Hlervu Ancestral Tomb"
local THEFT_CELL = "Ald-ruhn, The Rat In The Pot"
local STORY_CELLS = {"-14, 17", "-14, 19", "-14, 20"}
local DRAGON_CELL = "-3, 8"
local EIGHTH_BOSS_CELL = "Kazooie, Boss_8"

local RUN_CELL = "-20, 17"
local SPINNER_CELL = "Sotha Sil, Dome of Kasia"
local ORC_SHRINE_CELLS = {"Kaushtarari, Shrine", "Ihinipalit, Shrine", "Ibishammus, Shrine", "Ibar-Dad"}
local SARGON_CELL = "Sargon"
local SANABI_CELL = "Sanabi"
local LOOSE_CELL = "Kazooie, Loose"
local NINTH_BOSS_CELL = "7, -7"

local JIMMY_CELLS = {"Kazooie, Jimmy", "Kazooie, Jimmy_2", "Kazooie, Jimmy_3", "Kazooie, Jimmy_4", "Kazooie, Jimmy_5"}

-- FOR DEBUG! SHOULD BE EMPTY!
local DEBUG_CELLS = {}

addCustomCellData(KRL_START_CELL, 0, "Start", KRL_Vector(2968, 3731, 14575), KRL_Angle(0.04, 1.55), KRL_ROOM_TYPE_SPECIAL)
addCustomCellData(KRL_DEATH_CELL, 0, "Death", KRL_Vector(4978, 4171, 14270), KRL_Angle(0, 0), KRL_ROOM_TYPE_SPECIAL)
addCustomCellData(KRL_INN_CELL, 0, "Inn", KRL_Vector(4234, 3855, 14988), KRL_Angle(0, 0), KRL_ROOM_TYPE_SPECIAL)
addCustomCellData(KRL_INVALID_CELL, 0, "Invalid", KRL_Vector(4108, 3894, 12230), KRL_Angle(0, 0), KRL_ROOM_TYPE_SPECIAL)
addCustomCellData(SHOP_CELLS, 0, "Azerjin", KRL_Vector(5681, 2946, 20492), KRL_Angle(0, 0), KRL_ROOM_TYPE_SPECIAL)
addCustomCellData(KRL_DEBUG_CELL, 0, "Debug", KRL_Vector(4355, 2859, 12041), KRL_Angle(0, 0), KRL_ROOM_TYPE_SPECIAL)
addCustomCellData(KRL_DEBUFFS_CELL, 0, "Debuff", KRL_Vector(3690, 4085, 15375), KRL_Angle(0, 0), KRL_ROOM_TYPE_SPECIAL)
addCustomCellData(KRL_BUFFS_CELL, 0, "Buff", KRL_Vector(3857, 4050, 12235), KRL_Angle(0, 0), KRL_ROOM_TYPE_SPECIAL)
addCustomCellData(KRL_VENGEANCE_CELL, 0, "Vengeance", KRL_Vector(4092, 3929, 15075), KRL_Angle(0, 0), KRL_ROOM_TYPE_SPECIAL)
addCustomCellData(KRL_ALDRUHN, 0, "Vvardenfell", KRL_Vector(-16127, 54701, 2193), KRL_Angle(0, 0), KRL_ROOM_TYPE_SPECIAL)

addCustomCellData(MOUSE_CELL, 1, "Mouse House", KRL_Vector(3841, 3919, 16550))
addCustomCellData(CAVE_CELL, 1, "Smuggler Cave", KRL_Vector(6318, 2771, 12910))
addCustomCellData(ICARIAN_CELL, 1, "Meet Tahriel", KRL_Vector(-18207, -58239, 775))
addCustomCellData(KEY_CELL, 1, "Keytastrophy", KRL_Vector(4131, 3957, 15520))
addCustomCellData(BAR_CELL, 1, "Bar", KRL_Vector(3903, 3774, 15320))
addCustomCellData(PIRATE_CELLS, 1, "Pirate Battle", KRL_Vector(-118498, 145308, 32), KRL_Angle(0, 180))
addCustomCellData(FIRST_BOSS_CELL, 1, "Jeff the Hound", KRL_Vector(4324, 4763, 11930), KRL_Angle(0, 0), KRL_ROOM_TYPE_BOSS)

addCustomCellData(ARGUMENT_CELLS, 2, "The Argument", KRL_Vector(4174, 4004, 15760))
addCustomCellData(TOMB_CELL, 2, "Tomb of Lord Brinne", KRL_Vector(-2272, 992, 352), KRL_Angle(0, 90))
addCustomCellData(NIXHOUND_CELL, 2, "Infested Manor", KRL_Vector(466, 509, 91), KRL_Angle(0, 270))
addCustomCellData(MUSHROOM_CELL, 2, "Tall Mushroom", KRL_Vector(682, -40170, 645), KRL_Angle(0, 270))
addCustomCellData(HIGHWAY_CELL, 2, "Toll Bridge", KRL_Vector(-1885, -13467, 2595), KRL_Angle(0, 0))
addCustomCellData(SAFETY_CELL, 2, "Safety", KRL_Vector(-2953, 1155, 2515), KRL_Angle(0, 90))
addCustomCellData(SECOND_BOSS_CELL, 2, "Dwemer Ruins", KRL_Vector(-801, 3607, 1616), KRL_Angle(0, 180), KRL_ROOM_TYPE_BOSS)

addCustomCellData(FALL_TOMB, 3, "Tomb of Verticality", KRL_Vector(2092, 272, -75), KRL_Angle(0, 271))
addCustomCellData(BROTHEL_CELL, 3, "Toad Fiasco", KRL_Vector(16, 5, 210), KRL_Angle(0, 90))
addCustomCellData(PARKOUR_CELL, 3, "Parkour", KRL_Vector(2541, 2470, 9999), KRL_Angle(0, 0))
addCustomCellData(RATFESTATION_CELL, 3, "Mouse Infestation", KRL_Vector(-230, 117, -85), KRL_Angle(0, 0))
addCustomCellData(WHISTLE_CELL, 3, "Greatest Shop", KRL_Vector(-8374, 11406, 1690), KRL_Angle(0, 0))
addCustomCellData(LIBRARY_CELL, 3, "Library", KRL_Vector(4097, 2648, 15104), KRL_Angle(0, 0))
addCustomCellData(THIRD_BOSS_CELL, 3, "Greg the Mudcrab", KRL_Vector(-11553, -2869, 796), KRL_Angle(0, 90), KRL_ROOM_TYPE_BOSS)

addCustomCellData(MALFUNCTION_CELL, 4, "Malfunction", KRL_Vector(-2012, 1368, -1120), KRL_Angle(0, 0))
addCustomCellData(GREED_TOMB, 4, "Tomb of Greed", KRL_Vector(-486, -96, 2567), KRL_Angle(0, -182))
addCustomCellData(FARGOTH_CELL, 4, "Tragedy of Seyda Neen", KRL_Vector(-12432, -66312, 95), KRL_Angle(0, 90))
addCustomCellData(MONSTER_SEWER_CELLS, 4, "Monster Sewers", KRL_Vector(2114, 350, 50), KRL_Angle(0, 0))
addCustomCellData(ULIZ_CELL, 4, "Meet Uliz", KRL_Vector(512, -503, 350), KRL_Angle(0, 360))
addCustomCellData(FATH_CELL, 4, "Tyrant of Beauty", KRL_Vector(4, -104, -68), KRL_Angle(0, 0))
addCustomCellData(FOURTH_BOSS_CELL, 4, "Cauliflower the Clannfear", KRL_Vector(4278, 4777, 11882), KRL_Angle(0, 0), KRL_ROOM_TYPE_BOSS)

addCustomCellData(RAT_BOY_CAVE, 5, "Ratkinn Cave", KRL_Vector(-3113, 2057, 739), KRL_Angle(0, 90))
addCustomCellData(BONELORD_CELL, 5, "Cursed Tomb", KRL_Vector(-2554, 3920, -540), KRL_Angle(0, 360))
addCustomCellData(HLORMAREN_CELL, 5, "Occupied Fortress", KRL_Vector(1662, -1284, -355), KRL_Angle(0, 180))
addCustomCellData(DRUGS_CELLS, 5, "Drugs", KRL_Vector(20, -223, 100), KRL_Angle(0, 0))
addCustomCellData(PEMENIE_CELL, 5, "Pemenie", KRL_Vector(-30888, 30878, 1310), KRL_Angle(0, 0))
addCustomCellData(CAFE_CELL, 5, "Cafe", KRL_Vector(386, 22, 1), KRL_Angle(0, 180))
addCustomCellData(KRL_FIFTH_BOSS_CELL, 5, "Meet Jimmy", KRL_Vector(3135, 4407, 14998), KRL_Angle(0, 0), KRL_ROOM_TYPE_BOSS)

addCustomCellData(ASSARNUD_CELL, 6, "Slave Revolt", KRL_Vector(-3577, 2352, 125), KRL_Angle(0, 143))
addCustomCellData(LAVA_CELL, 6, "Lava Flood", KRL_Vector(1660, 8, 355), KRL_Angle(0, 178))
addCustomCellData(KUSH_CELL, 6, "Kush", KRL_Vector(-10, 6207, 355), KRL_Angle(0, 176))
addCustomCellData(BONES_CELL, 6, "Wild Ride", KRL_Vector(-515, -31, 2), KRL_Angle(0, 0))
addCustomCellData(IMPOSTERS_CELL, 6, "Imposters", KRL_Vector(-130, 324, 209), KRL_Angle(0, 0))
addCustomCellData(DODGE_CELL, 6, "Dodge", KRL_Vector(-704, 6464, 1665), KRL_Angle(0, 0))
addCustomCellData(AZAVIUV_CELL, 6, "Meet Azaviuv", KRL_Vector(5599, 1204, 12899), KRL_Angle(0, 0))
addCustomCellData(SIXTH_BOSS_CELL, 6, "Three Wizards", KRL_Vector(320, -256, 403), KRL_Angle(0, 0), KRL_ROOM_TYPE_BOSS)

addCustomCellData(BTHANCHEND_CELL, 7, "Vampire Ruins", KRL_Vector(560, 1632, -126), KRL_Angle(0, 270))
addCustomCellData(KUDANAT_CELL, 7, "Pet Dremora Cave", KRL_Vector(-89, 2, 88), KRL_Angle(0, 270))
addCustomCellData(TRAPS_CELL, 7, "Puzzle", KRL_Vector(3360, -512, -350), KRL_Angle(0, 180))
addCustomCellData(SURPRISE_CELL, 7, "Surprise", KRL_Vector(997, -1026, 128), KRL_Angle(0, 90))
addCustomCellData(MOUSETRAP_CELL, 7, "Gameshow", KRL_Vector(1883, 5228, 15380), KRL_Angle(0, 0))
addCustomCellData(FORK_TOMB_CELL, 7, "Goblin Tomb", KRL_Vector(1056, -4588, 2018), KRL_Angle(0, 180))
addCustomCellData(SEVENTH_BOSS_CELL, 7, "Alison the Alligator", KRL_Vector(131, 410, -430), KRL_Angle(0, 0), KRL_ROOM_TYPE_BOSS)

addCustomCellData(KUNIRAI_CELL, 8, "Forgotten Blacksmith", KRL_Vector(1406, -811, 602), KRL_Angle(0, 0))
addCustomCellData(GINGERBREAD_CELL, 8, "Gingerbread", KRL_Vector(0, -3356, 560), KRL_Angle(0, 180))
addCustomCellData(BATS_CELL, 8, "Vampire Tomb", KRL_Vector(-3, 2550, -430), KRL_Angle(0, 90))
addCustomCellData(THEFT_CELL, 8, "Rat in the Pot", KRL_Vector(1, -566, -137), KRL_Angle(0, 0))
addCustomCellData(STORY_CELLS, 8, "Unfinished Story", KRL_Vector(-109622, 146967, 296), KRL_Angle(0, 180))
addCustomCellData(DRAGON_CELL, 8, "Dragon", KRL_Vector(-18029, 70212, 6024), KRL_Angle(0, 0))
addCustomCellData(EIGHTH_BOSS_CELL, 8, "Johnny", KRL_Vector(4118, 3695, 15298), KRL_Angle(0, 0), KRL_ROOM_TYPE_BOSS)

addCustomCellData(RUN_CELL, 9, "Run", KRL_Vector(-163737, 144115, 590), KRL_Angle(0, 0))
addCustomCellData(SPINNER_CELL, 9, "Death Trap", KRL_Vector(128, -672, 210), KRL_Angle(0, 0))
addCustomCellData(ORC_SHRINE_CELLS, 9, "Shrines", KRL_Vector(3, 3009, -432), KRL_Angle(0, 180))
addCustomCellData(SARGON_CELL, 9, "Flooded Cave", KRL_Vector(-2576, 5218, -805), KRL_Angle(0, 90))
addCustomCellData(SANABI_CELL, 9, "Giants", KRL_Vector(521, 1812, 348), KRL_Angle(0, 176))
addCustomCellData(LOOSE_CELL, 9, "Sealed Shrine", KRL_Vector(3691, 4447, 13346), KRL_Angle(0, 0))
addCustomCellData(NINTH_BOSS_CELL, 9, "Umbra", KRL_Vector(64846, -54298, 1230), KRL_Angle(0, 0), KRL_ROOM_TYPE_BOSS)

addCustomCellData(JIMMY_CELLS, 10, "Kill Jimmy", KRL_Vector(704, -1024, 4545), KRL_Angle(0, 0), KRL_ROOM_TYPE_BOSS)

local function getCustomCellData(cellName)
    return CUSTOM_CELL_DATA[cellName]
end

function KRL_GetRoomType(cellName)
    local customCellData = getCustomCellData(cellName)
    return customCellData.roomType or KRL_ROOM_TYPE_NORMAL
end

function KRL_GetRoomDescription(cellName)
    local customCellData = getCustomCellData(cellName)
    return customCellData.description or cellName
end

function KRL_TeleportToCell(pid, cellName, pos, ang)
    local customCellData = getCustomCellData(cellName)

    if customCellData then
        if not pos then
            pos = customCellData.enterPos
        end

        if not ang then
            ang = customCellData.enterAngle
        end
    end

    tes3mp.SetCell(pid, cellName)
    tes3mp.SendCell(pid)

    tes3mp.SetPos(pid, pos.x, pos.y, pos.z)
    tes3mp.SetRot(pid, ang.x, ang.z)
    tes3mp.SendPos(pid)
end

function KRL_ResetCell(cellName)
    local cell = Cell(cellName)
    local cellFilePath = tes3mp.GetModDir().."/cell/"..cell.entryFile

    if tes3mp.DoesFileExist(cellFilePath) then
        tes3mp.LogMessage(enumerations.log.INFO, "resetting cell: ["..tostring(cellFilePath).."]")
        jsonInterface.ioLibrary.fs.rm(cellFilePath)
    end
end

function KRL_ResetAllCustomCells()
    for _, cellData in pairs(CUSTOM_CELL_DATA) do
        for _, cellName in pairs(cellData.cellNames) do
            KRL_ResetCell(cellName)
        end
    end
end

function KRL_GenerateNextRandomCell(expectedLevel, levelRoomCount)
    local function selectBossRoom()
        local bossCellsOnLevel = {}

        for cellName, cellData in pairs(CUSTOM_CELL_DATA) do
            if cellData.roomType == KRL_ROOM_TYPE_BOSS and cellData.level == expectedLevel then
                table.insert(bossCellsOnLevel, cellName)
            end
        end

        if bossCellsOnLevel and #bossCellsOnLevel > 0 then
            return bossCellsOnLevel[math.random(#bossCellsOnLevel)], KRL_ROOM_TYPE_BOSS
        end
    end

    if levelRoomCount >= KRL_CONFIG.roomsUntilBoss then return selectBossRoom() end

    local cellsOnLevel = {}
    local visitedRooms = KRL_GetSaveData("visitedRooms") or {}

    for cellName, cellData in pairs(CUSTOM_CELL_DATA) do
        if cellData.roomType == KRL_ROOM_TYPE_NORMAL and cellData.level == expectedLevel and not visitedRooms[cellName] then
            table.insert(cellsOnLevel, cellName)
        end
    end

    if #cellsOnLevel <= 0 then return selectBossRoom() end

    return cellsOnLevel[math.random(#cellsOnLevel)], KRL_ROOM_TYPE_NORMAL
end

function KRL_GetNextRandomCell(doorType)
    if DEBUG_CELLS and #DEBUG_CELLS > 0 then
        local debugCell = table.remove(DEBUG_CELLS, 1)
        return debugCell, getCustomCellData(debugCell).roomType
    end

    if doorType == "Boss" then return KRL_INN_CELL, KRL_ROOM_TYPE_SPECIAL end

    local roomsUntilShop = KRL_GetSaveData("roomsUntilShop")
    if not roomsUntilShop then error("KRL data has no roomsUntilShop?") end

    if doorType ~= "Shop" and roomsUntilShop <= 0 then
        KRL_ResetRoomsUntilShop()
        return KRL_SHOP_CELL, KRL_ROOM_TYPE_SPECIAL
    end

    if KRL_RollLuck(KRL_CONFIG.buffRoomChance) then return KRL_BUFFS_CELL, KRL_ROOM_TYPE_SPECIAL end
    if KRL_RollLuck(KRL_CONFIG.debuffRoomChance) then return KRL_DEBUFFS_CELL, KRL_ROOM_TYPE_SPECIAL end

    local expectedLevel = KRL_GetSaveData("expectedLevel") or 1
    local levelRoomCount = KRL_GetSaveData("levelRoomCount") or 0

    return KRL_GenerateNextRandomCell(expectedLevel, levelRoomCount)
end

customEventHooks.registerHandler("OnPlayerCellChange", function(_, pid, newCell)
    if not KRL_IsPlayerValid(pid) then return end

    local newCellName = newCell.location.cell

    if newCellName == KRL_DEATH_CELL and Players[pid] and Players[pid].data and Players[pid].data.customVariables then
        KRL_ResumeChipRun(pid)
    end

    if KRL_IsGameWon() then
        if newCellName == KRL_START_CELL or newCellName == KRL_INVALID_CELL or newCellName == KRL_DEATH_CELL then
            KRL_TeleportToCell(pid, KRL_ALDRUHN)
        end

        return 
    end

    local activeCell = KRL_GetSaveData("activeCell")

    if not activeCell then
        KRL_SaveData("activeCell", KRL_START_CELL)
        activeCell = KRL_START_CELL
    end

    if KRL_IsPlayerWiped(pid) then
        if newCellName ~= KRL_INVALID_CELL then
            KRL_TeleportToCell(pid, KRL_INVALID_CELL)
        end

        return
    end

    local cellData = getCustomCellData(activeCell)

    if cellData and cellData.roomType == KRL_ROOM_TYPE_BOSS then
        tes3mp.MessageBox(pid, -1, "Boss time!")
    end

    if not krl_array(cellData.cellNames).has(newCellName) then
        if activeCell == KRL_START_CELL then
            KRL_TeleportToCell(pid, KRL_START_CELL)
            return
        end

        if activeCell == KRL_INN_CELL then
            KRL_TeleportToCell(pid, KRL_INN_CELL)
            return
        end

        if KRL_IsPlayerLiving(pid) then
            KRL_TeleportToCell(pid, activeCell)
        else
            if newCellName ~= KRL_DEATH_CELL then
                KRL_TeleportToCell(pid, KRL_DEATH_CELL)
            end
        end
    end
end)

function KRL_OnRoomEntered(cellName)
    if cellName == KRL_DEBUFFS_CELL then
        local debuffsCellAccountNames = {}

        for _, player in pairs(Players) do
            table.insert(debuffsCellAccountNames, player.accountName)
        end

        KRL_SaveData("debuffsCellAccountNames", debuffsCellAccountNames)
    end
end

-- Basically, guards only care about one player (whoever joins first). 
-- So, player B can just steal everything and nothing will happen besides their bounty going up.
-- This helps fix that. Any cell that has some kind of shop should be handled here.

local onBountyInCell = {
    [KRL_START_CELL] = function(cellName, pid, bountyValue)
        local mimiIndexes = KRL_GetObjectIndexesByRefId("kazooie_mimi", cellName)

        if mimiIndexes and #mimiIndexes > 0 then
            local mimiIndex = mimiIndexes[1]
            logicHandler.RunConsoleCommandOnObject(pid, "SetFight 100", cellName, mimiIndex, true)
        end
    end,
    [KRL_SHOP_CELL] = function(cellName, pid, bountyValue)
        local guardObjectIndexes = KRL_GetObjectIndexesByRefId("kazooie_tart_guard", cellName)
        guardObjectIndexes = krl_array(guardObjectIndexes).merge(KRL_GetObjectIndexesByRefId("kazooie_tart_sniper", cellName))

        for _, objectIndex in pairs(guardObjectIndexes or {}) do
            logicHandler.RunConsoleCommandOnObject(pid, "SetFight 100", cellName, objectIndex, true)
        end
    end,
    [WHISTLE_CELL] = function(cellName, pid, bountyValue)
        -- this one seems to work fine enough without actually doing anything
        return true
    end
}

customEventHooks.registerHandler("OnPlayerBounty", function(_, pid)
    local bountyValue = tes3mp.GetBounty(pid)

    if bountyValue > 0 then
        local currentCell = tes3mp.GetCell(pid)

        if onBountyInCell[currentCell] then
            tes3mp.SetActorAITargetToPlayer(pid)
            onBountyInCell[currentCell](currentCell, pid, bountyValue)
        end
    end
end)

customEventHooks.registerValidator("OnObjectActivate", function(_, pid, cellName, objects, players)
    for _, object in pairs(objects) do
        local refId = object.refId

        if refId == "kazooie_whistle" then
            tes3mp.SetActorAITargetToPlayer(pid)
        elseif refId == "krl_shop_ship_door" then
            tes3mp.SetActorAITargetToPlayer(pid)

            local guardObjectIndexes = KRL_GetObjectIndexesByRefId("kazooie_tart_guard_3", cellName)

            for _, objectIndex in pairs(guardObjectIndexes or {}) do
                logicHandler.RunConsoleCommandOnObject(pid, "SetFight 100", cellName, objectIndex, true)
            end
        end
    end
end)
