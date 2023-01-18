//Whether to accept integer-based circular references when deserializing JSON
#macro  ELEPHANT_FROM_JSON_ACCEPT_LEGACY_CIRCULAR_REFERENCE  true

//Whether Elephant write functions should default to writing diffs only
//This has the advantage of outputting substantially smaller files, but has the
//disadvantage of occasionally making life hard when the default values shouldn't
//be migrated between different versions of a game
//
//If you do need to adjust default values when migrating between versions, you may
//find it useful to set up a post-read callback -  see documentation for more info
#macro  ELEPHANT_DEFAULT_WRITE_DIFFS_ONLY  false