local ej = require "ejoy2d"
local fw = require "ejoy2d.framework"
local pack = require "ejoy2d.simplepackage"
local logic = require "scripts2.logic"
local crypt = require"crypt"

local send_request = logic.send_request

logic.user = "hello"
logic.name = "ding"

local label
local me
local other = {}
local game = {}
local screencoord = { x = 512, y = 384, scale = 1.0 }

function logic.RESPONSE.PlayerMoveRet(args)
	if args.nTempID == logic.nTempID then
		me:ps(args.x,args.y)
	else
		--other[args.nTempID]:ps(args.x,args.y)
	end
end

local function moveto(x,y)
	local PlayerMove = {
		x = x,
		y = y,
		z = 1,
	}
	send_request(PlayerMove,3,3)
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
