local I = require("openmw.interfaces")
local self = require("openmw.self")
local time = require("openmw_aux.time")
local types = require("openmw.types")
local core = require("openmw.core")
local storage = require("openmw.storage")

local traitType = require("scripts.WretchedAndWeird.utils.traitTypes").background
local settings = storage.playerSection("SettingsWretchedAndWeird_drunk")

local period = 5
local bgPicked = false
local lastDrinkTimeIngame = core.getGameTime()
local stopTimer
local recovered = false
local debuffed = false

local drinksList = {
    ["p_vintagecomberrybrandy1"] = true,
    ["potion_ancient_brandy"] = true,
    ["potion_comberry_brandy_01"] = true,
    ["potion_comberry_wine_01"] = true,
    ["potion_cyro_brandy_01"] = true,
    ["potion_cyro_whiskey_01"] = true,
    ["potion_local_brew_01"] = true,
    ["potion_local_liquor_01"] = true,
    ["potion_nord_mead"] = true,
    ["potion_skooma_01"] = true,
    ["ab_dri_musa"] = true,
    ["ab_dri_sillapi"] = true,
    ["ab_dri_yamuz"] = true,
    ["t_bre_drink_aperitifbevonche_01"] = true,
    ["t_bre_drink_beer_01"] = true,
    ["t_bre_drink_brandychallegoux_01"] = true,
    ["t_bre_drink_ciderpommon_01"] = true,
    ["t_bre_drink_digestifeillevon_01"] = true,
    ["t_bre_drink_duxpom"] = true,
    ["t_bre_drink_jinevere"] = true,
    ["t_bre_drink_liquorbreque_01"] = true,
    ["t_bre_drink_winebalfiera_01"] = true,
    ["t_bre_drink_wineheartplum_01"] = true,
    ["t_bre_drink_winemarivon_01"] = true,
    ["t_bre_drink_winewayrest_01"] = true,
    ["t_cnq_ngopta"] = true,
    ["t_com_potion_daedricichor_e"] = true,
    ["t_com_subst_aqua_vita_01"] = true,
    ["t_de_drink_bourbongoya_01"] = true,
    ["t_de_drink_liquorllotham_01"] = true,
    ["t_de_drink_punavitjug"] = true,
    ["t_de_drink_punavitresin_01"] = true,
    ["t_de_drink_shakhal_01"] = true,
    ["t_de_drink_sweetbarrel_wine_01"] = true,
    ["t_de_subst_greydust_01"] = true,
    ["t_esr_drink_pudjing"] = true,
    ["t_he_drink_beerhautoma"] = true,
    ["t_he_drink_wineathelin"] = true,
    ["t_he_drink_wineisquel"] = true,
    ["t_he_drink_winerosado"] = true,
    ["t_he_drink_winesolicichi"] = true,
    ["t_imp_drink_aleakul_01"] = true,
    ["t_imp_drink_cherrybrandy_01"] = true,
    ["t_imp_drink_cideraliyew_01"] = true,
    ["t_imp_drink_ricebeermori_01"] = true,
    ["t_imp_drink_winebattle_01"] = true,
    ["t_imp_drink_wineblackhill_01"] = true,
    ["t_imp_drink_winefreeestat_01"] = true,
    ["t_imp_drink_wineplallovin_01"] = true,
    ["t_imp_drink_winerufinoclr_01"] = true,
    ["t_imp_drink_winesour"] = true,
    ["t_imp_drink_winesuriliebr_01"] = true,
    ["t_imp_drink_winesweet"] = true,
    ["t_imp_drink_winetamikaclr_01"] = true,
    ["t_imp_drink_winetwinmoon_01"] = true,
    ["t_imp_drink_winewolfsbl_01"] = true,
    ["t_imp_subst_aegrotat_01"] = true,
    ["t_imp_subst_blackdrake_01"] = true,
    ["t_imp_subst_incarnadine_01"] = true,
    ["t_imp_subst_indulcetpreserve_01"] = true,
    ["t_imp_subst_quaestovil_01"] = true,
    ["t_imp_subst_quaestovil_02"] = true,
    ["t_imp_subst_siyatcigar_01"] = true,
    ["t_imp_subst_sloadoil_01"] = true,
    ["t_ingflor_lotusseed_01"] = true,
    ["t_kha_drink_sugarrum"] = true,
    ["t_nor_drink_beer_01"] = true,
    ["t_nor_drink_beerlight_01"] = true,
    ["t_nor_drink_bodja_01"] = true,
    ["t_nor_drink_fyrg_01"] = true,
    ["t_nor_drink_gjeche_01"] = true,
    ["t_nor_drink_gjulve_01"] = true,
    ["t_nor_drink_risla_01"] = true,
    ["t_nor_drink_snowberryaleveig_01"] = true,
    ["t_nor_drink_strmead_01"] = true,
    ["t_nor_drink_winereach_01"] = true,
    ["t_orc_drink_liquorungorth_02"] = true,
    ["t_pi_drink_palmwine"] = true,
    ["t_qyc_cimoa"] = true,
    ["t_qyk_ngopta"] = true,
    ["t_rea_drink_liquoraeli_01"] = true,
    ["t_rea_drink_teagyrrg_01"] = true,
    ["t_rga_drink_abeceanrum_01"] = true,
    ["t_rga_drink_aibe_01"] = true,
    ["t_rga_drink_beer_01"] = true,
    ["t_rga_drink_bogru_01"] = true,
    ["t_rga_drink_cactuswine_01"] = true,
    ["t_rga_drink_kaay_01"] = true,
    ["t_rga_drink_sift"] = true,
    ["t_rga_drink_soge_01"] = true,
    ["t_rga_drink_winesutchgonogro_01"] = true,
    ["t_rga_drink_winesutchtalan_01"] = true,
    ["t_we_drink_meatjuicerotmeth_01"] = true,
    ["t_we_drink_pigmilkbeerjagga_01"] = true,
    ["t_we_drink_wine_01"] = true,
    ["t_yne_drink_pudjing"] = true,
    ["t_yne_drink_tsokni"] = true,
    ["ingred_blood_innocent_unique"] = true,
}

