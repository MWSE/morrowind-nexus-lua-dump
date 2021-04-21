local x = {}

function x.is_grandmaster_hlaalu()
	local f1 = tes3.getFaction('Hlaalu')
	return f1.playerJoined and f1.playerRank == 9
end
function x.is_not_grandmaster_hlaalu()
	return not x.is_grandmaster_hlaalu()
end
function x.is_not_hlaalu_member()
	local f1 = tes3.getFaction('Hlaalu')
	return not f1.playerJoined
end

function x.is_grandmaster_redoran()
	local f1 = tes3.getFaction('Redoran')
	return f1.playerJoined and f1.playerRank == 9
end
function x.is_not_grandmaster_redoran()
	return not x.is_grandmaster_redoran()
end
function x.is_not_redoran_member()
	local f1 = tes3.getFaction('Redoran')
	return not f1.playerJoined
end


function x.is_grandmaster_telvanni()
	local f1 = tes3.getFaction('Telvanni')
	return f1.playerJoined and f1.playerRank == 9
end
function x.is_not_grandmaster_telvanni()
	return not x.is_grandmaster_telvanni()
end



function x.is_legion_member()
	local f1 = tes3.getFaction('Imperial Legion')
	return f1.playerJoined
end
function x.is_not_legion_member()
	return not x.is_legion_member()
end


return x