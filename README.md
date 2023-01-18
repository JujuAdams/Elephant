<h1 align="center">Elephant 1.4.0</h1>

<p align="center">Advanced struct/array serialization for GameMaker 2022 LTS</p>

<p align="center"><b>@jujuadams</b></p>

<p align="center">Chat about Elephant on the <a href="https://discord.gg/8krYCqr">Discord server</a></p>

&nbsp;

&nbsp;

&nbsp;

# Introduction

Elephant is a struct/array serialization system that offers extended functionality beyond the typical JSON functions:
  - Serialization of arrays, structs, and scalar datatypes
  - Circular references are stored and recreated correctly
  - Structs made with constructors are recreated using the constructor
  - Constructed structs can have schemas to control which variables are serialized and how
  - Constructed structs can have read/write callbacks

&nbsp;

When using Elephant, some considerations must be taken into account:
  - Constructors must be in global scope i.e. in a script
  - Whilst static methods in constructors will persist, non-static methods cannot be serialized
  - Constructor schemas are shallow without nesting/recursion, and arrays cannot have schemas
  - Upon deserialization, structs are rebuilt by new-ing the constructor with zero arguments
  - Arrays are limited to 65534 elements and structs are limited to 65533 member variables

&nbsp;
  
Arrays are assumed to have flexible typing, though arrays that are found to have a consistent datatype throughout are optimised automatically when serializing. Preferably, constructors should only set default variable values and structs shouldn't alter state outside of their scope on instantiation.

**N.B. When using Elephant it is very important to ensure constructor methods are static. A non-static method cannot be serialized and will instead be set to `undefined` upon deserialization.**

&nbsp;

Elephant introduces a handful of macros that are useful for interacting with the library. These are explained in further detail later in the document.

Schema definition for constructors:
- `ELEPHANT_SCHEMA`
- `ELEPHANT_FORCE_VERSION`
- `ELEPHANT_VERSION_VERBOSE`
- `ELEPHANT_VERBOSE_EXCLUDE`

Custom datatypes that can be used with Elephant schemas:
- `buffer_any`
- `buffer_array`
- `buffer_struct`
- `buffer_undefined`

Callbacks, and callback state:
- `ELEPHANT_PRE_WRITE_METHOD`
- `ELEPHANT_POST_WRITE_METHOD`
- `ELEPHANT_PRE_READ_METHOD`
- `ELEPHANT_POST_READ_METHOD`
- `ELEPHANT_SCHEMA_VERSION`
- `ELEPHANT_IS_DESERIALIZING`

&nbsp;

&nbsp;

&nbsp;

# Functions

Elephant has five public functions that can be used:
    
- `ElephantWrite(target, [buffer])`
  - Serializes the given target data and writes it to the given buffer, starting at the `buffer_tell()` position. This function uses `buffer_write()` and will move the buffer head as it writes. If no buffer is provided then a new buffer is created that fits the serialized data. This function calls `ELEPHANT_PRE_WRITE_METHOD` and `ELEPHANT_POST_WRITE_METHOD` for constructed structs, and `ELEPHANT_IS_DESERIALIZING` is set to `false`. `ELEPHANT_SCHEMA_VERSION` will contain the constructor schema version that Elephant is using to serialize data.
    
- `ElephantExportString(target)`
  - As above, but returns a base64 encoded version of the buffer. This function also performs compression on the buffer.
    
- `ElephantRead(buffer)`
  - Deserializes Elephant data from a buffer, starting at the `buffer_tell()` point. This function uses `buffer_read()` and will move the buffer head as it reads data. This function calls `ELEPHANT_PRE_READ_METHOD` and `ELEPHANT_POST_READ_METHOD` for constructed structs, and `ELEPHANT_IS_DESERIALIZING` is set to `true`. `ELEPHANT_SCHEMA_VERSION` will contain the constructor schema version that Elephant found in the source data.
    
- `ElephantImportString(string)`
  - As above, but takes a string rather than a buffer. This string should have been created by `ElephantExportString()`.
    
- `ElephantDuplicate(target)`
  - Makes an identical copy of the target. Unlike `ElephantWrite()`, this function ignores schemas and will copy all member variables and non-static methods. This function will recreate constructed structs appropriately and will also correctly duplicate circular references.

&nbsp;

&nbsp;

&nbsp;

# Schemas

Schemas may be defined for constructors by using the macro `ELEPHANT_SCHEMA` to define a struct literal. This struct literal contains schema versions as the top-level keys, and member variables names with associated datatype as second-level keys.

