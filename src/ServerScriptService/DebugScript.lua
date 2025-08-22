-- @ScriptType: Script
-- Debug Script for Testing Developer Products
-- Place this script in ServerScriptService
-- This will help you test if developer products are working
-- this is a test 2

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- Wait for MarketplaceHandler to load
local MarketplaceHandler = nil
spawn(function()
	while not _G.MarketplaceHandler do
		wait(0.1)
	end
	MarketplaceHandler = _G.MarketplaceHandler
	print("🔧 Debug Script connected to MarketplaceHandler!")
end)

-- Test the ProcessReceipt function manually
local function testProcessReceipt(playerId, productId)
	local receiptInfo = {
		PlayerId = playerId,
		ProductId = productId,
		PurchaseId = "test_" .. tick() .. "_" .. math.random(1000, 9999)
	}

	print("🧪 Testing ProcessReceipt with:")
	print("  Player ID: " .. playerId)
	print("  Product ID: " .. productId)
	print("  Purchase ID: " .. receiptInfo.PurchaseId)

	local result = MarketplaceService.ProcessReceipt(receiptInfo)
	print("  Result: " .. tostring(result))

	return result
end

-- Enhanced admin commands for testing
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		-- Allow any player to use debug commands (remove this in production)
		-- Replace "YourUsernameHere" with your actual username for security
		local isAdmin = player.Name == "YourUsernameHere" or player.Name == player.Name -- TEMP: Allow all players

		if isAdmin then
			local command = message:lower()

			if command == "/debug" then
				print("🔧 DEBUG INFORMATION:")
				print("  MarketplaceHandler available: " .. tostring(MarketplaceHandler ~= nil))
				print("  ProcessReceipt set: " .. tostring(MarketplaceService.ProcessReceipt ~= nil))
				print("  _G.PlayerTempBoosts available: " .. tostring(_G.PlayerTempBoosts ~= nil))

				if MarketplaceHandler then
					local products = MarketplaceHandler.getDeveloperProducts()
					print("  Developer Products:")
					for name, id in pairs(products) do
						print("    " .. name .. ": " .. id)
					end
				end

			elseif command == "/testcoffee" then
				print("☕ Testing Coffee Purchase...")
				if MarketplaceHandler then
					local products = MarketplaceHandler.getDeveloperProducts()
					testProcessReceipt(player.UserId, products.BUY_COFFEE)
				else
					print("❌ MarketplaceHandler not available")
				end

			elseif command == "/testkey" then
				print("🗝️ Testing Magic Key Purchase...")
				if MarketplaceHandler then
					local products = MarketplaceHandler.getDeveloperProducts()
					testProcessReceipt(player.UserId, products.MAGIC_KEY_SPAWN)
				else
					print("❌ MarketplaceHandler not available")
				end

			elseif command == "/testspeed" then
				print("🚀 Testing Speed Boost Purchase...")
				if MarketplaceHandler then
					local products = MarketplaceHandler.getDeveloperProducts()
					testProcessReceipt(player.UserId, products.SPEED_BOOST_TEMP)
				else
					print("❌ MarketplaceHandler not available")
				end

			elseif command == "/checkspeed" then
				local character = player.Character
				if character and character:FindFirstChildOfClass("Humanoid") then
					local speed = character.Humanoid.WalkSpeed
					print("🏃 Current speed for " .. player.Name .. ": " .. speed)

					if _G.PlayerTempBoosts then
						local hasBoost = _G.PlayerTempBoosts.hasTemporarySpeedBoost(player)
						local timeLeft = _G.PlayerTempBoosts.getRemainingSpeedBoostTime(player)
						print("  Temporary boost active: " .. tostring(hasBoost))
						if hasBoost then
							print("  Time remaining: " .. math.floor(timeLeft) .. " seconds")
						end
					end
				else
					print("❌ No character found")
				end

			elseif command == "/prompttest" then
				print("💳 Testing purchase prompt...")
				if MarketplaceHandler then
					local products = MarketplaceHandler.getDeveloperProducts()
					MarketplaceHandler.promptPurchase(player, products.BUY_COFFEE)
					print("💳 Prompted purchase for coffee (cheapest item)")
				else
					print("❌ MarketplaceHandler not available")
				end

			elseif command == "/gamestate" then
				local CoinCollectorModule = require(game:GetService("ReplicatedStorage"):WaitForChild("CoinCollectorModule"))
				print("🎮 Game State:")
				print("  Game Active: " .. tostring(CoinCollectorModule.gameActive))
				print("  Current Items: " .. #CoinCollectorModule.coins)
				print("  Max Items: " .. CoinCollectorModule.MAX_COINS)
				print("  Time Left: " .. math.floor(CoinCollectorModule.gameTimeLeft))

			elseif command == "/forcekey" then
				local CoinCollectorModule = require(game:GetService("ReplicatedStorage"):WaitForChild("CoinCollectorModule"))
				if MarketplaceHandler and MarketplaceHandler.createMagicKey then
					local success, message = MarketplaceHandler.createMagicKey()
					if success then
						print("🗝️ Force-spawned Magic Key successfully!")
						-- Notify all players
						CoinCollectorModule.notifyAllPlayersAboutMagicKey()
					else
						print("❌ Failed to spawn Magic Key: " .. message)
					end
				else
					print("❌ MarketplaceHandler.createMagicKey not available")
				end

			elseif command == "/testreceipt" then
				print("📋 Testing if ProcessReceipt is working...")
				local testReceipt = {
					PlayerId = player.UserId,
					ProductId = 999999999, -- Fake product ID
					PurchaseId = "debug_test_" .. tick()
				}

				if MarketplaceService.ProcessReceipt then
					local result = MarketplaceService.ProcessReceipt(testReceipt)
					print("📋 ProcessReceipt result for fake product: " .. tostring(result))
				else
					print("❌ ProcessReceipt function not set!")
				end

			elseif command == "/help" then
				print("🔧 DEBUG COMMANDS:")
				print("  /debug - Show debug information")
				print("  /testcoffee - Test coffee purchase")
				print("  /testkey - Test magic key purchase")
				print("  /testspeed - Test speed boost purchase")
				print("  /checkspeed - Check current speed")
				print("  /prompttest - Test purchase prompt")
				print("  /gamestate - Show game state")
				print("  /forcekey - Force spawn magic key")
				print("  /testreceipt - Test ProcessReceipt function")
			end
		end
	end)
end)

-- Monitor ProcessReceipt calls
local originalProcessReceipt = MarketplaceService.ProcessReceipt
if originalProcessReceipt then
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		print("🛒 ProcessReceipt called!")
		print("  Player ID: " .. tostring(receiptInfo.PlayerId))
		print("  Product ID: " .. tostring(receiptInfo.ProductId))
		print("  Purchase ID: " .. tostring(receiptInfo.PurchaseId))

		local result = originalProcessReceipt(receiptInfo)
		print("  Returning: " .. tostring(result))

		return result
	end
	print("🔧 ProcessReceipt monitoring enabled!")
end

-- Show error notifications in chat
local function showError(player, message)
	pcall(function()
		game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
			Text = "🔧 DEBUG: " .. message;
			Color = Color3.fromRGB(255, 100, 100);
		})
	end)
end

print("🔧 Debug Script loaded! Use /help for commands")
print("🔧 All players can use debug commands (REMOVE THIS IN PRODUCTION)")
print("🔧 ProcessReceipt monitoring: " .. (originalProcessReceipt and "✅ ENABLED" or "❌ NOT FOUND"))