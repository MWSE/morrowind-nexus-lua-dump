local H = {}

--1 is cost, 2 is sound folder in Data Files\\Sounds\\Cr
H.doorTable = {
	["Samarys Ancestral Tomb"] = { [1] = 500, [2] = "ancghst" }
}

--1 is cost, 2 is random factor (+/- it), 3 is value Rating from 1-10
H.dialogueTable = {
	["Background"] = { [1] = 50, [2] = 0, [3] = 1 },
	["little advice"] = { [1] = 50, [2] = 0, [3] = 1 }
}

--1 is cost
H.rewardTable = {
	["905232419206199259"] = { [1] = 65 }, --"An Escort to Molag Mar," 50 gold reward if trader dies
	--["16113140832821732391"] = { [1] = 15 } --generic imperial guard Background, test
}

return H