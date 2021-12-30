----------------------------------------------------------------------------------------------------
--[[
Target Fill Level Mod for Farming Simulator 2022

Copyright (c) -tinte-, 2021

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

        --[[ The fill level could be added to any combine, but as they are concatenated
        by type, it doesn't make sence to display them. Therefor it will be displayed
        only for forage harvesters.
        ]]
        -- detect forage harvester as AI does it
        local dischargeNode = combine:getCurrentDischargeNode()
        if dischargeNode ~= nil and combine:getFillUnitCapacity(dischargeNode.fillUnitIndex) == math.huge then
            TargetFillLevel:addFillLevelDisplay(trailer, display)
        end
    end
end

function TargetFillLevel:addFillLevelDisplay(targetVehicle, display)
    if targetVehicle.getFillLevelInformation ~= nil then
        targetVehicle:getFillLevelInformation(display)
    elseif targetVehicle.getFillLevel ~= nil and targetVehicle.getFillType ~= nil then
        local fillType = targetVehicle:getFillType()
        local fillLevel = targetVehicle:getFillLevel()
        local capacity = fillLevel

        if targetVehicle.getCapacity ~= nil then
            capacity = targetVehicle:getCapacity()
        end

        display:addFillLevel(fillType, fillLevel, capacity)
    end
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

initTargetFillLevel(g_currentModName)
