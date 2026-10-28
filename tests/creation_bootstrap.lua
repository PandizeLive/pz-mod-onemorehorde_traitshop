local Bootstrap = require('OMHTS_CreationBootstrap')
function ModData.get(key) return testTables[key] end
local State = require('OMHTS_State')
local store = {}
State.initialize(store)
local account = 'user:5:Alice:0'
local record = State.attach(store, account, 901, 0)
record.prestige.earned = 3
testTables.OMHTraitShop_State_v1 = store
testBootstrap = nativeCreationRoundTrip(Bootstrap.initialState)
check(testBootstrap.ready and testBootstrap.bonuses[account] == 3,
    'actual native initial-state serialization/registration supplies bonus before playerConnectSent')
check(testBootstrap.accounts == nil and testBootstrap.tokens == nil, 'bootstrap never exports account records or wallets')
local zero = State.attach(store, 'user:3:Bob:0', 902, 0)
check(Bootstrap.initialState().bonuses['user:3:Bob:0'] == nil, 'zero accounts omitted from complete map')
store.accounts['broken'] = {prestige={pending=3}}
check(Bootstrap.initialState().bonuses.broken == false, 'invalid account is blocked, not silently zeroed')
store.schema = 999
check(not nativeCreationRoundTrip(Bootstrap.initialState).ready, 'invalid authority schema cannot supply a zero fallback')
store.schema = State.SCHEMA
record.prestige.earned = 7
testBootstrap = nativeCreationRoundTrip(Bootstrap.initialState)
check(testBootstrap.bonuses[account] == 7, 'native client reset/reconnect replaces the previous preview')
testBootstrap.bonuses[account] = 3
CGlobalObjects = {registerSystem=function(name)
    check(name == 'OMHTS_Creation', 'creator uses the registered connection system')
    return {getModData=function() return testBootstrap end}
end}
