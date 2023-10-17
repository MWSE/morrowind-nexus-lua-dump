local stationID = "_COR_lr_alchemy_table" 
local apparati = {
    "_cor_mortar",
    "_cor_calc",
    "_cor_retort",
    "_cor_alem",
}

local usingTable
local inMenu

local function activate(e)
    if e.target.object.id == stationID then
        for _, apparatus in ipairs(apparati) do
            mwscript.addItem{ reference = tes3.player, item = apparatus }
        end
        mwscript.equip{ reference = tes3.player, item = apparati[1] }
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
                mwscript.removeItem{ reference = tes3.player, item = apparatus }
                inMenu = false
            end
        end
    end

    if usingTable then
        inMenu = ( menu ~= nil )
    end
end

event.register("simulate", simulate)