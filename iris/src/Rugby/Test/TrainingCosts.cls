Class Rugby.Test.TrainingCosts Extends %RegisteredObject
{
ClassMethod Run()
{
    set game=##class(Rugby.Service.Store).Game(),club=##class(Rugby.Service.Store).Get("Club","c1"),plan=##class(Rugby.Service.Store).Get("TrainingPlan","c1"),balance=club.balance,staff=##class(Rugby.Service.Staff).View("c1").%ToJSON()
    set saved=##class(Rugby.Service.Development).Save("c1",{"version":(plan.version),"groups":[{"id":"no-extra-cost","name":"Fuerza","focus":"strength","intensity":"high","playerIds":["c1-p1"]}]})
    do ##class(Rugby.Test.Suite).Assert((saved.dailyCost=0)&&(saved.rawDailyCost=0),"Intensive training is covered by salaries")
    set suggestion=##class(Rugby.Service.Development).Suggest("c1",3)
    do ##class(Rugby.Test.Suite).Assert(suggestion.dailyCost=0,"Automatic training has no daily fee")
    // A stored plan from the previous version must not revive a charge or a reserve.
    set saved.dailyCost=99999,saved.rawDailyCost=199999
    do ##class(Rugby.Service.Store).Put("TrainingPlan",saved)
    set summary=##class(Rugby.Service.Payroll).Summary("c1")
    do ##class(Rugby.Test.Suite).Assert(summary.annualTraining=0,"Legacy plans cannot reserve training expenditure")
    set before=##class(Rugby.Service.Store).All("FinancialMovement"),count=0
    for i=0:1:before.%Size()-1 { if before.%Get(i).type="training" set count=count+1 }
    set next=##class(Rugby.Service.Management).Advance("c1",{"version":(club.version)},"test-no-training-fee"),execution=##class(Rugby.Service.Store).Get("TrainingExecution","c1-day"_next.day),after=##class(Rugby.Service.Store).All("FinancialMovement"),newCount=0
    for i=0:1:after.%Size()-1 { if after.%Get(i).type="training" set newCount=newCount+1 }
    do ##class(Rugby.Test.Suite).Assert((next.balance=balance)&&(newCount=count)&&(execution.trainingCost=0),"Managed and rival clubs incur no training debits when advancing")
    set audit=##class(Rugby.Service.Store).Get("RivalExecution","rivals-day-"_next.day)
    for i=0:1:audit.clubs.%Size()-1 { do ##class(Rugby.Test.Suite).Assert(audit.clubs.%Get(i).trainingCost=0,"Rival training audit has zero cost") }
    set changes=##class(Rugby.Service.Payroll).RemoveTrainingCosts(),normalized=##class(Rugby.Service.Store).Get("TrainingPlan","c1")
    do ##class(Rugby.Test.Suite).Assert((changes.%Size()>0)&&(normalized.dailyCost=0)&&(normalized.rawDailyCost=0)&&(normalized.groups.%ToJSON()=saved.groups.%ToJSON()),"Adoption clears old quotes and preserves training assignments")
    do ##class(Rugby.Test.Suite).Assert(##class(Rugby.Service.Staff).View("c1").%ToJSON()=staff,"Removing training costs preserves signed employee salaries")
    do ##class(Rugby.Test.Suite).Assert(##class(Rugby.Service.Payroll).RemoveTrainingCosts().%Size()=0,"Training cost adoption is idempotent")
}
}
