Class Rugby.Service.Positions Extends %RegisteredObject
{
ClassMethod Describe(position As %Integer) As %DynamicObject
{
    // Legacy numeric keys identify positions, never permanent player shirt numbers.
    set roles=[
        {"id":"loosehead-prop","name":"Pilar izquierdo","group":"forwards"},
        {"id":"hooker","name":"Talonador","group":"forwards"},
        {"id":"tighthead-prop","name":"Pilar derecho","group":"forwards"},
        {"id":"left-lock","name":"Segunda línea I","group":"forwards"},
        {"id":"right-lock","name":"Segunda línea II","group":"forwards"},
        {"id":"blindside-flanker","name":"Ala lado ciego","group":"forwards"},
        {"id":"openside-flanker","name":"Ala lado abierto","group":"forwards"},
        {"id":"number-eight","name":"Número ocho","group":"forwards"},
        {"id":"scrum-half","name":"Medio melé","group":"backs"},
        {"id":"fly-half","name":"Apertura","group":"backs"},
        {"id":"left-wing","name":"Ala izquierdo","group":"backs"},
        {"id":"inside-centre","name":"Centro interior","group":"backs"},
        {"id":"outside-centre","name":"Centro exterior","group":"backs"},
        {"id":"right-wing","name":"Ala derecho","group":"backs"},
        {"id":"fullback","name":"Zaguero","group":"backs"}
    ]
    if '##class(Rugby.Service.Store).Integer(position,1,15) do ##class(Rugby.Service.Store).Fail(422,"PLAYER_POSITION","Posición de rugby no válida.")
    quit roles.%Get(position-1)
}
}
