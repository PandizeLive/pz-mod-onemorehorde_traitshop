testStage = "Checkpoint 7 Prestige lifecycle"
local State = require("OMHTS_State")
local Creation = require("OMHTS_Creation")
local Prestige = require("OMHTS_Prestige")
local policy = require("OMH_ModSettingsIntegrity")
local function defaults()
    local value = {}
    for i=1,#policy.TRAIT_SHOP_RULES do
        local rule=policy.TRAIT_SHOP_RULES[i]
        value[rule.key]=rule.default
    end
    return value
end
SandboxVars.OMHTraitShop=defaults()
testHorde=true
testSide="server"
local store={}
State.initialize(store)
local first=State.attach(store,"user:5:Alice:0",1,0)
check(first.life.prestigeUnofficial==false,"new official life has verified origin")
first.prestige.earned=3
first.life.tokens=99
first.life.level=14
first.life.xp=30
check(State.settleDeath(first,first.life.id),"first death settles")
check(first.prestige.pending==3 and first.life.tokens==0 and first.life.level==0 and first.life.xp==0,"death preserves only Prestige")
Prestige.publish("user:5:Alice:0",first)
local preview=testTables[Prestige.tag("user:5:Alice:0")]
check(preview.bonus==3 and preview.schema==1,"pre-spawn preview publishes full pending bonus")
check(preview.accounts==nil and preview.tokens==nil and preview.username==nil,"preview excludes wallet and account records")
local revision=first.revision
check(not State.settleDeath(first,first.life.id) and first.revision==revision,"replayed death cannot add a second bonus")
store=nativeRoundTrip(store)
check(State.initialize(store),"pending bonus survives disk round trip")
local record=State.attach(store,"user:5:Alice:0",2,0)
local alice=player("Alice",0,2,0)
testProfession.cost=0
alice.traits={['base:fastreader']=true}
check(Creation.remainingPoints(alice)==nil and Creation.remainingPoints(alice,3)==1,"Prestige permits spending beyond vanilla budget")
check(Creation.settle(alice,record),"successful entry settles Prestige")
check(record.life.tokens==1 and record.life.creation.prestigeBonus==3 and record.life.creation.prestigeTokens==1,"only unspent point becomes a Token")
check(record.prestige.pending==0 and record.prestige.retained==1 and record.prestige.earned==0,"3 bonus retains 1, without earned Prestige")
check(record.life.level==0 and record.life.xp==0 and record.life.creation.prestigeUnofficial==false,"starts at displayed Level 1 and preserves official origin")
record=nativeRoundTrip(record)
local revision=record.revision
check(not Creation.settle(alice,record) and record.revision==revision and record.life.tokens==1,"repeated entry cannot grant or retain twice")
store.accounts['user:5:Alice:0']=record
local resumed,result=State.attach(store,'user:5:Alice:0',2,0.1)
check(result=='resumed' and resumed.prestige.retained==1,"reconnect keeps retained balance")
State.settleDeath(record,record.life.id)
check(record.prestige.pending==1,"second death transfers the retained 1")
record=State.attach(store,'user:5:Alice:0',3,0)
alice.traits={}
check(Creation.settle(alice,record) and record.life.tokens==1 and record.prestige.retained==0,"1 bonus rounds to 0 retained")
State.settleDeath(record,record.life.id)
check(record.prestige.pending==0,"no minimum-one immortality")
record=State.attach(store,'user:5:Alice:0',4,0)
record.prestige.pending=5
record.prestige.unofficial=true
SandboxVars.OMHTraitShop.PrestigeRetentionPercentage=10
check(Creation.settle(alice,record) and record.prestige.retained==1,"exact half rounds up")
check(record.life.creation.prestigeUnofficial and record.life.prestigeUnofficial,"custom inheritance taints benefits and future earnings")
SandboxVars.OMHTraitShop.PrestigeRetentionPercentage=100
local isolated=State.attach(store,'user:3:Bob:0',5,0)
isolated.prestige.pending=3
check(Creation.settle(alice,isolated) and isolated.prestige.retained==3,"100 percent retains all")
check(record.prestige.retained==1,"other account is untouched")
local invalid=State.attach(store,'invalid',6,0)
invalid.prestige.pending=3
SandboxVars.OMHTraitShop.PrestigeRetentionPercentage=101
check(not Creation.settle(alice,invalid) and invalid.prestige.pending==3 and invalid.life.creation.status=='pending',"invalid retention leaves entitlement untouched")
SandboxVars.OMHTraitShop.PrestigeRetentionPercentage=0
check(Creation.settle(alice,invalid) and invalid.prestige.retained==0 and invalid.life.tokens==3,"zero retention still gives full creation bonus")
local overflow=State.attach(store,'overflow',7,0)
overflow.prestige.pending=State.LIMIT
testProfession.cost=5
Creation.settle(alice,overflow)
check(overflow.life.creation.status=='invalid' and overflow.prestige.pending==State.LIMIT and overflow.life.tokens==0,"overflow preserves pending entitlement without minting")
testProfession.cost=0
local old=State.attach(store,'old',8,10)
old.prestige.pending=3
check(not Creation.settle(alice,old) and old.prestige.pending==3,"aged character cannot claim a new creation bonus")
local legacy=State.attach(store,'legacy',9,0)
legacy.prestige.earned=3
legacy.prestige.unofficial=nil
legacy.life.prestigeUnofficial=nil
State.settleDeath(legacy,legacy.life.id)
check(legacy.prestige.unofficial,"pre-audit Prestige cannot become verified by migration")
SandboxVars.OMHTraitShop=defaults()
local mixed=State.attach(store,'mixed',10,0)
SandboxVars.OMHTraitShop.TokensPerLevel=2
check(State.awardXP(mixed,mixed.life.id,mixed.revision,10) and mixed.life.prestigeUnofficial,"custom XP below a milestone preserves origin")
SandboxVars.OMHTraitShop=defaults()
State.awardXP(mixed,mixed.life.id,mixed.revision,1000)
check(mixed.prestige.earned>0 and mixed.prestige.unofficial,"restoring rules cannot clean custom XP origin")
local clean=State.attach(store,'clean',11,0)
State.awardXP(clean,clean.life.id,clean.revision,1000)
check(clean.prestige.earned>0 and clean.prestige.unofficial==false,"verified earnings remain verified")
check(Prestige.tag('user:1:A:0')~=Prestige.tag('user:1:a:0'),"preview account encoding is case preserving")
check(Prestige.encode(string.char(4660))~=Prestige.encode(string.char(18)..string.char(52)),"native Unicode code units cannot collide with ASCII sequences")
testSide='singleplayer'
Prestige.publish('local:0',legacy)
local path=Prestige.localPath(0)
check(tonumber(testFiles[path])==3,"SP menu preview is written outside the Lua VM")
check(Prestige.localPath(1)~=path,"SP slots have separate previews")
testTransportPackets={preview,State.snapshot(record,0)}

testStage='Checkpoint 7 creation screen and cancellation'
MainScreen={instance={desc={},createWorld=false}}
CharacterCreationProfession={PointToSpend=function(self) return self.basePoints end,render=function(self) self.nativeRendered=true end}
function getClientUsername() return 'Alice' end
function getText(key,value) return key .. tostring(value) end
UIFont={Small=1}
UI_BORDER_SPACING=10
function getTextManager() return {getFontHeight=function() return 20 end} end
testRequests={}
function ModData.request(tag) testRequests[#testRequests+1]=tag end
testPanel={basePoints=0,width=1000,playButton={setEnable=function(self,value) self.enabled=value end,
    setTooltip=function() end,getY=function() return 600 end},drawTextCentre=function(self,text) self.label=text end}
setmetatable(testPanel,{__index=CharacterCreationProfession})
testStore=store
