local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileStore = require(ReplicatedStorage.Packages.ProfileStore)

local PROFILE_TEMPLATE = {
	Cash = 0,
	Items = {},
}

local DATA_KEY = "TEST_1"

local PlayerStore = ProfileStore.New(DATA_KEY, PROFILE_TEMPLATE)
local Profiles: { [Player]: typeof(PlayerStore:StartSessionAsync()) } = {}

local function PlayerAdd(Player)
	-- Start a profile session for this player's data:

	local Profile = PlayerStore:StartSessionAsync(`{Player.UserId}`, {
		Cancel = function()
			return Player.Parent ~= Players
		end,
	})

	-- Handling new profile session or failure to start it:

	if Profile ~= nil then
		Profile:AddUserId(Player.UserId) -- GDPR compliance
		Profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

		Profile.OnSessionEnd:Connect(function()
			Profiles[Player] = nil
			Player:Kick(`Profile session end - Please rejoin`)
		end)

		if Player.Parent == Players then
			Profiles[Player] = Profile
			print(`Profile loaded for {Player.DisplayName}!`)
			-- EXAMPLE: Grant the player 100 coins for joining:
			Profile.Data.Cash += 100
		-- You should set "Cash" in PROFILE_TEMPLATE and use "Profile:Reconcile()",
		-- otherwise you'll have to check whether "Data.Cash" is not nil
		else
			-- The player has left before the profile session started
			Profile:EndSession()
		end
	else
		-- This condition should only happen when the Roblox server is shutting down
		Player:Kick(`Profile load fail - Please rejoin`)
	end
end

Players.PlayerAdded:Connect(PlayerAdd)

-- In case Players have joined the server earlier than this script ran:
for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdd, player)
end
