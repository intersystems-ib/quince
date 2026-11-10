Class Rugby.Test.GameDeletion Extends %RegisteredObject
{
ClassMethod Assert(ok As %Boolean, text As %String) { do ##class(Rugby.Test.Suite).Assert(ok,text) }
ClassMethod Run()
{
    set oldGame=##class(Rugby.Service.Store).Game(),oldClub=##class(Rugby.Service.Store).ManagedClub(),oldUser=$get(%RugbyUser)
    try {
        set %RugbyUser="deletion-owner",first=##class(Rugby.Service.Games).Create({"name":"Eliminar prueba","clubId":"c1","divisionId":416},"deletion-create-first"),firstId=first.id
        set c=##class(Rugby.Service.Store).Get("Club","c1"),opts=##class(Rugby.Service.Calendar).Options(c.id,c.date),f=##class(Rugby.Service.Calendar).Create(c.id,{"date":(c.date),"opponentId":(opts.items.%Get(0).id),"venue":"home","version":(c.version)},"deletion-friendly"),m=##class(Rugby.Service.Matches).Create({"fixtureId":(f.id)},"deletion-match"),m=##class(Rugby.Service.Matches).Start(m.id),rows=[],kind=""
        for { set kind=$order(^RugbyWorld(firstId,"catalog",kind)) quit:kind=""  set id="" for { set id=$order(^RugbyWorld(firstId,"catalog",kind,id)) quit:id=""  do rows.%Push({"kind":(kind),"id":(id)}) } }
        set sibling=##class(Rugby.Service.Games).Create({"name":"Conservar propia","clubId":"c2","divisionId":416},"deletion-create-sibling"),siblingId=sibling.id,siblingPlayer=##class(Rugby.Service.Store).Get("Player","c1-p1").%ToJSON()
        set %RugbyUser="deletion-other",foreign=##class(Rugby.Service.Games).Create({"name":"Conservar ajena","clubId":"c11","divisionId":417},"deletion-create-foreign"),foreignId=foreign.id,foreignPlayer=##class(Rugby.Service.Store).Get("Player","c1-p1").%ToJSON(),caught=0
        try { set out=##class(Rugby.Service.Games).Delete(firstId,{"confirm":true},"deletion-denied") } catch ex { set caught=(ex.Code=404)&&(ex.Location="GAME_NOT_FOUND") }
        do ..Assert(caught&&$data(^RugbyGames(firstId)),"Another account cannot delete or discover a game")
        set %RugbyUser="deletion-owner",caught=0
        try { set out=##class(Rugby.Service.Games).Delete(firstId,{},"deletion-no-confirm") } catch ex { set caught=ex.Location="DELETE_CONFIRMATION" }
        do ..Assert(caught&&$data(^RugbyWorld(firstId)),"Explicit confirmation is required")
        set loaded=##class(Rugby.Service.Games).Load(firstId),out=##class(Rugby.Service.Games).Delete(firstId,{"confirm":true},"deletion-confirmed"),again=##class(Rugby.Service.Games).Delete(firstId,{"confirm":true},"deletion-retry")
        do ..Assert(out.deleted&&(out.recordsDeleted=rows.%Size())&&(out.%ToJSON()=again.%ToJSON()),"Deletion returns one stable receipt on retries")
        do ..Assert(('$data(^RugbyGames(firstId)))&&('$data(^RugbyWorld(firstId))),"Game metadata, world and simulation state are removed")
        for i=0:1:rows.%Size()-1 { set r=rows.%Get(i) do ..Assert('$classmethod("Rugby.Model."_r.kind,"%ExistsId",firstId_"|"_r.id),"Every persistent entity of the selected save is removed") }
        set list=##class(Rugby.Service.Games).List()
        do ..Assert((list.items.%Size()=1)&&(list.items.%Get(0).id=siblingId),"The owner's remaining save stays listed")
        set caught=0
        try { set out=##class(Rugby.Service.Games).Load(firstId) } catch ex { set caught=ex.Location="GAME_NOT_FOUND" }
        do ..Assert(caught,"Deleted save cannot be loaded")
        do ##class(Rugby.Service.Games).Select(siblingId)
        do ..Assert(##class(Rugby.Service.Store).Get("Player","c1-p1").%ToJSON()=siblingPlayer,"Sibling data with identical entity IDs is preserved")
        set %RugbyUser="deletion-other"
        do ##class(Rugby.Service.Games).Select(foreignId)
        do ..Assert(##class(Rugby.Service.Store).Get("Player","c1-p1").%ToJSON()=foreignPlayer,"Other account data is preserved")
        set caught=0
        try { set out=##class(Rugby.Service.Games).Delete(firstId,{"confirm":true},"deletion-foreign-retry") } catch ex { set caught=ex.Location="GAME_NOT_FOUND" }
        do ..Assert(caught,"Deletion receipts cannot be read by other accounts")
        set %RugbyUser="deletion-owner",caught=0
        try { set fresh=##class(Rugby.Service.Games).Create({"name":"Nueva prueba","clubId":"c1","divisionId":416},"deletion-create-first") } catch ex { set caught=ex.Location="GAME_DELETED" }
        do ..Assert(caught,"A delayed creation retry cannot recreate an intentionally deleted save")
    } catch ex {
        set %RugbyGame=oldGame,%RugbyManagedClub=oldClub,%RugbyUser=oldUser
        throw ex
    }
    set %RugbyGame=oldGame,%RugbyManagedClub=oldClub,%RugbyUser=oldUser
}
}
