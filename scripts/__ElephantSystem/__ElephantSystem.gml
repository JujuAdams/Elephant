#macro  __ELEPHANT_SCHEMA_NAME             "__Elephant_Schema__"
#macro  __ELEPHANT_PRE_WRITE_METHOD_NAME   "__Elephant_Pre_Write_Method__"
#macro  __ELEPHANT_POST_WRITE_METHOD_NAME  "__Elephant_Post_Write_Method__"
#macro  __ELEPHANT_PRE_READ_METHOD_NAME    "__Elephant_Pre_Read_Method__"
#macro  __ELEPHANT_POST_READ_METHOD_NAME   "__Elephant_Post_Read_Method__"
#macro  __ELEPHANT_FORCE_VERSION_NAME      "__Elephant_Force_Version__"
#macro  __ELEPHANT_VERSION_VERBOSE_NAME    "__Elephant_Version_Verbose__"
#macro  __ELEPHANT_VERBOSE_EXCLUDE_NAME    "__Elephant_Verbose_Exclude__"

#macro __ELEPHANT_JSON_CIRCULAR_REF    "__Elephant_Circular_Ref__"
#macro __ELEPHANT_JSON_CONSTRUCTOR     "__Elephant_Constructor__"
#macro __ELEPHANT_JSON_SCHEMA_VERSION  "__Elephant_Schema_Version__"

__ElephantSystem();

function __ElephantSystem()
{
    static _system = undefined;
    if (_system != undefined) return _system;
    
    _system = {};
    with(_system)
    {
        __readFunction          = undefined;
        __constructorNextIndex  = 0;
        __constructorIndexesMap = ds_map_create();
        __foundCount            = 0;
        __foundMap              = ds_map_create();
        __templatesMap          = ds_map_create();
        __forceVerbose          = false;
        
        __postReadCallbackOrder   = ds_list_create();
        __postReadCallbackVersion = ds_list_create();
        
        __isDeserializing = undefined;
        __schemaVersion   = undefined;
        
        __ElephantTrace("Welcome to Elephant by Juju Adams! This is version " + string(ELEPHANT_VERSION) + ", " + string(ELEPHANT_DATE));
    }
    
    return _system;
}