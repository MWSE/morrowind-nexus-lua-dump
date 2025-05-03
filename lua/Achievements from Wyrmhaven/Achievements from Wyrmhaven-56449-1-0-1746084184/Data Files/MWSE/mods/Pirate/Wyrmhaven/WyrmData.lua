local wData = {
    colours = {
        BlueWyrm  = { 78 / 255, 102 / 255, 255 / 255 }
    }
}

local defaults = {
    MusicalInstrumentsCount = 0,
    MusicalInstruments = {
        ["_WYRM_church_rope"] = false,
        ["_WYRM_harp"] = false,
        --["_WYRM_harpsichord_gov"] = false,
        ["_WYRM_harpsichord"] = false
    },
	EquipSirUldorCorpse = 0
}
-- взято из примера хранения данных https://mwse.github.io/MWSE/guides/storing-data/#persistent-storage-for-the-same-player-character
-- эта функция инициализирует таблицу данных tes3.player.data.
local function initTableValues(data, t)
    for k, v in pairs(t) do
         --If a field already exists - we initialized the data
         --table for this character before. Don't do anything.
        if data[k] == nil then
            if type(v) ~= "table" then
                data[k] = v
            elseif v == {} then
                data[k] = {}
            else
                -- Fill out the sub-tables
                data[k] = {}
                initTableValues(data[k], v)
            end
        end
    end
end

-- функция проверки активированного объекта. (Призрачный галеон)
function wData.checGhostGalleon(e)
    -- проверяем открыто ли достижение в загруженном файле сохранения, если нет, проверяем нужный ли объект был активирован.
    if not tes3.player.data.achievements.Wyrm_GhostGalleon then
        if e.activator == tes3.player and e.target.object.id == "_WYRM_ghost_galleon"
           then
		   -- если нужный, присваиваем переменной значение true.
		   wData.GhostGalleon = true
        end
    end
end

-- функция проверки экипированных предметов. (Черный рыцарь)
function wData.onEquip(e)
    -- проверяем открыто ли достижение в загруженном файле сохранения, если нет, проверяем предметы.
    if not tes3.player.data.achievements.Wyrm_black_knight then
	    -- проверяем кто экипировал предмет.
	    if e.reference == tes3.player then --если игрок, то
          -- получаем предметы, экипированные в требуемые слоты.
          local bootsBlack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.boots })
	      local gauntlet_leftBlack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.leftGauntlet })
	      local gauntlet_rightBlack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot =tes3.armorSlot.rightGauntlet })
	      local helmBlack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.helmet })
	      local cuirassBlack = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.cuirass })
          -- сравниваем ID экипированных предметов с требуемыми.
	      if bootsBlack.object.id == "_WYRM_black_boots"
	      and gauntlet_leftBlack.object.id == "_WYRM_black_gauntlet_left"
	      and gauntlet_rightBlack.object.id == "_WYRM_black_gauntlet_right"
	      and helmBlack.object.id == "_WYRM_black_helm"
	      and cuirassBlack.object.id == "_WYRM_black_tabard"
	      then
		  -- если экипированы все требуемые предметы, присваиваем переменной значение true.
	      wData.black_knight = true
	      end
		end
	end
end
-- функция проверки и подсчета на скольких типов музыкальных инструментов сыграл игрок. (Человек-оркестр)
function wData.countMusicalInstr(e)
    local myData = wData.getData()
    if (e.activator == tes3.player) then
    if (myData["MusicalInstruments"][e.target.object.id] == false) then
        myData["MusicalInstruments"][e.target.object.id] = true
        myData["MusicalInstrumentsCount"] = myData["MusicalInstrumentsCount"] + 1
    else
        return
    end
	end
end
-- функция подсчета количества попыток поднять тело Сира Ульдора.
function wData.countSirUldorCorpse(e)
    local myData = wData.getData()
	-- проверяем обнаружено ли тело Сира Ульдора.
	if tes3.getJournalIndex { id = "WYRM_19_Chimeranyon" } == 30
	    then
		-- проверяем кто экипировал предмет.
	    if e.reference == tes3.player then
		    local shieldUldor = tes3.getEquippedItem({ actor = tes3.player, objectType = tes3.objectType.armor, slot = tes3.armorSlot.shield })
		    if shieldUldor.object.id == "_WYRM_sir_uldor_corpse" then
		    myData["EquipSirUldorCorpse"] = myData["EquipSirUldorCorpse"] + 1
		    end
	    end
	end
end

function wData.getData()
    return tes3.player.data.achieveWyrm
end
function wData.initachieveWyrm()
    -- загружаем данные мода из файла сохранения, если отсутствуют, то загружаем значения из таблицы defaults
    local data = tes3.player.data
    data.achieveWyrm = data.achieveWyrm or {}
    local myData = data.achieveWyrm
    initTableValues(myData, defaults)
    -- проверяем выполнено условие для открытия достижения, если нет регистрируем необходимые функции.
	-- Человек-оркестр. проверяем сколько типов инструментов активировал игрок.
    if (myData["MusicalInstrumentsCount"] < 3 and not event.isRegistered(tes3.event.activate, wData.countMusicalInstr)) then
        event.register(tes3.event.activate, wData.countMusicalInstr)
    end
	-- Сир Ульдор. проверяем не пройден ли квест.
	if tes3.getJournalIndex { id = "WYRM_19_Chimeranyon" } < 40 and not event.isRegistered(tes3.event.equipped, wData.countSirUldorCorpse)
	then
	event.register(tes3.event.equipped, wData.countSirUldorCorpse)
	end
	-- Черный рыцарь. присваиваем переменной значение по умолчанию false. проверяем открыто ли достижение.
	wData.black_knight = false
	if not tes3.player.data.achievements.Wyrm_black_knight and not event.isRegistered(tes3.event.equipped, wData.onEquip)
	then
	event.register(tes3.event.equipped, wData.onEquip)
	end
	-- Корабль призрак. присваиваем переменной значение по умолчанию false. проверяем открыто ли достижение.
	wData.GhostGalleon = false
	if not tes3.player.data.achievements.Wyrm_GhostGalleon and not event.isRegistered(tes3.event.activate, wData.checGhostGalleon)
	then 
	event.register(tes3.event.activate, wData.checGhostGalleon)
	end
	
end

return wData
