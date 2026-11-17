Class Rugby.Test.RenewalPayroll Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Run()
{
    for percent=0,90 {
        for category="senior","academy" {
            for delta=-10000,0,100 {
                tstart
                set club=##class(Rugby.Service.Store).ManagedClub(),c=##class(Rugby.Service.Store).Get("Club",club),o=##class(Rugby.Service.Finance).Office(club),o.salaryBudget={"year":(##class(Rugby.Service.Competition).Year(c.date)),"percent":(percent)}
                do ##class(Rugby.Service.Store).Put("FinancialOffice",o)
                set p=##class(Rugby.Service.Store).Get("Player",club_"-p"_$select(category="senior":1,1:24)),p.monthlyWage=200000,p.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(p.monthlyWage),blocker=##class(Rugby.Service.Store).Get("Player",club_"-p2"),blocker.monthlyWage=10000000,blocker.weeklyWage=##class(Rugby.Service.MonthlyPayroll).Weekly(blocker.monthlyWage)
                do ##class(Rugby.Service.Store).Put("Player",p),##class(Rugby.Service.Store).Put("Player",blocker)
                do ..Assert(##class(Rugby.Service.Payroll).Used(club)>##class(Rugby.Service.Payroll).WeeklyCap(club),"The club is already over its wage limit")
                set n=##class(Rugby.Service.Transfers).Open(p.id,{"version":(p.version)},"renew-payroll-open","renewal"),raw=##class(Rugby.Service.Store).Get("Negotiation",n.id),raw.reservationWage=100
                do ##class(Rugby.Service.Store).Put("Negotiation",raw)
                set n=##class(Rugby.Service.Transfers).Offer(n.id,{"version":(raw.version),"monthlyWage":(200000+delta),"contractYears":1},"renew-payroll-offer"),before=##class(Rugby.Service.Store).Get("Player",p.id).%ToJSON(),body={"version":(n.version)},error=""
                do ..Assert(n.status="agreed","The player accepts the proposed salary before checking the wage limit")
                try { set signed=##class(Rugby.Service.Transfers).Sign(n.id,body,"renew-payroll-sign") } catch ex { set error=ex.Location }
                if delta<=0 {
                    set player=##class(Rugby.Service.Store).Get("Player",p.id),retry=##class(Rugby.Service.Transfers).Sign(n.id,body,"renew-payroll-sign")
                    do ..Assert((error="")&&(signed.status="signed")&&(player.monthlyWage=(200000+delta))&&(player.category=category),"Equal or lower monthly renewals succeed for senior and academy players, including flexible budgets")
                    do ..Assert(signed.%ToJSON()=retry.%ToJSON(),"Retrying the renewal never creates a second contract")
                } else {
                    do ..Assert((error="PAYROLL_LIMIT")&&(##class(Rugby.Service.Store).Get("Player",p.id).%ToJSON()=before),"Even a one-euro increase is rejected while above the wage limit, without changing the player")
                }
                trollback 1
            }
        }
    }
}
}
