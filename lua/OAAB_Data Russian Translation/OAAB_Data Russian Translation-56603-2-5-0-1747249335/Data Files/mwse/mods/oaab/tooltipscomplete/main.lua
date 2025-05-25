local tooltipsComplete = include("Tooltips Complete.interop")
local tooltipData = {

	-- Ingredients:
    { id = "ab_dri_sillapi", description = "Силлапи — напиток шахтёров, который иногда используют в качестве лекарства, поскольку он может притупить боль и обеспечить спокойный сон. Его варят из различных продуктов квама, часто прямо в шахтах, и традиционно хранят в кувшине, сделанном из обработанного яйца квама.", itemType = "ingredients" },
	{ id = "ab_ingcrea_dungcake", description = "Плоская рассыпчатая лепешка из высушенного навоза. Имеет легкий мускусный запах.", itemType = "ingredients" },
	
	-- Clothing:
	{ id = "ab_c_commonamulet02", description = "Простой амулет, изготовленный из зубов рыбы-убийцы. Зубы имеют радужное покрытие, что делает их популярным украшением.", itemType = "clothing" },
	{ id = "ab_c_dwemeramuletclock", description = "Небольшое декоративное устройство двемерской работы. Кажется, что сложные механизмы внутри все еще работают в том же ритме даже спустя тысячелетия.", itemType = "clothing" },
	
	-- Miscellaneous:
	{ id = "ab_misc_scalesbrass", description = "Простые и надежные весы из матовой латуни с легким металлическим отливом. В Тамриэле подобные весы принято считать символом справедливости и торговли.", itemType = "miscItem" },
	{ id = "ab_misc_scalesbrassskew", description = "Простые и надежные весы из матовой латуни с легким металлическим отливом. В Тамриэле подобные весы принято считать символом справедливости и торговли.", itemType = "miscItem" },
	{ id = "ab_misc_scalesbrasswght", description = "Маленькая латунная гиря, предназначенная для использования с весами.", itemType = "miscItem" },
	{ id = "ab_misc_scalesbrasswghtbig", description = "Латунная гиря, предназначенная для использования с весами.", itemType = "miscItem" },	
	
	{ id = "ab_misc_scalessilver", description = "Элегантные небольшие весы, изготовленные из серебра и отполированные до блеска. В Тамриэле подобные весы принято считать символом справедливости и торговли.", itemType = "miscItem" },
	{ id = "ab_misc_scalessilverskew", description = "Элегантные небольшие весы, изготовленные из серебра и отполированные до блеска. В Тамриэле подобные весы принято считать символом справедливости и торговли.", itemType = "miscItem" },
	{ id = "ab_misc_scalessilverwght", description = "Маленькая серебряная гиря, предназначенная для использования с весами.", itemType = "miscItem" },
	{ id = "ab_misc_scalessilverwghtbig", description = "Серебряная гиря, предназначенная для использования с весами.", itemType = "miscItem" },
	
	{ id = "ab_misc_sfishhead", description = "Отрезанная голова рыбы-убийцы. Часто используется в качестве приманки для других рыб-убийц.", itemType = "miscItem" },
	{ id = "ab_misc_shackles", description = "Простой, дешевый, но довольно эффективный вид усмирения, слишком хорошо знакомый как преступнику, так и рабу.", itemType = "miscItem" },
	
	-- Weapons:
	{ id = "ab_w_dreughshortbow", description = "Лук небольшого размера, изготовленный из упругого хряща Дреуга. Обладает некоторой вязкостью движений, по сравнению с луками из других материалов.", itemType = "weapon" },	
	{ id = "ab_w_dwrvstar", description = "Дискообразный метательный клинок двемерского производства. По-прежнему сохраняет остроту бритвы и металлический блеск.", itemType = "weapon" },
	{ id = "ab_w_dwrvknife", description = "Небольшой метательный нож из двемерского металла. Если бы не хорошо рассчитанный баланс, он казался бы слишком тяжелым.", itemType = "weapon" },
	{ id = "ab_w_dwrvtoolcrowbar", description = "Старый ржавый лом, сделанный Двемерами. Тяжелый и крепкий, он может пригодиться при попытке управлять или сломать ихние древние машины.", itemType = "weapon" },
	
	-- Arrow quivers:
	{ id = "AB_w_AshlEbonyArrow10x", description = "Атака: 3 - 5", itemType = "miscItem" },
	{ id = "AB_w_AshlGlassArrow10x", description = "Атака: 1 - 5", itemType = "miscItem" },
	{ id = "AB_w_BoneArrow10x", description = "Атака: 2 - 3", itemType = "miscItem" },
	{ id = "AB_w_BonemoldArrow10x", description = "Атака: 1 - 4", itemType = "miscItem" },
	{ id = "AB_w_ChitinArrow10x", description = "Атака: 1 - 2", itemType = "miscItem" },
	{ id = "AB_w_CorkbulbArrow10x", description = "Атака: 1 - 1", itemType = "miscItem" },
	{ id = "AB_w_DaedricArrow10x", description = "Атака: 10 - 15", itemType = "miscItem" },
	{ id = "AB_w_DreughArrow10x", description = "Атака: 1 - 5", itemType = "miscItem" },
	{ id = "AB_w_EbonyArrow10x", description = "Атака: 5 - 10", itemType = "miscItem" },
	{ id = "AB_w_FlintArrow10x", description = "Атака: 1 - 2", itemType = "miscItem" },
	{ id = "AB_w_GlassArrow10x", description = "Атака: 1 - 6", itemType = "miscItem" },
	{ id = "AB_w_GoblinArrow10x", description = "Атака: 6 - 12", itemType = "miscItem" },
	{ id = "AB_w_HuntsArrow10x", description = "Атака: 1 - 5", itemType = "miscItem" },
	{ id = "AB_w_IronArrow10x", description = "Атака: 1 - 3", itemType = "miscItem" },
	{ id = "AB_w_OrcishArrow10x", description = "Атака: 3 - 5", itemType = "miscItem" },
	{ id = "AB_w_SilverArrow10x", description = "Атака: 1 - 3", itemType = "miscItem" },
	{ id = "AB_w_StalhrimArrow10x", description = "Атака: 9 - 16", itemType = "miscItem" },
	{ id = "AB_w_SteelArrow10x", description = "Атака: 1 - 4", itemType = "miscItem" }
}
local function initialized()
    if tooltipsComplete then
        for _, data in ipairs(tooltipData) do
            tooltipsComplete.addTooltip(data.id, data.description, data.itemType)
        end
    end
end
event.register("initialized", initialized)