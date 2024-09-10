// Feather disable all

////////////////////////////////////////////////////////////////////////////
//                                                                        //
// You're welcome to use any of the following macros in your game but ... //
//                                                                        //
//                       DO NOT EDIT THIS SCRIPT                          //
//                       Bad things might happen.                         //
//                                                                        //
//        Customisation options can be found in __ElephantConfig().       //
//                                                                        //
////////////////////////////////////////////////////////////////////////////

#macro  ELEPHANT_BYTE_VERSION  ((1 << 16) | (5 << 8) | (1))
#macro  ELEPHANT_VERSION       (string(ELEPHANT_BYTE_VERSION >> 16) + "." + string((ELEPHANT_BYTE_VERSION >> 8) & 0xFF) + "." + string(ELEPHANT_BYTE_VERSION & 0xFF))
#macro  ELEPHANT_DATE          "2024-09-10"
#macro  ELEPHANT_HEADER        0x454C4550  //ELEP
#macro  ELEPHANT_FOOTER        0x48414E54  //HANT

//      buffer_u8           1
//      buffer_s8           2
//      buffer_u16          3
//      buffer_s16          4
//      buffer_u32          5
//      buffer_s32          6
//      buffer_f16          7
//      buffer_f32          8
//      buffer_f64          9
//      buffer_bool        10
//      buffer_string      11
//      buffer_u64         12
//      buffer_text        13
#macro  buffer_any        204
#macro  buffer_array      205
#macro  buffer_struct     206
#macro  buffer_undefined  207

#macro  ELEPHANT_IS_DESERIALIZING   (__ElephantSystem().__isDeserializing)
#macro  ELEPHANT_SCHEMA_VERSION     (__ElephantSystem().__schemaVersion)
#macro  ELEPHANT_SCHEMA             static __Elephant_Schema__ =
#macro  ELEPHANT_PRE_WRITE_METHOD   static __Elephant_Pre_Write_Method__  = function()
#macro  ELEPHANT_POST_WRITE_METHOD  static __Elephant_Post_Write_Method__ = function()
#macro  ELEPHANT_PRE_READ_METHOD    static __Elephant_Pre_Read_Method__   = function()
#macro  ELEPHANT_POST_READ_METHOD   static __Elephant_Post_Read_Method__  = function()
#macro  ELEPHANT_FORCE_VERSION      __Elephant_Force_Version__
#macro  ELEPHANT_VERSION_VERBOSE    __Elephant_Version_Verbose__
#macro  ELEPHANT_VERBOSE_EXCLUDE    __Elephant_Verbose_Exclude__

ELEPHANT_SCHEMA_VERSION   = undefined;
ELEPHANT_IS_DESERIALIZING = undefined;