"""Generate the committed JSON contract without third-party dependencies."""
import json
from pathlib import Path

def ref(name): return {"$ref": f"#/components/schemas/{name}"}
def obj(properties, required=()): return {"type":"object", "properties":properties, "required":list(required)}
def arr(item): return {"type":"array", "items":item}
S={"type":"string"}
I={"type":"integer"}
N={"type":"number"}
B={"type":"boolean"}
def enum(*values): return {"type":"string", "enum":list(values)}
def page(item): return obj({"items":arr(ref(item)),"total":I,"offset":I,"limit":I},["items","total","offset","limit"])
attributes={k:{"type":"number","minimum":1,"maximum":100} for k in ['speed','strength','stamina','agility','passing','handling','tackling','kicking','scrum','lineout','discipline','decisions','leadership','ruck','maul','attacking','defensiveReading']}
schemas={
 "Error":obj({"code":S,"message":S,"details":{"type":"object"},"requestId":S},['code','message','details','requestId']),
 "Tactic":obj({"style":enum('hands','balanced','kicking'),"tempo":enum('slow','normal','fast'),"defense":enum('low','normal','high')},['style','tempo','defense']),
 "Attributes":obj(attributes,attributes.keys()),
 "Club":obj({"id":S,"name":S,"city":S,"color":S,"officialName":S,"shortName":S,"competitionId":I,"competition":S,"officialTeamId":I,"sourceUrl":S,"sourceVerifiedOn":S,"season":S,"generatedRoster":B,"initialBalance":I,"balance":I,"day":I,"date":{"type":"string","format":"date"},"version":I},['id','name','balance','day','date','version']),
 "Player":obj({"id":S,"clubId":S,"name":S,"age":I,"category":enum('senior','academy'),"position":{"type":"integer","minimum":1,"maximum":15},"positionRole":S,"positionName":S,"positionGroup":enum("forwards","backs"),"secondary":arr(I),"potential":N,"potentialDate":{"type":"string","format":"date"},"potentialTrend":enum("growth","decline","stable"),"average":N,"morale":N,"form":N,"energy":N,"available":B,"recoveryDay":I,"weeklyWage":I,"seniorWeeklyWage":I,"birthDay":I,"developmentYear":I,"developmentGains":{"type":"object","additionalProperties":N},"developmentModel":S,"developmentSeason":S,"developmentProgress":N,"attributes":ref('Attributes'),"version":I},['id','clubId','name','category','position','attributes']),
 "LineupSlot":obj({"position":{"type":"integer","minimum":1,"maximum":15},"playerId":S},['position','playerId']),
 "Lineup":obj({"id":S,"clubId":S,"name":{"type":"string","minLength":1,"maxLength":80},"slots":{"type":"array","minItems":15,"maxItems":15,"items":ref('LineupSlot')},"bench":{"type":"array","maxItems":8,"uniqueItems":True,"items":S},"captainId":S,"tactic":ref('Tactic'),"version":I},['name','slots','bench','captainId','tactic']),
 "Validation":obj({"valid":B,"errors":arr(S)},['valid','errors']),
 "TrainingGroup":obj({"id":S,"name":{"type":"string","minLength":1,"maxLength":60},"focus":enum(*attributes.keys(),'recovery'),"intensity":enum('low','normal','high'),"playerIds":{"type":"array","minItems":1,"maxItems":100,"uniqueItems":True,"items":S}},['id','name','focus','intensity','playerIds']),
 "Training":obj({"id":S,"clubId":S,"groups":{"type":"array","maxItems":50,"items":ref('TrainingGroup')},"dailyCost":{"type":"integer","enum":[0],"description":"Sin coste adicional: cubierto por las nóminas."},"modelVersion":S,"version":I},['groups','version']),
 "TrainingSuggestion":obj({"groups":arr(ref('TrainingGroup')),"variant":I,"playerCount":I,"recoveryCount":I,"dailyCost":{"type":"integer","enum":[0],"description":"Sin coste adicional: cubierto por las nóminas."}},['groups','variant','playerCount','recoveryCount','dailyCost']),
 "TrainingType":obj({"id":S,"name":S,"coachRole":S,"supportRole":S},['id','name','coachRole','supportRole']),
 "Coach":obj({"id":S,"clubId":S,"name":S,"role":enum('head','forwards','backs','defense','attack','skills','fitness','academy'),"quality":{"type":"integer","minimum":1,"maximum":100},"weeklyWage":I,"monthlyWage":I,"effectiveness":N,"status":enum('available','employed'),"version":I},['id','name','role','quality','weeklyWage','effectiveness','status']),
 "StaffRole":obj({"id":S,"name":S,"englishName":S,"description":S,"baseWeeklyWage":I}),
 "Staff":obj({"id":S,"clubId":S,"version":I,"coaches":arr(ref('Coach')),"weeklyWage":I,"monthlyWage":I,"payPeriod":S,"roles":arr(ref('StaffRole'))},['id','clubId','version','coaches','weeklyWage','roles']),
 "HireCoach":obj({"coachId":S,"version":I},['coachId','version']),
 "TrainingExecution":obj({"id":S,"clubId":S,"day":I,"modelVersion":S,"groups":arr(ref('TrainingGroup')),"staffSnapshot":arr(ref('Coach')),"trainingCost":I,"playerWeeklyWages":I,"staffWeeklyWages":I,"results":arr({"type":"object","description":"playerId, groupId, focus, age, energyDelta, attributeGain, averageBefore, averageAfter, averageDelta, annualTarget, changes[{attribute,before,after,delta,reason}]"})},['id','clubId','day','results']),
 "Movement":obj({"id":S,"clubId":S,"day":I,"date":S,"amount":I,"type":enum('training','wages','staffWages','match','transfer'),"concept":S,"source":S,"idempotencyKey":S},['id','amount','concept']),
 "Finances":obj({"balance":I,"initialBalance":I,"currency":{"const":"EUR"},"unit":{"const":"cent"},"negative":B},['balance','initialBalance','currency','unit','negative']),
 "Fixture":obj({"id":S,"clubId":S,"homeId":S,"awayId":S,"day":I,"status":enum('scheduled','live','finished'),"matchId":S,"homeScore":I,"awayScore":I},['id','homeId','awayId','day','status','matchId']),
 "Stats":{"type":"object","additionalProperties":N,"description":"actions, possessionSeconds, metres, carries, tackles, conversionAttempts, penaltyAttempts, dropAttempts, knockOns, points, turnovers, scrums, lineouts, penalties, tries, conversions, penaltyGoals, drops, kicks, passes, yellowCards, redCards, infringements"},
 "Snapshot":obj({"id":S,"matchId":S,"playerId":S,"clubId":S,"side":enum('home','away'),"name":S,"attributes":ref('Attributes'),"position":I,"naturalPosition":I,"positionRole":S,"positionName":S,"positionGroup":enum("forwards","backs"),"secondary":arr(I),"status":enum('field','bench','replaced','sinBin','sentOff'),"energy":N,"form":N,"morale":N,"stats":ref('Stats')},['id','playerId','status','energy','attributes']),
 "Match":obj({"id":S,"clubId":S,"fixtureId":S,"homeId":S,"awayId":S,"homeName":S,"awayName":S,"homeColor":S,"awayColor":S,"lineupId":S,"status":enum('scheduled','first','halftime','second','finished'),"period":I,"clock":I,"speed":{"type":"integer","enum":[0,1,5,20,60]},"pauseReason":S,"pauseMessage":S,"pausedClock":I,"pausedPlayerId":S,"credit":N,"homeScore":I,"awayScore":I,"possession":enum('home','away'),"x":{"type":"number","minimum":0,"maximum":100},"y":{"type":"number","minimum":0,"maximum":70},"phase":enum('restart','open','ruck','scrum','lineout','penalty','conversion','stoppage'),"seed":I,"rng":I,"engineVersion":S,"sequence":I,"commandSequence":I,"version":I,"settled":B,"homeSubs":I,"awaySubs":I,"homePlayers":arr(ref('Snapshot')),"awayPlayers":arr(ref('Snapshot')),"homeStats":ref('Stats'),"awayStats":ref('Stats'),"homeTactic":ref('Tactic'),"awayTactic":ref('Tactic')},['id','status','clock','sequence','version']),
 "Event":obj({"id":S,"matchId":S,"sequence":I,"period":I,"clock":I,"type":S,"side":enum('home','away',''),"playerId":S,"from":obj({'x':N,'y':N}),"to":obj({'x':N,'y':N}),"points":{"type":"integer","enum":[0,2,3,5]},"homeScore":I,"awayScore":I,"result":obj({'phase':S,'possession':S,'inGoal':B}),"text":S},['id','sequence','clock','type','points','text']),
 "SpeedCommand":obj({"type":{"const":"speed"},"speed":{"type":"integer","enum":[0,1,5,20,60]}},['type','speed']),
 "TacticCommand":obj({"type":{"const":"tactic"},"tactic":ref('Tactic')},['type','tactic']),
 "SubstitutionCommand":obj({"type":{"const":"substitution"},"outId":S,"inId":S},['type','outId','inId']),
 "CommandRequest":{"oneOf":[ref('SpeedCommand'),ref('TacticCommand'),ref('SubstitutionCommand')],"discriminator":{"propertyName":"type","mapping":{k:f'#/components/schemas/{v}' for k,v in [('speed','SpeedCommand'),('tactic','TacticCommand'),('substitution','SubstitutionCommand')]}}},
 "Command":obj({"id":S,"matchId":S,"clubId":S,"side":S,"type":enum('speed','tactic','substitution'),"parameters":ref('CommandRequest'),"idempotencyKey":S,"sequence":I,"status":enum('pending','applied','rejected'),"receivedClock":I,"appliedClock":I,"reason":S,"source":enum('user','ai')},['id','type','status','sequence','reason']),
 "CreateMatch":obj({"fixtureId":S,"lineupId":S,"seed":{"type":"integer","minimum":1,"maximum":2147483646,"default":17341}},['fixtureId']),
 "Version":obj({"version":I},['version']),
 "Health":obj({"status":S,"workerHeartbeat":N}),
}
schemas['Player']['properties'].update({'signingFee':I,'askingWeeklyWage':I,'nationalityCode':S,'nationality':S,'realIdentity':B,'identityClubId':S,'identitySource':S,'identitySourceId':S,'identitySourceFile':S,'identitySourcePage':I,'identityMatchDate':S,'identityMatchCode':S,'identitySeason':S,'identityRawName':S,'identityCategory':S,'positionSource':S,'frontRowQualifications':arr(S),'nationalitySource':S,'ageSource':S,'attributesSource':S,'wageSource':S})
schemas['Negotiation']=obj({'id':S,'clubId':S,'playerId':S,'player':ref('Player'),'version':I,'playerVersion':I,'kind':enum('signing','promotion','renewal'),'contractEndDate':{'type':'string','format':'date'},'status':enum('open','counteroffer','agreed','signed','rejected','withdrawn','expired','unavailable','changed'),'askingWeeklyWage':I,'counterWeeklyWage':I,'agreedWeeklyWage':I,'signingFee':I,'round':I,'maxRounds':I,'createdDay':I,'updatedDay':I,'expiresDay':I,'contractId':S,'contractYears':I,'counterContractYears':I,'agreedContractYears':I,'preferredMinYears':I,'preferredMaxYears':I,'offers':arr(obj({'round':I,'day':I,'offeredWeeklyWage':I,'offeredContractYears':I,'counterContractYears':I,'agreedContractYears':I,'status':S,'counterWeeklyWage':I}))},['id','playerId','player','version','status','offers'])
schemas['NegotiationPage']=page('Negotiation')
schemas['Player']['properties'].update({'attributeSeasonChanges':{'type':'object','additionalProperties':{'type':'number'}},'attributeSeasonYear':I,'contractYears':{'type':'integer','minimum':1,'maximum':5},'contractEndDate':{'type':'string','format':'date'},'contractStatus':S,'retirementAnnounced':B,'retirementDate':{'type':'string','format':'date'},'retired':B})
schemas['Club']['properties'].update({'seasonYear':I,'seasonStartDate':{'type':'string','format':'date'}})
schemas['SalaryOffer']=obj({'version':I,'contractYears':{'type':'integer','minimum':1,'maximum':5},'weeklyWage':{'type':'integer','minimum':100,'maximum':5000000,'multipleOf':100},'monthlyWage':{'type':'integer','minimum':500,'maximum':21666600,'multipleOf':100}},['version'])
schemas['SalaryOffer']['oneOf']=[{'required':['monthlyWage'],'not':{'required':['weeklyWage']}},{'required':['weeklyWage'],'not':{'required':['monthlyWage']}}]
schemas['Club']['properties'].update({'aiLastDay':I,'aiAdoptedDay':I,'aiSeason':{'oneOf':[I,{'const':''}]},'aiSignings':I,'aiPromotions':I})
schemas['ReleaseResult']=obj({'playerId':S,'name':S,'formerClubId':S,'status':{'const':'released'},'day':I,'fee':I},['playerId','name','status','day','fee'])
schemas['Player']['properties'].update({'contractStatus':S,'formerClubId':S,'releasedDay':I,'previousWeeklyWage':I})
schemas['Kit']=obj({'id':enum('primary','secondary'),'name':S,'color':{'type':'string','pattern':'^#[0-9a-fA-F]{6}$'},'numberColor':S},['id','name','color','numberColor'])
schemas['Club']['properties'].update({'kits':obj({'primary':obj({'color':S}), 'secondary':obj({'color':S})}), 'kitVersion':S})
schemas['Match']['properties'].update({'homeKit':ref('Kit'),'awayKit':ref('Kit'),'kitVersion':S,'kitClashResolved':B})
schemas['LeaguePoints']=obj({'basePoints':I,'bonusOffensive':I,'bonusDefensive':I,'total':I},['basePoints','bonusOffensive','bonusDefensive','total'])
schemas['Classification']=obj({'eligible':B,'rule':S,'home':ref('LeaguePoints'),'away':ref('LeaguePoints')},['eligible','rule'])
schemas['Match']['properties']['classification']=ref('Classification')
schemas['Fixture']['properties']['classification']=ref('Classification')
schemas['Snapshot']['properties'].update({'yellowCards':I,'redCards':I,'sinBinUntil':I,'redCardReason':S,'infringements':I,'cards':arr(obj({'color':enum('yellow','red'),'clock':I,'reason':S}))})
schemas['Match']['properties'].update({'disciplineVersion':S,'redCardRule':{'const':'permanent'}})
schemas['Fixture']['properties'].update({'homeYellowCards':I,'awayYellowCards':I,'homeRedCards':I,'awayRedCards':I,'disciplineVersion':S,'redCardRule':S,'disciplineEvents':arr(obj({'type':enum('yellowCard','redCard','sinBinReturn'),'side':enum('home','away'),'playerId':S,'clock':I,'text':S})),'disciplineParticipants':arr(obj({'side':S,'playerId':S,'playedSeconds':I}))})
schemas['Snapshot']['properties'].update({'x':{'type':'number','minimum':2.5,'maximum':97.5},'y':{'type':'number','minimum':3,'maximum':67}})
schemas['Match']['properties'].update({'ballCarrierId':S,'movementVersion':S})
schemas['Standing']=obj({k:(S if k in ['clubId','name','shortName'] else I) for k in ['clubId','name','shortName','rank','played','wins','draws','losses','pointsFor','pointsAgainst','difference','triesFor','triesAgainst','bonusOffensive','bonusDefensive','points']})
schemas['Competition']=obj({'id':S,'divisionId':I,'name':S,'season':S,'year':I,'drawSeed':I,'teamIds':arr(S),'startDate':S,'endDate':S,'semifinalDates':arr(S),'finalDate':S,'phase':enum('regular','playoffs','groups','quarterfinal','semifinal','final','finished'),'regularOrder':arr(S),'championId':S,'runnerUpId':S,'maxVenueStreak':I,'version':I},['id','divisionId','season','teamIds','phase'])
schemas['CompetitionView']=obj({**schemas['Competition']['properties'],'standings':arr(ref('Standing')),'regularFixtures':arr(ref('Fixture')),'semifinals':arr(ref('Fixture')),'final':{'oneOf':[ref('Fixture'),{'const':''}]},'regularFinished':I},['id','standings','regularFixtures','semifinals','final','regularFinished'])
schemas['Competition']['properties'].update({'type':enum('league','cup'),'exemptTeamIds':arr(S),'qualifiedTeamIds':arr(S),'groupDates':arr(S),'quarterfinalDate':S,'groups':arr(obj({'id':S,'teamIds':arr(S),'standings':arr(ref('Standing'))}))})
schemas['CompetitionView']['properties'].update(schemas['Competition']['properties'])
schemas['CompetitionView']['properties'].update({'quarterfinals':arr(ref('Fixture')),'fixtures':arr(ref('Fixture'))})
schemas['CompetitionPage']=page('Competition')
schemas['Fixture']['properties'].update({'competitionType':S,'groupId':S,'competitionKey':S,'divisionId':I,'season':S,'stage':enum('regular','cup-group','quarterfinal','semifinal','final','friendly'),'round':I,'slot':I,'date':S,'homeRank':I,'awayRank':I,'winnerId':S,'homeTries':I,'awayTries':I,'homeShootout':I,'awayShootout':I,'archived':B})
schemas['Match']['properties'].update({'competitionType':S,'groupId':S,'competitionKey':S,'stage':S,'round':I,'date':S,'winnerId':S,'homeShootout':I,'awayShootout':I})
schemas['InjuryType']=obj({'id':S,'name':S,'grade':I,'severity':enum('leve','moderada','grave'),'minWeeks':I,'maxWeeks':I},['id','name','grade','severity','minWeeks','maxWeeks'])
schemas['Injury']=obj({'id':S,'typeId':S,'name':S,'grade':I,'severity':enum('leve','moderada','grave'),'weeks':I,'startedDay':I,'startedOn':S,'recoveryDay':I,'expectedReturn':S,'remainingDays':I,'remainingWeeks':I,'source':enum('match','training'),'contextId':S,'status':enum('active','recovered'),'recoveredOn':S},['id','typeId','name','grade','weeks','startedOn','recoveryDay','expectedReturn','source','status'])
schemas['Player']['properties'].update({'injury':ref('Injury'),'injuryHistory':arr(ref('Injury')),'unavailableReason':S,'monthlyWage':I,'seniorMonthlyWage':I,'askingMonthlyWage':I})
schemas['Snapshot']['properties'].update({'injury':ref('Injury'),'injuredClock':I,'substituted':B})
schemas['Snapshot']['properties']['status']=enum('field','bench','replaced','sinBin','sentOff','injured')
for entity in ['Club','Player','Lineup','Movement','Fixture','Command','Coach','TrainingExecution']:
 schemas[entity+'Page']=page(entity)
