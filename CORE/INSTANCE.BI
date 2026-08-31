''
' DRAW - CORE/INSTANCE.BI
' =============================================================================
' Multiple-instance support: per-instance identity, state isolation, and a small
' file-based registry so cooperating DRAW copies can find each other (for the
' "Send Layer -> Instance N" handoff) and tag their window titles.
'
' Identity is resolved at INCLUDE time (INSTANCE_bootstrap below), right after
' PATHS_init and BEFORE CFG/CONFIG.BI resolves the config path -- because a
' secondary instance's config path is derived from its instance id.
'
' Isolation is ALWAYS on when more than one instance runs. The
' CFG.ALLOW_MULTIPLE_INSTANCES preference only gates DRAW's in-app "New Window"
' command; a manually-launched second copy is still allowed and still isolated.
'
' Liveness is an MTIME-FREE heartbeat: each instance writes a TIMER value into
' its own registry file every few seconds; a file whose heartbeat is older than
' INSTANCE_STALE_SECS is treated as a dead instance and reaped. (QB64-PE has no
' file-mtime keyword, and LOCK/UNLOCK are no-ops on Linux/macOS, so coordination
' is done with atomic write-temp-then-NAME renames + this heartbeat.)
'
' @author Rick Christy <grymmjack@gmail.com>
'
$INCLUDEONCE

CONST INSTANCE_MAX        = 32    ' highest instance slot we will ever assign (1..MAX)
CONST INSTANCE_STALE_SECS = 60    ' a registry file whose heartbeat is older than this = dead.
'                                    BUG-34: was 12s — shorter than a normal modal-dialog dwell,
'                                    which freezes the heartbeat (INSTANCE_tick only runs in the
'                                    main loop) → peers falsely reaped a live instance → slot/config
'                                    collision, dropped Send-Layer, double music. 60s covers typical
'                                    modal dwell. (Full fix would pump the heartbeat inside modal loops.)
CONST INSTANCE_HEARTBEAT_SECS = 3 ' rewrite our own registry file this often (updates heartbeat)
CONST INSTANCE_MAILPOLL_SECS  = 1 ' poll our mailbox inbox this often (see LAYERXFER handoff)

TYPE INSTANCE_OBJ
    id            AS INTEGER ' this instance's slot (1..INSTANCE_MAX); 1 = first/primary (normal config)
    explicitId    AS INTEGER ' TRUE if id came from --instance N (vs auto-assigned)
    active        AS INTEGER ' TRUE once registered
    startToken    AS DOUBLE  ' TIMER at startup -- uniqueness hint / claim tie-breaker
    registryDir   AS STRING  ' <cache>/instances/
    mailboxDir    AS STRING  ' <cache>/instances/mailbox/<id>/   (THIS instance's inbox)
    myRegFile     AS STRING  ' <registryDir><id>.instance
    title         AS STRING  ' human label written into the registry (app + current filename)
    liveCount     AS INTEGER ' number of live instances at last scan
    isMusicOwner  AS INTEGER ' TRUE if this is the lowest-id live instance (only it plays background music)
    lastHeartbeat AS DOUBLE  ' TIMER of our last heartbeat write
    lastMailPoll  AS DOUBLE  ' TIMER of our last mailbox poll
END TYPE
DIM SHARED INST AS INSTANCE_OBJ

' Resolve identity + isolation paths NOW (PATHS_init has already run; CONFIG.BI
' has not yet resolved the config path -- it will read INST.id).
INSTANCE_bootstrap
