Class Rugby.Test.FriendlyRequests Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Run()
{
    set own=##class(Rugby.Service.Store).ManagedClub(),c=##class(Rugby.Service.Store).Get("Club",own),c.date="2026-09-01",c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3)
    do ##class(Rugby.Service.Store).Put("Club",c)
    set first=##class(Rugby.Service.FriendlyRequests).Tick(),v=first.invitation,fixtures=##class(Rugby.Service.Store).All("Fixture").%Size(),weekday=($zdateh(v.date,3)+4)#7
    do ..Assert(first.created&&((weekday=0)||(weekday=6))&&(v.opponentId'=own),"A rival invites the user for a free weekend")
    do ..Assert((##class(Rugby.Service.FriendlyRequests).List(own).%Size()=1)&&(##class(Rugby.Service.Store).All("Fixture").%Size()=fixtures),"Invitations do not schedule a match before consent")
    set again=##class(Rugby.Service.FriendlyRequests).Tick()
    do ..Assert('again.created,"One request maximum per month")
    set result=##class(Rugby.Service.FriendlyRequests).Respond(own,v.id,{"version":(v.version),"decision":"reject"},"reject-test"),again=##class(Rugby.Service.FriendlyRequests).Tick()
    do ..Assert((result.status="rejected")&&('again.created),"Rejecting does not generate another invitation this month")
    set c.date="2026-10-01",c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3)
    do ##class(Rugby.Service.Store).Put("Club",c)
    set next=##class(Rugby.Service.FriendlyRequests).Tick(),v=next.invitation,conflict={"id":"invite-conflict","homeId":(v.opponentId),"awayId":(own),"date":(v.date),"day":($zdateh(v.date,3)-$zdateh("2026-11-07",3)),"stage":"friendly","status":"scheduled"}
    do ##class(Rugby.Service.Store).Put("Fixture",conflict)
    set failed=0
    try { set result=##class(Rugby.Service.FriendlyRequests).Respond(own,v.id,{"version":(v.version),"decision":"accept"},"conflict-test") } catch ex { set failed=ex.Location="CALENDAR_BUSY" }
    do ..Assert(failed,"Accepting rechecks both teams' calendars")
    set conflict.archived=1
    do ##class(Rugby.Service.Store).Put("Fixture",conflict)
    set b={"version":(v.version),"decision":"accept"},result=##class(Rugby.Service.FriendlyRequests).Respond(own,v.id,b,"accept-test"),retry=##class(Rugby.Service.FriendlyRequests).Respond(own,v.id,b,"accept-test"),f=##class(Rugby.Service.Store).Get("Fixture",result.fixtureId)
    do ..Assert((result.%ToJSON()=retry.%ToJSON())&&(f.stage="friendly")&&(f.date=v.date)&&(f.invitationId=v.id),"Acceptance creates exactly one normal friendly, with safe retries")
    set c.date="2026-11-01",c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3)
    do ##class(Rugby.Service.Store).Put("Club",c)
    set next=##class(Rugby.Service.FriendlyRequests).Tick(),v=next.invitation,c.date=$zdate($zdateh(v.expiresOn,3)+1,3),c.day=$zdateh(c.date,3)-$zdateh("2026-11-07",3)
    do ##class(Rugby.Service.Store).Put("Club",c)
    set failed=0
    try { set result=##class(Rugby.Service.FriendlyRequests).Respond(own,v.id,{"version":(v.version),"decision":"accept"},"expired-test") } catch ex { set failed=ex.Location="INVITATION_EXPIRED" }
    do ..Assert(failed,"Expired invitations cannot be accepted")
    set tick=##class(Rugby.Service.FriendlyRequests).Tick()
    do ..Assert(##class(Rugby.Service.Store).Get("FriendlyInvitation",v.id).status="expired","Advancing updates invitation expiry")
}
}