schemas['EventPage']=obj({'items':arr(ref('Event')),'lastSequence':I,'hasMore':B},['items','lastSequence','hasMore'])
schemas['PlayerMatchStats']=obj({'id':S,'playerId':S,'playerName':S,'clubId':S,'clubName':S,'opponentId':S,'opponentName':S,'fixtureId':S,'matchId':S,'date':S,'day':I,'season':S,'stage':S,'competitionType':S,'side':enum('home','away'),'position':I,'playedSeconds':I,'homeScore':I,'awayScore':I,'stats':ref('Stats'),'complete':B,'source':enum('live','aggregate','legacy'),'modelVersion':S},['id','playerId','fixtureId','date','stats','complete'])
schemas['PlayerMatchStatsPage']=page('PlayerMatchStats')
schemas['PlayerMatchStatsPage']['properties']['summary']=obj({'appearances':I,'playedSeconds':I,'stats':ref('Stats'),'partialMatches':I})
schemas['Snapshot']['properties'].update({'playedSeconds':I,'infringements':I,'statsVersion':S})
schemas['News']=obj({'id':S,'type':enum('injury','playerSigning','staffSigning'),'date':S,'day':I,'clubId':S,'clubName':S,'personName':S,'playerId':S,'title':S,'text':S,'category':S,'role':S})
schemas['NewsPage']=page('News')
schemas['NewsPage']['properties'].update({'fromDate':S,'toDate':S})
paths={}
pagination=[{'name':'offset','in':'query','schema':{'type':'integer','minimum':0,'default':0}},{'name':'limit','in':'query','schema':{'type':'integer','minimum':1,'maximum':500,'default':100}}]
def route(path,method,summary,response,request=None,key=False,paged=False,created=False):
 parameters=[{'name':part[1:-1],'in':'path','required':True,'schema':S} for part in path.split('/') if part.startswith('{')]
 if key: parameters.append({'name':'Idempotency-Key','in':'header','required':True,'schema':{'type':'string','minLength':1,'maxLength':100,'pattern':'^[a-zA-Z0-9_.-]+$'}})
 if paged:parameters.extend(pagination)
 operation={'summary':summary,'operationId':method+'_'+path.replace('/','_').replace('{','').replace('}',''),'parameters':parameters,'responses':{str(201 if created else 200):{'description':'Operación confirmada','content':{'application/json':{'schema':ref(response)}}}}}
 for code,label in [(400,'Entrada o paginación inválida'),(403,'Club no gestionable'),(404,'Entidad no encontrada'),(409,'Versión obsoleta, ocupado o partido activo/pendiente'),(413,'Más de 64 KiB'),(422,'Regla de negocio inválida'),(500,'Error interno')]:
  operation['responses'][str(code)]={'description':label,'content':{'application/json':{'schema':ref('Error')}}}
 if request:operation['requestBody']={'required':True,'content':{'application/json':{'schema':ref(request)}}}
 paths.setdefault(path,{})[method]=operation

