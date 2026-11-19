if isClient() then return end

local Config = require("OMHTS_RewardsConfig")
if not Config.hasHordeNight() then return end

local Extensions = require("OMH_Extensions")
local TraitShop = require("OMHTS_Bootstrap")
local Authority = require("OMHTS_Authority")
if not Config.hasHordeRewards() then
    print("[OMH Trait Shop] Horde XP requires Horde Night 0.6.15 or newer; standalone rewards remain available")
    return
end

local accepted, reason = Extensions.register({
    id = "OMH.TraitShop.Rewards",
    apiVersion = 3,
    version = TraitShop.VERSION,
    capabilities = { hordeEvents = true },
    eventHooks = { onKill = Authority.onHordeKill, onFinished = Authority.onHordeFinished },
})
if not accepted then
    print("[OMH Trait Shop] Horde reward registration rejected: " .. tostring(reason))
else
    print("[OMH Trait Shop] Horde reward adapter registered; API 3")
end
