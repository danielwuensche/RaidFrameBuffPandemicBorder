local ADDON_NAME = "RaidFrameBuffPandemicBorder"
local THRESHOLD = 0.30 -- 30% threshold
local UPDATE_INTERVAL = 0.2 -- seconds between updates
local BORDER_COLOR = { r = 1, g = 0.2, b = 0.2, a = 1 } -- red border
local BORDER_SIZE = 2

TrackedFrames = {} -- { key: buffFrame, val: borderFrame, shown, auraInstanceID }
setmetatable(TrackedFrames, { __mode = "k" })
local timeSinceUpdate = 0

local function CreateBorder(parent)
	local border = parent:CreateTexture(nil, "OVERLAY")
	border:SetPoint("TOPLEFT", parent, "TOPLEFT", -BORDER_SIZE, BORDER_SIZE)
	border:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", BORDER_SIZE, -BORDER_SIZE)
	border:SetColorTexture(BORDER_COLOR.r, BORDER_COLOR.g, BORDER_COLOR.b, BORDER_COLOR.a)
	border:SetDrawLayer("ARTWORK", -1)
	border:Hide()

	return border
end

local function IsInPandemicWindow(unitAura)
	local duration = unitAura.duration
	local expirationTime = unitAura.expirationTime

	if duration and duration > 0 then
		local remaining = expirationTime - GetTime()
		local remainingThreshold = duration * THRESHOLD
		if remaining > 0 and remaining <= remainingThreshold then
			return true
		else
			return false
		end
	else
		return false
	end
end

local function FindUnitAura(unitAuras, auraInstanceID)
	for _, unitAura in pairs(unitAuras) do
		if unitAura.auraInstanceID == auraInstanceID then
			return unitAura
		end
	end
	return false
end

local function IterateMemberFrame(memberFrame)
	-- iterate over party member frames
	if memberFrame and memberFrame:IsShown() then
		-- get current memberFrame unit type (player, party1, party2, etc.)
		local unitToken = memberFrame.displayedUnit

		-- get all buffs of that unit casted by myself
		local unitAuras = C_UnitAuras.GetUnitAuras(unitToken, "PLAYER HELPFUL RAID_IN_COMBAT")

		-- iterate over all buff frames of that units party frame
		if memberFrame.buffFrames then
			for _, buffFrame in pairs(memberFrame.buffFrames) do
				if not TrackedFrames[buffFrame] then
					TrackedFrames[buffFrame] = { CreateBorder(buffFrame), false }
				end

				local border = TrackedFrames[buffFrame]

				border[2] = false -- set "shown" back to init
				-- border[3] = nil -- clear auraInstanceID

				-- -- track auraInstanceID alongside the buffFrame
				-- if buffFrame.auraInstanceID then
				-- 	border[3] = buffFrame.auraInstanceID
				-- end

				-- check if the aura last displayed is still active
				if buffFrame:IsShown() and buffFrame.auraInstanceID then
					-- local unitAura = FindUnitAura(unitAuras, border[3])
					local unitAura = FindUnitAura(unitAuras, buffFrame.auraInstanceID)
					if unitAura then
						-- show border if aura is in pandemic window
						border[2] = IsInPandemicWindow(unitAura)
					end
				end

				if border[2] then
					border[1]:Show()
				else
					border[1]:Hide()
				end
			end
		end
	end
end

local function RunMainRoutine()
	for _, memberFrame in pairs(CompactPartyFrame.memberUnitFrames) do
		IterateMemberFrame(memberFrame)
	end

	for _, memberFrame in pairs(CompactRaidFrameContainer.flowFrames) do
		if type(memberFrame) == "table" then
			IterateMemberFrame(memberFrame)
		end
	end
end

local frame = CreateFrame("Frame", ADDON_NAME .. "Frame", UIParent)

frame:SetScript("OnUpdate", function(self, elapsed)
	timeSinceUpdate = timeSinceUpdate + elapsed
	if timeSinceUpdate >= UPDATE_INTERVAL then
		timeSinceUpdate = 0
		RunMainRoutine()
	end
end)
