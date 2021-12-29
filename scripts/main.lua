----------------------------------------------------------------------------------------------------
--[[
Target Fill Level Mod for Farming Simulator 2022

Copyright (c) -tinte-, 2021

Author: André Buchmann
Issues: https://github.com/schliesser/fs-targetfilllevel/issues

Feel free to open a pull reuests for enhancements or bugfixes.

You are not allowed to sell this or a modified version of the mod.
]] ----------------------------------------------------------------------------------------------------

-- Load inspect for debugging
-- local modDir = g_currentModDirectory
-- source(modDir .. "scripts/lib/inspect.lua");
TargetFillLevel = {}
local TargetFillLevel_mt = Class(TargetFillLevel)

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

        print('TFL: Valid trailer in trigger')
        if trailer.getFillLevelInformation ~= nil then
            trailer:getFillLevelInformation(display)
        elseif trailer.getFillLevel ~= nil and trailer.getFillType ~= nil then
            local fillType = trailer:getFillType()
            local fillLevel = trailer:getFillLevel()
            local capacity = fillLevel

            if trailer.getCapacity ~= nil then
                capacity = trailer:getCapacity()
            end

            display:addFillLevel(fillType, fillLevel, capacity)
        end
    end
end

function initTargetFillLevel(name)
    -- Client side mod only
    if name == nil or g_client == nil then
        return
    end

    addModEventListener(TargetFillLevel)

    -- Hook onto fill level display
    Vehicle.getFillLevelInformation = Utils.overwrittenFunction(
        Vehicle.getFillLevelInformation,
        TargetFillLevel.getFillLevelInformation
    )
end

initTargetFillLevel(g_currentModName)
