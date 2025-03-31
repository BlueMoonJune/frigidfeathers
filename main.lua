love.graphics.setDefaultFilter("nearest", "nearest")

tiles = require "tileset"

local propKey = {
	_0_1_0_1 = { image = love.graphics.newImage("assets/tree.png"), offsetX = -8, offsetY = -48, collider = {l = 0, r = 16, t = -16, b = 8} },
	_0_0_0_1 = { image = love.graphics.newImage("assets/truck.png"), offsetY = -16, collider = {l = 28, r = 64, t = 0, b = 2}},
	_0_0_1_1 = { image = love.graphics.newImage("assets/truck_overlay.png"), offsetY = -48, collider = {l = 32, r = 64, t = -20, b = 16}},
}

local propmap = love.image.newImageData("assets/props.png")
local propmapTex = love.graphics.newImage(propmap)

local function _draw(self)
	love.graphics.draw(self.prop.image, (self.prop.offsetX or 0) + self.x, (self.prop.offsetY or 0) + self.y)
end

local props = {}

local function instantiateProp(prop, x, y)
	local ret = {prop = prop, x = x, y = y, draw = _draw}
	table.insert(props, ret)
	return ret
end

local shader = love.graphics.newShader("assets/water.glsl")
local waterTex = love.graphics.newImage("assets/noise.png")
waterTex:setWrap("repeat", "repeat")

shader:send("speeds"
	,{0.01, 0.01, 2, 1}
	,{-0.02, -0.02, 4, 1}
)
shader:send("texCount", 2)

for i = 0, propmap:getHeight() - 1 do
	for j = 0, propmap:getWidth() - 1 do
		local prop = propKey[("_%d_%d_%d_%d"):format(propmap:getPixel(j, i))]
		if prop then
			instantiateProp(prop, j * 16, i * 16)
		end
	end
end

local player = {
	x = 256,
	y = 64,
	facing = 0,
	frame = 0,
	image = love.graphics.newImage("assets/player.png"),
	draw = function (self)
		self._quad:setViewport(self.facing * 16, math.floor(self.frame) * 24, 16, 24)
		love.graphics.draw(self.image, self._quad, self.x-8, self.y-(self.frame >= 4 and 9 or 12))
	end,
	prop = {}
}
player._quad = love.graphics.newQuad(0, 0, 16, 24, player.image)

local ducks = {}
function createDuck(x, y)
	local ret = {
		x = x,
		y = y,
		facing = 0,
		stateTimer = 0,
		moving = false,
		image = love.graphics.newImage("assets/duck.png"),
		draw = function (self)
			self._quad:setViewport(self.facing * 12, 0, 12, 12)
			love.graphics.draw(self.image, self._quad, self.x-6, self.y)
		end,
		prop = {}
	}
	ret._quad = love.graphics.newQuad(0, 0, 12, 12, ret.image)

	table.insert(ducks, ret)
	table.insert(props, ret)
	return ret
end

table.insert(props, player)

local t = 0

for i = 1, 100 do
createDuck(160, 120)
end

function collide(px, py, x, y, c, cx, cy)
	local l, r, t, b = c.l + cx, c.r + cx, c.t + cy, c.b + cy
	l = l - 4
	r = r + 4
	if px < r and px > l then
		if py >= b and py + y < b then
			py = b
			y = 0
		end
		if py <= t and py + y > t then
			py = t
			y = 0
		end
	elseif py < b and py > t then
		if px >= r and px + x < r then
			px = r
			x = 0
		end
		if px <= l and px + x > l then
			px = l
			x = 0
		end
	end
	return px, py, x, y
end

function love.update(dt)
	t = t + dt
	local vx = (love.keyboard.isDown("right") and 1 or 0) - (love.keyboard.isDown("left") and 1 or 0)
	local vy = (love.keyboard.isDown("down") and 1 or 0) - (love.keyboard.isDown("up") and 1 or 0)
	local speed = 60
	if vy > 0 then
		player.facing = 0
	elseif vy < 0 then
		player.facing = 2
	elseif vx > 0 then
		player.facing = 1
	elseif vx < 0 then
		player.facing = 3
	end
	if vy ~= 0 or vx ~= 0 then
		player.frame = (player.frame + dt * 8) % 4
	else
		player.frame = 0
	end
	if  map[math.floor(player.y / 16 + 1.0)][math.floor(player.x / 16 + 0.5)] == 1 and
		map[math.floor(player.y / 16 + 1.0)][math.floor(player.x / 16 + 1.5)] == 1 and
		map[math.floor(player.y / 16 + 2.0)][math.floor(player.x / 16 + 1.5)] == 1 and
		map[math.floor(player.y / 16 + 2.0)][math.floor(player.x / 16 + 0.5)] == 1 then
		player.frame = player.frame + 4
		speed = 45
	end
	for _, v in ipairs(props) do
		local col = v.prop.collider
		if col then
			print(col)
			player.x, player.y, vx, vy = collide(player.x, player.y, vx, vy, col, v.x, v.y)
		end
	end
	player.x = player.x + vx * dt * speed
	player.y = player.y + vy * dt * speed

	for _, duck in ipairs(ducks) do
		duck.stateTimer = duck.stateTimer - dt
		if duck.stateTimer <= 0 then
			duck.stateTimer = math.random() * (duck.moving and 1 or 2)
			if duck.moving then
				duck.moving = false
			else
				duck.moving = true
				duck.facing = math.random(0, 3)
			end
		end
		if duck.moving then
			local dx = ({0, -1, 0, 1})[duck.facing+1]
			local dy = ({1, 0, -1, 0})[duck.facing+1]
			if map[math.floor(duck.y/16)+1+dy][math.floor(duck.x/16+0.5)+dx] == 0 then
				duck.stateTimer = 0
			else
				duck.x = duck.x + dx * dt * 30
				duck.y = duck.y + dy * dt * 30
			end
		end
	end

end

function love.draw()

	shader:send("time", t)
	local w, h = love.graphics.getDimensions()
	local s = math.min(w/20/16, h/15/16)
	love.graphics.translate(w/2, 0)
	love.graphics.scale(s, s)
	love.graphics.translate(-20*8, 0)
	love.graphics.stencil(function () love.graphics.rectangle("fill", 0, 0, 20*16, 15*16) end)
	love.graphics.setStencilTest("equal", 1)
	love.graphics.setShader(shader)
	love.graphics.draw(waterTex, 0, 0)
	love.graphics.setShader()
	love.graphics.draw(tiles, 0, 0)
	table.sort(props, function(a, b) return a.y < b.y end)
	for k, v in ipairs(props) do
		v:draw()
	end
end
