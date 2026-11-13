Class Rugby.Test.Sessions Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, message As %String) { do ##class(Rugby.Test.Suite).Assert(ok,message) }
ClassMethod Token(claims As %DynamicObject, algorithm As %String = "HS256") As %String
{
    set header={"alg":(algorithm),"typ":"JWT"},data=##class(Rugby.Service.Auth).Encode(header.%ToJSON())_"."_##class(Rugby.Service.Auth).Encode(claims.%ToJSON())
    quit data_"."_##class(Rugby.Service.Auth).Encode($system.Encryption.HMACSHA(256,data,^RugbyAuth("secret")))
}
ClassMethod Run()
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),oldUser=$get(%RugbyUser)
    try {
        set user={"id":"test-session-owner","username":"test-manager"},^RugbyAuth("users",user.id)=user.%ToJSON(),^RugbyAuth("sessions","test-session")=user.id,now=##class(Rugby.Service.Auth).Now(),claims={"sub":(user.id),"jti":"test-session","iss":"quince","aud":"rugby-manager","iat":(now),"exp":(now+300)},token=..Token(claims)
        set actual=##class(Rugby.Service.Auth).Require(token)
        do ..Assert(actual.id=user.id,"Signed JWT identifies the account")
        for mode="signature","expired","algorithm","audience","revoked" {
            set c=##class(%DynamicObject).%FromJSON(claims.%ToJSON()),bad="",caught=0
            if mode="signature" set bad=$extract(token,1,$length(token)-2)_"!!"
            if mode="expired" set c.exp=now-1
            if mode="audience" set c.aud="other-application"
            if mode="revoked" set c.jti="missing-session"
            if bad="" set bad=..Token(c,$select(mode="algorithm":"none",1:"HS256"))
            try { set ignored=##class(Rugby.Service.Auth).Require(bad) } catch ex { set caught=ex.Code=401 }
            do ..Assert(caught,"JWT rejects "_mode)
        }
        set %RugbyUser=user.id
        set first=##class(Rugby.Service.Games).Create({"name":"Élite test","divisionId":417,"clubId":"c11"},"new-save-a"),firstId=first.id
        set retry=##class(Rugby.Service.Games).Create({"name":"Élite test","divisionId":417,"clubId":"c11"},"new-save-a")
        do ..Assert(firstId=retry.id,"New save request can be retried without creating another game")
        do ..Assert(##class(Rugby.Service.Store).ManagedClub()="c11","Any participant can be managed")
        set club=##class(Rugby.Service.Store).Get("Club","c11")
        do ..Assert((club.date="2026-09-01")&&(club.day=-67),"New season begins September 1")
        set club.date="2026-09-02",club.day=-66
        do ##class(Rugby.Service.Store).Put("Club",club)
        set options=##class(Rugby.Service.Calendar).Options("c11",club.date),again=##class(Rugby.Service.Calendar).Options("c11",club.date),divisions={}
        do ..Assert((options.items.%Size()=3)&&(options.%ToJSON()=again.%ToJSON()),"Three stable random opponents per selected day")
        for i=0:1:2 { set opponent=options.items.%Get(i) do divisions.%Set(opponent.competitionId,1) do ..Assert(opponent.id'="c11","Cannot play against own club") }
        do ..Assert(divisions.%Size()=2,"Friendly suggestions cover both divisions")
        set opponent=options.items.%Get(0),body={"version":(club.version),"date":(club.date),"opponentId":(opponent.id),"venue":"away"},f=##class(Rugby.Service.Calendar).Create(club.id,body,"test-friendly"),retry=##class(Rugby.Service.Calendar).Create(club.id,body,"test-friendly")
        do ..Assert((f.id=retry.id)&&(f.awayId=club.id)&&(f.homeId=opponent.id),"Friendly supports away venue and idempotency")
        set found=0,fixtures=##class(Rugby.Service.Competition).ClubFixtures(club.id)
        for i=0:1:fixtures.%Size()-1 { if fixtures.%Get(i).id=f.id set found=1 }
        do ..Assert(found,"Friendly is included alongside league fixtures")
        set caught=0
        try { set ignored=##class(Rugby.Service.Calendar).Create(club.id,body,"another-friendly") } catch ex { set caught=ex.Location="CALENDAR_BUSY" }
        do ..Assert(caught,"Cannot schedule two matches on the same date")
        set caught=0
        try { set ignored=##class(Rugby.Service.Calendar).Options(club.id,"2026-08-31") } catch ex { set caught=ex.Location="FRIENDLY_DATE" }
        do ..Assert(caught,"Cannot create a friendly in the past")
        set league=##class(Rugby.Service.Store).Get("Competition","league-417-2026")
        do ..Assert(##class(Rugby.Service.Calendar).Busy(club.id,league.semifinalDates.%Get(0)),"Unassigned playoff dates remain reserved")
        set m=##class(Rugby.Service.Matches).Create({"fixtureId":(f.id)},"test-game-match"),m=##class(Rugby.Service.Matches).Start(m.id),firstMatch=m.id
        do ..Assert((m.awayId="c11")&&(m.awayPlayers.%Get(0).clubId="c11"),"Selected club can play a friendly using its own lineup")
        set p=##class(Rugby.Service.Store).Get("Player","c11-p1"),p.energy=42
        do ##class(Rugby.Service.Store).Put("Player",p)
        set second=##class(Rugby.Service.Games).Create({"name":"Honor test","divisionId":416,"clubId":"c2"},"new-save-b"),secondId=second.id
        do ..Assert(##class(Rugby.Service.Store).Get("Player","c11-p1").energy=100,"Player state is isolated between saves")
        set club=##class(Rugby.Service.Store).Get("Club","c2"),club.date="2026-09-02",club.day=-66
        do ##class(Rugby.Service.Store).Put("Club",club)
        set options=##class(Rugby.Service.Calendar).Options(club.id,club.date),f=##class(Rugby.Service.Calendar).Create(club.id,{"version":(club.version),"date":(club.date),"opponentId":(options.items.%Get(0).id),"venue":"home"},"test-friendly"),m=##class(Rugby.Service.Matches).Create({"fixtureId":(f.id)},"test-game-match"),m=##class(Rugby.Service.Matches).Start(m.id)
        do ..Assert((m.id=firstMatch)&&(m.homeId="c2"),"Identical match IDs and event sequences coexist in separate saves")
        set loaded=##class(Rugby.Service.Games).Load(firstId)
        do ..Assert(##class(Rugby.Service.Store).Get("Player","c11-p1").energy=42,"Loading a save restores its actual current player state")
        set list=##class(Rugby.Service.Games).List()
        do ..Assert(list.items.%Size()=2,"Account lists both saves")
        do ##class(Rugby.Service.Games).PauseUser()
        do ..Assert('##class(%DynamicObject).%FromJSON(^RugbyGames(firstId)).active,"Signing out pauses the account's running saves")
        set %RugbyUser="another-user",caught=0
        try { do ##class(Rugby.Service.Games).Select(firstId) } catch ex { set caught=ex.Location="GAME_NOT_FOUND" }
        do ..Assert(caught,"Another account cannot load a save")
    } catch ex {
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub,%RugbyUser=oldUser
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub,%RugbyUser=oldUser
}
}
