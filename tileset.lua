local tiles = {
	size = {16, 16},
	[0] = {
		image = "grass"
	},
	[1] = {
		image = "tiles",
		autotile = {
			XXXX = {1, 3},
			XXOO = {0, 0},
			XOOX = {1, 0},
			OOXX = {1, 1},
			OXXO = {0, 1},
			XOOO = {0, 2},
			OOXO = {0, 3},
			OXOO = {1, 2},
			OOOX = {2, 2},
			OXOOOOOO = {2, 0},
			XOOOOOOO = {3, 0},
			OOXOOOOO = {2, 1},
			OOOXOOOO = {3, 1},
			OOOO = {2, 3}
		},
		merge = {
			[1] = true
		}
	}
}

map = {
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0},
	{0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0},
	{0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0},
	{0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0},
	{0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0},
	{0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,1,0,0,0,0},
	{0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
	{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
}

local canv = love.graphics.newCanvas(#map[1] * tiles.size[1], #map * tiles.size[2])
local empty = {}

local offsets = {
	{1, -1},
	{-1, -1},
	{-1, 1},
	{1, 1},
	{0, -1},
	{-1, 0},
	{0, 1},
	{1, 0},
}

for k, v in pairs(tiles) do
	if type(k) == "number" then
		v.image = love.graphics.newImage(("assets/%s.png"):format(v.image))
		if v.autotile then
			for s, t in pairs(v.autotile) do
				v.autotile[s] = love.graphics.newQuad(t[1]*tiles.size[1], t[2]*tiles.size[2], 16, 16, v.image)
			end
		end
	end
end


--love.graphics.setBlendMode("alpha", "premultiplied")

canv:renderTo(function ()
	for i, r in ipairs(map) do
		for j, v in ipairs(r) do
			local t = tiles[v]
			print(v, t)
			if t.autotile then
				local str = ""
				for _, o in ipairs(offsets) do
					local ox, oy = unpack(o)
					str = str .. ((t.merge[(map[i+oy] or empty)[j+ox]]) and "O" or "X")
				end
				local q = t.autotile[str] or t.autotile[str:sub(5)]
				if q then
					love.graphics.draw(t.image, q, (j-1)*tiles.size[1], (i-1)*tiles.size[2])
				end
			else
				print(t.image)
				love.graphics.draw(t.image, (j-1)*tiles.size[1], (i-1)*tiles.size[2])
			end
		end
	end
end)

return canv

