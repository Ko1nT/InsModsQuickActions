require "TimedActions/ISBaseTimedAction"

IMFMS_ISMakeMarkOnMap = ISBaseTimedAction:derive("IMFMS_ISMakeMarkOnMap");

function IMFMS_ISMakeMarkOnMap:isValid()
	return ISWorldMap.IsAllowed()
end

function IMFMS_ISMakeMarkOnMap:update()
end

function IMFMS_ISMakeMarkOnMap:start()
	self:setAnimVariable("ReadType", "newspaper")
	self:setActionAnim(CharacterActionAnims.Read)
    self:setOverrideHandModelsString(nil, "MapInHand");
	self.character:playSoundLocal("MapOpen")
end

function IMFMS_ISMakeMarkOnMap:stop()
	ISBaseTimedAction.stop(self)
end

function IMFMS_ISMakeMarkOnMap:perform()
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function IMFMS_ISMakeMarkOnMap:new(character)
	local o = ISBaseTimedAction.new(self, character)
	o.maxTime = 50
	if character:isTimedActionInstant() then
		o.maxTime = 1
	end
	o.playerNum = character:getPlayerNum()
	return o
end

