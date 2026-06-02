local constants = require("JosephMcKean.MistyStep.constants")
local defaults = {
    logLevel = 3,
    targetMode = "camera",
    scrollMerchants = {
        ["tanar llervi"] = true,
        ["Sauleius Cullian"] = true,
        ["folms mirel"] = true,
        ["barusi venim"] = true,
        ["felayn andral"] = true,
        ["ureso drath"] = true
    },
    spellMerchants = {
        ["orrent geontene"] = true,
        ["guls llervu"] = true,
        ["llaalam madalas"] = true,
        ["sirilonwe"] = true,
        ["eraamion"] = true,
        ["llaros uvayn"] = true,
        ["rirnas athren"] = true,
        ["felara andrethi"] = true,
        ["salam andrethi"] = true,
        ["idonea munia"] = true,
        ["j'rasha"] = true,
        ["sedris omalen"] = true,
        ["minnibi selkin-adda"] = true,
        ["llathyno hlaalu"] = true,
        ["llarara omayn"] = true,
        ["ulmiso maloren"] = true,
        ["farena arelas"] = true,
        ["Salyni Nelvayn"] = true,
        ["galero andaram"] = true
    }
}
local config = mwse.loadConfig(constants.MOD_NAME, defaults)
return config
