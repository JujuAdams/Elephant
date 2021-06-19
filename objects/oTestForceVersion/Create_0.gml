struct = new TestForceVersion(); //Forces serialization to "a" only
struct.a = "wheee";
struct.b = 31;
struct.c = 42;

buffer = ElephantWrite(struct);
result = ElephantRead(buffer);

show_debug_message(result); //Expect a = "wheee", b = 2, c = 4

show_debug_message(ElephantToJSON(struct));
show_debug_message(ElephantFromJSON(ElephantToJSON(struct)));
show_debug_message(instanceof(ElephantFromJSON(ElephantToJSON(struct))));