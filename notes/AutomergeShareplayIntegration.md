# Integration Point: SharePlay

[SharePlay](https://developer.apple.com/shareplay/) is the name of an Apple-platform specific collaborative capability.
The API associated with SharePlay is [GroupActivities](https://developer.apple.com/documentation/GroupActivities/).
Originally developed to be started over a Facetime video call, the capability expands with iOS 17 (and macOS 13) to start interactive collaborative sessions when Apple devices are brought within close proximity of each other, one running an application that supports group activities.
Sessions can also be initiated through Apple's GameCenter lobby and using Airdrop.
This technology is supported on Apple platforms back to iOS 15 and macOS 12.

The API provides ephemeral connections to share information between all participants.
The API notably doesn't include the concept of a group "leader" - with all participants being effectively equal.
Technology isn't provided by Apple to support the synchronization of any concurrent state or agreement between the various participants, being left to the developer to provide - and where Automerge might work extremely well.

The general flow of the API:

0. An app defines a app-specific [GroupActivity](https://developer.apple.com/documentation/groupactivities/groupactivity).
1. Someone who has that app offers to start a session, through a number of channels (Facetime, GameCenter, iMessage, or AirDrop).
2. One or more recipients receive the offer, and upon user confirmation activates the activity.
3. Upon activation, the GroupActivity API configures a session (for example - perhaps a video playback) and the various participants who've opted to take part join the session.
4. The API provides a means to share Codable data updates between all participants through a [messenger](https://developer.apple.com/documentation/groupactivities/groupsessionmessenger) provided by the [session](https://developer.apple.com/documentation/groupactivities/groupsession).
5. At any point, a participant can drop out or stop a session - or invite another person to join into the session. 

There is a limit to the session size, but relatively undocumented - I suspect 6 to 8 as the max.
The continued connection, at least when initiated from AirDrop, is dependent on all app participants being signed into an iCloud account, which supports the "local to network-based" communication transfer.

The messenger that comes with a Session provides a FIFO connection - and can be configurable for either "reliable", "unreliable", or both kinds of messages.
Unreliable messages providing the expectation that they may be faster (the standard UDP vs. TCP networking thing).
However, the framework constrains the messages in data size; in the initial release, messages were limited to 64Kb.
In iOS 16 (and macOS 13), the message size constraint was raised to 256Kb.
In iOS 17 (and macOS 14) additional API is offered that provides to share files up to 100Mb in size.

## Applying Automerge

A CRDT style document, such as an Automerge Document, appears to be a perfect fit for the SharePlay API, with a small caveat.
Using an Automerge document as the core of the shared data model in a GroupActivity would provide the seamless merging and up-to-date synchronization that an app developer would otherwise have to manage on their own.

If the iOS17+ API is available to the app developer, a larger Automerge document can be shared as a file, and then updated with sync messages.
Otherwise, the app could create an ephemeral Automerge for the state of the session, or if the activity was focused on collaboratively editing a document - that document could be an Automerge-based model that is shared and synced.
Each application involved would need to create and manage a SyncState object for the other participants, and use that state when receiving sync messages from those peers.
Syncing using the expected pair of [generateSyncMessage(state:)](https://automerge.org/automerge-swift/documentation/automerge/document/generatesyncmessage(state:)) and [receiveSyncMessage(state:message:)](https://automerge.org/automerge-swift/documentation/automerge/document/receivesyncmessage(state:message:)) methods on an Automerge document.

> NOTE: The caveat here is that if the documents are large, or hold large items (for example, megapixel images), any single change message may be too large for SharePlay, let alone a collection of them. The current Automerge API doesn't provide a filter or limiter function to even potentially constrain the number of changes by size of the changes.

## Apple Documentation/References

API:

- [GroupActivities](https://developer.apple.com/documentation/GroupActivities/)
  - [GroupActivity](https://developer.apple.com/documentation/groupactivities/groupactivity)
  - [GroupSession](https://developer.apple.com/documentation/groupactivities/groupsession)
  - [GroupMessenger](https://developer.apple.com/documentation/groupactivities/groupsessionmessenger)

WWDC23:

- [Add SharePlay to your app](https://developer.apple.com/videos/play/wwdc2023/10239)
- [Design Spatial SharePlay experiences](https://developer.apple.com/videos/play/wwdc2023/10075/)
- [Build Spatial SharePlay experiences](https://developer.apple.com/videos/play/wwdc2023/10087)
- [Share files with SharePlay](https://developer.apple.com/videos/play/wwdc2023/10241)

Techtalks:

- [Add SharePlay to your multiplayer game with Game Center](https://developer.apple.com/videos/play/tech-talks/110338/)

WWDC22:

- [https://developer.apple.com/videos/play/wwdc2022/10139/](https://developer.apple.com/videos/play/wwdc2022/10139/)
- [What's new in SharePlay](https://developer.apple.com/videos/play/wwdc2022/10140/)

WWDC21:

- [Meet Group Activities](https://developer.apple.com/videos/play/wwdc2021/10183/)
- [Coordinate media experiences with Group Activities](https://developer.apple.com/videos/play/wwdc2021/10225/)
- [Design for Group Activities](https://developer.apple.com/videos/play/wwdc2021/10184/)
- [Build custom experiences with Group Activities](https://developer.apple.com/videos/play/wwdc2021/10187/)
- [Coordinate media playback in Safari with Group Activities](https://developer.apple.com/videos/play/wwdc2021/10189/)