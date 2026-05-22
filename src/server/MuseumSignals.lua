-- MuseumSignals.lua (ModuleScript)
-- Lightweight server-side event bus so that data-owning services and
-- world-building services don't have to require each other directly.
--
-- MuseumService fires MuseumChanged after a player's displayed artifacts
-- change; PedestalService listens and rebuilds that player's pedestals.

local MuseumSignals = {}

-- Fired with (player) whenever a player's set of displayed artifacts changes.
MuseumSignals.MuseumChanged = Instance.new("BindableEvent")

-- Fired with (player) when someone steps into a museum's hub portal.
-- HubService listens and teleports them to the hub (avoids a require cycle).
MuseumSignals.GoToHubRequested = Instance.new("BindableEvent")

return MuseumSignals
