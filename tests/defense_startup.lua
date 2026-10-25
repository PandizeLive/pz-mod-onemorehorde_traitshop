testStage = "SP defense startup identity"
local p = player("Bob", 0, 1, 0)
local originalPrint, auditLines = print, {}
print = function(line) auditLines[#auditLines + 1] = tostring(line) end
testPlayers = {p}
SandboxVars.OMHTurretsTraps = {DefenseXPEnabled = true, DefenseXPPercent = 50,
    Enabled = true, TurretsEnabled = true, DiagnosticLogging = true, TurretDiagnosticLogging = true, TurretDetailedLogging = true}
Events.OnInitGlobalModData.fire(true)
Events.OnNewGame.fire(p, nil)
Events.OnCreatePlayer.fire(0, p)
local store = ModData.getOrCreate("OMHTraitShop_State_v1")
local record = store.accounts["local:0"]
check(store.defense.members["local:0"].username == "Bob", "constructor name initially registered")
p.name = "Test Survivor"
Events.OnGameStart.fire()
local Credit = require("OMHTS_DefenseCredit")
local function death(owner, manual)
    local z = {kind = "IsoZombie", isDead = function() return true end,
        isOnKillDone = function() return false end, getModData = function() return {} end,
        getAttackedBy = function() if manual then return p end end}
    if not manual then Credit.zombieFinisher(z, owner, nil) end
    Events.OnZombieDead.fire(z)
    Events.OnZombieDead.fire(z)
end
for i = 1, 7 do death(p.name, false) end
death(nil, true)
death(nil, true)
check(record.life.xp == 11, "seven turret and two manual kills pay eleven, duplicates pay nothing")
check(store.defense.members["local:0"].username == p.name, "game-start refresh retains the stable account")
death("Bob", false)
check(record.life.xp == 11, "old constructor alias cannot claim ownership")
local oldLife = record.life.id
Events.OnSave.fire()
Events.OnInitGlobalModData.fire(false)
Events.OnGameStart.fire()
check(store.accounts["local:0"].life.id == oldLife and record.life.xp == 11, "same-life reload retains awards")
death(p.name, false)
check(record.life.xp == 12, "same-life restored identity receives subsequent credit")
SandboxVars.OMHTurretsTraps.DefenseXPPercent = 0
death(p.name, false)
check(record.life.xp == 12, "zero percent does not manufacture a minimum reward")
require("OMHTS_Rewards").flushAudit(true)
local reconciled = false
for i = 1, #auditLines do
    local line = auditLines[i]
    if string.find(line, "xp-summary", 1, true) and string.find(line, "defense-paid-xp=7", 1, true)
        and string.find(line, "ordinary-paid-xp=4", 1, true) then reconciled = true end
end
check(reconciled, "bounded summary reconciles seven defense XP and four manual XP")
print = originalPrint
testOutput = testChecks .. " SP defense startup assertions passed"
