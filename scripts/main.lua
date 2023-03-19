----------------------------------------------------------------------------------------------------
--[[
Target Fill Level Mod for Farming Simulator 2022

Copyright (c) -tinte-, 2023

Author: André Buchmann
Issues: https://github.com/schliesser/fs-targetfilllevel/issues

Feel free to open a pull reuests for enhancements or bugfixes.

You are not allowed to sell this or a modified version of the mod.
]] ----------------------------------------------------------------------------------------------------

TargetFillLevel = {}

function TargetFillLevel:getFillLevelInformation(superFunc, display)
    superFunc(self, display)

    -- Variable self is the vehicle in this method
    if SpecializationUtil.hasSpecialization(Combine, self.specializations) then
        local combine = self
        -- print('TFL: I\'m a combine!')

        if combine.spec_pipe == nil then
            -- print('TFL: combine has no pipe!!')
            return
        end

        if combine.spec_pipe.targetState ~= 2 then
            -- print('TFL: pipe is not ready!!')
            return
        end

        if combine.spec_pipe.nearestObjectInTriggerIgnoreFillLevel then
            -- print('TFL: Invalid trailer in trigger!')
            return
        end

        local trailer = NetworkUtil.getObject(combine.spec_pipe.nearestObjectInTriggers.objectId)
        if trailer == nil then
            -- print('TFL: No trailer in trigger!')
            return
        end

        TargetFillLevel:addFillLevelDisplay(trailer, display)
    end
end

function TargetFillLevel:addFillLevelDisplay(targetVehicle, display)
    -- print('TFL: addFillLevelDisplay')
    if targetVehicle.getFillLevelInformation ~= nil then
        -- here we have the pipe target on forage harvesters and combines
        -- print('TFL: target has getFillLevelInformation')
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

                -- idea: match fillUnit fillType with combine filltype
                -- and skip all unneccessary fillType outputs

                display:addFillLevel(TargetFillLevel:getFillType(), fillLevel, capacity)
            end
        end
    elseif targetVehicle.getFillLevel ~= nil and targetVehicle.getFillType ~= nil then
        -- when do we run in here?
        -- print('TFL: target has getFillLevel and getFillType')
        local fillLevel = targetVehicle:getFillLevel()
        local capacity = fillLevel

        if targetVehicle.getCapacity ~= nil then
            capacity = targetVehicle:getCapacity()
        end

        display:addFillLevel(TargetFillLevel:getFillType(), fillLevel, capacity)
    end
end

function TargetFillLevel:getFillType()
    local fillTypeObject = g_fillTypeManager:getFillTypeByName("TARGET_VEHICLE")

    if fillTypeObject ~= nil and fillTypeObject.index ~= nil then
        return fillTypeObject.index
    end

    return 0
end

function initTargetFillLevel(name)
    -- Client side mod only
    if name == nil or g_client == nil then
        return
    end

    addModEventListener(TargetFillLevel)

    -- Hook onto fill level display
    Vehicle.getFillLevelInformation = Utils.overwrittenFunction(Vehicle.getFillLevelInformation, TargetFillLevel.getFillLevelInformation)
end

-- helper function to debug tables
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
