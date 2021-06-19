//      buffer_u8          1
//      buffer_s8          2
//      buffer_u16         3
//      buffer_s16         4
//      buffer_u32         5
//      buffer_s32         6
//      buffer_f16         7
//      buffer_f32         8
//      buffer_f64         9
//      buffer_bool       10
//      buffer_string     11
//      buffer_u64        12
//      buffer_text       13
#macro  buffer_any        14
#macro  buffer_array      15
#macro  buffer_struct     16
#macro  buffer_undefined  17

#macro  __ELEPHANT_SCHEMA_NAME             "__Elephant_Schema__"
#macro  __ELEPHANT_PRE_WRITE_METHOD_NAME   "__Elephant_Pre_Write_Method__"
#macro  __ELEPHANT_POST_WRITE_METHOD_NAME  "__Elephant_Post_Write_Method__"
#macro  __ELEPHANT_PRE_READ_METHOD_NAME    "__Elephant_Pre_Read_Method__"
#macro  __ELEPHANT_POST_READ_METHOD_NAME   "__Elephant_Post_Read_Method__"
#macro  __ELEPHANT_FORCE_VERSION_NAME      "__Elephant_Force_Version__"
#macro  __ELEPHANT_VERSION_VERBOSE_NAME    "__Elephant_Version_Verbose__"
#macro  __ELEPHANT_VERBOSE_EXCLUDE_NAME    "__Elephant_Verbose_Exclude__"

#macro  ELEPHANT_IS_DESERIALIZING   global.__elephantIsDeserializing
#macro  ELEPHANT_SCHEMA_VERSION     global.__elephantSchemeVersion
#macro  ELEPHANT_SCHEMA             static __Elephant_Schema__ =
#macro  ELEPHANT_PRE_WRITE_METHOD   static __Elephant_Pre_Write_Method__  = function()
#macro  ELEPHANT_POST_WRITE_METHOD  static __Elephant_Post_Write_Method__ = function()
#macro  ELEPHANT_PRE_READ_METHOD    static __Elephant_Pre_Read_Method__   = function()
#macro  ELEPHANT_POST_READ_METHOD   static __Elephant_Post_Read_Method__  = function()
#macro  ELEPHANT_FORCE_VERSION      __Elephant_Force_Version__
#macro  ELEPHANT_VERSION_VERBOSE    __Elephant_Version_Verbose__
#macro  ELEPHANT_VERBOSE_EXCLUDE    __Elephant_Verbose_Exclude__

global.__elephantReadFunction         = undefined;
global.__elephantConstructorIndexes   = {};
global.__elephantConstructorNextIndex = 0;
global.__elephantFound                = undefined;
global.__elephantFoundCount           = 0;
ELEPHANT_SCHEMA_VERSION               = undefined;
ELEPHANT_IS_DESERIALIZING             = undefined;



#macro  __ELEPHANT_HEADER       0x454C4550  //ELEP
#macro  __ELEPHANT_FOOTER       0x48414E54  //HANT
#macro  __ELEPHANT_BYTE_VERSION ((1 << 16) | (2 << 8) | (0))
#macro  __ELEPHANT_VERSION      (string(__ELEPHANT_BYTE_VERSION >> 16) + "." + string((__ELEPHANT_BYTE_VERSION >> 8) & 0xFF) + "." + string(__ELEPHANT_BYTE_VERSION & 0xFF))
#macro  __ELEPHANT_DATE         "2021-06-12"

__ElephantTrace("Welcome to Elephant by @jujuadams! This is version " + string(__ELEPHANT_VERSION) + ", " + string(__ELEPHANT_DATE));





function __ElephantTrace()
{
    var _string = "Elephant: ";
    var _i = 0;
    repeat(argument_count)
    {
        _string += string(argument[_i]);
        ++_i;
    }
    
    show_debug_message(_string);
}

function __ElephantError()
{
    var _string = "";
    var _i = 0;
    repeat(argument_count)
    {
        _string += string(argument[_i]);
        ++_i;
    }
    
    show_debug_message("Elephant: " + _string);
    show_error("Elephant:\n" + _string + "\n ", true);
}

function __ElephantValueToDatatype(_value)
{
    switch(typeof(_value))
    {
        case "int32":     return buffer_s32;       break;
        case "bool":      return buffer_bool;      break;
        case "number":    return buffer_f64;       break;
        case "string":    return buffer_string;    break;
        case "undefined": return buffer_undefined; break;
        case "struct":    return buffer_struct;    break;
        
        case "array":
        case "vec3":
        case "vec4": return buffer_array; break;
        
        case "int64":
        case "ptr": return buffer_u64; break;
                
        case "method":
            __ElephantTrace("Methods not supported, writing <undefined>");
            return buffer_undefined;
        break;
                
        default:
            __ElephantError("Datatype not recognised \"", typeof(_value), "\"");
        break
    }
    
    return buffer_undefined;
}