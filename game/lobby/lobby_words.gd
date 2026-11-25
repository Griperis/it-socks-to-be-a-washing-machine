## Every word the Lobby shows, in one place (docs/architecture/lobby.md "Core/67", the old 02-lobby.md "Words
## and refusals"): the screen, its places, the World card's page, the drawer and its rows. The scenes carry no
## text of their own; each view sets its words from here, so changing a word is one line.
## placeholder: the old wording, until the designer words the screens.
class_name LobbyWords
extends RefCounted

# The bottom bar and its captions.
const BACK := "Back"
const LEAVE := "Leave"
const READY := "Ready"
const READY_ON := "✓ Ready"
const READY_CAPTION := "press again to un-ready"
const START := "Start"
const START_CAPTION := "when everyone is Ready"
const WAITING_HOST := "Waiting for the Host to start"
const CONTINUE := "Continue"
const NEW_GAME_SOLO := "New Game"

# The card, the places, the "i" page.
const SOLO_TITLE := "Solo"
const NEW_WORLD := "New World"
const WHO_KEY := "i"
const WHO_HEADING := "Who was in %s"
const HOST_MARK := "HOST"
const WAITING_PLAYER := "Waiting for a player"
const NOT_READY_DASH := "–"
const READY_TICK := "✓"
const CHOSEN_TICK := "✓"

# Solo's question.
const NEW_GAME_HEADING := "New game"
const NEW_GAME_ASK := "Start a new game? The saved game is lost."
## Solo's New Game page with the debug slider and no save to lose: its key.
const NEW_GAME_GO := "Start"

# The debug "Pairs per Drawer" slider (Q668, core/91).
const PAIRS := "Pairs per Drawer: %d"

# The drawer and its rows.
const DRAWER_HEADING := "World settings"
const DRAWER_WORLD := "World"
const NEW_GAME := "New game"
const NEW_GAME_ON := "✓ New game"
const INVITE := "Invite friends"
const CHOOSE := "Choose"
const CHOSEN := "✓ Chosen"
const DELETE := "Delete"
const DELETE_HEADING := "Delete World"
const DELETE_ASK := "Delete %s? It cannot be brought back."
const FULL_LINE := "All %d co-op Worlds are used: delete one first"

# Why the game cannot go on.
const CANNOT_HOST := "Could not host on port %d"
