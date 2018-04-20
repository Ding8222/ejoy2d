local socket = require"mylib.lualib.socket"
local handler = require "scripts2.handler"
local crypt = require"crypt"

local logic
local REQUEST = {}
local RESPONSE = {}

local _handler = handler.new (REQUEST,RESPONSE)

_handler:init (function (l)
	logic = l
end)

_handler:release (function ()
	logic = nil
end)

local account = "Ding"
local clientkey = crypt.randomkey()
local challenge

function REQUEST.HandShake()
	local HandShake = { 
	   sClientKey = clientkey,
	}
	logic.send_request(HandShake,2,1)
end

function REQUEST.Auth()
	local Auth = { 
	   Account = account,
	   Secret = clientkey
	}
	logic.send_request(Auth,2,5)
end

function REQUEST.PlayerList()
	local PlayerList = {
	
	}
	
	logic.send_request(PlayerList,2,9)
end

function REQUEST.CreatePlayer()
	local CreatePlayer = { 
	   sName = "Ding",
	   nJob = 1,
	   nSex = 1,
	}
	
	logic.send_request(CreatePlayer,2,11)
end

function REQUEST.SelectPlayer(guid)
	local SelectPlayer = { 
	   nGuid = guid
	}
	
	logic.send_request(SelectPlayer,2,13)
end

function REQUEST.Login()
	local Login = { 
	   Account = account,
	   Secret = challenge,
	}
	
	logic.send_request(Login,2,7)
end

------------------------------------------------
function RESPONSE.HandShakeRet(args)
	if args.nCode == 1 then
		challenge = args.sChallenge
		REQUEST.Auth()
	end
end

function RESPONSE.AuthRet(args)
	if args.nCode == 1 then
		REQUEST.PlayerList()
	end
end

function RESPONSE.PlayerListRet(args)
	if table.size(args) == 0 then
		REQUEST.CreatePlayer()
	else
		REQUEST.SelectPlayer(args.list[1].nGuid)
	end
end

function RESPONSE.CreatePlayerRet(args)
	if args.nCode == 1 then
		REQUEST.SelectPlayer(args.Info.nGuid)
	end
end

function RESPONSE.SelectPlayerRet(args)
	if args.nCode == 1 then
		tcp = assert(socket.tcp())
		assert(tcp:connect(args.sIP, args.nPort))
		tcp:settimeout(0)
		REQUEST.Login()
	end
end

function RESPONSE.LoginRet(args)
	logic.nTempID = args.nTempID
end

return _handler
