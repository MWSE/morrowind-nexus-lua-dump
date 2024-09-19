---@class ShopAround.i18n
---@field PurchaseMessage fun(data:{itemName:string, price:number, merchantName:string}):string
---@field NotEnoughGold fun():string
---@field TooltipMessage fun(data:{price:number}):string
---@field ModName fun():string
---@field ModDescription fun():string
---@field ReleaseHistory fun():string
---@field BuyMeACoffee fun():string
---@field MadeBy fun():string
---@field Links fun():string
---@field Credits fun():string
---@field Settings fun():string
---@field EnableMod fun():string
---@field EnableModDescription fun():string
---@field LogLevel fun():string
---@field LogLevelDescription fun():string
--Translators: Do not include the above code in translation files

return {
    PurchaseMessage = "Purchase %{itemName} for %{price} gold?\nMerchant: %{merchantName}",
    NotEnoughGold = "You do not have enough gold to purchase this item.",
    TooltipMessage = "Purchase (%{price} gold)",
    --MCM
    ModName = "Shop Around",
    ModDescription = "This mod allows you to purchase items by activating them directly.\n"
        .. "The price of the item will be the default barter price. To haggle on prices, talk to the shop keeper and use the normal barter menu.",
    ReleaseHistory = "Release history",
    BuyMeACoffee = "Buy me a coffee",
    MadeBy = "Made by Merlord",
    Links = "Links",
    Credits = "Credits",
    Settings = "Settings",
    EnableMod = "Enable Mod",
    EnableModDescription = "Enables the mod.",
    LogLevel = "Log Level",
    LogLevelDescription = "Set the logging level for all Loggers.",
}