// Feather disable all

function __ElephantConstructorFindLatestVersion(_elephantSchemas, _instanceof)
{
    var _latestVersion = 0;
    
    if (is_struct(_elephantSchemas))
    {
        if (variable_struct_exists(_elephantSchemas, __ELEPHANT_FORCE_VERSION_NAME))
        {
            _latestVersion = _elephantSchemas[$ __ELEPHANT_FORCE_VERSION_NAME];
            
            if (_latestVersion != 0) //Allow forcing to version 0
            {
                if (!variable_struct_exists(_elephantSchemas, "v" + string(_latestVersion)))
                {
                    __ElephantError("Forced schema version \"", _latestVersion, "\" has no data (constructor = \"", _instanceof, "\")");
                }
            }
        }
        else
        {
            //Iterate over names inside the root of the schema struct
            var _names = variable_struct_get_names(_elephantSchemas);
            var _i = 0;
            repeat(array_length(_names))
            {
                var _name = _names[_i];
                
                if ((_name != __ELEPHANT_VERSION_VERBOSE_NAME)
                &&  (_name != __ELEPHANT_VERBOSE_EXCLUDE_NAME))
                {
                    try
                    {
                        //Check the first character (should only ever be "v")
                        if (string_char_at(_name, 1) != "v") throw -1;
                        
                        //Extract the numeric version from the remainder of the string 
                        var _version = real(string_delete(_name, 1, 1));
                        
                        //Check to see if the version number is between 1 and 127 (inclusive)
                        if ((_version < 0x01) || (_version > 0x7F) || (floor(_version) != _version)) throw -2;
                        
                        //Check if we can go backwards from the version number back to the struct entry
                        if (_name != "v" + string(_version)) throw -3;
                        
                        //Finally, if the found version is larger than the latest version we found already, update the latest version
                        if (_version > _latestVersion) _latestVersion = _version;
                    }
                    catch(_)
                    {
                        __ElephantError("Schema version tag \"", _name, "\" is invalid:\n- Schema versions must start with a lowercase \"v\" and be followed by a version number\n- The version number must be an integer from 1 to 255 inclusive\n- The version number must contain no leading zeros e.g. \"v001\" is invalid");
                    }
                }
                
                ++_i;
            }
        }
    }
    
    return _latestVersion;
}