local Screen=require('OMHTS_CreationScreen')
local Prestige=require('OMHTS_Prestige')
check(UI_BORDER_SPACING==nil,'native file-local spacing is not exposed globally')
testPanel:create()
check(testPanel.nativeCreated and testPanel.topOfLists==94,'creation wrapper calls native create and reserves bonus row')
check(testPanel.listboxProf.y==94 and testPanel.listboxProf.height==376
    and testPanel.listboxTrait.y==94 and testPanel.listboxTraitSelected.y==94,
    'all creation lists move below the bonus row without extending profession list bottom')
check(testPanel:PointToSpend()==3,'SP reads pending Prestige on creation screen')
testPanel.basePoints=-2
check(testPanel:PointToSpend()==1,'screen adds bonus once, preserving native chosen-trait balance')
testPanel:render()
check(testPanel.nativeRendered and string.find(testPanel.label,'3'),'native rendering preserved and bonus labeled')
check(testPanel.labelX==500 and testPanel.labelY==43,'bonus label has numeric native-aligned coordinates')
for frame=1,120 do testPanel:render() end
check(testPanel.labelY==43 and testPanel.topOfLists==94,'repeated render does not drift layout')
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
check(Screen.context(testPanel).bonus==nil and #testRequests==0,'creator cannot register bootstrap before native OnConnected')
Events.OnConnected.fire()
MainScreen.instance.desc={}
testPanel:render()
check(Screen.context(testPanel).bonus==3 and #testRequests==0,'first join gets connection bonus without blocked ModData requests')
check(testPanel:PointToSpend()==1,'connection bonus contributes before entering the world')
testPanel:render()
check(#testRequests==0,'no per-frame request flood on first join')
Events.OnReceiveGlobalModData.fire(Prestige.tag('user:5:Alice:0'),{schema=1,bonus=99,revision=10})
check(testPanel:PointToSpend()==1,'unsolicited ordinary reply cannot override first-join snapshot')
testBootstrap.bonuses['user:5:Alice:0']=nil
MainScreen.instance.desc={}
check(testPanel:PointToSpend()==-2,'fresh account gets zero from complete connection snapshot')
testBootstrap={schema=1,ready=false}
Events.OnConnected.fire()
MainScreen.instance.desc={}
testPanel:render()
check(Screen.context(testPanel).unavailable and not testPanel.playButton.enabled
    and string.find(testPanel.label,'PrestigeUnavailable'),'invalid bootstrap explains failure and preserves unknown entitlement')
for frame=1,120 do testPanel:render() end
check(#testRequests==0,'invalid bootstrap does not spam requests that cannot arrive')
testBootstrap={schema=1,ready=true,bonuses={['user:5:Alice:0']=false}}
Events.OnConnected.fire()
MainScreen.instance.desc={}
check(Screen.context(testPanel).unavailable,'invalid account cannot masquerade as zero Prestige')
testBootstrap={schema=1,ready=true,bonuses={['user:5:Alice:0']=3}}
Events.OnConnected.fire()
MainScreen.instance.desc={}
check(testPanel:PointToSpend()==1,'valid bootstrap recovers without spending entitlement')
Events.OnGameStart.fire()
MainScreen.instance.desc={}
testPanel:render()
check(not testPanel.playButton.enabled and #testRequests==1,'respawn requests fresh entitlement after world entry')
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
testBootstrap={schema=1,ready=true,bonuses={['user:5:Alice:0']=8}}
Events.OnDisconnect.fire()
Events.OnConnected.fire()
check(testPanel:PointToSpend()==6,'disconnect invalidates context even if descriptor is reused')
check(#testRequests==2,'reconnection uses bootstrap, not an in-world request')

testOutput=tostring(testChecks)..' Checkpoint 7 assertions passed.'
