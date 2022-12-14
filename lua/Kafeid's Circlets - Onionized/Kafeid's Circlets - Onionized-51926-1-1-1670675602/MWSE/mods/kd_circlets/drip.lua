local interop = include("mer.drip")

if interop then
	mwse.log('[kd_ciclets] Found DRIP! Adding circlets to its database')
	local items = require("kd_circlets.items")
	for _, item in ipairs(items.all) do
		interop.registerClothing(item)
	end
	
	interop.registerMaterialPattern('grand')
else 
	mwse.log('[kd_ciclets] skipping DRIP integration.')
end
