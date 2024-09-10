// Feather disable all

function __ElephantRemoveExcludedVariables(_names, _elephantSchemas)
{
    //There's no specific serialization information so we write this constructor as a generic struct
    if (is_struct(_elephantSchemas))
    {
        //Check to see if we have an array of variables to exclude from serialization
        if (variable_struct_exists(_elephantSchemas, __ELEPHANT_VERBOSE_EXCLUDE_NAME))
        {
            var _excludeArray = _elephantSchemas[$ __ELEPHANT_VERBOSE_EXCLUDE_NAME];
            if (!is_array(_excludeArray)) __ElephantError("Verbose exclude data must be an array (datatype = ", typeof(_excludeArray), ", constructor = \"", _instanceof, "\")");
            
            var _foundLength = array_length(_names);
            var _i = 0;
            repeat(array_length(_excludeArray))
            {
                var _exclude = _excludeArray[_i];
                
                var _j = 0;
                repeat(_foundLength)
                {
                    if (_names[_j] == _exclude)
                    {
                        array_delete(_names, _j, 1);
                        --_foundLength;
                        break;
                    }
                    
                    ++_j;
                }
                
                ++_i;
            }
        }
    }
}