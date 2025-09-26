function SmartDig()
    local has_block = turtle.inspect()
    if not has_block then
        return false
    end
    turtle.dig()

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
    local selected = 1
    turtle.select(selected)
    while state.fuel < 256 do
        if not turtle.refuel() then
            if selected < 16 then
                selected = selected + 1
                turtle.select(selected)
            else
                return false
            end
        else
            print("Refueling!")
            state.fuel = turtle.getFuelLevel()
        end
    end
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

    turtle.forward()
    local test_x, test_y, test_z = Locate()
    turtle.back()
    local direction = nil
    if state.z ~= test_z then
        if test_z - state.z > 0 then
            direction = 0
            print("Direction is North!")
        else
            direction = 2
            print("Direction is South!")
        end
    end
    if state.x ~= test_x then
        if test_x - state.x > 0 then
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

function GoHome(state, home)
    print("Going Home...")
    for x = 0, home.x - state.x do
        if home.x > state.x then
            Move(state, "East")
        else
            Move(state, "West")
        end
    end
    for y = 0, home.y - state.y do
        if home.y > state.y then
            Move(state, "North")
        else
            Move(state, "South")
        end
    end
    for z = 0, home.z - state.z do
        if home.z > state.z then
            Move(state, "Up")
        else
            Move(state, "Down")
        end
    end

end

function Move(state, direction)
    local convert_direction = {
        ["North"] = 0,
        ["East"] = 1,
        ["South"] = 2,
        ["West"] = 3,
        ["Up"] = 4,
        ["Down"] = 5
    }
    local direction = convert_direction[direction]
    if convert_direction < 4 then
        ChangeDirection(state, direction)
        turtle.forward()
    elseif convert_direction == 4 then
        turtle.up()
    elseif convert_direction == 5 then
        turtle.down()
    end
    state.x, state.y, state.z = Locate()
end

local state = {
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

local home = {
    x = state.x,
    y = state.y,
    z = state.z
}

if not state.direction then
    print("Checking Direction...")
    CheckDirection(state)
end

while true do
    print("Nothing to do yet...")
    os.sleep(1)
    -- ToDo
    -- Dig Layer
    -- Return Home
    -- Dump inventory
end