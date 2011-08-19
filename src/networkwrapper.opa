package chess

NetworkWrapper = {{

   @server networks = ServerReference.create(StringMap_empty: stringmap(Network.network(message)))

    memo(name: string): Network.network(message) =
    (
        ServerReference.get(networks) |> map -> Map.get(name,map) |> x -> match x with 
            | {some = channel} -> 
                channel
            | {none} ->
                channel = Network.cloud(name)
                do ServerReference.set(networks, StringMap_add(name, channel, map))
                channel
    )

}}