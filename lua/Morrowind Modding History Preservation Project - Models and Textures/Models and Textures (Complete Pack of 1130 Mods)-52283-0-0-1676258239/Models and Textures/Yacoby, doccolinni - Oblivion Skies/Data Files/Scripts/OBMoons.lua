--DOES: Adds Oblivions Moons to Morrowind
--BY: Yacoby
--CONTACT: Yacoby on Offical ES Forums
--SCRIPT VER: 0.1


--If I used functions that didn't work in some older version, I would check the version.
--progVer = getProgramVer()


--Get the paths from the registry.
print("Getting paths...")
MWPath = getMWPath()
OBPath = getOBPath()

--Check we are all good.
if MWPath == nil then
	print("Cannot find Morrowind's install location. You must have Morrowind istalled")
	return 0
end

if OBPath == nil then
	print("Cannot find Oblivion's install location. You must have Oblivion istalled")
	return 0
end


--set texture paths.
obTexBSA = OBPath .. "Data\\Oblivion - Textures - Compressed.bsa"
mwTexDir = MWPath .. "Data Files\\Textures"

print("Opening BSA...")

--open the BSA
bsa = TES4BSAFile(obTexBSA)

	print("Extracting Files...")

	--extract the files.
	bsa:extract("Masser_full.dds", mwTexDir .. "\\Tx_Masser_full.dds")
	bsa:extract("Masser_half_wan.dds", mwTexDir .. "\\Tx_Masser_half_wan.dds")
	bsa:extract("Masser_half_wax.dds", mwTexDir .. "\\Tx_Masser_half_wax.dds")
	bsa:extract("Masser_new.dds", mwTexDir .. "\\Tx_Masser_new.dds")
	bsa:extract("Masser_one_wan.dds", mwTexDir .. "\\Tx_Masser_one_wan.dds")
	bsa:extract("Masser_one_wax.dds", mwTexDir .. "\\Tx_Masser_one_wax.dds")
	bsa:extract("Masser_three_wan.dds", mwTexDir .. "\\Tx_Masser_three_wan.dds")
	bsa:extract("Secunda_full.dds", mwTexDir .. "\\TX_Secunda_full.dds")
	bsa:extract("Secunda_half_wan.dds", mwTexDir .. "\\Tx_Secunda_half_wan.dds")
	bsa:extract("Secunda_half_wax.dds", mwTexDir .. "\\Tx_Secunda_half_wax.dds")
	bsa:extract("Secunda_new.dds", mwTexDir .. "\\TX_Secunda_new.dds")
	bsa:extract("Secunda_one_wan.dds", mwTexDir .. "\\Tx_Secunda_one_wan.dds")
	bsa:extract("Secunda_one_wax.dds", mwTexDir .. "\\Tx_Secunda_one_wax.dds")
	bsa:extract("Secunda_three_wan.dds", mwTexDir .. "\\Tx_Secunda_three_wan.dds")
	bsa:extract("Secunda_three_wax.dds", mwTexDir .. "\\Tx_Secunda_three_wax.dds")

bsa:closeBSA()

print("Finished...")