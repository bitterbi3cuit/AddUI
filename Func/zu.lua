local _,ns = ...
ns.event("PLAYER_LOGIN", function()

-- Auto-invite on whisper
local function OnWhisperEvent(event, arg1, arg2, _, _, _, _, _, _, _, _, _, _, arg13)
	if IsInInstance() then return end
	if not AddUIDB.zu then return end
	if (not IsInGroup() or UnitIsGroupLeader("player")) 
		and GetNumGroupMembers() <40			-- Invite when group size is less than 40
		and (arg1 == "123") 			-- Auto-invite on "123"
		or (arg1 == "组")			-- Auto-invite on "组" -- To match keyword instead, change to: or arg1:lower():match("组") )
	then
	if (event== "CHAT_MSG_BN_WHISPER") then
		local characterName = C_BattleNet.GetAccountInfoByID(arg13).gameAccountInfo.characterName
		local realmName = C_BattleNet.GetAccountInfoByID(arg13).gameAccountInfo.realmDisplayName
		if characterName and realmName then
		C_PartyInfo.InviteUnit(characterName.."-"..realmName)
		else
		print("The player is invisible or offline and cannot be invited.")
		end
	else
		C_PartyInfo.InviteUnit(arg2)
	end
	end
end

ns.event("CHAT_MSG_WHISPER", OnWhisperEvent)
ns.event("CHAT_MSG_BN_WHISPER", OnWhisperEvent)

end)
