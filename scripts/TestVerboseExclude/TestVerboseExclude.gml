function TestVerboseExclude() constructor
{
    a = 0;
    b = 2;
    c = 4;
    
    ELEPHANT_SCHEMA
    {
        ELEPHANT_VERBOSE_EXCLUDE : ["a"],
    }
}