route('/competitions','get','Competiciones y sorteos persistentes por división y temporada','CompetitionPage',paged=True)
route('/competitions/{competitionId}','get','Clasificación, jornadas y cuadro final de la competición','CompetitionView')
route('/health','get','Estado del servicio y trabajador','Health')
route('/news','get','Lesiones y fichajes de todos los clubes en los últimos siete días de la partida','NewsPage',paged=True)
route('/clubs','get','Veinte clubes oficiales','ClubPage',paged=True)
route('/clubs/{clubId}','get','Detalle de club','Club')
route('/clubs/{clubId}/players','get','Plantilla y cantera del club','PlayerPage',paged=True)
route('/players/{playerId}','get','Ficha de jugador','Player')
route('/players/{playerId}/match-stats','get','Historial individual por encuentro, paginado y con totales de todos los registros disponibles','PlayerMatchStatsPage',paged=True)
route('/players/{playerId}/release','post','Rescindir contrato y retirar al jugador de plantilla, entrenamientos y alineaciones','ReleaseResult','Version',key=True)
route('/clubs/{clubId}/academy','get','Jugadores juveniles','PlayerPage',paged=True)
route('/clubs/{clubId}/academy/{playerId}/promote','post','Abrir negociación salarial para promocionar; no cambia todavía de categoría','Negotiation','Version',key=True)
route('/clubs/{clubId}/lineups','get','Alineaciones guardadas','LineupPage',paged=True)
route('/clubs/{clubId}/lineups','post','Crear alineación válida','Lineup','Lineup',created=True)
route('/lineups/{lineupId}','put','Editar con versión actual','Lineup','Lineup')
route('/lineups/{lineupId}/validate','post','Validar alineación guardada','Validation')
route('/injury-types','get','Catálogo de lesiones, grados y duración en semanas','InjuryType')
route('/training-types','get','Tipos de entrenamiento y responsables','TrainingType')
route('/transfer-market','get','Mercado compartido de hasta 20 agentes; salarios mensuales y primas en céntimos','PlayerPage',paged=True)
route('/players/{playerId}/renew','post','Negociar la renovación por una temporada adicional; no disponible tras anunciar retirada','Negotiation','Version',key=True)
route('/players/{playerId}/negotiate','post','Abrir negociación de siete días con un agente libre; no reserva al jugador','Negotiation','Version',key=True)
route('/negotiations','get','Historial privado de negociaciones del club gestionado','NegotiationPage',paged=True)
route('/negotiations/{negotiationId}','get','Estado actual de la negociación y del jugador','Negotiation')
route('/negotiations/{negotiationId}/offer','post','Negociar salario y contrato de 1 a 5 temporadas; hasta cinco ofertas y contraofertas','Negotiation','SalaryOffer',key=True)
route('/negotiations/{negotiationId}/sign','post','Confirmar salario acordado, pagar prima una sola vez e incorporar al primer equipo','Negotiation','Version',key=True)
route('/negotiations/{negotiationId}/withdraw','post','Retirar una negociación sin contratar','Negotiation','Version',key=True)
route('/staff-market','get','Entrenadores disponibles para contratar','CoachPage',paged=True)
route('/clubs/{clubId}/staff','get','Cuerpo técnico contratado, roles y gasto semanal','Staff')
route('/clubs/{clubId}/staff','post','Contratar candidato y sustituir al titular del mismo puesto','Staff','HireCoach',key=True)
route('/clubs/{clubId}/training-executions','get','Historial de sesiones aplicado una vez por día','TrainingExecutionPage',paged=True)
route('/clubs/{clubId}/training-plan','get' ,'Consultar semana y próximas sesiones por posición','Training')
route('/clubs/{clubId}/training-suggestion','get','Proponer grupos para toda la plantilla sin guardar','TrainingSuggestion')
paths['/clubs/{clubId}/training-suggestion']['get']['parameters'].append({'name':'variant','in':'query','schema':{'type':'integer','minimum':0,'maximum':1000000,'default':0}})
route('/clubs/{clubId}/training-plan','put','Guardar planificación semanal recurrente con versión actual','Training','Training')
route('/clubs/{clubId}/advance-day','post','Aplicar entrenamiento, recuperación y economía una vez','Club','Version',key=True)
route('/clubs/{clubId}/finances','get','Saldo en céntimos','Finances')
route('/clubs/{clubId}/financial-movements','get','Libro de movimientos','MovementPage',paged=True)
route('/clubs/{clubId}/fixtures','get','Calendario e historial','FixturePage',paged=True)
route('/matches','post','Crear partido para un encuentro disponible','Match','CreateMatch',key=True,created=True)
route('/matches/{matchId}/start','post','Validar convocatoria y comenzar; reintentos no reinician','Match',key=True)
route('/matches/{matchId}','get','Estado autoritativo y convocados','Match')
route('/matches/{matchId}/events','get','Eventos posteriores a una secuencia','EventPage')
paths['/matches/{matchId}/events']['get']['parameters'].extend([{'name':'afterSequence','in':'query','schema':{'type':'integer','minimum':0,'maximum':1000000,'default':0}},pagination[1]])
route('/matches/{matchId}/stats','get','Estadísticas de ambos equipos','Stats')
paths['/injury-types']['get']['responses']['200']['content']['application/json']['schema']=obj({'items':arr(ref('InjuryType')),'modelVersion':S},['items','modelVersion'])
paths['/training-types']['get']['responses']['200']['content']['application/json']['schema']=obj({'items':arr(ref('TrainingType')),'modelVersion':S},['items','modelVersion'])
paths['/matches/{matchId}/stats']['get']['responses']['200']['content']['application/json']['schema']=obj({'home':ref('Stats'),'away':ref('Stats')},['home','away'])
route('/matches/{matchId}/commands','get','Cola, confirmaciones y rechazos','CommandPage',paged=True)
route('/matches/{matchId}/commands','post','Enviar una decisión para el equipo gestionado','Command','CommandRequest',key=True)

