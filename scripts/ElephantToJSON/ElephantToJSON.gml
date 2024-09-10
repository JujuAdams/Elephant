/// Makes a copy of a struct/array JSON, respecting Elephant schemas, circular references, and constructors.
/// 
/// @return Struct/array JSON
/// 
/// @param target       Data to serialize
/// @param [diffsOnly]  Optional, whether to only write diffs. If no value is provided then this defaults to ELEPHANT_DEFAULT_WRITE_DIFFS_ONLY

function ElephantToJSON(_target, _diffsOnly = ELEPHANT_DEFAULT_WRITE_DIFFS_ONLY)
{
    static _system       = __ElephantSystem();
    static _foundMap     = _system.__foundMap;
    static _templatesMap = _system.__templatesMap;
    
    ds_map_clear(_foundMap);
    ds_map_clear(_templatesMap);
    
    ELEPHANT_IS_DESERIALIZING = false;
    ELEPHANT_SCHEMA_VERSION   = undefined;
    
    var _duplicate = __ElephantToJSONInner(_target, "", _diffsOnly);
    
    ds_map_clear(_foundMap);
    ds_map_clear(_templatesMap);
    
    ELEPHANT_IS_DESERIALIZING = undefined;
    ELEPHANT_SCHEMA_VERSION   = undefined;
    
    return _duplicate;
}

function __ElephantToJSONInner(_target, _longName, _diffsOnly)
{
    static _system       = __ElephantSystem();
    static _foundMap     = _system.__foundMap;
    static _templatesMap = _system.__templatesMap;
    
    if (is_struct(_target))
    {
        var _duplicate = {};
        
        var _circularRef = _foundMap[? _target];
        if (_circularRef != undefined)
        {
            _duplicate[$ __ELEPHANT_JSON_CIRCULAR_REF] = _circularRef;
        }
        else
        {
            var _diffTemplate = undefined;
            _foundMap[? _target] = _longName;
            
            var _instanceof = instanceof(_target);
            if (_instanceof == "struct")
            {
                var _names = variable_struct_get_names(_target);
                var _verbose = true;
            }
            else
            {
                if (_diffsOnly)
                {
                    //Grab a diff template we've made before if possible
                    _diffTemplate = _templatesMap[? _instanceof];
                    if (_diffTemplate == undefined)
                    {
                        //Try to spin up an empty instance of the constructor
                        var _constructor = asset_get_index(_instanceof);
                        if (is_method(_constructor) || (is_numeric(_constructor) && script_exists(_constructor)))
                        {
                            _diffTemplate = new _constructor();
                            _templatesMap[? _instanceof] = _diffTemplate;
                        }
                    }
                }
                
                var _elephantSchemas = _target[$ __ELEPHANT_SCHEMA_NAME];
                
                //Discover the latest schema version
                var _latestVersion = __ElephantConstructorFindLatestVersion(_elephantSchemas, _instanceof);
                if (_latestVersion > 0)
                {
                    //Get the appropriate schema
                    var _schema = _elephantSchemas[$ "v" + string(_latestVersion)];
                    var _names = variable_struct_get_names(_schema);
                    
                    var _verbose = false;
                    if (variable_struct_exists(_schema, __ELEPHANT_VERSION_VERBOSE_NAME)) _verbose = _schema[$ __ELEPHANT_VERSION_VERBOSE_NAME];
                }
                else
                {
                    var _names = variable_struct_get_names(_target);
                    var _verbose = true;
                }
                
                //Record the constructor and version
                _duplicate[$ __ELEPHANT_JSON_CONSTRUCTOR   ] = _instanceof;
                _duplicate[$ __ELEPHANT_JSON_SCHEMA_VERSION] = _latestVersion;
                
                //Execute the pre-write callback if we can
                var _callback = _target[$ __ELEPHANT_PRE_WRITE_METHOD_NAME];
                if (is_method(_callback))
                {
                    ELEPHANT_SCHEMA_VERSION = _latestVersion;
                    method(_target, _callback)();
                }
                
                if (_verbose) __ElephantRemoveExcludedVariables(_names, _elephantSchemas);
            }
            
            //Sort the names alphabetically
            //This is important for serializing circular references so that the indexes are always created in the same order
            array_sort(_names, true);
            
            //Write the relevant data to the JSON
            if (is_struct(_diffTemplate))
            {
                //If we have a diff template then only write values that are different... obviously
                var _length = array_length(_names);
                var _i = 0;
                repeat(_length)
                {
                    var _name = _names[_i];
                    var _value = _target[$ _name];
                    
                    if (_value != _diffTemplate[$ _name])
                    {
                        _duplicate[$ _name] = __ElephantToJSONInner(_value, _longName + "." + _name, _diffsOnly);
                    }
                    
                    ++_i;
                }
            }
            else
            {
                //Otherwise write everything
                var _length = array_length(_names);
                var _i = 0;
                repeat(_length)
                {
                    var _name = _names[_i];
                    _duplicate[$ _name] = __ElephantToJSONInner(_target[$ _name], _longName + "." + _name, _diffsOnly);
                    ++_i;
                }
            }
            
            if (_instanceof != "struct")
            {
                //Execute the post-write callback if we can
                var _callback = _target[$ __ELEPHANT_POST_WRITE_METHOD_NAME];
                if (is_method(_callback))
                {
                    ELEPHANT_SCHEMA_VERSION = _latestVersion;
                    method(_target, _callback)();
                }
            }
        }
        
        return _duplicate;
    }
    else if (is_array(_target))
    {
        var _circularRef = _foundMap[? _target];
        if (_circularRef != undefined)
        {
            var _duplicate = {};
            _duplicate[$ __ELEPHANT_JSON_CIRCULAR_REF] = _circularRef;
        }
        else
        {
            _foundMap[? _target] = _longName;
            
            var _length = array_length(_target);
            var _duplicate = array_create(_length);
            var _i = 0;
            repeat(_length)
            {
                _duplicate[@ _i] = __ElephantToJSONInner(_target[_i], _longName + "[" + string(_i) + "]", _diffsOnly);
                ++_i;
            }
        }
        
        return _duplicate;
    }
    else
    {
        return _target;
    }
}