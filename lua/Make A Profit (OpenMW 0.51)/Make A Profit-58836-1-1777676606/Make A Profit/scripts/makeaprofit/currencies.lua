local core = require('openmw.core')
local self = require('openmw.self')

local Currencies = {}

Currencies.default = {
    id   = 'gold_001',
    icon = 'icons/gold.dds',
    name = 'Septim',
}

--[[ dwemer coin
Currencies.dwemer = {
    id   = { 'misc_dwrv_coin00', 'misc_dwrv_cursed_coin00' }
    icon = '',
    name = 'Dwemer Coin',
]]

--	['t_ayl_coingold_01']				= true,
--	['t_ayl_coinsquare_01']				= true,
--	['t_ayl_coinbig_01']				= true,
--	['t_he_dirennicoin_01']				= true,
--	['t_imp_coinreman_01']				= true,
--	['t_imp_coinalessian_01']			= true,
--	['t_nor_coinbarrowcopper_01']		= true,
--	['t_nor_coinbarrowiron_01']			= true,
--	['t_nor_coinbarrowsilver_01']		= true,
	
	-- OAAB
--	['ab_misc_cointriune']				= true,

Currencies.regions = {
    ['ascadian isles region'] = Currencies.default,
    ['west gash region']      = Currencies.default,
    -- placeholder regional currencies
    -- ['bitter coast region'] = {
    --     id   = 'misc_map_drake',
    --     icon = 'icons/m/misc_map_drake.dds',
    --     name = 'Drake',
    -- },
}

function Currencies.getCurrent()
    local cell = self.cell
    if not cell then
        return Currencies.default
    end
	
    local regionId = cell.region
    if regionId then
        local entry = Currencies.regions[regionId:lower()]
        if entry then return entry end
    end
	
    return Currencies.default
end

function Currencies.getPlayerCount(currency)
    currency = currency or Currencies.getCurrent()
    return self.type.inventory(self):countOf(currency.id)
end

function Currencies.getForRegion(regionId)
    if not regionId then return Currencies.default end
    return Currencies.regions[regionId:lower()] or Currencies.default
end

return Currencies