schemas['Credentials']=obj({'username':{'type':'string','minLength':3,'maxLength':40},'password':{'type':'string','minLength':10,'maxLength':128}},['username','password'])
schemas['User']=obj({'id':S,'username':S},['id','username'])
schemas['AuthResult']=obj({'user':ref('User'),'expiresAt':I})
schemas['Game']=obj({'id':S,'name':S,'clubId':S,'clubName':S,'divisionId':I,'division':S,'date':S,'active':B,'createdAt':I,'updatedAt':I})
schemas['Games']=obj({'items':arr(ref('Game'))})
schemas['NewGame']=obj({'name':{'type':'string','minLength':1,'maxLength':60},'clubId':S,'divisionId':{'type':'integer','enum':[416,417]}},['name','clubId','divisionId'])
schemas['FriendlyOptions']=obj({'date':S,'items':arr(ref('Club')),'version':I})
schemas['NewFriendly']=obj({'date':{'type':'string','format':'date'},'opponentId':S,'venue':enum('home','away'),'version':I},['date','opponentId','venue','version'])
schemas['Saved']=obj({'saved':B})
schemas['SignedOut']=obj({'signedOut':B})
route('/auth/register','post','Crear cuenta e iniciar sesión JWT en cookie HttpOnly','AuthResult','Credentials')
route('/auth/login','post','Iniciar sesión JWT en cookie HttpOnly','AuthResult','Credentials')
route('/auth/me','get','Cuenta autenticada','User')
route('/auth/logout','post','Revocar sesión y borrar cookie','SignedOut')
schemas['GameCatalog']=obj({'items':arr(ref('Club'))})
route('/game-catalog','get','Clubes para crear partida','GameCatalog')
route('/games','get','Partidas de la cuenta','Games')
route('/games','post','Crear una partida independiente desde el 1 de septiembre','Game','NewGame',key=True)
schemas['DeleteGame']=obj({'confirm':{'type':'boolean','const':True}},['confirm'])
schemas['DeletedGame']=obj({'deleted':B,'gameId':S,'name':S,'deletedAt':I,'recordsDeleted':I,'entities':{'type':'object','additionalProperties':I}},['deleted','gameId','recordsDeleted'])
route('/games/{gameId}','delete','Eliminar definitivamente una partida propia y sus datos; requiere confirmación','DeletedGame','DeleteGame',key=True)
route('/games/{gameId}/load','post','Cargar partida y reanudar su simulación','Game')
route('/games/{gameId}/unload','post','Guardar y pausar partida','Saved')
route('/clubs/{clubId}/friendly-options','get','Tres rivales aleatorios disponibles en la fecha','FriendlyOptions')
paths['/clubs/{clubId}/friendly-options']['get']['parameters'].append({'name':'date','in':'query','required':True,'schema':{'type':'string','format':'date'}})
schemas['FriendlyInvitation']=obj({'id':S,'clubId':S,'opponentId':S,'date':{'type':'string','format':'date'},'venue':enum('home','away'),'status':enum('pending','accepted','rejected','expired'),'createdOn':S,'expiresOn':S,'fixtureId':S,'version':I},['id','clubId','opponentId','date','venue','status','expiresOn','version'])
schemas['FriendlyInvitationPage']=page('FriendlyInvitation')
schemas['FriendlyInvitationResponse']=obj({'invitationId':S,'version':I,'decision':enum('accept','reject')},['invitationId','version','decision'])
route('/clubs/{clubId}/friendly-invitations','get','Invitaciones vigentes: máximo una al mes, en fin de semana libre','FriendlyInvitationPage',paged=True)
route('/clubs/{clubId}/friendly-invitations','post','Aceptar o rechazar una invitación; aceptar crea un amistoso','FriendlyInvitation','FriendlyInvitationResponse',key=True)
route('/clubs/{clubId}/friendlies','post','Concertar amistoso en casa o fuera','Fixture','NewFriendly',key=True)
schemas['TeamSummary']=obj({'count':I,'average':N,'energy':N,'morale':N,'attributes':ref('Attributes')})
schemas['ComparisonTeam']=obj({'clubId':S,'name':S,'lineupId':S,'groups':obj({k:ref('TeamSummary') for k in ['all','forwards','backs']})})
schemas['MatchComparison']=obj({'matchId':S,'ready':B,'attributes':arr(obj({'id':S,'name':S})),'home':ref('ComparisonTeam'),'away':ref('ComparisonTeam')})
route('/matches/{matchId}/comparison','get','Medias del XV seleccionado, delanteros y tres cuartos de ambos equipos','MatchComparison')
schemas['Stadium']=obj({'name':S,'capacity':I,'sourceUrl':S,'verifiedOn':S,'referenceSeason':S})
for model,field in [('Club','stadium'),('Match','venue'),('Fixture','venue')]:schemas[model]['properties'][field]=ref('Stadium')
schemas['FinancialDirector']=obj({'id':S,'name':S,'quality':I,'weeklyWage':I,'monthlyWage':I})
schemas['MatchEconomy']=obj({key:I for key in ['attendance','seasonTicketHolders','payingAttendees','ticketPrice','ticketRevenue','barRevenue','barCosts','netRevenue','homeShare','awayShare']})
schemas['KitAppearance']=obj({'color':S,'accentColor':S,'thirdColor':S,'pattern':enum('solid','hoops','stripes','halves','trim'),'description':S,'numberColor':S})
schemas['Club']['properties']['kits']=obj({'primary':ref('KitAppearance'),'secondary':ref('KitAppearance')})
schemas['PayrollSummary']=obj({key:N for key in ['budget','weeklyLimit','weeklyPlayers','weeklyAvailable','budgetReference','annualPlayers','annualSenior','annualAcademy','annualStaff','annualDirector','annualTraining','annualRegistrations','annualTravelReserve','annualSafetyReserve','annualProjectedCosts','annualMargin','weeks','monthlyLimit','monthlyPlayers','monthlyStaff','monthlyDirector','monthlyAvailable','paymentsPerYear']})
schemas['FinancialPlan']=obj({**{k:N for k in ['projectedCosts','projectedIncome','projectedMargin','marginPercent','targetMarginPercent','privateSponsors','barConcession','memberships','tickets','publicGrants','requiredGrants','directorQuality']},'modelVersion':S,'provisional':B})
schemas['FinancialView']=obj({'financialPlan':ref('FinancialPlan'),'payroll':ref('PayrollSummary'),'fundingReference':I,'barConcession':{'type':'object'},'office':obj({'version':I,'director':ref('FinancialDirector'),'candidates':arr(ref('FinancialDirector')),'budgetReference':I,'baseAttendance':I}),'season':{'type':'object'},'agreements':arr({'type':'object'}),'balance':I,'income':I,'expenses':I,'securedAnnualIncome':I,'annualWages':I,'annualTraining':I,'monthly':{'type':'object'},'breakdown':{'type':'object'},'movements':arr(ref('Movement'))})
schemas['MatchEconomy']['properties'].update({'barModel':enum('concession'),'modelVersion':S})
schemas['HireFinancialDirector']=obj({'candidateId':S,'version':I},['candidateId','version'])
schemas['TicketPrice']=obj({'ticketPrice':{'type':'integer','minimum':0,'maximum':5000},'version':I},['ticketPrice','version'])
route('/clubs/{clubId}/finances','get','Tesorería, financiero, acuerdos, campaña y previsión anual','FinancialView')
route('/clubs/{clubId}/financial-director','post','Contratar o sustituir al financiero; gestión automática en septiembre','FinancialView','HireFinancialDirector',key=True)
route('/matches/{matchId}/ticketing','get','Previsión de asistentes, taquilla y bar; disponibilidad de edición','Ticketing')
schemas['Ticketing']=obj({'forecast':ref('MatchEconomy'),'editable':B})
route('/matches/{matchId}/ticketing','put','Fijar precio en céntimos, en casa y antes del inicio el día del partido','Match','TicketPrice',key=True)
paths['/staff-market']['get']['parameters'].append({'name':'role','in':'query','required':False,'schema':enum('head','forwards','backs','defense','attack','skills','fitness','academy'),'description':'Filtra por especialidad antes de ordenar por calidad y paginar.'})
for path,operations in paths.items():
 for op in operations.values():
  if path=='/health' or path in ['/auth/login','/auth/register']:
   op['security']=[]
  if not path.startswith(('/auth/','/games','/game-catalog','/health')):
   op['parameters'].append({'name':'X-Game-Id','in':'header','required':True,'schema':S})
  op['responses']['401']={'description':'Sesión JWT ausente, inválida o caducada'}
  op['responses']['429']={'description':'Límite de intentos de acceso'}

