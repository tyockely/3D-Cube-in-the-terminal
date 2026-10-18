local Vector3D = {}
Vector3D.__index = Vector3D

function Vector3D.new(x, y, z)
    return setmetatable({x = x or 0, y = y or 0, z = z or 0}, Vector3D)
end

function Vector3D:add(v)
    return Vector3D.new(self.x + v.x, self.y + v.y, self.z + v.z)
end

function Vector3D:sub(v)
    return Vector3D.new(self.x - v.x, self.y - v.y, self.z - v.z)
end

function Vector3D:rotateY(angle)
    local rad = math.rad(angle)
    local cosA = math.cos(rad)
    local sinA = math.sin(rad)
    local x = self.x * cosA + self.z * sinA
    local z = -self.x * sinA + self.z * cosA
    return Vector3D.new(x, self.y, z)
end

function Vector3D:rotateX(angle)
    local rad = math.rad(angle)
    local cosA = math.cos(rad)
    local sinA = math.sin(rad)
    local y = self.y * cosA - self.z * sinA
    local z = self.y * sinA + self.z * cosA
    return Vector3D.new(self.x, y, z)
end

function Vector3D:project(fov, distance)
    local factor = fov / (distance + self.z)
    local x = math.floor(self.x * factor + 40)
    local y = math.floor(self.y * factor + 12)
    return x, y
end

local Cube = {
    vertices = {
        Vector3D.new(-1, -1, -1),
        Vector3D.new(1, -1, -1),
        Vector3D.new(1, 1, -1),
        Vector3D.new(-1, 1, -1),
        Vector3D.new(-1, -1, 1),
        Vector3D.new(1, -1, 1),
        Vector3D.new(1, 1, 1),
        Vector3D.new(-1, 1, 1)
    },
    edges = {
        {1, 2}, {2, 3}, {3, 4}, {4, 1},
        {5, 6}, {6, 7}, {7, 8}, {8, 5},
        {1, 5}, {2, 6}, {3, 7}, {4, 8}
    }
}

local function clearCanvas()
    local canvas = {}
    for y = 1, 24 do
        canvas[y] = {}
        for x = 1, 80 do
            canvas[y][x] = " "
        end
    end
    return canvas
end

local function drawPoint(canvas, x, y, char)
    if x >= 1 and x <= 80 and y >= 1 and y <= 24 then
        canvas[y][x] = char
    end
end

local function drawLine(canvas, x0, y0, x1, y1, char)
    local dx = math.abs(x1 - x0)
    local dy = math.abs(y1 - y0)
    local sx = x0 < x1 and 1 or -1
    local sy = y0 < y1 and 1 or -1
    local err = dx - dy

    while true do
        drawPoint(canvas, x0, y0, char)
        if x0 == x1 and y0 == y1 then break end
        local e2 = 2 * err
        if e2 > -dy then
            err = err - dy
            x0 = x0 + sx
        end
        if e2 < dx then
            err = err + dx
            y0 = y0 + sy
        end
    end
end

local function renderCanvas(canvas)
    local lines = {}
    for y = 1, 24 do
        lines[y] = table.concat(canvas[y])
    end
    io.write("\27[H" .. table.concat(lines, "\n"))
end

local function sleep(n)
    local t0 = os.clock()
    while os.clock() - t0 < n do end
end

io.write("\27[2J\27[?25l")

local angleX = 0
local angleY = 0

for frame = 1, 150 do
    local canvas = clearCanvas()
    local projected = {}

    for i, v in ipairs(Cube.vertices) do
        local rotated = v:rotateX(angleX):rotateY(angleY)
        local px, py = rotated:project(60, 3.5)
        projected[i] = {x = px, y = py}
    end

    for _, edge in ipairs(Cube.edges) do
        local p1 = projected[edge[1]]
        local p2 = projected[edge[2]]
        drawLine(canvas, p1.x, p1.y, p2.x, p2.y, "#")
    end

    renderCanvas(canvas)

    angleX = (angleX + 3) % 360
    angleY = (angleY + 5) % 360

    sleep(0.03)
end

io.write("\27[?25h\nDone!\n")