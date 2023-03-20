--[[
Target Fill Level Mod for Farming Simulator 22

Author: André Buchman & VertexDezign
Website: https://vertexdezign.net/
Issues: https://github.com/schliesser/fs-targetfilllevel/issues

Feel free to open a pull reuests for enhancements or bugfixes.

FS22_TargetFillLevel © 2023 by André Buchmann & VertexDezign is licensed under CC BY-NC-ND 4.0. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
]]

TargetFillLevel = {}
TargetFillLevel.debug = false

function TargetFillLevel:getFillLevelInformation(superFunc, display)
    superFunc(self, display)

    -- Variable self is the vehicle in this method
    if SpecializationUtil.hasSpecialization(Pipe, self.specializations) then
        local pipe = self.spec_pipe
        tflPrint('I\'m a vehicle with a pipe!')

        -- Check if vehicle has spec_foldable and exit if not unfolded
        if SpecializationUtil.hasSpecialization(Foldable, self.specializations) then
            if not self.spec_foldable:getIsUnfolded() then
                tflPrint('unfold first!!')
                return
            end
        end

        -- All basegame vehicles have <states num="2" unloading="2" /> except Ropa Maus6 and Grimme Ventor4150
        -- they are foldable, but they have no movable pipes, so we skip them in this check
        if (pipe.hasMovablePipe and pipe.targetState ~= pipe.numStates) then
            tflPrint('Pipe is not ready!!')
            return
        end

        -- Check for valid discharge location
        if pipe.nearestObjectInTriggerIgnoreFillLevel then
            tflPrint('Invalid trailer in trigger!')
            return
        end

        -- Get the trailer to find it's current fill level
        local trailer = NetworkUtil.getObject(pipe.nearestObjectInTriggers.objectId)
        if trailer == nil then
            tflPrint('No trailer in trigger!')
            return
        end

        TargetFillLevel:addFillLevelDisplay(trailer, display)
    end
end

function TargetFillLevel:addFillLevelDisplay(targetVehicle, display)
    if targetVehicle.getFillLevelInformation == nil then
        return
    end

    -- here we have the pipes target vehicle (e.g. trailer under combine pipe)
    tflPrint('Target has getFillLevelInformation')
    local spec = targetVehicle.spec_fillUnit

    for i = 1, #spec.fillUnits do
        local fillUnit = spec.fillUnits[i]

        if fillUnit.capacity > 0 and fillUnit.showOnHud then
            local fillLevel = fillUnit.fillLevel

            if fillUnit.fillLevelToDisplay ~= nil then
                fillLevel = fillUnit.fillLevelToDisplay
            end

            local capacity = fillUnit.capacity

            if fillUnit.parentUnitOnHud ~= nil then
                capacity = 0
            end

            display:addFillLevel(TargetFillLevel:getFillType(), fillLevel, capacity)
        end
    end
end

function TargetFillLevel:getFillType()
    local fillTypeObject = g_fillTypeManager:getFillTypeByName("TARGET_VEHICLE")

    if fillTypeObject ~= nil and fillTypeObject.index ~= nil then
        return fillTypeObject.index
    end

    -- fallback to fillType "unknown" to prevent errors
    return 0
end

function initTargetFillLevel(name)
    -- Client side mod only
    if name == nil or g_client == nil then
        return
    end

    -- Hook onto fill level display
    Vehicle.getFillLevelInformation = Utils.overwrittenFunction(Vehicle.getFillLevelInformation, TargetFillLevel.getFillLevelInformation)
end

-- Helper function to print in debug mode
function tflPrint(value)
    if TargetFillLevel.debug then
        print('TFL: ' .. tflDump(value))
    end
end

-- Helper function to debug tables
function tflDump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. tflDump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end

initTargetFillLevel(g_currentModName)
