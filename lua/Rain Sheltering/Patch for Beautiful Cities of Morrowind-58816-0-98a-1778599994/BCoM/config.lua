local config = {
	checkInterval = 2.0,
    --[[ Максимальная дистанция поиска укрытия. Ограничение (почти) не скажется на производительности, т.к
        поиск укрытий происходит только в текущем городе. В Балморе хватит и 2500.
        Но в Гнисисе нужен очень много.]]--
	maxShelterDistance = 8500.0,
	recordHotkey = tes3.scanCode.F8, -- Горячая клавиша для записи укрытия в таблицу
	arriveDistance = 85.0, -- Обычно хватает 65, но если NPC уперся в текстуру - может потребоваться больше
	is_guard_patrolling_in_rain = true,
    unloadedNpcTeleportDelay = 4.0,    -- время в игровых часах до телепортации NPC, если он не подгружен

    -- классы NPC, которые должны оставаться под дождем
    excludedClasses = {
        ["Guard"] = true,
        ["Caravaner"] = true,
        ["Shipmaster"] = true,
        ["Gondolier"] = true,
        ["Slave"] = true,
    },

    excludedObjectIdNpc = {
        --[[ Street traders of Sadrith Mora
        ["ancola"] = true,
        ["manicky"] = true,
        ["anruin"] = true,
        ["arangaer"] = true,
        ["elegal"] = true,
        ["brallion"] = true, ]]--

        -- Street traders of Gnisis
        ["ashuma-nud matluberib"] = true,
        ["hannabi zabynatus"] = true,
        ["shulki ashunbabi"] = true,
        ["zebba benamamat"] = true,

        ["vatollia apo"] = true,    -- Guard at the entrance to the Gnisis mine
        ["galyn arvel"] = true,     -- Quest Shipmaster Ald Velothi
        ["anes hlaren"] = true,     -- Quest Ald Velothi
        ["garyn girith"] = true,    -- Quest Ald Velothi
        ["sadal doren"] = true,     -- Quest Ald Velothi
        ["andilo thelas"] = true,   -- Standing on the balcony Gnaar Mok
        ["Blatta Hateria"] = true,  -- Quest Shipmaster Ebonheart
        ["imperial archer"] = true, -- Archers in Forts. Usually locked on the walls and are not Guards.

        -- Beautiful Cities of Morrowind
        ["shadbak gra-burbug"] = true,  -- Pelagiad street trader
        -- Gnisis
        ["G93_TavernGirl"] = true,          -- pavilion bartender
        ["HV_Gn_LlarisaSendras"] = true,    -- priest on the roof
        ["HV_Gn_BelsDarodyr"] = true,       -- tradehouse roof
        ["dul gro-dush"] = true,            -- gate guard
    },

    questRequirements = {
        ["hentus yansurnummu"] = {
            { journal = "MS_HentusPants", stageComplete = 100}  -- without pants. В BCoM он телепортируется в текстуру.
        }
    }
}

return config