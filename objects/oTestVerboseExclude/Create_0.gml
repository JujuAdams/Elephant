show_debug_message("--------------------------------------------------------------------------------------------------------------------------------");
show_debug_message(object_get_name(object_index));

struct = new TestVerboseExclude(); //Excludes serialization of "a"
struct.a = 99;
struct.b = 1;
struct.c = 2;

buffer = ElephantWrite(struct);
result = ElephantRead(buffer);

show_debug_message(result); //Expect a = 0, b = 1, c = 2

show_debug_message(ElephantToJSON(struct));

show_debug_message("--------------------------------------------------------------------------------------------------------------------------------");