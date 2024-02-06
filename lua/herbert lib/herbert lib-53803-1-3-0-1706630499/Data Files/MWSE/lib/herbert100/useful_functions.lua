-- this stuff is now included in the `herbert100/init.lua` file, use that instead
-- this is deprecated
---@deprecated
return setmetatable({ tostring = json.encode, }, {__index=require("herbert100")})