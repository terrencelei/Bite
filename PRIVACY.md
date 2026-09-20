# Data and location behavior

Bite stores your optional display name, saved places, restaurant rankings, ranking activity, preference tags, and derived achievements locally in its app container. It has no account server, advertising SDK, or analytics SDK.

Location access is optional and requested only after tapping **Near me**. Bite requests a one-time location fix while in use, does not request background access, and does not retain a location history. You can search for a city or address without granting location permission. Approximate location is sufficient; results may cover a less precise area.

Map rendering, address lookup, and restaurant search use Apple's MapKit services. Search text and the requested geographic area are processed by Apple to return results. Opening a restaurant website or Apple Maps leaves Bite and is governed by that destination's privacy practices.

Saved restaurant coordinates and details remain on the device so saved places and rankings can be shown offline. Device backups may include the app container according to the user's device backup settings. There is no Bite-managed cloud synchronization. Use **Profile → ⋯ → Delete local data** to remove the current app's local history. The earlier prototype's separate data file is not used by this version.
