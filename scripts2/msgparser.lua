local pb = require "pb"

assert(pb.loadfile "scripts2/pb/Login.pb")
assert(pb.loadfile "scripts2/pb/ClientMsg.pb")

local MsgParser = {}

function MsgParser.msgname_2_1()
	return "HandShake"
end

function MsgParser.msgname_2_2()
	return "HandShakeRet"
end

function MsgParser.msgname_2_5()
	return "Auth"
end

function MsgParser.msgname_2_6()
	return "AuthRet"
end

function MsgParser.msgname_2_7()
	return "PlayerList"
end

function MsgParser.msgname_2_8()
	return "PlayerListRet"
end

function MsgParser.msgname_2_9()
	return "CreatePlayer"
end

function MsgParser.msgname_2_10()
	return "CreatePlayerRet"
end

function MsgParser.msgname_2_11()
	return "SelectPlayer"
end

function MsgParser.msgname_2_12()
	return "SelectPlayerRet"
end

function MsgParser.msgname_2_13()
	return "Login"
end

function MsgParser.msgname_2_14()
	return "LoginRet"
end

function MsgParser.msgname_3_2()
	return "LoadPlayerDataFinish"
end

function MsgParser.msgname_3_3()
	return "LoadMapFinish"
end

function MsgParser.msgname_3_3()
	return "PlayerMove"
end

function MsgParser.msgname_3_4()
	return "PlayerMoveRet"
end

function MsgParser.msgname_3_7()
	return "UpdataObjInfo"
end

function MsgParser.msgname_3_8()
	return "DelObjFromView"
end

function MsgParser.encode(mainid,subid,data)
	local funType = MsgParser["msgname_"..mainid.."_"..subid]
	assert(type(funType) == "function")
	return assert(pb.encode("netData."..funType(), data))
end

function MsgParser.decode(mainid,subid,data)
	local funType = MsgParser["msgname_"..mainid.."_"..subid]
	assert(type(funType) == "function","msgname_"..mainid.."_"..subid)
	return assert(pb.decode("netData."..funType(), data))
end

return MsgParser