local NAME, S = ...
local SCR = ScrollingChatText

local ACD = LibStub("AceConfigDialog-3.0")
local L = S.L

	---------------------
	--- LibDataBroker ---
	---------------------

local dataobject = {
	type = "launcher",
	icon = "Interface\\ChatFrame\\UI-ChatIcon-Chat-Up",
	text = NAME,
	OnClick = function(clickedframe, button)
		if IsModifierKeyDown() then
			SCR:SlashCommand(SCR:IsEnabled() and "0" or "1")
		else
			ACD[ACD.OpenFrames.ScrollingChatText_Parent and "Close" or "Open"](ACD, "ScrollingChatText_Parent")
		end
	end,
	OnTooltipShow = function(tt)
		tt:AddLine("|cffADFF2F"..NAME.."|r")
		tt:AddLine(L.BROKER_CLICK)
		tt:AddLine(L.BROKER_SHIFT_CLICK)
	end,
}

LibStub("LibDataBroker-1.1"):NewDataObject(NAME, dataobject)
