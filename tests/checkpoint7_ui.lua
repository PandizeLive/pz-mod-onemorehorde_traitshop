local Screen=require('OMHTS_CreationScreen')
local Prestige=require('OMHTS_Prestige')
check(testPanel:PointToSpend()==3,'SP reads pending Prestige on creation screen')
testPanel.basePoints=-2
check(testPanel:PointToSpend()==1,'screen adds bonus once, preserving native chosen-trait balance')
testPanel:render()
check(testPanel.nativeRendered and string.find(testPanel.label,'3'),'native rendering preserved and bonus labeled')
local before=testStore.accounts['legacy'].prestige.pending
MainScreen.instance.desc={}
check(testPanel:PointToSpend()==1 and testStore.accounts['legacy'].prestige.pending==before,'cancellation/reopening never spends Prestige')
MainScreen.instance.createWorld=true
MainScreen.instance.desc={}
check(testPanel:PointToSpend()==-2,'new world cannot use a previous world preview')
CoopCharacterCreation={instance={playerIndex=0}}
MainScreen.instance.desc={}
check(testPanel:PointToSpend()==1,'in-world respawn reads preview even when original new-world flag remains set')
CoopCharacterCreation=nil
testSide='client'
MainScreen.instance.desc={}
testPanel:render()
check(not testPanel.playButton.enabled and #testRequests==1,'MP waits for pre-spawn reply before enabling Next')
testPanel:render()
check(#testRequests==1,'no per-frame request flood')
Events.OnReceiveGlobalModData.fire(Prestige.tag('user:3:Bob:0'),{schema=1,bonus=100,revision=10})
check(Screen.context(testPanel).bonus==nil,'other account reply ignored')
Events.OnReceiveGlobalModData.fire(Prestige.tag('user:5:Alice:0'),{schema=1,bonus=3,revision=10})
check(testPanel:PointToSpend()==1,'own server preview supplies creation bonus')
Events.OnReceiveGlobalModData.fire(Prestige.tag('user:5:Alice:0'),{schema=1,bonus=99,revision=9})
check(testPanel:PointToSpend()==1,'older preview cannot replace newer data')
Events.OnReceiveGlobalModData.fire(Prestige.tag('user:5:Alice:0'),{schema=1,bonus=-1,revision=11})
check(testPanel:PointToSpend()==1,'malformed bonus rejected')
MainScreen.instance.desc={}
testPanel:PointToSpend()
Events.OnReceiveGlobalModData.fire(Prestige.tag('user:5:Alice:0'),false)
check(testPanel:PointToSpend()==-2,'fresh account without stored preview has zero bonus')
testOutput=tostring(testChecks)..' Checkpoint 7 assertions passed.'
