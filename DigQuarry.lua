function SmartDig(dir)
    dir = dir or "Forward"

    if dir == "Forward" then
        local has_block, info = turtle.inspect()
        if not has_block then
            return false
        end
        turtle.dig()
    elseif dir == "Down" then
        local has_block, info = turtle.inspectDown()
        turtle.digDown()
    elseif dir == "Up" then
        local has_block, info = turtle.inspectUp()
        turtle.digUp()
    end

    local pickup_time = os.startTimer(0.5)
    while true do
        local event, id = os.pullEvent()
        if event == "turtle_inventory" then
            return true
        elseif event == "timer" and id == pickup_time then
            print("Inventory Full...")
            return false
        end
    end
end

function Locate(timeout)
    timeout = timeout or 5
    return gps.locate(timeout, false)
end

function Refuel(state)
    local first_empty = 0
    local selected = 1
    turtle.select(selected)

    while state.fuel < 1000 do
        print("Refueling...")
        if first_empty == 0 then
            if turtle.getItemCount(selected) == 0 then
                first_empty = selected
            end
        end

        if not turtle.refuel(1) then
            if selected < 16 then
                selected = selected + 1
                turtle.select(selected)
            elseif state.fuel < 256 then
                print("Out of fuel! Coming home!")
                return false
            elseif state.fuel > 256 then
                return true
            end
        else
            print("Refueling!")
            state.fuel = turtle.getFuelLevel()
        end
    end
    turtle.select(first_empty)
    return true
end

function CheckDirection(state)
    state.x, state.y, state.z = Locate()
    local has_block = turtle.inspect()
    local turn_count = 0
    while has_block do
        if turn_count < 3 then
            turtle.turnRight()
            turn_count = turn_count + 1
            has_block = turtle.inspect()
        else
            print("Turtle is blocked! Clear a space!")
            turtle.turnRight()
            has_block = turtle.inspect()
            turn_count = 0
        end
    end
    print("Current pos: " ..state.x ..", " ..state.y ..", " ..state.z)

    turtle.forward()
    local test_x, test_y, test_z = Locate()
    print("Test pos: " ..test_x ..", " ..test_y ..", " ..test_z)
    turtle.back()
    local direction = nil
    if state.z ~= test_z then
        if state.z - test_z > 0 then
            direction = 0
            print("Direction is North!")
        else
            direction = 2
            print("Direction is South!")
        end
    end
    if state.x ~= test_x then
        if state.x - test_x < 0 then
            direction = 1
            print("Direction is East!")
        else
            direction = 3
            print("Direction is West!")
        end
    end
    if direction == "" then
        return false
    end
    state.direction = direction
    return true
end

function ChangeDirection(state, direction)
    if state.direction == direction then
        return
    end
    local checkcw = (direction - state.direction + 4) % 4
    local checkccw = (state.direction - direction + 4) % 4
    if checkcw < checkccw then
        for i = 1, checkcw do
            turtle.turnRight()
        end
    else
        for i = 1, checkccw do
            turtle.turnLeft()
        end
    end
    state.direction = direction
end

function GoToPosition(state, target)
    state.last_direction = state.direction
    local x = target.x - state.x
    local y = target.y - state.y
    local z = target.z - state.z
    print("Distance to move: " ..x ..", " ..y ..", " ..z)
    if x < 0 then
        for i = 1, math.abs(x) do
            Move(state, "West")
        end
    elseif x > 0 then
        for i = 1, math.abs(x) do
            Move(state, "East")
        end
    end
    if z < 0 then
        for i = 1, math.abs(z) do
            Move(state, "North")
        end
    elseif z > 0 then
        for i = 1, math.abs(z) do
            Move(state, "South")
        end
    end
    if y < 0 then
        for i = 1, math.abs(y) do
            Move(state, "Down")
        end
    elseif y > 0 then
        for i = 1, math.abs(y) do
            Move(state, "Up")
        end
    end
    ChangeDirection(state, target.direction)

    print("I made it to the target position!")
end