If no schema is defined then all member variables for the struct will be serialized using the generic `buffer_any` datatype. This typically leads to large buffers and is much slower to both serialize and deserialize and should generally be avoided. Try to declare a schema whenever you can.

Schemas must be defined by setting `ELEPHANT_SCHEMA` in a constructor e.g.

```GML
function Example() constructor
{
	x = 0;
	y = 0;
	
	ELEPHANT_SCHEMA
	{
		v1 : {
			x : buffer_f64,
			y : buffer_f64,
		},
	}
	
	static SetPosition = function(_x, _y)
	{
		x = _x;
		y = _y;
	}
}
```

Top-level keys in a struct delineate schema versions. Versioning is critical for writing robust code that will work as your project develops and changes. Schema versions must start with a lowercase `v` and must be followed by a positive integer from 1 to 255 inclusive.

**N.B. It is very important that you do not ever remove schema versions! If you remove a schema version then any old files that use the old schema version cannot be recovered, which is very likely to break your project.**

Variables defined in a schema can take any of the following datatypes, partially shared with GameMaker's native constants that are used for buffer access.

**N.B. Elephant does no type checking for scalar values in the interests of speed. Please ensure that the value you're serializing matches the datatype in the schema.**

|Value|Name              |Description                                                                                                                                                           |
|-----|------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|1    |`buffer_u8`       |Unsigned 8-bit integer, a positive value from 0 to 255                                                                                                                |
|2    |`buffer_s8`       |Signed 8-bit integer, a positive or negative value from -128 to 127                                                                                                   |
|3    |`buffer_u16`      |Unsigned 16-bit integer, a positive value from 0 - 65535                                                                                                              |
|4    |`buffer_s16`      |Signed 16-bit integer, a positive or negative value from -32,768 to 32,767                                                                                            |
|5    |`buffer_u32`      |Unsigned 32-bit integer, a positive value from 0 to 4,294,967,295                                                                                                     |
|6    |`buffer_s32`      |Signed 32-bit integer, a positive or negative value from -2,147,483,648 to 2,147,483,647                                                                              |
|7    |`buffer_f16`      |16-bit float                                                                                                                                                          |
|8    |`buffer_f32`      |32-bit float                                                                                                                                                          |
|9    |`buffer_f64`      |64-bit float                                                                                                                                                          |
|10   |`buffer_bool`     |Boolean value, can only be 0 or 1                                                                                                                                     |
|11   |`buffer_string`   |String of any size, with a null terminator                                                                                                                            |
|12   |`buffer_u64`      |An unsigned 64-bit integer                                                                                                                                            |
|13   |`buffer_text`     |String of any size, with a null terminator (there is no difference between `buffer_text` and `buffer_string`)                                                         |
|14   |`buffer_any`      |Datatype can be any serializable data. This is the default when serializing content in arrays or structs that have no schema                                          |
|15   |`buffer_array`    |Data is an array. Array elements themselves can be any datatype, though Elephant will optimise arrays with a consistent datatype. Arrays are limited to 65534 elements|
|16   |`buffer_struct`   |Data is a struct, either anonymous or created by a constructor. Structs are limited to 65533 member variables                                                         |
|17   |`buffer_undefined`|Undefined value, using GameMaker's <undefined> datatype. This is equivalent to `null` in JavaScript                                                                   |

&nbsp;

&nbsp;

&nbsp;

# Schema Extensions

Whilst Elephant will default to choosing the latest version number for serialization, the schema version to be used can be forced by setting `ELEPHANT_FORCE_VERSION` in the base `ELEPHANT_SCHEMA` struct e.g.

```GML
function Example() constructor
{
	x = 0;
	y = 0;
	
	ELEPHANT_SCHEMA
	{
		ELEPHANT_FORCE_VERSION : 1, //Force Elephant to use schema v1 rather than v2
		
		v1 : {
			x : buffer_f64,
			y : buffer_f64,
		},
		
		v2 : {
			x : buffer_f32,
			y : buffer_f32,
		},
	}
	
	static SetPosition = function(_x, _y)
	{
		x = _x;
		y = _y;
	}
}
```

One of the main advantages of using schemas is that filesizes can be reduced, and performance increased, by storing variables without contextual information in the outputted binary data (context is instead infered by reading the schema). The trade-off is that once a schema is set up variables name and datatype cannot change.

During the early development phase of your game, it's likely that the filesize and performance advantages of strict schemas are not preferable and you'd instead like to store data more loosely. By setting `ELEPHANT_VERSION_VERBOSE` to `true` in a schema definition, Elephant will instead store variables with all contextual data so that it can be more reliably read upon deserialization.

