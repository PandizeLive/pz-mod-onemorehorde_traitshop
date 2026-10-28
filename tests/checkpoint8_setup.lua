testSide = "server"
testHorde = true
Events.OnServerStarted = event()
Events.EveryTenMinutes = event()
__modules.OMH_EventRules = {}
__modules.OMH_Config = { newLogger = function() return function() end end }
__modules.OMH_Phase3Persistence = {
    getPlayerIdentityId = function(p)
        if isServer() then return p:getUsername() end
        return "singleplayer:" .. p:getPlayerNum()
    end,
    getOrCreatePlayerRecord = function() return testCorePlayer end,
    getOwnerRecord = function() return testCoreOwner end,
}
testCorePlayer = {}
testCoreOwner = {}

OneMoreHordeDifficultyRuntime = {
    isTraitShopEnabled = function() return true end,
    isTraitShopEarningOfficial = function() return true end,
}
