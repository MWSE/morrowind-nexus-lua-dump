--[[
ErnDebt for OpenMW.
Copyright (C) Erin Pentecost 2026

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

return {
    questId = "ern_debt",
    questStages = {
        [0] = "name",
        [1] = "start",
        [5] = "approached",
        [10] = "killed_collector",
        -- 100 and over MUST be finished stages.
        [100] = "paid_off",
        [101] = "killed_lender"
    },
    ---@param stage number
    ---@return boolean
    enabled = function(stage)
        return stage > 0 and stage < 100
    end
}