**N.B.** Setting `ELEPHANT_VERSION_VERBOSE` to `true` will cause `ELEPHANT_SCHEMA_VERSION` to return `0` when deserializing.

```GML
function Example() constructor
{
	x = 0;
	y = 0;
	
	ELEPHANT_SCHEMA
	{
		v1 : {
			ELEPHANT_VERSION_VERBOSE : true, //Store data with 1) its datatype and 2) the variable name
			x : buffer_f64,
			y : buffer_f64,
		},
	}
	
	static SetPosition = function(_x, _y)
	{
		x = _x;
		y = _y;
	}
}
```

For quick development, it's useful to not use schemas at all and instead specify what you *don't* want to save. Defining `ELEPHANT_VERBOSE_EXCLUDE` as an array that contains unwanted variable names (as strings) will instruct Elephant to ignore those names when saving without a schema, or when a schema version is set to verbose (see `ELEPHANT_VERSION_VERBOSE` above).

```GML
function Example() constructor
{
	startHP = 10;
	hp = startHP;
	
	ELEPHANT_SCHEMA
	{
		ELEPHANT_VERBOSE_EXCLUDE : ["startHP"], //Don't serialize the starting HP
	}
	
	static Damage = function(_damage)
	{
		hp -= _damage;
	}
}
```

&nbsp;

&nbsp;

&nbsp;

# Callbacks

Elephant allows for the definition of callback methods per constructor. These are executed as follows:

|Method Macro                |Timing                                     |
|----------------------------|-------------------------------------------|
|`ELEPHANT_PRE_WRITE_METHOD` |Executed immediately before serialization  |
|`ELEPHANT_POST_WRITE_METHOD`|Executed immediately after serialization   |
|`ELEPHANT_PRE_READ_METHOD`  |Executed immediately before deserialization|
|`ELEPHANT_POST_READ_METHOD` |Executed immediately after deserialization |

During the execution of callbacks, two macros can be read: `ELEPHANT_SCHEMA_VERSION` and `ELEPHANT_IS_DESERIALIZING`. `ELEPHANT_SCHEMA_VERSION` contains the schema version that is being used, whereas `ELEPHANT_IS_DESERIALIZING` will be either `true` or `false`. Both variables are set to `undefined` outside of serialization/deserialization.

```GML
function Example() constructor
{
	x = 0;
	y = 0;
	
	//Distance to the centre of the room
	distance = point_distance(x, y, room_width/2, room_height/2);
	
	ELEPHANT_SCHEMA
	{
		v1 : {
			x : buffer_f64,
			y : buffer_f64,
			distance : buffer_f64,
		},
		v2 : {
			x : buffer_f64,
			y : buffer_f64,
		}
	}
	
	ELEPHANT_POST_READ_METHOD
	{
		//After deserializing the struct, update the distance to the centre of the room
		//We only need to run this code for v2 schemas because v1 serializes distance
		if (ELEPHANT_SCHEMA_VERSION == 2)
		{
			distance = point_distance(x, y, room_width/2, room_height/2);
		}
	}
	
	static SetPosition = function(_x, _y)
	{
		x = _x;
		y = _y;
		distance = point_distance(x, y, room_width/2, room_height/2);
	}
}
```

&nbsp;

&nbsp;

&nbsp;

# Binary Format

Elephant uses a custom binary format to encode data, the details of which are described below. There are two key concepts that allow Elephant to handle circular references and constructors.

Elephant serializes/deserializes circular references by associating a unique integer ID with every struct and array that gets created. Structs and arrays share the same "pool" of IDs such that no struct and array can ever share the same ID. IDs start at 0 for the first struct/array that is seen and increases by 1 for each additional struct/array. When a struct or array is deserialized, this unique integer ID can then be used to rebuild circular references.

Constructor indexes work in a similar way. Each constructor is given an ID when it is first seen. If a later struct uses the same constructor then the constructor index can be translated into the correct constructor function without having to repeat the construcor name for every struct.

&nbsp;

### Wrapper

|Datatype    |Name   |Description                                                                                                                                |
|------------|-------|-------------------------------------------------------------------------------------------------------------------------------------------|
|`buffer_u32`|header |`0x454C4550` a.k.a. UTF-8/ASCII string `ELEP`. If this is missing then the data is invalid                                                 |
|`buffer_u32`|version|The version number of Elephant used to create the data. This is calculated by `((majorVersion << 16) + (minorVersion << 8) + patchVersion)`|
|`buffer_any`|content|The root value                                                                                                                             |
|`buffer_u32`|footer |`0x48414E54` a.k.a. UTF-8/ASCII string `HANT`. If this is missing then the data is invalid                                                 |

