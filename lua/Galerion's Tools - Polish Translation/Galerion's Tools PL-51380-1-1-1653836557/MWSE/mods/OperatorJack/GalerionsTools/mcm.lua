local config = require("OperatorJack.GalerionsTools.config")

local function createGeneralCategory(template)
    local page = template:createSideBarPage{
        label = "Ustawienia ogólne",
        description = "Najedź kursorem na ustawienie, aby dowiedzieć się więcej na jego temat."
    }

    local category = page:createCategory{
        label = "Ustawienia ogólne"
    }

    category:createSlider{
        label = "Podstawowa szansa na wydobycie duszy",
        description = "Użyj tej opcji, aby ustawić podstawową szansę powodzenia podczas korzystania z ekstraktora dusz. Zostanie ona dodana do normalnego wyniku obliczenia szansy. Tak więc wartość 10 w tym ustawieniu da wszystkim przedmiotom szansę co najmniej 10, plus cokolwiek zwróci normalna formuła. Wartość ta jest dodawana do obliczeń szansy po zwiększeniu wyniku obliczeń szansy z dowolnej liczby ujemnej do 0, ale przed zmniejszeniem wyniku obliczeń szansy z dowolnej liczby dodatniej powyżej 100 do 100.",
        min = 0,
        max = 100,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "baseChance",
            table = config
        }
    }

    category:createSlider{
        label = "Modyfikator procentowy szansy na wydobycie duszy",
        description = "Użyj tej opcji, aby zwiększyć lub zmniejszyć trudność użycia ekstraktora dusz. Modyfikator jest stosowany bezpośrednio do wyniku obliczenia szansy w procentach. Zatem wartość 100 w tym ustawieniu pomnoży wynik przez 100%, czyli 1, zachowując domyślną wartość obliczeń. Wartość 125 w tym ustawieniu spowoduje pomnożenie wyniku przez 125%, czyli 1,25. Jeśli wynik obliczenia szansy jest mniejszy niż 0, wartość obliczenia szansy zostanie zwiększona do 0, a to ustawienie nie będzie miało żadnego wpływu.",
        min = 0,
        max = 500,
        step = 1,
        jump = 10,
        variable = mwse.mcm.createTableVariable{
            id = "chanceModifierPercent",
            table = config
        }
    }

    return category
end

-- Handle mod config menu.
local template = mwse.mcm.createTemplate("Galerion's Tools")
template:saveOnClose("Galerions-Tools", config)

createGeneralCategory(template)

mwse.mcm.register(template)