for operations in paths.values():
 for op in operations.values():
  for code,response in op['responses'].items():
   response.setdefault('headers',{}).update({'X-Request-Id':{'description':'Identificador de correlación de la petición','schema':S},'X-Interop-Session-Id':{'description':'Sesión nativa de interoperabilidad para el visor de mensajes y la traza visual','schema':S}})
  op['responses']['503']={'description':'Producción de interoperabilidad no disponible; no se ejecuta la operación','content':{'application/json':{'schema':ref('Error')}}}

schemas['Competition']['properties'].update({'seasonStartDate':{'type':'string','format':'date'},'closedDate':{'type':'string','format':'date'},'retiringPlayers':arr(obj({'playerId':S,'name':S,'clubId':S,'retirementDate':{'type':'string','format':'date'}}))})

schemas['Player']['properties'].update({'talentScaleVersion':S,'talentScaleFactor':N})

schemas['WeeklyDay']=obj({'day':{'type':'integer','minimum':1,'maximum':7},'theme':enum('attack','defense','physical','technique','setPieces','tactics','rest'),'forwards':S,'backs':S},['day','theme'])
schemas['TrainingWeek']=obj({c:{'type':'array','minItems':7,'maxItems':7,'items':ref('WeeklyDay')} for c in ['senior','academy']},['senior','academy'])
schemas['Training']['properties'].update({'mode':enum('weekly','groups'),'weekly':ref('TrainingWeek'),'weeklyConfigured':B,'nextGroups':arr(ref('TrainingGroup')),'nextDay':I,'nextDate':S,'nextWeekday':I,'themes':arr(obj({'id':S,'name':S,'forwards':S,'backs':S}))})
schemas['Training']['required']=[k for k in schemas['Training']['required'] if k!='groups']
schemas['Training']['description']='Plan semanal: mode=weekly y weekly con siete días por categoría. Los grupos manuales se conservan por compatibilidad. Las sesiones se resuelven cada día por posición, edad, energía y calendario.'

doc={'openapi':'3.1.0','info':{'title':'Quince · API local de Rugby Manager','version':'1.0.0','description':'Sesión JWT HS256 en cookie HttpOnly y partidas privadas seleccionadas con X-Game-Id. Importes en céntimos. GET listas con offset/limit, salvo eventos con afterSequence. Los PUT requieren version del GET; las claves de reintento devuelven la primera intención y no comparan cuerpos.'},'servers':[{'url':'http://localhost:5175/api/v1'},{'url':'http://localhost:8085/api/v1'}],'paths':paths,'security':[{'sessionJWT':[]}],'components':{'schemas':schemas,'securitySchemes':{'sessionJWT':{'type':'apiKey','in':'cookie','name':'rugby_session','description':'JWT HS256; también admite Authorization: Bearer para clientes API.'}}}}
target=Path(__file__).resolve().parents[1]/'docs'/'openapi.json'
target.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(f'{len(paths)} rutas documentadas en {target}')