&nbsp;

### `buffer_any`

|Datatype    |Name    |Description                                                                                                                                     |
|------------|--------|------------------------------------------------------------------------------------------------------------------------------------------------|
|`buffer_u8` |datatype|Indicates the datatype of content to follow. Matches the list of constants laid out above (`buffer_array`, `buffer_u8`, `buffer_string` etc.)   |
|Varies      |content |Content that this datapoint describes. For scalar data, this is the value itself stored using the datatype                                      |

&nbsp;

### Scalar datatype (`buffer_string`, `buffer_f32`, `buffer_u8` etc.):

|Datatype|Name |Description                               |
|--------|-----|------------------------------------------|
|Varies  |value|The value itself stored using the datatype|

&nbsp;

### `buffer_array`

|Datatype    |Name    |Description                                                                                                                                                                     |
|------------|--------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|`buffer_u16`|length  |Number of elements in the array. If this value is 0 then no datatype nor content follows. If the length is 65535 (`0xFFFF)` then special behaviour should be executed, see below|
|`buffer_u8` |datatype|Datatype to use to deserialize following data. This can be any of the constants laid out above, including buffer_any                                                            |
|As above    |value 0 |Value for the 0th element                                                                                                                                                       |
|            |etc.    |                                                                                                                                                                                |

&nbsp;

### `buffer_array` circular reference, length = 65535 (`0xFFFF`)

|Datatype    |Name           |Description                                                                                                                          |
|------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------|
|`buffer_u16`|length         |`0xFFFF`. This indicates that the struct/array has already been seen before and that this struct/array reference should be duplicated|
|`buffer_u16`|reference index|Index of the struct/array to use                                                                                                     |

&nbsp;

### `buffer_struct`

|Datatype       |Name           |Description                                                                                                                                                                                               |
|---------------|---------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|`buffer_u16`   |length         |Number of member variables for this struct. If this value is 0 then no key/value pairs follow. If the length is 65535 or 65534 (`0xFFFF` or `0xFFFE`) then special behaviour should be executed, see below|
|`buffer_string`|variable name 0|Name of the 0th member variable as a null-terminated string                                                                                                                                               |
|`buffer_any`   |value 0        |The value of the 0th member variable                                                                                                                                                                      |
|               |etc.           |                                                                                                                                                                                                          |

&nbsp;

### `buffer_struct` circular reference, length = 65535 (`0xFFFF`)

|Datatype    |Name           |Description                                                                                                                          |
|------------|---------------|-------------------------------------------------------------------------------------------------------------------------------------|
|`buffer_u16`|length         |`0xFFFF`. This indicates that the struct/array has already been seen before and that this struct/array reference should be duplicated|
|`buffer_u16`|reference index|Index of the struct/array to use                                                                                                     |

&nbsp;

### `buffer_struct` constructor with schema,  length = 65534 (`0xFFFE`)

|Datatype         |Name              |Description                                                                                    |
|-----------------|------------------|-----------------------------------------------------------------------------------------------|
|`buffer_u16`     |length            |`0xFFFE`. This indicates that the struct was instantiated using a constructor                  |
|`buffer_u16`     |constructor index |Index of the constructor that was used to create the struct                                    |
|(`buffer_string`)|(constructor name)|(If the constructor index is new then the name of the constructor function follows as a string)|
|`buffer_u8`      |version           |The schema version that was used to serialize the content that follows                         |
|Varies           |value 0           |Value for the 0th member variable, the name and datatype of which is determined by the schema  |
|                 |etc.              |                                                                                               |

&nbsp;

### `buffer_struct` verbose constructor,  length = 65534 (`0xFFFE`)

|Datatype         |Name              |Description                                                                                    |
|-----------------|------------------|-----------------------------------------------------------------------------------------------|
|`buffer_u16`     |length            |`0xFFFE`. This indicates that the struct was instantiated using a constructor                  |
|`buffer_u16`     |constructor index |Index of the constructor that was used to create the struct                                    |
|(`buffer_string`)|(constructor name)|(If the constructor index is new then the name of the constructor function follows as a string)|
|`buffer_u8`      |version           |`0x00`. This indicates that variable data will be enumerated verbosely                         |
|`buffer_string`  |variable name 0   |Name of the 0th member variable as a null-terminated string                                    |
|`buffer_any`     |value 0           |Value for the 0th element                                                                      |
|                 |etc.              |                                                                                               |
