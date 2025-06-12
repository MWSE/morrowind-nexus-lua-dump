local zjust = require('openmw.util').vector3(0,0,999)
local world = require('openmw.world')
local types = require('openmw.types')
local Static = types.Static
local Door   = types.Door
local destCell = Door.destCell
local destPos  = Door.destPosition
local destRot  = Door.destRotation
local hasDest  = Door.isTeleport

local function targetCell(cell)
   for _, door in ipairs(cell:getAll(Door)) do
      if hasDest(door) then
         for _, door in ipairs(destCell(door):getAll(Door)) do
            if hasDest(door) and destCell(door).name == cell.name then
               return { cell=cell, pos=destPos(door), rot=destRot(door) }
   end end end end
   local any = cell:getAll(Static)
   if #any == 0 then any = cell:getAll() end
   any = any[1] or {position=zjust}
   return {
      cell = cell,
      pos  = cell.isExterior and zjust + any.position or any.position,
      rot  = any.rotation
   }
end

local cache = {}
local function targetCellname(s)
   local to = cache[s]
   if to then return to end
   for _, cell in ipairs(world.cells) do
      if cell.name == s then
         to = targetCell(cell)
         cache[s] = to
         return to
end end end

return {
   eventHandlers = {
      yksuiReqMoveToCell = function(req)
         local to = targetCellname(req.to)
         req.obj:teleport(to.cell, to.pos, { rotation=to.rot, onGround=true })
      end,
      yksuiReqCellTable = function(player)
         local res, i = {[""]=""}, 1
         for _, cell in ipairs(world.cells) do
            local s = cell.name
            local r = s:lower()
            if not res[r] then
               res[r] = s
               res[i] = r
               i = i + 1
         end end
         res[""] = nil
         player:sendEvent('yksuiResCellTable', res)
      end,
   },
}
