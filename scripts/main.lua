local modDir = g_currentModDirectory
source(modDir .. "scripts/lib/inspect.lua");
TargetFillLevel = {}
-- local TargetFillLevel_mt = Class(TargetFillLevel)

function TargetFillLevel:registerActionEvents()
    print('TFL: register Event')
    local _, event1 = g_inputBinding:registerActionEvent(InputAction.TFL_ACTION, self, TargetFillLevel.myAction, false,
        true, false, true)
    -- g_inputBinding:setActionEventTextVisibility(event1, true)
end

function TargetFillLevel:myAction()
    if g_currentMission == nil or g_currentMission.controlledVehicle == nil then
        return
    end

    print('TFL: controlledVehicle found!')

    if SpecializationUtil.hasSpecialization(Combine, g_currentMission.controlledVehicle.specializations) then
        local combine = g_currentMission.controlledVehicle
        print('TFL: I\'m a combine!')

        if combine.spec_pipe == nil then
            print('TFL: combine has no pipe!!')
            return
        end

        local capacity = 0
        local dischargeNode = combine:getCurrentDischargeNode()
        local showTargetFillLevel = false

        if dischargeNode ~= nil then
            capacity = combine:getFillUnitCapacity(dischargeNode.fillUnitIndex)
        end

        local trailer = NetworkUtil.getObject(combine.spec_pipe.nearestObjectInTriggers.objectId)
        -- print(inspect(trailer, {depth = 1}))

        if trailer == nil then
            print('TFL: No trailer in trigger!')
            return
        end
        print(inspect(trailer:getFillUnits(), {
            depth = 2
        }))

        if combine.spec_pipe.nearestObjectInTriggerIgnoreFillLevel then
            print('TFL: Invalid trailer in trigger!')
            return
        end

        if capacity == math.huge then
            -- forage harvester
            print('TFL: forage harvester')

            -- see orginial in AIDriveStrategyCombine:111 "allowedToDrive = trailerInTrigger and targetObject ~= nil"
            local targetObject, _ = combine:getDischargeTargetObject(dischargeNode)
            showTargetFillLevel = targetObject ~= nil

            print(inspect(targetObject, {
                depth = 1
            }))
        else
            -- normal combine
            print('TFL: normal combine')
        end
    end
end

function TargetFillLevel:getFillLevelInformation(superFunc, display)
    superFunc(self, display)
    -- print('TFL: getFillLevelInformation')

    -- self is the vehicle
    if SpecializationUtil.hasSpecialization(Combine, self.specializations) then
        local combine = self
        print('TFL: I\'m a combine!')

        if combine.spec_pipe == nil then
            print('TFL: combine has no pipe!!')
            return
        end

        if combine.spec_pipe.targetState ~= 2 then
            print('TFL: pipe is not ready!!')
            return
        end

        local capacity = 0
        local dischargeNode = combine:getCurrentDischargeNode()
        local showTargetFillLevel = false

        if dischargeNode ~= nil then
            capacity = combine:getFillUnitCapacity(dischargeNode.fillUnitIndex)
        end

        local trailer = NetworkUtil.getObject(combine.spec_pipe.nearestObjectInTriggers.objectId)
        -- print(inspect(trailer, {depth = 1}))

        if trailer == nil then
            print('TFL: No trailer in trigger!')
            return
        end
        -- print(inspect(trailer:getFillUnits(), {
        --     depth = 2
        -- }))

        if combine.spec_pipe.nearestObjectInTriggerIgnoreFillLevel then
            print('TFL: Invalid trailer in trigger!')
            return
        end

        if capacity == math.huge then
            -- forage harvester
            print('TFL: forage harvester')

            -- see orginial in AIDriveStrategyCombine:111 "allowedToDrive = trailerInTrigger and targetObject ~= nil"
            local targetObject, _ = combine:getDischargeTargetObject(dischargeNode)
            showTargetFillLevel = targetObject ~= nil

            if trailer ~= nil then
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

            -- print(inspect(targetObject, {
            --     depth = 1
            -- }))
        else
            -- normal combine
            print('TFL: normal combine')
        end
    end

    -- print(inspect(self,{depth = 2}))

    -- local spec = self.spec_tensionBelts

    -- if spec.hasTensionBelts then
    --     for _, objectData in pairs(spec.objectsToJoint) do
    --         local object = objectData.object

    --         if object ~= nil then
    --             if object.getFillLevelInformation ~= nil then
    --                 object:getFillLevelInformation(display)
    --             elseif object.getFillLevel ~= nil and object.getFillType ~= nil then
    --                 local fillType = object:getFillType()
    --                 local fillLevel = object:getFillLevel()
    --                 local capacity = fillLevel

    --                 if object.getCapacity ~= nil then
    --                     capacity = object:getCapacity()
    --                 end

    --                 display:addFillLevel(fillType, fillLevel, capacity)
    --             end
    --         end
    --     end
    -- end
end

function initTargetFillLevel(name)
    if name == nil then
        return
    end

    if g_client ~= nil then
        -- client side mod only
        FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents,
            TargetFillLevel.registerActionEvents)
        addModEventListener(TargetFillLevel)
        Vehicle.getFillLevelInformation = Utils.overwrittenFunction(Vehicle.getFillLevelInformation,
            TargetFillLevel.getFillLevelInformation)
    end

end

initTargetFillLevel(g_currentModName)
