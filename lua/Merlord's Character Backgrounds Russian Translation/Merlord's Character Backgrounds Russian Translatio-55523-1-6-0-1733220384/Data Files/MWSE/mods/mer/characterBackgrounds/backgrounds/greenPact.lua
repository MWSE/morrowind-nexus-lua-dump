local config = require('mer.characterBackgrounds.config')
local function getData()
    local data = tes3.player.data.merBackgrounds or {}
    return data
end

local meatPatterns = {
    "meat",
    "cuttle",
    "egg",
    "skin",
    "hide",
    "jerky",
    "bone",
    "blood",
    "fish",
    "scales",
    "scrib",
    "shalk",
    "leather",
    "pelt",
    "flesh",
    "brain",
    "_ear",
    "eye",
    "heart",
    "tail",
    "tongue",
    "morsel",
    "_ingcrea"
}

local function hasMeatyName(id)
    for _, pattern in ipairs(meatPatterns) do
        if string.find(id, pattern) then
            return true
        end
    end
end

return {
    id = "greenPact",
    name = "Зеленый пакт",
    description = (
        "Будучи Босмером, вы принесли клятву, известную как Зеленый пакт, лесному божеству И'ффре. " ..
        "Одно из условий этого соглашения гласит, что вы можете употреблять в пищу только мясные продукты." ..
        "\n\nТребования: Только Лесные Эльфы."
    ),
    checkDisabled = function()
        local race = tes3.player.object.race.id
        return race ~= "Wood Elf"
    end,
    callback = function()

        local function checkIsMeat(e)
            local data = getData()
            if data.currentBackground ~= "greenPact" then return end

            if e.item.objectType == tes3.objectType.ingredient then
                local id = string.lower(e.item.id)
                if not hasMeatyName(id) then
                    if not config.mcm.greenPactAllowed[id] then
                        tes3.messageBox("Зеленый пакт запрещает вам есть это.")
                        return false
                    end
                end
            end
        end
        event.unregister("equip", checkIsMeat )
        event.register("equip", checkIsMeat )
    end
}