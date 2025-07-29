-- This is for compatability only. Please do not include this file!
-- Use `require(OperatorJack.MagickaExpanded)` instead!
--
local log = require("OperatorJack.MagickaExpanded.utils.logger")

log:warn(
    "A mod is using a deprecated method for loading Magicka Expanded. Please update mods to no longer use `include(OperatorJack.MagickaExpanded.magickaExpanded)`. Please use `require(OperatorJack.MagickaExpanded)` instead.")

return require("OperatorJack.MagickaExpanded")