local function checkSoberity()
    if lastDrinkTimeIngame + settings:get("drunkTime") * time.hour >= core.getGameTime() or recovered then return end

    if lastDrinkTimeIngame + settings:get("recoveryTime") * time.day < core.getRealTime() then
        if debuffed then
            local agility = self.type.stats.attributes.agility(self)
            agility.base = agility.base + 30
            local faituge = self.type.stats.dynamic.fatigue(self)
            faituge.base = faituge.base + 10
            debuffed = false
        end

        recovered = true
        stopTimer()
        I.UI.showInteractiveMessage(
            "It feels like ages since you've had a drink, " ..
            "but strangely, you don't feel compelled to find one.\n\n" ..
            "You will no longer experience alcohol withdrawal."
        )
        return
    end

    if not debuffed then
        local agility = self.type.stats.attributes.agility(self)
        agility.base = agility.base - 30
        local faituge = self.type.stats.dynamic.fatigue(self)
        faituge.base = faituge.base - 10

        debuffed = true
        self:sendEvent("ShowMessage", { message = "You could use a drink..." })
    end
end

I.CharacterTraits.addTrait {
    id = "drunk",
    type = traitType,
    name = "Drunkard",
    description = (
        "For as long as you can remember (which admittedly isn't very long), you've needed a drink to get through the working day. " ..
        "You've got a strong stomach, but on days where you can't get a drink your hands shake and you feel awful. " ..
        "You could probably kick the habit if you endured the withdrawal long enough, but it would be tough.\n" ..
        "\n" ..
        "+15 Endurance\n" ..
        "-50 Fatigue while you're not drunk\n" ..
        "-30 Agility while you're not drunk\n" ..
        "> Not drinking for a long time might make you recover from your addiction"
    ),
    doOnce = function()
        local endurance = self.type.stats.attributes.endurance(self)
        endurance.base = endurance.base + 15
    end,
    onLoad = function()
        bgPicked = true
        if not recovered then
            stopTimer = time.runRepeatedly(checkSoberity, period)
        end
    end
}

local function drinkConsumed()
    lastDrinkTimeIngame = core.getGameTime()

    if debuffed then
        local agility = self.type.stats.attributes.agility(self)
        agility.base = agility.base + 30
        local faituge = self.type.stats.dynamic.fatigue(self)
        faituge.base = faituge.base + 10

        self:sendEvent("ShowMessage", { message = "Finally, a drink!" })
        debuffed = false
    end
end

local function onConsume(item)
    if not bgPicked or item.type ~= types.Potion or recovered then return end

    if I.SunsDusk then
        local ret, _ = I.SunsDusk.isConsumable(item)
        if not ret or ret.consumeCategory ~= "alcohol" then
            return
        end
    elseif not drinksList[item.recordId] then
        return
    end

    drinkConsumed()
end

local function sdInteraction(obj)
    local name = obj.type.records[obj.recordId].name:lower()
    if name:find("water") or name:find("tea") then return end
    drinkConsumed()
end

local function onLoad(data)
    if not data then return end
    lastDrinkTimeIngame = data.lastDrinkTimeIngame or lastDrinkTimeIngame
    recovered = data.recovered or recovered
    debuffed = data.debuffed or debuffed
end

local function onSave()
    return {
        lastDrinkTimeIngame = lastDrinkTimeIngame,
        recovered = recovered,
        debuffed = debuffed,
    }
end

return {
    engineHandlers = {
        onLoad = onLoad,
        onSave = onSave,
        onConsume = onConsume,
    },
    eventHandlers = {
        WretchedAndWeird_SDInteraction = sdInteraction,
    }
}
