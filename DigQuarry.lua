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

--- THERE IS AN ERROR HERE AFTER FIRST COLUMN IS FINISHED AND CW TURN IS INITIATED ---
function Move(state, direction, destructive)
    local converted
    destructive = destructive or false
    local convert_direction = {
        ["North"] = 0,
        ["East"] = 1,
        ["South"] = 2,
        ["West"] = 3,
        ["Up"] = 4,
        ["Down"] = 5,
        ["Forward"] = state.direction
    }
    if type(direction) == "string" then
        converted = convert_direction[direction]
    elseif direction == "cw" then
        converted = state.direction + 1
        if converted > 3 then
            converted = 0
        end
    elseif direction == "ccw" then
        converted = state.direction - 1
        if converted < 0 then
            converted = 3
        end
        else
            converted = direction
    end
    if converted < 4 then
        ChangeDirection(state, converted)
        if destructive then
            SmartDig("Forward")
        end
        turtle.forward()
    elseif converted == 4 then
        if destructive then
            SmartDig("Up")
        end
        turtle.up()
    elseif converted == 5 then
        if destructive then
            SmartDig("Down")
        end
        turtle.down()
    end
    state.x, state.y, state.z = Locate()
end

function InventoryFull(state, home)
    if home.direction > 0 then
        local all_items = home.direction - 1
    else
        local all_items = 3
    end
    if home.direction > 1 then
        local just_coal = home.direction - 2
    else
        local just_coal = (home.direction - 2) + 4
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
    for i = 1, 16 do
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
    GoToPosition(state)

end

function DigLayer(state, home)
    print("Digging Layer...")
    local start_dir = state.direction
    if state.y <= -62 then
        print("At base level! Coming home!")
        GoToPosition(state, home)
        return false
    end
    if SmartDig("Down") then
        Move(state, "Down")
    else GoToPosition(state, home)
        return false
    end
    for row = 1, 16 do
        for col = 1, 16 do
            Move(state, "Forward", true)
        end
        if row % 2 == 1 then
            Move(state, "cw", true)
        else
            Move(state, "ccw", true)
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
    CheckDirection(state)
end

while true do
    print("Nothing to do yet...")
    print("State.Direction: " ..state.direction)

    if not DigLayer(state, home) then
        break
    end
    -- ToDo
    -- Dig Layer
    -- Return Home
    -- Dump inventory
end
