local mod_name = "SneakIsGoodNow"
local prefix = mod_name .. "_"
local MtoGU = 69.99
local GUtoM = 1/MtoGU

return {
    MtoGU = MtoGU,
    GUtoM = GUtoM,
    mod_name = mod_name,
    KNOCKOUT_SPELL_ID = "detd_sleep",
    e = {
        ReportAttack = prefix.."ReportAttack"
    }
}