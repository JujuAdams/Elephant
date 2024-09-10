/// Unpacks a struct/array JSON created by ElephantToJSON(), respecting Elephant schemas, constructors, and circular references.
/// 
/// @return  The data that was encoded
/// 
/// @param  target

function ElephantFromJSON(_target)
{
    static _system                  = __ElephantSystem();
    static _foundMap                = _system.__foundMap;
    static _postReadCallbackOrder   = _system.__postReadCallbackOrder;
    static _postReadCallbackVersion = _system.__postReadCallbackVersion;
    
    ds_map_clear(_foundMap);
    if (ELEPHANT_FROM_JSON_ACCEPT_LEGACY_CIRCULAR_REFERENCE) _system.__foundCount = 0;
    ds_list_clear(_postReadCallbackOrder);
    ds_list_clear(_postReadCallbackVersion);
    
    ELEPHANT_IS_DESERIALIZING = true;
    ELEPHANT_SCHEMA_VERSION   = undefined;
    
    var _duplicate = __ElephantFromJSONInner(_target, "");
    
    //Now execute post-read callbacks in the order that the structs were created
    var _i = 0;
    repeat(ds_list_size(_postReadCallbackOrder))
    {
        with(_postReadCallbackOrder[| _i])
        {
            //Execute the post-read callback if we can
            if (variable_struct_exists(self, __ELEPHANT_POST_READ_METHOD_NAME))
            {
                ELEPHANT_SCHEMA_VERSION = _postReadCallbackVersion[| _i];
                self[$ __ELEPHANT_POST_READ_METHOD_NAME]();
            }
        }
        
        ++_i;
    }
    
    ds_map_clear(_foundMap);
    ds_list_clear(_postReadCallbackOrder);
    ds_list_clear(_postReadCallbackVersion);
    
    ELEPHANT_IS_DESERIALIZING = undefined;
    ELEPHANT_SCHEMA_VERSION   = undefined;
    
    return _duplicate;
}

function __ElephantFromJSONInner(_target, _longName)
{
    static _system                  = __ElephantSystem();
    static _foundMap                = _system.__foundMap;
    static _postReadCallbackOrder   = _system.__postReadCallbackOrder;
    static _postReadCallbackVersion = _system.__postReadCallbackVersion;
    
    if (is_struct(_target))
    {
        if (variable_struct_exists(_target, __ELEPHANT_JSON_CIRCULAR_REF))
        {
            return _foundMap[? _target[$ __ELEPHANT_JSON_CIRCULAR_REF]];
        }
        else if (variable_struct_exists(_target, __ELEPHANT_JSON_CONSTRUCTOR))
        {
            var _instanceof = _target[$ __ELEPHANT_JSON_CONSTRUCTOR   ];
            var _version    = _target[$ __ELEPHANT_JSON_SCHEMA_VERSION];
            
            if (_version == undefined) __ElephantError("No schema version found");
            
            var _constructorFunction = asset_get_index(_instanceof);
            if (is_method(_constructorFunction))
            {
                //Is a method
                var _struct = new _constructorFunction();
            }
            else if (is_numeric(_constructorFunction) && script_exists(_constructorFunction))
            {
                //Is a script
                var _struct = new _constructorFunction();
            }
            else
            {
                __ElephantError("Could not resolve constructor function \"", _instanceof, "\"");
            }
            
            //Execute the pre-read callback if we can
            var _callback = _struct[$ __ELEPHANT_PRE_READ_METHOD_NAME];
            if (is_method(_callback))
            {
                ELEPHANT_SCHEMA_VERSION = _version;
                method(_struct, _callback)();
            }
            
            //Add this struct to our lists so we can call its post-read method later
            ds_list_add(_postReadCallbackOrder,   _struct);
            ds_list_add(_postReadCallbackVersion, _version);
        }
        else
        {
            //Generic struct
            var _struct  = {};
            var _version = undefined;
        }
        
        //Store a reference to this struct so if we see a circular reference later we can reconstruct it
        _foundMap[? _longName] = _struct;
        
        if (ELEPHANT_FROM_JSON_ACCEPT_LEGACY_CIRCULAR_REFERENCE)
        {
            _foundMap[? _system.__foundCount] = _struct;
            _system.__foundCount++;
        }
        
        var _names = variable_struct_get_names(_target);
        
        //Sort the names alphabetically
        //This is important for deserializing circular references so that the indexes are always created in the same order
        array_sort(_names, true);
        
        var _i = 0;
        repeat(array_length(_names))
        {
            var _name = _names[_i];
            if ((_name != __ELEPHANT_JSON_CONSTRUCTOR) && (_name != __ELEPHANT_JSON_SCHEMA_VERSION))
            {
                _struct[$ _name] = __ElephantFromJSONInner(_target[$ _name], _longName + "." + _name);
            }
            
            ++_i;
        }
        
        return _struct;
    }
    else if (is_array(_target))
    {
        var _length = array_length(_target);
        var _array = array_create(_length);
        
        //Store a reference to this struct so if we see a circular reference later we can reconstruct it
        _foundMap[? _longName] = _array;
        
        if (ELEPHANT_FROM_JSON_ACCEPT_LEGACY_CIRCULAR_REFERENCE)
        {
            _foundMap[? _system.__foundCount] = _array;
            _system.__foundCount++;
        }
        
        var _i = 0;
        repeat(_length)
        {
            _array[@ _i] = __ElephantFromJSONInner(_target[_i], _longName + "[" + string(_i) + "]");
            ++_i;
        }
        
        return _array;
    }
    else
    {
        return _target;
    }
}