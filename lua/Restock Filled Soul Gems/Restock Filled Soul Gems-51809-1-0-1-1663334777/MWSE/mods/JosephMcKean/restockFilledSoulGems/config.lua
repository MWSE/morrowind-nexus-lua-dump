local this = {}
this.configPath = "Restock Filled Soul Gems"
this.defaultConfig = {
    modEnabled = true,
    maxFilledCount = 10,
    maxUnfilledCount = 10,
    logLevel = "INFO",
    soulGemsMerchants = {

        -- BTBGI soul gem merchants
        ["aunius autrus"] = true, -- Wolverine Hall Imperial Cult, priest service
        ["chanil_lee"] = true, -- Six Fishes, sorcerer, mages guild
        ["diren vendu"] = true, -- Tel Mora Tower Service, sorcerer service, telvanni
        ["elynu saren"] = true, -- Suran Temple, priest service
        ["fanildil"] = true, -- Hawkmoth Legion Garrison, healer service
        ["ferise varo"] = true, -- Vos Varo Tradehouse, mage service
        ["j'rasha"] = true, -- Vivec J'Rasha Healer, healer service
        ["medila indaren"] = true, -- Caldera Mages Guild, mage service
        ["mertisi andavel"] = true, -- Tel Branora Upper Tower, nightblade service, telvanni
        ["nelso salenim"] = true, -- Telvanni Council House Entry, mage service
        ["salver lleran"] = true, -- Vivec Telvanni Sorcerer, sorcerer service
        ["saras orelu"] = true, -- Molag Mar Temple, healer service
        ["solea nuccusius"] = true, -- Moonmoth Prison Towers, battlemage service, legion
        ["ulmiso maloren"] = true, -- Ghostgate Tower of Dawn Lower Level, healer service

        -- for non BTBGI users
        ["arrille"] = true, -- Seyda Neen, trader service
        ["elbert nermarc"] = true, -- mournhold craftsmen's hall, enchanter service
        ["galar rothan"] = true, -- Telvanni Council House Entry, enchanter service
        ["galbedir"] = true, -- Balmora Mages Guild, enchanter service
        ["ilen faveran"] = true, -- Balmora Temple, enchanter service
        ["llandris thirandus"] = true, -- High Fane, enchanter service
        ["maren uvaren"] = true, -- Tel Aruhn Maren Uvaren, enchanter service
        ["ralds oril"] = true, -- Suran Ralds Oril, trader service
        ["syloria siruliulus"] = true, -- Buckmoth, trader service, impeiral cult 
        ["ureso drath"] = true -- Ald'ruhn Temple, enchanter service
    },
    --[[soulGems = {
        ["misc_soulgem_petty"] = true, -- 10
        ["misc_soulgem_lesser"] = true, -- 30
        ["misc_soulgem_common"] = true, -- 100
        ["misc_soulgem_greater"] = true -- 200
    },]]
    souls = {
        ["mudcrab"] = true, -- 5 (petty)
        ["nix-hound"] = true, -- 10 (petty)
        ["rat"] = true, -- 10 (petty)
        ["slaughterfish"] = true, -- 10 (petty)
        ["slaughterfish_small"] = true, -- 10 (petty)
        ["kwama forager"] = true, -- 15 (lesser)
        ["alit"] = true, -- 20 (lesser)
        ["kagouti"] = true, -- 20 (lesser)
        ["kwama warrior"] = true, -- 20 (lesser)
        ["ancestor_ghost"] = true, -- 30 (lesser)
        ["bm_frost_boar"] = true, -- 30 (lesser), bloodmoon rebalance
        ["bm_horker"] = true, -- 30 (lesser)
        ["bm_wolf_grey"] = true, -- 30 (lesser), bloodmoon rebalance
        ["shalk"] = true, -- 30 (lesser)
        ["skeleton"] = true, -- 30 (lesser)
        ["skeleton archer"] = true, -- 30 (lesser)
        ["skeleton warrior"] = true, -- 30 (lesser)
        ["goblin_grunt"] = true, -- 30 (lesser), tribunal rebalance
        ["bm_bear_black"] = true, -- 50 (common), bloodmoon rebalance
        ["bm_wolf_red"] = true, -- 50 (common)
        ["bm_wolf_skeleton"] = true, -- 50 (common)
        ["netch_bull"] = true, -- 50 (common)
        ["bonewalker_greater"] = true, -- 75 (common)
        ["dreugh"] = true, -- 75 (common)
        ["ash_slave"] = true, -- 100 (common)
        ["ash_zombie"] = true, -- 100 (common)
        ["bonelord"] = true, -- 100 (common)
        ["clannfear"] = true, -- 100 (common)
        ["corprus_stalker"] = true, -- 100 (common)
        ["dremora"] = true, -- 100 (common)
        ["scamp"] = true, -- 100 (common)
        ["atronach_flame"] = true, -- 105 (greater)
        ["atronach_frost"] = true, -- 138  (greater)
        ["atronach_storm"] = true, -- 150  (greater)
        ["ogrim"] = true, -- 165 (greater)
        ["daedroth"] = true, -- 195 (greater)
        ["ancestor_ghost_greater"] = true, -- 200 (greater)
        ["bm_spriggan"] = true, -- 200 (greater), Bloodmoon rebalance
        ["dremora_lord"] = true, -- 200 (greater)
        ["dwarven ghost"] = true, -- 200 (greater)
        ["goblin_handler"] = true, -- 200 (greater)
        ["skeleton champion"] = true, -- 200 (greater)
        ["ogrim titan"] = true, -- 220 (grand), BTBGI
        ["winged twilight"] = true, -- 300 (grand)
        ["ascended_sleeper"] = true, -- 350 (grand), Beware the Sixth House
        ["golden saint"] = true -- 400 (grand)
        -- 600 (grand)
    }
}
local inMemConfig = mwse.loadConfig(this.configPath, this.defaultConfig)
this.config = setmetatable({
    save = function() mwse.saveConfig(this.configPath, inMemConfig) end
}, {
    __index = function(_, key) return inMemConfig[key] end,
    __newindex = function(_, key, value) inMemConfig[key] = value end
})
-- code that's copied over from merlord's mod 
return this
