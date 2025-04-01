love.graphics.setDefaultFilter("nearest", "nearest")

love.graphics.setFont(love.graphics.newFont("assets/skewpixel.ttf", 5))

local tiles = require "tileset"

local treeShader = love.graphics.newShader("assets/treeSnow.glsl")

local propKey = {
	_0_1_0_1 = {image = love.graphics.newImage("assets/tree.png"), offsetX = -8, offsetY = -48, collider = {l = 0, r = 16, t = -17, b = 8}, shader = treeShader},
	_0_0_0_1 = {image = love.graphics.newImage("assets/truck.png"), offsetY = -16, collider = {l = 28, r = 64, t = 0, b = 2}},
	_0_0_1_1 = {image = love.graphics.newImage("assets/truck_overlay.png"), offsetY = -48, collider = {l = 32, r = 64, t = -20, b = 16}},
	_1_1_1_1 = {image = love.graphics.newCanvas(1,1), collider = {l = 0, r = 32, t = 0, b = 16}}
}

local propmap = love.image.newImageData("assets/props.png")
local propmapTex = love.graphics.newImage(propmap)

local function _draw(self)
	love.graphics.setShader(self.prop.shader)
	love.graphics.draw(self.prop.image, (self.prop.offsetX or 0) + self.x, (self.prop.offsetY or 0) + self.y)
end

local props = {}

local function instantiateProp(prop, x, y)
	local ret = {prop = prop, x = x, y = y, draw = _draw}
	table.insert(props, ret)
	return ret
end

local shader = love.graphics.newShader("assets/water.glsl")
local waterTex = love.graphics.newImage("assets/waterNoise.png")
waterTex:setWrap("repeat", "repeat")

local snowNoise = love.graphics.newImage("assets/snowNoise.png")
propKey._0_1_0_1.shader:send("noise", snowNoise)

local grassShader = love.graphics.newShader("assets/grass.glsl")
grassShader:send("noise", snowNoise)

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
		love.graphics.setShader()
		self._quad:setViewport(self.facing * 16 + (self.duck and 64 or 0), math.floor(self.frame) * 24, 16, 24)
		love.graphics.draw(self.image, self._quad, self.x-8, self.y-(self.frame >= 4 and 9 or 12))
	end,
	iceHold = 0,
	prop = {}
}
player._quad = love.graphics.newQuad(0, 0, 16, 24, player.image)

local ducks = {}
function createDuck(x, y)
	local ret = {
		x = x,
		y = y,
		facing = 3,
		frame = 0,
		stateTimer = 0,
		moving = false,
		image = love.graphics.newImage("assets/duck.png"),
		flyIn = 1,
		draw = function (self)
			love.graphics.setShader()
			self._quad:setViewport(self.facing * 12, self.frame * 12, 12, 12)
			love.graphics.draw(self.image, self._quad, self.x-6 - self.flyIn * 200, self.y - self.flyIn * 200)
		end,
		prop = {}
	}
	ret._quad = love.graphics.newQuad(0, 0, 12, 12, ret.image)

	table.insert(ducks, ret)
	table.insert(props, ret)
	return ret
end

local ice = {

}

local function getIce(x, y)
	return ice[math.floor(x)..","..math.floor(y)]
end

local function createIce(x, y)
	if map[y+1][x+1] ~= 1 or getIce(x, y)then
		return
	end
	ice[x..","..y] = {x = x, y = y}
end

table.insert(props, player)

local t = 89

for i = 1, 10 do
createDuck(math.random(100, 220), math.random(80, 160))
end

function collide(px, py, x, y, c, cx, cy)
	local l, r, t, b = c.l + cx, c.r + cx, c.t + cy, c.b + cy
	l = l - 4
	r = r + 4
	local hit = false
	if px < r and px > l then
		if py >= b and py + y < b then
			py = b
			y = 0
			hit = true
		end
		if py <= t and py + y > t then
			py = t
			y = 0
			hit = true
		end
	elseif py < b and py > t then
		if px >= r and px + x < r then
			px = r
			x = 0
			hit = true
		end
		if px <= l and px + x > l then
			px = l
			x = 0
			hit = true
		end
	end
	return px, py, x, y, hit
end

local iceCol = {
	l=0,
	r=16,
	t=-10,
	b=8,
}

local score = 15

