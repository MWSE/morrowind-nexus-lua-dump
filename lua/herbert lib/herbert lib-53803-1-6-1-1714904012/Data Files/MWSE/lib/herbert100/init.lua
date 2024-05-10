---@class herbert.lib : herbert.lib.utils
local hlib = {}

for k, v in pairs(require("herbert100.utils")) do
    hlib[k] = v
end

hlib.Class = require("herbert100.Class") ---@type herbert.Class
hlib.Logger = require("herbert100.Logger") ---@type herbert.Logger
hlib.math = require("herbert100.math")
hlib.MCM = require("herbert100.MCM")

hlib.tbl_ext = require("herbert100.tbl_ext")

hlib.table_combine = hlib.tbl_ext.combine       ---@deprecated
hlib.table_concat = hlib.tbl_ext.combine        ---@deprecated
hlib.table_append = hlib.tbl_ext.append_missing ---@deprecated

return hlib