# Lilac

_너도 언젠가 날 잊게 될까?_

This project is part of Gowon bot ([main repo](https://github.com/gowon-bot/gowon))

## Structure

### Indexing

Lilac indexing leverages Elixir's OTP integration to dynamically spin up new indexing instances. [`Indexer`](lib/lilac/servers/indexing/supervisors/indexer.ex) supervises [`IndexingSupervisor`](lib/lilac/servers/indexing/supervisors/indexing_supervisor.ex) instances, which also have children to handle scrobble fetching, converting, inserting, and progress updating.

### The indexing pipeline:

Since `Artist`s, `Album`s, and `Track`s are associated to `Scrobble`s by ids, Lilac needs to convert the text based Last.fm scrobble fields to ids. For example, the artist "IU" needs to be turned into the id `1242`.

To accomplish this, Lilac uses a case insensitive map abstraction called `ConversionMap`. A list of entities is fetched from the database, and a conversion map is generated by mapping the entities' name to their ids.

This conversion map is generated for artists, albums, and tracks. These maps are then used to insert `Scrobble`s, `ArtistCount`s, `AlbumCount`s, and `TrackCount`s.

## Any questions?

Somethings broken? Just curious how something works?

Feel free to shoot me a Discord dm at john!#2527 or join the support server! https://discord.gg/9Vr7Df7TZf
