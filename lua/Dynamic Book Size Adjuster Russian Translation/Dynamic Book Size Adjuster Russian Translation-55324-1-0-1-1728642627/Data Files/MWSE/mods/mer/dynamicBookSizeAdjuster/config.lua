return {
    --Mod name will be used for the MCM menu as well as the name of the config .json file.
    modName = "Настройщик размера книг",
	modConfigPatch = "Dynamic Book Size Adjuster",
    --Description for the MCM sidebar
    modDescription =
[[
Многие предметы в Morrowind нереально большие, но больше всего - книги. 

Этот мод не изменяет размер размещенных в игре книг, так как в этом случае библиотеки будут выглядеть крайне скудными. Вместо этого мод будет корректировать масштаб любой книги, которую выложит игрок из инвентаря.
]],
    mcmDefaultValues = {
        enabled = true, 
        scale = 75,
        debug = false,
    },

}