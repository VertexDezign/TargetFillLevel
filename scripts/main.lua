--[[
Target Fill Level Mod for Farming Simulator 25

Author: André Buchman & VertexDezign
Website: https://vertexdezign.net/
Issues: https://github.com/VertexDezign/TargetFillLevel/issues

Feel free to open a pull reuests for enhancements or bugfixes.

FS25_TargetFillLevel © 2023 by André Buchmann & VertexDezign is licensed under CC BY-NC-ND 4.0. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/
]]

TargetFillLevel = {}
TargetFillLevel.debug = false

function TargetFillLevel:getFillLevelInformation(superFunc, display)
    -- Variable self is the vehicle in this method
    superFunc(self, display)

    local tlfDisplayed = TargetFillLevel:hasPipeTarget(self, display)
    if not tlfDisplayed then
        TargetFillLevel:hasDischargeTarget(self, display)
    end
end

function TargetFillLevel:hasPipeTarget(vehicle, display)
    if not SpecializationUtil.hasSpecialization(Pipe, vehicle.specializations) then
        return false
    end

    local pipe = vehicle.spec_pipe
    tflPrint('I\'m a vehicle with a pipe!')

    -- Check if vehicle has spec_foldable and exit if not unfolded
    if SpecializationUtil.hasSpecialization(Foldable, vehicle.specializations) then
        if not vehicle.spec_foldable:getIsUnfolded() then
            tflPrint('unfold first!!')
            return false
        end
    end

    -- All basegame vehicles have <states num="2" unloading="2" /> except Ropa Maus6 and Grimme Ventor4150
    -- they are foldable, but they have no movable pipes, so we skip them in this check
    if (pipe.hasMovablePipe and pipe.targetState ~= pipe.numStates) then
        tflPrint('Pipe is not ready!!')
        return false
    end

    -- Check for valid discharge location
    if pipe.nearestObjectInTriggerIgnoreFillLevel then
        tflPrint('Invalid trailer in trigger!')
        return false
    end

    -- Get the trailer to find it's current fill level
    local trailer = NetworkUtil.getObject(pipe.nearestObjectInTriggers.objectId)
    if trailer == nil then
        tflPrint('No trailer in trigger!')
        return false
    end

    -- Display fill level of target vehicle
    TargetFillLevel:addFillLevelDisplay(vehicle, trailer, display)
    return true
end

function TargetFillLevel:hasDischargeTarget(vehicle, display)
    if not SpecializationUtil.hasSpecialization(Dischargeable, vehicle.specializations) then
        return false
    end

    -- Show target fill level for shovels, unload triggers,...
    local dischargeable = vehicle.spec_dischargeable
    local dischargeNode = dischargeable:getCurrentDischargeNode()
    tflPrint('I\'m a vehicle with a Dischargeable!')

    -- Show only discharges to objects. There is no level when dumping on the ground
    if dischargeable:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OBJECT then
        tflPrint('Wrong discharge state!')
        return false
    end

    -- Return early when access check fails
    if not dischargeable:getCanDischargeToObject(dischargeNode) then
        tflPrint('Can\'t discharge to object!')
        return false
    end

    -- Get discharge target object
    local target = dischargeable:getCurrentDischargeObject(dischargeNode)
    if target == nil then
        tflPrint('No discharge object in trigger!')
        return false
    end

    if target.getFillUnitFillLevelTFL ~= nil and target.getFillUnitCapacityTFL ~= nil then
        -- Calculate fill level for storages / productions
        local fillLevel = target:getFillUnitFillLevelTFL(dischargeNode.dischargeFillUnitIndex, dischargeable:getDischargeFillType(dischargeNode), dischargeable:getActiveFarm())
        local capacity = target:getFillUnitCapacityTFL(dischargeNode.dischargeFillUnitIndex, dischargeable:getDischargeFillType(dischargeNode), dischargeable:getActiveFarm())
        if fillLevel ~= nil and capacity ~= nil then
            tflPrint('Show FillLevel of storage/production')
            display:addFillLevel(TargetFillLevel:getFillType(), fillLevel, capacity)
            return true
        end
    else
        -- Propably a vehicle at this point
        -- an unsupported object which is catched in the early exit method of addFillLevelDisplay()
        TargetFillLevel:addFillLevelDisplay(vehicle, target, display)
        return true
    end
    return false
end


function TargetFillLevel:addFillLevelDisplay(vehicle, targetVehicle, display)
    -- skip unsupported target types
    if targetVehicle.getFillLevelInformation == nil then
        return
    end
    tflPrint('Show FillLevel of vehicle')

    -- here we have the pipes target vehicle (e.g. trailer under combine pipe)
    local spec = targetVehicle.spec_fillUnit

    for i = 1, #spec.fillUnits do
        local fillUnit = spec.fillUnits[i]

        if fillUnit.capacity > 0 and fillUnit.showOnHud then
            local fillLevel = fillUnit.fillLevel

            if fillUnit.fillLevelToDisplay ~= nil then
                fillLevel = fillUnit.fillLevelToDisplay
            end

            display:addFillLevel(TargetFillLevel:getFillType(), fillLevel, fillUnit.capacity)

            local fillLevelPercentage = targetVehicle:getFillUnitFillLevelPercentage(i)
            tflPrint(fillLevelPercentage)

            -- Save state on fill unit to support multi storage semi trailer
            if fillUnit.notificationTFLNearlyFullShown == nil and fillLevelPercentage > 0 then
                fillUnit.notificationTFLNearlyFullShown = false
            end

            if fillUnit.notificationTFLFullShown == nil and fillLevelPercentage > 0 then
                fillUnit.notificationTFLFullShown = false
            end

            if fillLevelPercentage > 0.8 then
                -- Show notification when target is nearly full
                if not fillUnit.notificationTFLNearlyFullShown then
                    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("tfl_messageErrorTargetIsNearlyFull"), vehicle:getFullName(), targetVehicle:getFullName()))

                    fillUnit.notificationTFLNearlyFullShown = true
                end
            end

            if fillLevelPercentage > 0.99 then
                -- Show notification when target is completely full
                if not fillUnit.notificationTFLFullShown then
                    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("tfl_messageErrorTargetIsFull"), vehicle:getFullName(), targetVehicle:getFullName()))

                    fillUnit.notificationTFLFullShown = true
                end
            end
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

initTargetFillLevel(g_currentModName)

-- ################
-- Helper functions
-- ################

-- Print when debug mode is active
function tflPrint(value)
    if TargetFillLevel.debug then
        print('TFL: ' .. tostring(value))
    end
end

-- Add helper functions to UnloadTrigger objects
function UnloadTrigger:getFillUnitFillLevelTFL(fillUnitIndex, fillTypeIndex, farmId)
	if self.target ~= nil and self.target.getFillLevel ~= nil then
		local conversion = self.fillTypeConversions[fillTypeIndex]

		if conversion ~= nil then
			return self.target:getFillLevel(conversion.outgoingFillType, farmId, self.extraAttributes) / conversion.ratio
		end

		return self.target:getFillLevel(fillTypeIndex, farmId, self.extraAttributes)
	end

	return nil
end

function UnloadTrigger:getFillUnitCapacityTFL(fillUnitIndex, fillTypeIndex, farmId)
	if self.target ~= nil and self.target.getCapacity ~= nil then
		local conversion = self.fillTypeConversions[fillTypeIndex]

		if conversion ~= nil then
			return self.target:getCapacity(conversion.outgoingFillType, farmId, self.extraAttributes) / conversion.ratio
		end

		return self.target:getCapacity(fillTypeIndex, farmId, self.extraAttributes)
	end

	return nil
end
