Class Rugby.Service.Finance Extends %RegisteredObject
{
Parameter VERSION = "2.0.0";
ClassMethod Hash(text As %String) As %Integer { quit ##class(Rugby.Service.Rivals).Hash(text,##class(Rugby.Service.Rivals).Seed()) }
ClassMethod Budget(c As %DynamicObject) As %Integer
{
    if c.%Get("divisionBudgetReference",0)>0 quit c.divisionBudgetReference
    set h=..Hash("budget-"_c.id),amount=300000+(h#75001)
    if $listfind($listbuild("c2","c3","c8"),c.id) { set amount=650000+(h#150001) }
    elseif $listfind($listbuild("c1","c4","c6","c7","c10"),c.id) { set amount=400000+(h#200001) }
    elseif c.id="c12" { set amount=400000+(h#100001) }
    elseif c.competitionId=417 { set amount=250000+(h#100001) }
    quit amount*100
}
ClassMethod Funding(c As %DynamicObject) As %Integer
{
    set budget=..Budget(c),grants=(budget*.2425)\1,members=((budget*.1175)\15000)*15000
    // Minimum of the seven agreements plus conservative grants and memberships; no tickets.
    quit 8000000+grants+members
}
ClassMethod Success(c As %DynamicObject) As %Numeric
{
    set rank=c.%Get("qualityReferenceRank",5),year=##class(Rugby.Service.Competition).Year(c.date)
    for y=year:-1:year-1 {
        set comp=##class(Rugby.Service.Store).Get("Competition","league-"_c.competitionId_"-"_y,0)
        if '$isobject(comp) continue
        set table=##class(Rugby.Service.Competition).Table(comp),found=0
        for i=0:1:table.%Size()-1 { set row=table.%Get(i) if (row.clubId=c.id)&&(row.played>=3) set rank=row.rank,found=1 }
        if found quit
    }
    quit $select(c.competitionId=416:.4,1:0)+(.6*(10-rank)/9)
}
ClassMethod Company(c As %DynamicObject, year As %Integer, slot As %Integer, option As %Integer) As %String
{
    set game=##class(Rugby.Service.Store).Game(),key=c.id_"-"_year_"-"_slot_"-"_option
    if $data(^RugbyWorld(game,"companyByOffer",key)) quit ^RugbyWorld(game,"companyByOffer",key)
    set stream=##class(%Stream.FileCharacter).%New(),stream.TranslateTable="UTF8",sc=stream.LinkToFile("/opt/rugby/data/sponsor-companies.json")
    if $system.Status.IsError(sc) throw ##class(%Exception.StatusException).CreateFromStatus(sc)
    set catalog=##class(%DynamicObject).%FromJSON(stream),sectors=$select(slot=7:catalog.barSectors,1:catalog.sectors),attempt=0
    for {
        set h=..Hash("company-"_key_"-"_attempt),brand=..Hash("brand-"_key_"-"_attempt),name=sectors.%Get(h#sectors.%Size())_" "_catalog.brands.%Get(brand#catalog.brands.%Size())_" "_c.city
        if attempt>=10000 set name=name_" "_(attempt\10000)
        set owner=$get(^RugbyWorld(game,"companyNameOwner",name))
        quit:(owner="")||(owner=key)
        set attempt=attempt+1
    }
    set ^RugbyWorld(game,"companyNameOwner",name)=key,^RugbyWorld(game,"companyByOffer",key)=name
    quit name
}
ClassMethod OfferTerms(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject, slot As %Integer, option As %Integer, success As %Numeric) As %DynamicObject
{
    set h=..Hash(c.id_"-agreement-"_s.year_"-"_slot_"-"_option),years=1+(h#3),score=##class(Rugby.Simulation.Engine).Clamp((success*.75)+(o.director.%Get("quality",35)*.0025)+(((h#11)-5)*.005),0,1)
    set low=$select(slot=1:3000000,slot=7:2500000,1:500000),high=$select(slot=1:8000000,slot=7:4500000,1:1000000),amount=+$justify(low+((high-low)*score),0,0),kind=$select(slot=7:"barConcession",1:"sponsorship"),category=$select(slot=1:"principal",slot=7:"bar",1:"secondary")
    quit {"years":(years),"annualAmount":(amount),"kind":(kind),"category":(category)}
}
ClassMethod Offer(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject, slot As %Integer, option As %Integer, success As %Numeric) As %DynamicObject
{
    set terms=..OfferTerms(c,s,o,slot,option,success),name=..Company(c,s.year,slot,option)
    quit {"id":(s.id_"-offer-"_slot_"-"_option),"clubId":(c.id),"slot":(slot),"kind":(terms.kind),"category":(terms.category),"name":(name),"annualAmount":(terms.annualAmount),"years":(terms.years),"startYear":(s.year),"endYear":(s.year+terms.years-1),"offeredOn":(c.date),"quality":(o.director.%Get("quality",35)),"success":(success),"status":"declined","modelVersion":(..#VERSION)}
}
ClassMethod SignSlot(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject, slot As %Integer, success As %Numeric)
{
    set all=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id)
    for i=0:1:all.%Size()-1 { set a=all.%Get(i) if (a.slot=slot)&&(a.startYear<=s.year)&&(a.endYear>=s.year) quit }
    if $isobject($get(a))&&(a.slot=slot)&&(a.startYear<=s.year)&&(a.endYear>=s.year) quit
    set best={},bestScore=-1
    for option=1:1:2 {
        set offer=..Offer(c,s,o,slot,option,success),score=offer.annualAmount*(1+((offer.years-1)*.015))
        do s.offers.%Push(offer)
        if score>bestScore set best=offer,bestScore=score
    }
    set best.status="signed",best.signedOn=c.date,best.id=s.id_"-agreement-"_slot
    do ##class(Rugby.Service.Store).Put("FinancialAgreement",best)
}
ClassMethod Rebase(c As %DynamicObject, o As %DynamicObject) As %DynamicObject
{
    set year=##class(Rugby.Service.Competition).Year(c.date),report={"clubId":(c.id),"previousBudget":(o.budgetReference),"budget":(..Budget(c)),"agreements":[]},agreements=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id),ledger=##class(Rugby.Service.Store).All("FinancialMovement","clubId",c.id),season={"id":(c.id_"-finance-"_year),"year":(year)},success=..Success(c)
    for i=0:1:agreements.%Size()-1 {
        set a=agreements.%Get(i)
        if (a.endYear<year)||(a.%Get("kind")="grant") continue
        if a.%Get("modelVersion")=..#VERSION continue
        set offer=..Offer(c,season,o,a.slot,1,success),a.previousAnnualAmount=a.annualAmount,a.previousName=a.name,a.name=offer.name,a.annualAmount=offer.annualAmount,a.kind=offer.kind,a.category=offer.category,a.success=success,a.amendedOn=c.date,a.modelVersion=..#VERSION
        do ##class(Rugby.Service.Store).Put("FinancialAgreement",a),report.agreements.%Push(a)
        for y=a.startYear:1:a.endYear {
            set paid=0,prefix=a.id_"-payment-"_y_"-"
            for j=0:1:ledger.%Size()-1 { set m=ledger.%Get(j) if $extract(m.source,1,$length(prefix))=prefix set paid=paid+m.amount }
            set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"agreementPaid",a.id,y)=paid
        }
    }
    set seasons=##class(Rugby.Service.Store).All("FinancialSeason","clubId",c.id)
    for i=0:1:seasons.%Size()-1 {
        set s=seasons.%Get(i)
        if s.year<year continue
        if s.%Get("modelVersion")=..#VERSION continue
        set s.previousBudgetReference=s.budgetReference,s.budgetReference=..Budget(c),s.legacyOffers=s.offers,s.offers=[],s.modelVersion=..#VERSION
        do s.%Set("sponsorsComplete",0,"boolean"),s.%Set("barComplete",0,"boolean"),##class(Rugby.Service.Store).Put("FinancialSeason",s)
    }
    set o.previousBudgetReference=o.budgetReference,o.budgetReference=..Budget(c),o.modelVersion=..#VERSION
    do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
    quit report
}
ClassMethod Attendance(c As %DynamicObject) As %Integer
{
    set h=..Hash("crowd-"_c.id),base=400+(h#301)
    if $listfind($listbuild("c2","c8"),c.id) set base=1200+(h#301)
    if c.id="c3" set base=1000+(h#201)
    if c.id="c4" set base=800+(h#201)
    if c.id="c7" set base=600+(h#201)
    if c.id="c10" set base=700+(h#201)
    if $listfind($listbuild("c1","c9"),c.id) set base=500+(h#301)
    if c.competitionId=417 set base=250+(h#351)
    quit base
}
ClassMethod Office(club As %String) As %DynamicObject { quit ##class(Rugby.Service.Store).Get("FinancialOffice",club) }
ClassMethod Initialize() As %DynamicObject
{
    set report={"gameId":(##class(Rugby.Service.Store).Game()),"offices":0,"rebased":[]},clubs=##class(Rugby.Service.Store).All("Club")
    for i=0:1:clubs.%Size()-1 {
        set c=clubs.%Get(i)
        set existing=##class(Rugby.Service.Store).Get("FinancialOffice",c.id,0)
        if $isobject(existing) { if existing.%Get("modelVersion")'=..#VERSION do report.rebased.%Push(..Rebase(c,existing))
            continue
        }
        set candidates=[]
        for tier=1:1:3 {
            set quality=$select(tier=1:35,tier=2:65,1:90),h=..Hash("director-"_c.id_"-"_tier),name=$piece("Laura,Daniel,Elena,Marcos,Clara,Andrés",",",1+(h#6))_" "_$piece("Soler,Navarro,Ortega,Rivas,Molina,Vidal",",",1+((h\6)#6))
            do candidates.%Push({"id":(c.id_"-finance-"_tier),"name":(name),"quality":(quality),"weeklyWage":(20000+(quality*500))})
        }
        set office={"id":(c.id),"clubId":(c.id),"director":{},"candidates":(candidates),"budgetReference":(..Budget(c)),"baseAttendance":(..Attendance(c)),"lastPayrollDay":(c.day),"salaryAccrued":0,"adoptedDate":(c.date),"modelVersion":(..#VERSION)}
        if c.id'=##class(Rugby.Service.Store).ManagedClub() set office.director=candidates.%Get(1+(..Hash("ai-finance-"_c.id)#2))
        do ##class(Rugby.Service.Store).Put("FinancialOffice",office)
        set report.offices=report.offices+1
    }
    quit report
}
ClassMethod Season(c As %DynamicObject) As %DynamicObject
{
    set year=##class(Rugby.Service.Competition).Year(c.date),id=c.id_"-finance-"_year,s=##class(Rugby.Service.Store).Get("FinancialSeason",id,0)
    if $isobject(s) quit s
    set o=..Office(c.id),s={"id":(id),"clubId":(c.id),"year":(year),"season":(year_"/"_(year+1)),"budgetReference":(o.budgetReference),"offers":[],"grants":[],"members":0,"seasonTicketPrice":15000,"campaignIncome":0,"campaignComplete":false,"sponsorsComplete":false,"grantsComplete":false,"barComplete":false,"modelVersion":(..#VERSION),"introducedOn":(c.date)}
    do ##class(Rugby.Service.Store).Put("FinancialSeason",s)
    quit s
}
ClassMethod Hire(club As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Managed(club),##class(Rugby.Service.Store).Key(key)
    set game=##class(Rugby.Service.Store).Game()
    if $data(^RugbyWorld(game,"retry","financeHire",club,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"retry","financeHire",club,key))
    set o=..Office(club)
    do ##class(Rugby.Service.Store).CheckVersion(o,b)
    set found=0
    for i=0:1:o.candidates.%Size()-1 { set candidate=o.candidates.%Get(i) if candidate.id=b.%Get("candidateId") set chosen=candidate,found=1 }
    if 'found do ##class(Rugby.Service.Store).Fail(422,"FINANCIAL_CANDIDATE","Elige un financiero disponible.")
    if o.director.%Get("id")=chosen.id do ##class(Rugby.Service.Store).Fail(409,"FINANCIAL_EMPLOYED","Este financiero ya está contratado.")
    set chosen.monthlyWage=##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(chosen.quality,club),chosen.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(chosen.monthlyWage)
    set chosen.payrollStartDay=##class(Rugby.Service.Store).Get("Club",club).day
    set o.director=chosen,c=##class(Rugby.Service.Store).Get("Club",club),o.hiredOn=c.date
    do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
    do ..Tick(club)
    set contract={"id":(club_"-finance-"_key),"clubId":(club),"directorId":(chosen.id),"employeeName":(chosen.name),"role":"finance","kind":"hire","day":(c.day),"date":(c.date),"monthlyWage":(chosen.monthlyWage),"weeklyWage":(chosen.weeklyWage),"payPeriod":"monthly","idempotencyKey":(key)}
    do ##class(Rugby.Service.Store).Put("StaffContract",contract)
    set result=..View(club),^RugbyWorld(game,"retry","financeHire",club,key)=result.%ToJSON()
    quit result
}
ClassMethod Deals(c As %DynamicObject, s As %DynamicObject, o As %DynamicObject)
{
    if o.director.%Get("id")="" quit
    set day=+$piece(c.date,"-",3),factor=.9+(o.director.quality*.002),year=s.year,budget=s.budgetReference
    set success=..Success(c)
    if (day>=7)&&('s.sponsorsComplete) {
        for slot=1:1:6 { do ..SignSlot(c,s,o,slot,success) }
        do s.%Set("sponsorsComplete",1,"boolean")
    }
    if (day>=28)&&('s.%Get("barComplete",0)) {
        do ..SignSlot(c,s,o,7,success),s.%Set("barComplete",1,"boolean")
    }
    if (day>=14)&&('s.grantsComplete) {
        set financialPlan=##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o),total=financialPlan.requiredGrants
        for n=1:1:2 {
            set h=..Hash(c.id_"-grant-"_year_"-"_n),institution=$select(n=1:"Ayuntamiento",1:$piece("Instituto público de deporte,Agencia pública de actividad física,Fundación pública deportiva",",",1+(h#3)))_" de "_c.city,amount=$select(n=1:total\2,1:total-(total\2))
            do s.grants.%Push({"id":(s.id_"-grant-"_n),"name":(institution),"amount":(amount),"awardedOn":(c.date),"status":"awarded"})
        }
        do s.%Set("grantsComplete",1,"boolean")
        set s.financingModelVersion=##class(Rugby.Service.FinancialPlanning).#VERSION,s.financingPlan=financialPlan
    }
    if (day>=21)&&('s.campaignComplete) {
        set s.members=+$justify(budget*.125*(.8+(o.director.quality*.004))/s.seasonTicketPrice,0,0),s.campaignIncome=s.members*s.seasonTicketPrice,s.campaignQuality=o.director.quality,s.campaignDate=c.date
        do ##class(Rugby.Service.Management).Money(c,s.campaignIncome,"memberships","Campaña de abonados "_s.season,s.id_"-memberships")
        do s.%Set("campaignComplete",1,"boolean")
    }
}
ClassMethod Tick(club As %String)
{
    set c=##class(Rugby.Service.Store).Get("Club",club),o=..Office(club),s=..Season(c),month=+$piece(c.date,"-",2)
    if month=9 do ..Deals(c,s,o)
    set planning=##class(Rugby.Service.FinancialPlanning).Adopt(c,s,o)
    // New obligations start at adoption; earlier instalments are never credited retroactively.
    if ((month>=9)||(month<=6)) {
        set monthIndex=$select(month>=9:month-9,1:month+3),agreements=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",club)
        for j=0:1:agreements.%Size()-1 {
            set a=agreements.%Get(j)
            if (a.startYear>s.year)||(a.endYear<s.year) continue
            set key=a.id_"-payment-"_s.year_"-"_month
            if $isobject(##class(Rugby.Service.Store).Get("FinancialMovement",club_"-"_key,0)) continue
            set paid=$get(^RugbyWorld(##class(Rugby.Service.Store).Game(),"agreementPaid",a.id,s.year)),remaining=$select(a.annualAmount>paid:a.annualAmount-paid,1:0),amount=remaining\(10-monthIndex)
            if amount {
                set kind=a.%Get("kind","sponsorship")
                do ##class(Rugby.Service.Management).Money(c,amount,kind,$select(kind="barConcession":"Canon de concesión de bar · ",kind="grant":"Subvención · ",1:"Patrocinio · ")_a.name,key)
                set ^RugbyWorld(##class(Rugby.Service.Store).Game(),"agreementPaid",a.id,s.year)=paid+amount
            }
        }
    }
    if month=9 {
        for j=0:1:s.grants.%Size()-1 {
            set g=s.grants.%Get(j)
            if g.status'="awarded" continue
            do ##class(Rugby.Service.Management).Money(c,g.amount,"grant",g.name,g.id)
            set g.status="paid",g.paidOn=c.date
        }
        if +$piece(c.date,"-",3)>=7 do ##class(Rugby.Service.Management).Money(c,+$justify(-s.budgetReference*.03,0,0),"registration","Fichas y participación federativa "_s.season,s.id_"-registration")
    }
    do ##class(Rugby.Service.Store).Put("FinancialOffice",o),##class(Rugby.Service.Store).Put("FinancialSeason",s)
}
ClassMethod TickAll(day As %Integer) As %DynamicArray
{
    set clubs=##class(Rugby.Service.Store).All("Club"),result=[]
    for i=0:1:clubs.%Size()-1 { set c=clubs.%Get(i) do ..Tick(c.id) set s=..Season(##class(Rugby.Service.Store).Get("Club",c.id)) do result.%Push({"clubId":(c.id),"seasonId":(s.id),"members":(s.members),"sponsorsComplete":(s.sponsorsComplete),"grantsComplete":(s.grantsComplete),"season":(s),"office":(..Office(c.id)),"agreements":(##class(Rugby.Service.Store).All("FinancialAgreement","clubId",c.id)),"movements":(..DailyMovements(c.id,day))}) }
    quit result
}
ClassMethod DailyMovements(club As %String, day As %Integer) As %DynamicArray
{
    set all=##class(Rugby.Service.Store).All("FinancialMovement","clubId",club),items=[]
    for i=0:1:all.%Size()-1 { set m=all.%Get(i) if m.day=day do items.%Push(m) }
    quit items
}
ClassMethod View(club As %String) As %DynamicObject
{
    set c=##class(Rugby.Service.Store).Get("Club",club),o=..Office(club),year=##class(Rugby.Service.Competition).Year(c.date),s=##class(Rugby.Service.Store).Get("FinancialSeason",club_"-finance-"_year,0),agreements=##class(Rugby.Service.Store).All("FinancialAgreement","clubId",club),active=[],bar={},sponsor=0,barIncome=0,grants=0
    if '$isobject(s) set s={"year":(year),"season":(year_"/"_(year+1)),"offers":[],"grants":[],"members":0,"seasonTicketPrice":15000,"campaignIncome":0,"campaignComplete":false,"sponsorsComplete":false,"grantsComplete":false,"barComplete":false,"modelVersion":(..#VERSION)}
    if ##class(Rugby.Service.MonthlyPayroll).Active() { for i=0:1:o.candidates.%Size()-1 { set candidate=o.candidates.%Get(i),candidate.monthlyWage=##class(Rugby.Service.MonthlyPayroll).DirectorMonthly(candidate.quality,club),candidate.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(candidate.monthlyWage) } }
    for i=0:1:agreements.%Size()-1 { set a=agreements.%Get(i) if (a.startYear<=year)&&(a.endYear>=year) { if a.%Get("kind")="barConcession" { set bar=a,barIncome=a.annualAmount } elseif a.%Get("kind","sponsorship")="sponsorship" { do active.%Push(a) set sponsor=sponsor+a.annualAmount } } }
    for i=0:1:s.grants.%Size()-1 { set grants=grants+s.grants.%Get(i).amount }
    set entries=##class(Rugby.Service.Store).All("FinancialMovement","clubId",club),income=0,expenses=0,monthly={},breakdown={}
    for i=0:1:entries.%Size()-1 {
        set m=entries.%Get(i)
        if ##class(Rugby.Service.Competition).Year(m.date)'=year continue
        if m.amount>0 { set income=income+m.amount } else { set expenses=expenses-m.amount }
        set mk=$extract(m.date,1,7),row=monthly.%Get(mk,{"income":0,"expenses":0})
        if m.amount>0 { set row.income=row.income+m.amount } else { set row.expenses=row.expenses-m.amount }
        do monthly.%Set(mk,row),breakdown.%Set(m.type,breakdown.%Get(m.type,0)+m.amount)
    }
    set players=##class(Rugby.Service.Store).All("Player","clubId",club),weekly=##class(Rugby.Service.Staff).View(club).weeklyWage+o.director.%Get("weeklyWage",0),plan=##class(Rugby.Service.Store).Get("TrainingPlan",club)
    for i=0:1:players.%Size()-1 { set weekly=weekly+players.%Get(i).weeklyWage }
    set payroll=##class(Rugby.Service.Payroll).Summary(club)
    quit {"office":(o),"season":(s),"agreements":(active),"barConcession":(bar),"fundingReference":(..Funding(c)),"balance":(c.balance),"initialBalance":(c.initialBalance),"currency":"EUR","unit":"cent","income":(income),"expenses":(expenses),"monthly":(monthly),"breakdown":(breakdown),"securedAnnualIncome":(sponsor+barIncome+grants+s.campaignIncome),"financialPlan":(##class(Rugby.Service.FinancialPlanning).Forecast(c,s,o)),"salaryBudget":(##class(Rugby.Service.SalaryBudget).Calculate(club)),"payroll":(payroll),"annualWages":(payroll.annualPlayers+payroll.annualStaff+payroll.annualDirector),"annualTraining":0,"movements":(entries)}
}
ClassMethod Forecast(f As %DynamicObject, price As %Integer = -1, seasonOverride As %DynamicObject = "") As %DynamicObject
{
    set home=##class(Rugby.Service.Store).Get("Club",f.homeId),away=##class(Rugby.Service.Store).Get("Club",f.awayId),o=..Office(home.id),year=##class(Rugby.Service.Competition).Year(f.%Get("date",home.date)),s=##class(Rugby.Service.Store).Get("FinancialSeason",home.id_"-finance-"_year,0),stage=f.%Get("stage","friendly"),seed=..Hash("attendance-"_f.id_"-"_f.%Get("date",home.date))
    if $isobject(seasonOverride) set s=seasonOverride
    if price<0 set price=f.%Get("ticketPrice",1200)
    set multiplier=$select(stage="friendly":.65,(stage="semifinal")||(stage="final"):2.5,home.city=away.city:2.7,1:1),demand=##class(Rugby.Simulation.Engine).Clamp(1+((1200-price)/2500),.25,1.6),attendance=+$justify(o.baseAttendance*multiplier*(.9+((seed#21)*.01))*demand,0,0),members=0
    if $isobject(home.%Get("stadium")) { set capacity=home.stadium.%Get("capacity",0) if capacity>0 set attendance=$select(attendance>capacity:capacity,1:attendance) }
    if (stage="regular")&&$isobject(s) set members=$select(s.members<attendance*.85:s.members,1:+$justify(attendance*.85,0,0))
    set tickets=(attendance-members)*price,bar=0,barCost=0
    quit {"attendance":(attendance),"seasonTicketHolders":(members),"payingAttendees":(attendance-members),"ticketPrice":(price),"ticketRevenue":(tickets),"barRevenue":(bar),"barCosts":(barCost),"netRevenue":(tickets),"barModel":"concession","seed":(seed),"modelVersion":(..#VERSION)}
}
ClassMethod Ticketing(id As %String, b As %DynamicObject, key As %String) As %DynamicObject
{
    do ##class(Rugby.Service.Store).Key(key)
    set game=##class(Rugby.Service.Store).Game()
    if $data(^RugbyWorld(game,"retry","ticketing",id,key)) quit ##class(%DynamicObject).%FromJSON(^RugbyWorld(game,"retry","ticketing",id,key))
    set m=##class(Rugby.Service.Store).Get("Match",id)
    do ##class(Rugby.Service.Store).Managed(m.homeId),##class(Rugby.Service.Store).CheckVersion(m,b)
    if m.status'="scheduled" do ##class(Rugby.Service.Store).Fail(409,"TICKETS_LOCKED","El precio queda cerrado al iniciar el partido.")
    set c=##class(Rugby.Service.Store).Get("Club",m.homeId)
    if m.date'=c.date do ##class(Rugby.Service.Store).Fail(409,"MATCH_DAY","El precio se fija el día del partido.")
    if '##class(Rugby.Service.Store).Integer(b.%Get("ticketPrice"),0,5000) do ##class(Rugby.Service.Store).Fail(422,"TICKET_PRICE","El precio debe estar entre 0 y 50 euros, en céntimos.")
    set m.ticketPrice=b.ticketPrice
    do ##class(Rugby.Service.Store).Put("Match",m)
    set ^RugbyWorld(game,"retry","ticketing",id,key)=m.%ToJSON()
    quit m
}
ClassMethod Settle(f As %DynamicObject, snapshot As %DynamicObject = "") As %DynamicObject
{
    if '$isobject(snapshot) set snapshot=..Forecast(f)
    set r=##class(%DynamicObject).%FromJSON(snapshot.%ToJSON()),r.barRevenue=0,r.barCosts=0,r.barModel="concession",r.modelVersion=..#VERSION,r.netRevenue=r.ticketRevenue,friendly=f.%Get("stage","friendly")="friendly",r.homeShare=0,r.awayShare=0
    for side="home","away" {
        set c=##class(Rugby.Service.Store).Get("Club",f.%Get(side_"Id")),base="economy-"_f.id,share=$select(friendly:.5,side="home":1,1:0),net=0
        for kind="ticketRevenue","barRevenue","barCosts" {
            set total=r.%Get(kind),amount=$select(share=0:0,(friendly)&&(side="away"):total-(total\2),friendly:total\2,1:total)
            if (kind="barCosts")&&friendly { set homeCost=(r.ticketRevenue\2)+(r.barRevenue\2)-(r.netRevenue\2),amount=$select(side="home":homeCost,1:total-homeCost) }
            if kind="barCosts" set amount=-amount
            if amount do ##class(Rugby.Service.Management).Money(c,amount,$select(kind="ticketRevenue":"tickets",kind="barRevenue":"bar",1:"barCosts"),$select(kind="ticketRevenue":"Taquilla",kind="barRevenue":"Ingresos de bar",1:"Costes de bar")_" · "_f.id,base_"-"_kind)
            set net=net+amount
        }
        do r.%Set(side_"Share",net)
        if (side="away")&&(f.%Get("stage","friendly")'="friendly") do ##class(Rugby.Service.Management).Money(c,-(80000+(..Hash("travel-"_f.id)#70001)),"travel","Desplazamiento · "_f.id,base_"-travel")
    }
    quit r
}
ClassMethod InitializeAll() As %DynamicArray
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),reports=[]
    lock +^RugbyWrite:30
    if '$test do ##class(Rugby.Service.Store).Fail(409,"BUSY","Preparando finanzas.")
    try {
        tstart
        do reports.%Push(..Initialize())
        set gid=""
        for { set gid=$order(^RugbyGames(gid)) quit:gid=""  set g=##class(%DynamicObject).%FromJSON(^RugbyGames(gid)),%RugbyGame=gid,%RugbyManagedClub=g.clubId do reports.%Push(..Initialize()) }
        tcommit
    } catch ex {
        if $tlevel trollback
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
        lock -^RugbyWrite
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub
    lock -^RugbyWrite
    quit reports
}
}