function love.update(dt)
	t = t + dt
	if t > 90 then
		return
	end
	local vx = (love.keyboard.isDown("right") and 1 or 0) - (love.keyboard.isDown("left") and 1 or 0)
	local vy = (love.keyboard.isDown("down") and 1 or 0) - (love.keyboard.isDown("up") and 1 or 0)
	local speed = 60
	if vy > 0 then
		player.facing = 0
	elseif vy < 0 then
		player.facing = 2
	elseif vx > 0 then
		player.facing = 3
	elseif vx < 0 then
		player.facing = 1
	end
	if vy ~= 0 or vx ~= 0 then
		player.frame = (player.frame + dt * 8) % 4
	else
		player.frame = 0
	end
	if getIce(player.x/16, player.y/16+0.5) then
		print("on ice")
		vx = player.vx
		vy = player.vy
		player.iceHold = 0
	else
		player.vx = vx
		player.vy = vy
		if  map[math.floor(player.y / 16 + 1.0)][math.floor(player.x / 16 + 0.5)] == 1 and
			map[math.floor(player.y / 16 + 1.0)][math.floor(player.x / 16 + 1.5)] == 1 and
			map[math.floor(player.y / 16 + 2.0)][math.floor(player.x / 16 + 1.5)] == 1 and
			map[math.floor(player.y / 16 + 2.0)][math.floor(player.x / 16 + 0.5)] == 1 then
			player.frame = player.frame + 4
			speed = 45
			if player.iceHold < 1 then
				local hitIce = false
				for _, v in pairs(ice) do
					player.x, player.y, vx, vy, hit = collide(player.x, player.y, vx, vy, iceCol, v.x*16, v.y*16)
					hitIce = hitIce or hit
				end
				if hitIce then
					player.iceHold = player.iceHold + dt
				else
					player.iceHold = 0
				end
			end
		end
	end
	for _, v in ipairs(props) do
		local col = v.prop.collider
		if col then
			player.x, player.y, vx, vy = collide(player.x, player.y, vx, vy, col, v.x, v.y)
		end
	end
	player.x = player.x + vx * dt * speed
	player.y = player.y + vy * dt * speed

	for i, duck in ipairs(ducks) do
		if duck.flyIn < 0.01 then
			duck.flyIn = 0
			if duck ~= player.duck then
				duck.frame = 0
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
					local dx = ({0,-1, 0, 1})[duck.facing+1]
					local dy = ({1, 0,-1, 0})[duck.facing+1]
					print("duck check")
					print(math.floor(duck.x/16+0.5+dx*0.5), math.floor(duck.y/16+0.5+dy*0.5))
					if map[math.floor(duck.y/16+1.5+dy*0.5)][math.floor(duck.x/16+1+dx*0.5)] ~= 1 or
						getIce(duck.x/16+dx*0.5, duck.y/16+0.5+dy*0.5) then
						duck.stateTimer = 0
						print("duck hit something")
					else
						duck.x = duck.x + dx * dt * 30
						duck.y = duck.y + dy * dt * 30
					end
				end
				if not player.duck and math.sqrt((duck.x-player.x)^2 + (duck.y-player.y)^2) < 4 then
					player.duck = duck
				end
			end
		else
			duck.frame = 1
			duck.flyIn = duck.flyIn * 0.99
		end
	end

	if player.duck then
		local dx = ({0,-1, 0, 1})[player.facing+1]
		local dy = ({1, 0,-1, 0})[player.facing+1]
		player.duck.x = player.x + dx * 6
		player.duck.y = player.y + dy * 6 - 1
		player.duck.facing = player.facing
		player.duck.frame = 1

		if player.duck.x > 288 and player.duck.y > 112 then
			for i, v in ipairs(ducks) do
				if player.duck == v then
					table.remove(ducks, i)
					break
				end
			end
			for i, v in ipairs(props) do
				if player.duck == v then
					table.remove(props, i)
					break
				end
			end
			player.duck = nil
			score = score + 1
			createDuck(math.random(100, 220), math.random(80, 160))
		end
	end

	for i, v in pairs(ice) do
		if math.random() < dt * t / 120 then
			local d = math.random(1, 4)
			local dx = ({0,-1, 0, 1})[d]
			local dy = ({1, 0,-1, 0})[d]
			createIce(v.x + dx, v.y + dy)
		end
	end
end

local iceTexture = love.graphics.newImage("assets/ice.png")
for i = 14, 20 do
end
createIce(14, 10)
createIce(6, 4)

local duckIcon = love.graphics.newImage("assets/duckIcon.png")

function love.draw()

	shader:send("time", t)
	propKey._0_1_0_1.shader:send("time", t/60)
	grassShader:send("time", t/60)
	local w, h = love.graphics.getDimensions()
	local s = math.min(w/20/16, h/15/16)
	local mat = love.math.newTransform(w/2, 0, 0, s)
	mat:translate(-160, 0)
	do
		local a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p = mat:inverse():getMatrix()
		local v = {{a,b,c,d},{e,f,g,h},{i,j,k,l},{m,n,o,p}}
		propKey._0_1_0_1.shader:send("transform", v)
		grassShader:send("transform", v)
	end

	love.graphics.replaceTransform(mat)
	love.graphics.stencil(function () love.graphics.rectangle("fill", 0, 0, 20*16, 15*16) end)
	love.graphics.setStencilTest("equal", 1)
	love.graphics.setShader(shader)
	love.graphics.draw(waterTex, 0, 0)
	love.graphics.setShader(grassShader)
	love.graphics.draw(tiles, 0, 0)
	love.graphics.setShader()
	table.sort(props, function(a, b) return a.y < b.y end)
	for k, v in pairs(ice) do
		love.graphics.draw(iceTexture, v.x*16, v.y*16)
	end
	for k, v in ipairs(props) do
		v:draw()
	end

	love.graphics.setShader()
	if t < 90 then
		love.graphics.draw(duckIcon)
		love.graphics.print(" "..score, 12, 4)
	else
		love.graphics.setColor(0, 0, 0, 0.9)
		love.graphics.rectangle("fill", 0, 0, 320, 240)
	love.graphics.setColor(1, 1, 1)
	end
	if t > 91 then
		love.graphics.print("GAME OVER", 78, 80, 0, 4, 4)
	end
	if t > 92 then
		love.graphics.print("*"..math.min(math.floor((t-92) * 10), score), 160, 120, 0, 2, 2)
		love.graphics.draw(duckIcon, 144, 120)
	end
	if t > 93 + score / 10 then
		love.graphics.print("HIGH: "..999, 120, 135, 0, 2, 2)
	end
end
