// Feather disable all

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
    show_error("Elephant " + string(ELEPHANT_VERSION) + ":\n" + _string + "\n ", true);
}