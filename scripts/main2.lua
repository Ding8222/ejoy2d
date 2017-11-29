local ej = require "ejoy2d"
local fw = require "ejoy2d.framework"
local pack = require "ejoy2d.simplepackage"
local logic = require "scripts.logic"
local crypt = require"crypt"
local send_request = logic.send_request

logic.user = "hello2"
logic.name = "ding2"

local clientkey = crypt.randomkey()
logic.set_clientkey(clientkey)
send_request("handshake",{clientkey = crypt.base64encode(crypt.dhexchange(clientkey))})

local label
local me
local other = {}
local game = {}
local screencoord = { x = 512, y = 384, scale = 1.0 }

function logic.REQUEST.characterupdate(args)
	--print("characterupdate:")
	local temp = other[args.info.tempid]
	if temp then
		--对象存在
		temp:ps(args.info.pos.x,args.info.pos.y)
		temp.label.text = string.format(args.info.name.."\n"..args.info.tempid.."\n[%d,%d]", args.info.pos.x,args.info.pos.y)
	else
		--对象不存在
		other[args.info.tempid] = ej.sprite("sample","mine")
		other[args.info.tempid].resource.frame = 70
		other[args.info.tempid]:ps(args.info.pos.x,args.info.pos.y)
		other[args.info.tempid]:ps(1.2)
		other[args.info.tempid].label.text = string.format(args.info.name.."\n"..args.info.tempid.."\n[%d,%d]", args.info.pos.x,args.info.pos.y)
	end
end

function logic.REQUEST.characterleave(args)
	for _,v in pairs(args) do
		for _,vv in pairs(v) do
			other[vv] = nil
		end
	end
end

function logic.REQUEST.moveto(args)
	local move = args.move
	for _,v in pairs(move) do
		if other[v.tempid] then
			other[v.tempid]:ps(v.pos.x,v.pos.y)
		end
	end
end

function logic.RESPONSE:moveto(args)
	me:ps(args.pos.x,args.pos.y)
	--quitgame()
end

local function moveto(x,y)
	--print("send moveto：",x,y)
	local pos = {
		x = x,
		y = y,
		z = 0,
	}
	send_request("moveto",{ pos = pos })
end

pack.load {
	pattern = fw.WorkDir..[[examples/asset/?]],
	"sample",
}

me = ej.sprite("sample","cannon")
local turret = me.turret
me:ps(-100,0,0.5)


label = ej.sprite("sample","mine")
label.resource.frame = 70
label:ps(400,250)
label:ps(1.2)


function game.update()
	turret.frame = turret.frame + 10
	label.frame = label.frame + 2
	for k,v in pairs(other) do
		v.frame = v.frame + 2
	end
	logic.dispatch_message()
end

function game.drawframe()
	ej.clear(0xff808080)	-- clear (0.5,0.5,0.5,1) gray
	me:draw(screencoord)
	label:draw(screencoord)
	for k,v in pairs(other) do
		v:draw(screencoord)
	end
end

function getIntPart(x)
	if x <= 0 then
	   return math.ceil(x);
	end

	if math.ceil(x) == x then
	   x = math.ceil(x);
	else
	   x = math.ceil(x) - 1;
	end
	return x;
end

function game.touch(what, x, y)
	if what ~= "END" then
		label.label.text = string.format("%s\n[%d,%d]", what, (x - 512), (y - 384))
		moveto((x - 512), (y - 384))
	end
end

function game.message(...)
end

function game.handle_error(...)
end

function game.on_resume()
end

function game.on_pause()
end

ej.start(game)
