local socket = require"mylib.lualib.socket"
local sprotoloader = require"mylib.lualib.sprotoloader"
local sprotoparser = require"mylib.lualib.sprotoparser"
local crypt = require"crypt"
require"mylib.lualib.luaext"

local logic = {}

------------加载解析proto文件--------------
local f = io.open("./mylib/proto/clientproto.lua")

if f == nil then
	print("proto open faild")
	return
end

local t = f:read "a"
f:close()

sprotoloader.save(sprotoparser.parse(t),0)

f = io.open("./mylib/proto/serverproto.lua")
if f == nil then
	print("proto open faild")
	return
end
t = f:read "a"
f:close()
sprotoloader.save(sprotoparser.parse(t),1)

--host用来解析接受到的消息
local host = sprotoloader.load(1):host "package"
--request用来发送消息
local request = host:attach(sprotoloader.load(0))

---------------------------------------------------

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

tcp = assert(socket.tcp())

assert(tcp:connect("127.0.0.1", 8101))

assert(tcp:settimeout(0))

local session = {}
local session_id = 0

local nIndex = 0
local function send_request(name, args)
	session_id = session_id + 1
	nIndex = nIndex + 1
	if nIndex > 255 then
		nIndex = 1
	end
	local str = request(name, args, session_id)
	local size = #str + 5
	local package = string.pack(">I2", size)..str..string.pack(">BI4", nIndex, session_id)
	tcp:send(package)
	session[session_id] = {name = name ,args = args}
end

local RESPONSE = {}
local clientkey
logic.RESPONSE = RESPONSE
logic.send_request = send_request
function logic.set_clientkey(key)
	clientkey = key
end
local challenge
local serverkey
local secret
function RESPONSE:handshake(args)
	challenge = crypt.base64decode(args.challenge)
	serverkey = crypt.base64decode(args.serverkey)

	--根据获取的serverkey 和 clientkey计算出secret
	assert(clientkey)
	secret = crypt.dhsecret(serverkey, clientkey)
	print("sceret is ", crypt.hexencode(secret))

	--回应服务器第一步握手的挑战码，确认握手正常。
	hmac = crypt.hmac64(challenge, secret)
	send_request("challenge",{hmac = crypt.base64encode(hmac)})
end

local token = {}

local function encode_token(token)
	return string.format("%s@%s:%s",
		crypt.base64encode(token.user),
		crypt.base64encode(token.server),
		crypt.base64encode(token.pass))
end

function RESPONSE:challenge(args)
	--使用DES算法，以secret做key，加密传输token串
	token = {
		server = "sample",
		user = logic.user,
		pass = "password",
	}
	local etoken = crypt.desencode(secret, encode_token(token))
	send_request("auth",{etokens = crypt.base64encode(etoken)})
end

local subid
local index = 1

local function login()
	--连接到gameserver
	tcp = assert(socket.tcp())
	assert(tcp:connect("127.0.0.1", 8547))
	tcp:settimeout(0)
	local handshake = string.format("%s@%s#%s:%d", crypt.base64encode(token.user), crypt.base64encode(token.server),crypt.base64encode(subid) , index)
	local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)
	send_request("login",{handshake = handshake .. ":" .. crypt.base64encode(hmac)})
end

local function getcharacterlist()
	print("send getcharacterlist")
	send_request("getcharacterlist")
end

local function charactercreate()
	print("send charactercreate")
	local character_create = {
		name = logic.name,
		job = 1,
		sex = 1,
	}
	send_request("charactercreate",character_create)
end

local function characterpick(uuid)
	print("send characterpick :"..uuid)
	send_request("characterpick",{uuid = uuid})
end

local function mapready()
	print("send mapready")
	send_request("mapready")
end

local function moveto()
	print("send moveto")
	local pos = {
		x = 1,
		y = 2,
		z = 3,
	}
	send_request("moveto",{ pos = pos })
end

local function quitgame()
	send_request("quitgame")
end

function RESPONSE:login(args)
	send_request("ping",{userid = "hahaha"})
end

function RESPONSE:ping( args )
	index = index + 1
	if index > 3 then
		getcharacterlist()
		return
	end
	--断开连接
	tcp:close()
	--再次连接到gameserver
	login()
end

function RESPONSE:getcharacterlist(args)
	print("getcharacterlist size:"..table.size(args.character))
	if(table.size(args.character) < 1) then
			charactercreate()
	else
		local uuid = 0
		local bpick = false
		for k,v in pairs(args.character)do
			print(v.name)
			if v.name == logic.name then
				uuid = k
				characterpick(uuid)
				bpick = true
				break
			end
		end
		if not bpick then
				charactercreate()
		end
	end
end


function RESPONSE:charactercreate(args)
	print("charactercreate:")
	getcharacterlist()
end

function RESPONSE:characterpick(args)
	print("characterpick:")
	print(args.ok)
	mapready()
end

function RESPONSE:mapready(args)
	print("mapready:")
	print(args.ok)
	moveto()
end

function RESPONSE:quitgame(args)
	print("quitgame:")
	print(args.ok)
end

local REQUEST = {}
logic.REQUEST = REQUEST
function REQUEST.subid(args)
	print("subid")
	--收到服务器发来的确认信息
	local result = args.result
	local code = tonumber(string.sub(result, 1, 3))
	--当确认成功的时候，断开与服务器的连接
	assert(code == 200)
	tcp:close()

	--通过确认信息获取subid
	subid = crypt.base64decode(string.sub(result, 5))

	print("login ok, subid=", subid)

	login()
end

function REQUEST.heartbeat()
	print("===heartbeat===")
end

function REQUEST.delaytest(args)
	print("delaytest:"..args.time)
	--print(args)
	return {time = args.time}
end

function REQUEST.delayresult(args)
	print("delayresult:"..args.time)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end
	return text:sub(3,2+s), text:sub(3+s)
end

local last = ""

local function unpack_f(f)
	local function try_recv(last)
		local result
		result, last = f(last)
		if result then
			return result, last
		end
		local r,e = tcp:receive(2)
		if not r then
			return nil, last
		else
			local size = r:byte(1) * 256 + r:byte(2)
			r = r..tcp:receive(size)
		end
		if r == "" then
			error "Server closed"
		end
		return f(last .. r)
	end

	--每秒尝试接受来自服务器的消息
	return function()
		--while true do
			local result
			result, last = try_recv(last)
			if result then
				return result
			end
			--socket.sleep(10)
		--end
	end
end

local readpackage = unpack_f(unpack_package)

local function recv_response(v)
	local size = #v - 5
	local content, ok, session = string.unpack("c"..tostring(size).."B>I4", v)
	return ok ~=0 , content, session
end

function logic.dispatch_message()
	while true do
		local str = readpackage()
		if str ~= nil then
			local ok , content, sessionid = recv_response(str)
			assert(ok)
			local type, id, args, response = host:dispatch(content)
			if type == "RESPONSE" then
				assert(id == sessionid,"session err! id:"..id.." session:"..sessionid)
				local s = assert(session[id])
				session[id] = nil
				local f = RESPONSE[s.name]
				if f then
					f (s.args, args)
				else
					print "response"
				end
			elseif type == "REQUEST" then
				local f = REQUEST[id]
				if f then
					local r = f(args)
					if r and response then
						local str = response(r)
						local size = #str + 5
						nIndex = nIndex + 1
						if nIndex > 255 then
							nIndex = 1
						end
						local package = string.pack(">I2", size)..str..string.pack(">BI4", nIndex, sessionid)
						tcp:send(package)
					end
				else
					print "response"
				end
			end
		else
			break
		end
	end
end

return logic
