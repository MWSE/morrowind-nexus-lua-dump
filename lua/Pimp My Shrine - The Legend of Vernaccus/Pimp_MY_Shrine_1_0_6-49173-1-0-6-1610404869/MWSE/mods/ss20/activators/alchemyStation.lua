local stationID = "ss20_tbl_alch" 
local apparati = {
    "ss20_mortar",
    "ss20_calc",
    "ss20_retort",
    "ss20_alem",
}

local usingTable
local inMenu

local function activate(e)
    if e.target.object.id == stationID then
        for _, apparatus in ipairs(apparati) do
            tes3.addItem{ reference = tes3.player, item = apparatus, playSound = false }
        end
        tes3.mobilePlayer:equip{ item = apparati[1], playSound = false }
        --tes3.mobilePlayer:equip{ item = apparati[1] }
        usingTable = true
    end
end

event.register("activate", activate)

local function simulate(e)
    local menu = tes3ui.findMenu(tes3ui.registerID("MenuAlchemy"))


    if inMenu then
        if not menu then
            usingTable = false
            for _, apparatus in ipairs(apparati) do
                tes3.removeItem{ reference = tes3.player, item = apparatus, playSound = false }
                inMenu = false
            end
        end
    end

    if usingTable then
        inMenu = ( menu ~= nil )
    end
end

event.register("simulate", simulate)