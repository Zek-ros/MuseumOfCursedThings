-- ExpeditionBuilder.lua (ModuleScript)
-- Generates a PROCEDURAL maze for each expedition — a different layout every
-- server start, built entirely from primitives so it needs no bespoke art.
-- The space is intentionally dark and lightless: the only light comes from the
-- player's flashlight (client-side), the green extraction pad, the faint glow
-- of artifacts, and monster eyes. `def` supplies Width/Height in cells
-- (see ExpeditionMaps). Returns { Model, SpawnCFrame, ExtractionZone,
-- SpawnPoints = {CFrame...}, HalfX, HalfZ }.

local ExpeditionBuilder = {}

local CELL        = 16   -- studs per maze cell (wide enough to run through)
local WALL_HEIGHT = 18
local WALL_THICK  = 1
local BRAID       = 0.16 -- chance an internal wall is dropped → loops/shortcuts

-- One dark palette for every map; atmosphere comes from lighting, not themes.
local FLOOR_COLOR = Color3.fromRGB(24, 24, 30)
local WALL_COLOR  = Color3.fromRGB(34, 32, 42)
local CRATE_COLOR = Color3.fromRGB(60, 50, 38)

local function makePart(origin, parent, name, size, localPos, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = origin * CFrame.new(localPos)
	part.Color = color
	part.Material = material
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

--- Carve a maze with an iterative recursive-backtracker. Returns two grids of
--- open passages: openE[c][r] = passage to the cell to the east of (c,r);
--- openS[c][r] = passage to the cell to the south. This is a spanning tree, so
--- every cell is reachable (artifacts and extraction can never be sealed off).
local function carveMaze(W: number, H: number)
	local visited, openE, openS = {}, {}, {}
	for c = 1, W do
		visited[c], openE[c], openS[c] = {}, {}, {}
	end

	local stack = { { 1, 1 } }
	visited[1][1] = true
	while #stack > 0 do
		local cell = stack[#stack]
		local c, r = cell[1], cell[2]

		local nbrs = {}
		if c > 1 and not visited[c - 1][r] then table.insert(nbrs, { c - 1, r, "W" }) end
		if c < W and not visited[c + 1][r] then table.insert(nbrs, { c + 1, r, "E" }) end
		if r > 1 and not visited[c][r - 1] then table.insert(nbrs, { c, r - 1, "N" }) end
		if r < H and not visited[c][r + 1] then table.insert(nbrs, { c, r + 1, "S" }) end

		if #nbrs == 0 then
			table.remove(stack)
		else
			local n = nbrs[math.random(#nbrs)]
			local nc, nr, dir = n[1], n[2], n[3]
			if dir == "E" then
				openE[c][r] = true
			elseif dir == "W" then
				openE[nc][nr] = true
			elseif dir == "S" then
				openS[c][r] = true
			else -- "N"
				openS[nc][nr] = true
			end
			visited[nc][nr] = true
			table.insert(stack, { nc, nr })
		end
	end

	return openE, openS
end

--- Build the procedural maze at `origin` (center of the floor top).
function ExpeditionBuilder.Build(origin: CFrame, def)
	local W = (def and def.Width) or 6
	local H = (def and def.Height) or 5
	local roomX, roomZ = W * CELL, H * CELL
	local halfX, halfZ = roomX / 2, roomZ / 2
	local wallY = WALL_HEIGHT / 2

	local model = Instance.new("Model")
	model.Name = "ExpeditionMap_" .. ((def and def.Id) or "maze")

	-- Per-maze look (falls back to the default dark palette).
	local floorColor = (def and def.Floor) or FLOOR_COLOR
	local wallColor = (def and def.Wall) or WALL_COLOR
	local crateColor = (def and def.Crate) or CRATE_COLOR
	local wallMat = (def and def.WallMaterial) or Enum.Material.Concrete

	-- Local center of cell (c, r): c = 1..W along X, r = 1..H along Z.
	local function cellPos(c: number, r: number): Vector3
		return Vector3.new((c - 0.5) * CELL - halfX, 0, (r - 0.5) * CELL - halfZ)
	end

	-- Floor + roof (the roof keeps skylight out so it stays dark inside)
	makePart(origin, model, "Floor", Vector3.new(roomX, WALL_THICK, roomZ),
		Vector3.new(0, -WALL_THICK / 2, 0), floorColor, Enum.Material.Concrete)
	makePart(origin, model, "Ceiling", Vector3.new(roomX, WALL_THICK, roomZ),
		Vector3.new(0, WALL_HEIGHT + WALL_THICK / 2, 0), wallColor, wallMat)

	-- Outer walls
	makePart(origin, model, "WallBack", Vector3.new(roomX, WALL_HEIGHT, WALL_THICK),
		Vector3.new(0, wallY, -halfZ), wallColor, wallMat)
	makePart(origin, model, "WallFront", Vector3.new(roomX, WALL_HEIGHT, WALL_THICK),
		Vector3.new(0, wallY, halfZ), wallColor, wallMat)
	makePart(origin, model, "WallLeft", Vector3.new(WALL_THICK, WALL_HEIGHT, roomZ),
		Vector3.new(-halfX, wallY, 0), wallColor, wallMat)
	makePart(origin, model, "WallRight", Vector3.new(WALL_THICK, WALL_HEIGHT, roomZ),
		Vector3.new(halfX, wallY, 0), wallColor, wallMat)

	-- Internal maze walls (braided so there are loops, not a single dead path)
	local openE, openS = carveMaze(W, H)
	for c = 1, W do
		for r = 1, H do
			local p = cellPos(c, r)
			if c < W and not openE[c][r] and math.random() > BRAID then
				makePart(origin, model, "MazeWall", Vector3.new(WALL_THICK, WALL_HEIGHT, CELL),
					Vector3.new(p.X + CELL / 2, wallY, p.Z), wallColor, wallMat)
			end
			if r < H and not openS[c][r] and math.random() > BRAID then
				makePart(origin, model, "MazeWall", Vector3.new(CELL + WALL_THICK, WALL_HEIGHT, WALL_THICK),
					Vector3.new(p.X, wallY, p.Z + CELL / 2), wallColor, wallMat)
			end
		end
	end

	-- Entrance cell at the front-center: you arrive on the extraction pad and
	-- must head into the dark to find artifacts, then return here to extract.
	local entranceC = math.ceil(W / 2)
	local entrance = cellPos(entranceC, H)
	local spawnCFrame = origin * CFrame.new(entrance.X, 4, entrance.Z)

	-- Extraction pad: the one bright landmark — it also lights your way home.
	local extraction = Instance.new("Part")
	extraction.Name = "ExtractionZone"
	extraction.Anchored = true
	extraction.CanCollide = false
	extraction.Size = Vector3.new(CELL - 3, 1, CELL - 3)
	extraction.CFrame = origin * CFrame.new(entrance.X, 0.5, entrance.Z)
	extraction.Color = Color3.fromRGB(60, 230, 120)
	extraction.Material = Enum.Material.Neon
	extraction.Transparency = 0.35
	local exLight = Instance.new("PointLight")
	exLight.Color = Color3.fromRGB(80, 255, 140)
	exLight.Range = 26
	exLight.Brightness = 5
	exLight.Parent = extraction
	local exBillboard = Instance.new("BillboardGui")
	exBillboard.Size = UDim2.new(0, 220, 0, 50)
	exBillboard.StudsOffset = Vector3.new(0, 5, 0)
	exBillboard.AlwaysOnTop = false
	exBillboard.MaxDistance = 90
	local exLabel = Instance.new("TextLabel")
	exLabel.Size = UDim2.fromScale(1, 1)
	exLabel.BackgroundTransparency = 1
	exLabel.Text = "▼ EXTRACTION ▼"
	exLabel.TextColor3 = Color3.fromRGB(120, 255, 170)
	exLabel.Font = Enum.Font.GothamBold
	exLabel.TextScaled = true
	exLabel.Parent = exBillboard
	exBillboard.Parent = extraction
	extraction.Parent = model

	-- All non-entrance cells, shuffled — split between the artifact pool and crates.
	local cells = {}
	for c = 1, W do
		for r = 1, H do
			if not (c == entranceC and r == H) then
				table.insert(cells, { c, r })
			end
		end
	end
	for i = #cells, 2, -1 do
		local j = math.random(i)
		cells[i], cells[j] = cells[j], cells[i]
	end

	-- Artifact spawn pool: random cells, low to the floor, deep in the dark maze.
	-- Scales with maze size so bigger mazes spread loot over more possible spots
	-- (more searching) without flooding the place.
	local poolCount = math.clamp(math.floor(#cells / 7), 12, 32)
	poolCount = math.min(poolCount, #cells)
	local spawnPoints = {}
	for i = 1, poolCount do
		local p = cellPos(cells[i][1], cells[i][2])
		table.insert(spawnPoints, origin * CFrame.new(p.X, 2.4, p.Z))
	end

	-- Crates for cover, in cells the artifacts don't use (disjoint, so nothing
	-- spawns inside a crate). More cover in bigger mazes.
	local crateCount = math.clamp(math.floor(#cells / 11), 5, 20)
	crateCount = math.min(crateCount, #cells - poolCount)
	for i = 1, crateCount do
		local cell = cells[poolCount + i]
		local p = cellPos(cell[1], cell[2])
		makePart(origin, model, "Crate", Vector3.new(4, 4, 4),
			Vector3.new(p.X + math.random(-3, 3), 2, p.Z + math.random(-3, 3)), crateColor, Enum.Material.WoodPlanks)
	end

	return {
		Model = model,
		SpawnCFrame = spawnCFrame,
		ExtractionZone = extraction,
		SpawnPoints = spawnPoints,
		HalfX = halfX,
		HalfZ = halfZ,
	}
end

return ExpeditionBuilder