function Move(state, direction, destructive)
    local converted
    destructive = destructive or false
    local convert_direction = {
        ["North"] = 0,
        ["East"] = 1,
        ["South"] = 2,
        ["West"] = 3,
        ["Up"] = 50, --- High number to stay above 3 after the cw check---
        ["Down"] = -50, --- Low number to stay below 0 after the ccw check---
        ["Forward"] = state.direction,
        ["cw"] = state.direction + 1,
        ["ccw"] = state.direction - 1,
    }
    if type(direction) == "string" then
        converted = convert_direction[direction]
    else
        converted = direction
    end
    if converted < 0 then
        converted = converted + 4
    elseif converted > 3 then
        converted = converted - 4
    end
    if -1 < converted and converted < 4 then
        ChangeDirection(state, converted)
        if destructive then
            if not SmartDig("Forward") then
                return false
            end
        end
        turtle.forward()
    elseif converted > 3 then
        if destructive then
            if not SmartDig("Up") then
                return false
            end
        end
        turtle.up()
    elseif converted < 0 then
        if destructive then
            if not SmartDig("Down") then
                return false
            end
        end
        turtle.down()
    end
    state.x, state.y, state.z = Locate()
end

function InventoryFull(state, home)
    print("Inventory Full! Going home!")
    local all_items
    local just_coal
    all_items = home.direction - 1
    if all_items < 0 then
        all_items = all_items + 4
    end
    just_coal = home.direction - 2
    if just_coal < 0 then
        just_coal = just_coal + 4
    end


    for key, value in state do
        Return_Position[key] = value
    end
    GoToPosition(state, home)
    while not turtle.inspect("minecraft:chest") do
        print("No where to put items!")
        turtle.turnRight()
        turtle.turnRight()
        turtle.turnRight()
        turtle.turnRight()
    end
    ChangeDirection(state, all_items)
    for i = 2, 16 do
        if turtle.getItemDetail(i) ~= "minecraft:coal" then
            turtle.drop(i)
        else
            ChangeDirection(state, just_coal)
            turtle.drop(i)
            ChangeDirection(state, all_items)
        end
    end
    ChangeDirection(state, just_coal)
    turtle.select(1)
    turtle.suck(turtle.getItemSpace(1))
    GoToPosition(state, Return_Position)

end

function DigLayer(state, home)
    print("Digging Layer...")

    local start_dir = state.direction
    if state.y <= -62 then
        print("At base level! Coming home!")
        GoToPosition(state, home)
        InventoryFull(state, home)
        return false
    end
    if SmartDig("Down") then
        Move(state, "Down")
    else GoToPosition(state, home)
        return false
    end
    local layer_start_pos = {
        x = state.x,
        y = state.y,
        z = state.z,
        direction = state.direction
    }
    for row = 1, 16 do
        for col = 1, 16 do
            if not Move(state, "Forward", true) then
                InventoryFull(state, home)
                return false
            end
        end
        if row % 2 == 1 then
            if not Move(state, "cw", true) then
                InventoryFull(state, home)
                return false
            end
        else
            if not Move(state, "ccw", true) then
                InventoryFull(state, home)
                return false
            end
        end
    end
    GoToPosition(state, layer_start_pos)
end

function PlaceChests()
    local placed = 0
    local slot, info
    for i = 1, 16 do
        turtle.select(i)
        slot, info = turtle.getItemDetail()
        if info.name == "minecraft:enderchest" then
            turtle.turnLeft()
            turtle.place()
            turtle.turnRight()
        elseif info.name == "minecraft:chest" then
            turtle.turnLeft()
            turtle.turnLeft()
            turtle.place()
            turtle.turnRight()
            turtle.turnRight()
        end
    end
end

local state = {
    direction = nil,
    x = nil,
    y = nil,
    z = nil,
    fuel = turtle.getFuelLevel()
}

local home = {
    direction = nil,
    x = nil,
    y = nil,
    z = nil,
    fuel = turtle.getFuelLevel()
}

Return_Position = {
    direction = nil,
    x = nil,
    y = nil,
    z = nil,
    fuel = turtle.getFuelLevel()
}


---- Start of main loop ----
print("Checking GPS...")
while not state.x do
    state.x, state.y, state.z = Locate()
    if not state.x then
        print("Failed to get position! Check GPS!")
    end
    os.sleep(1)
end

while state.fuel == 0 do
    print("Checking Fuel...")
    Refuel(state)
    os.sleep(1)
end

if not state.direction then
    print("Checking Direction...")
    if CheckDirection(state) then
        home.x, home.y, home.z = state.x, state.y, state.z
        home.direction = state.direction
    end
end

while true do
    if not DigLayer(state, home) then
        break
    end
    --- ToDo ---
    --- Handle Ender Chest ---
    --- Handle Coal Chest ---
    --- Move To New Chunk ---
end
