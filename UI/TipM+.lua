local _,ns = ...
ns.tips("Mythic+ Score UI Tooltip Enhancement")--https://ngabbs.com/read.php?tid=42357797

local function HookDungeonIcons()
	if not ChallengesFrame then
		return
	end
	
	for _, icon in ipairs(ChallengesFrame.DungeonIcons) do
		icon:HookScript("OnEnter", function(self)
				local mapChallengeModeID = self.mapID
				if not mapChallengeModeID then return end
				
				-- Dungeon completion times are stored in UTC; adjust manually to local time
				local offset = 8
				
				local dungeonName, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapChallengeModeID)
				if not dungeonName or not timeLimit then return end
				
				local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mapChallengeModeID)
				
				
				GameTooltip:ClearLines()
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				
				if intimeInfo then
					GameTooltip:AddLine(dungeonName, 1, 1, 1)
					
					local scoreColor = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(intimeInfo.dungeonScore)
					if scoreColor then
						GameTooltip:AddLine("Score: |c" .. scoreColor:GenerateHexColor() .. intimeInfo.dungeonScore .. "|r")
					else
						GameTooltip:AddLine("Score: " .. intimeInfo.dungeonScore)
					end
					
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine("Best Run", 1, 0.75, 0)
					GameTooltip:AddLine("Level " .. intimeInfo.level, 1, 1, 1)
					
					local completionTimeFormatted = string.format("%02d:%02d", math.floor(intimeInfo.durationSec / 60), intimeInfo.durationSec % 60)
					local remainingTime = timeLimit - intimeInfo.durationSec
					local remainingTimeFormatted
					
					if remainingTime >= 0 then
						remainingTimeFormatted = string.format("Remaining %02d:%02d", math.floor(remainingTime / 60), remainingTime % 60)
					else
						remainingTimeFormatted = string.format("Overtime %02d:%02d", math.abs(math.floor(remainingTime / 60)), math.abs(remainingTime % 60))
					end
					
					GameTooltip:AddLine("Time " .. completionTimeFormatted .. " (" .. remainingTimeFormatted .. ")", 1, 1, 1)
					GameTooltip:AddLine(" ")
					
					GameTooltip:AddLine("Team Members", 1, 0.75, 0)
					if intimeInfo.members then
						for _, member in ipairs(intimeInfo.members) do
							if member then
								local className = select(2,GetClassInfo(member.classID)) or "Unknown Class"
								local color = RAID_CLASS_COLORS[className] or {r = 255, g = 255, b = 255}
								local memberName = member.name or "Unknown"
								local specName = select(2,GetSpecializationInfoByID(member.specID)) or "Unknown Spec"
								GameTooltip:AddLine(memberName.."("..specName..")", color.r, color.g, color.b)
							end
						end
					end
					
					GameTooltip:AddLine(" ")
					local totalTimeFormatted = string.format("%02d:%02d", math.floor(timeLimit / 60), timeLimit % 60)
					GameTooltip:AddLine("Dungeon Timer: " .. totalTimeFormatted, 1, 1, 1)
					
					local completionDate = intimeInfo.completionDate
					if completionDate then
						local adjustedYear = completionDate.year
						local adjustedMonth = completionDate.month
						local adjustedDay = completionDate.monthDay
						local adjustedHour = completionDate.hour + offset
						local adjustedMinute = completionDate.minute
						
						if adjustedHour >= 24 then
							adjustedHour = adjustedHour - 24
							adjustedDay = adjustedDay + 1
						end
						
						GameTooltip:AddLine(string.format("Completion Date: %d/%02d/%02d %02d:%02d", adjustedYear, adjustedMonth, adjustedDay, adjustedHour, adjustedMinute), 1, 1, 1)
					else
						GameTooltip:AddLine("Date: Unavailable", 1, 1, 1)
					end
				else
					GameTooltip:AddLine("No records for this season", 1, 0.5, 0.5)
				end
				
				GameTooltip:Show()
		end)
		
		icon:HookScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
end

local T=CreateFrame("frame")
T:RegisterEvent('ADDON_LOADED')
T:SetScript("OnEvent",function(_,_,msg)
	if msg == 'Blizzard_ChallengesUI' then
		HookDungeonIcons()
		ChallengesFrame:HookScript("OnShow",HookDungeonIcons)
	end
end)
