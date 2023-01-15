local belts = false
local isUiOpen = false
local SeatbeltON = false
local InVehicle = false
local speedBuffer = {}
local velBuffer = {}
local GetEntitySpeed = GetEntitySpeed
local GetEntitySpeedVector = GetEntitySpeedVector
local GetVehicleClass = GetVehicleClass
local GetVehicleHandlingFloat = GetVehicleHandlingFloat
local GetVehicleCurrentRpm = GetVehicleCurrentRpm
local GetVehicleCurrentGear = GetVehicleCurrentGear
local GetVehicleFuelLevel = GetVehicleFuelLevel
local GetVehicleCurrentRpm = GetVehicleCurrentRpm
local GetEntityHealth = GetEntityHealth
local GetEntityMaxHealth = GetEntityMaxHealth
local GetVehicleLightsState = GetVehicleLightsState
local GetVehicleDoorLockStatus = GetVehicleDoorLockStatus
local SendNUIMessage = SendNUIMessage
local IsPlayerDead = IsPlayerDead
local DisableControlAction = DisableControlAction
local SetEntityCoords = SetEntityCoords
local SetEntityVelocity = SetEntityVelocity
local SetPedToRagdoll = SetPedToRagdoll
local GetEntityCoords = GetEntityCoords
local GetEntityHeading = GetEntityHeading

local function IsCar(veh)
    local vc = GetVehicleClass(veh)
    return (vc >= 0 and vc <= 7) or (vc >= 9 and vc <= 12) or (vc >= 17 and vc <= 20)
end

local function Fwv(entity)
    local hr = GetEntityHeading(entity) + 90.0
    if hr < 0.0 then hr = 360.0 + hr end
    hr = hr * 0.0174533
    return { x = math.cos(hr) * 2.0, y = math.sin(hr) * 2.0 }
end

local function speedoThread()
    while vehicle do
        if vehicle ~= false then
            local data = {}
            data.Speed = GetEntitySpeed(vehicle) * 2.236936
            data.MaxSpeed = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
            data.rpm = GetVehicleCurrentRpm(vehicle)
            data.gear = GetVehicleCurrentGear(vehicle)
            data.Fuel = GetVehicleFuelLevel(vehicle)
            data.Rpm = GetVehicleCurrentRpm(vehicle)
            data.Damage = GetEntityHealth(vehicle)
            data.MaxDamage = GetEntityMaxHealth(vehicle)
            local _, lights, _ = GetVehicleLightsState(vehicle)
            data.Lights = lights
            data.Lock = GetVehicleDoorLockStatus(vehicle)
            data.Belts = belts
            SendNUIMessage({ action = "show", data = data })
        end
        Wait(100)
    end
end

local function seatbeltThread()
    while vehicle do
        local timer = 1000
        local dead = IsPlayerDead(cache.playerId)
        if vehicle ~= false and (InVehicle or IsCar(vehicle)) then
            timer = 10
            InVehicle = true
            if isUiOpen == false and not dead then
                TriggerEvent('seatbelt:client:ToggleSeatbelt', SeatbeltON)
                isUiOpen = true
            end
            if SeatbeltON then
                DisableControlAction(0, 75, true) -- Disable exit vehicle when stop
                DisableControlAction(27, 75, true) -- Disable exit vehicle when Driving
            end
            speedBuffer[2] = speedBuffer[1]
            speedBuffer[1] = GetEntitySpeed(vehicle)
            velBuffer[2] = velBuffer[1]
            velBuffer[1] = GetEntityVelocity(vehicle)
            if not SeatbeltON and speedBuffer[2] ~= nil and GetEntitySpeedVector(vehicle, true).y > 1.0 and
                speedBuffer[2] > (100 / 3.6) and (speedBuffer[2] - speedBuffer[1]) > (speedBuffer[1] * 0.555) then
                local co = GetEntityCoords(ped)
                local fw = Fwv(ped)
                SetEntityCoords(ped, co.x + fw.x, co.y + fw.y, co.z - 0.47, true, true, true)
                SetEntityVelocity(ped, velBuffer.x, velBuffer.y, velBuffer.z)
                Wait(1)
                SetPedToRagdoll(ped, 1000, 1000, 0, 0, 0, 0)
            end
        elseif InVehicle then
            InVehicle = false
            SeatbeltON = false
            speedBuffer[1], speedBuffer[2] = 0.0, 0.0
            if isUiOpen == true and not dead then
                TriggerEvent('seatbelt:client:ToggleSeatbelt', SeatbeltON)
                isUiOpen = false
            end
        end
        Wait(timer)
    end
end

lib.onCache('ped', function(value)
    ped = value
end)

lib.onCache('vehicle', function(value)
    vehicle = value
    if value then
        CreateThread(speedoThread)
        CreateThread(seatbeltThread)
    else
        SendNUIMessage({ action = "hide" })
    end
end)

 
RegisterCommand("seatbelt", function()
    SeatbeltON = not SeatbeltON
    if SeatbeltON then
        TriggerEvent('seatbelt:client:ToggleSeatbelt', SeatbeltON)
        isUiOpen = true
    else
        TriggerEvent('seatbelt:client:ToggleSeatbelt', SeatbeltON)
        isUiOpen = true
    end
end)
RegisterKeyMapping('seatbelt', 'Toggle Seatbelt', 'keyboard', 'X')

 

