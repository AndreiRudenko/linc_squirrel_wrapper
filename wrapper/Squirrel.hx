package wrapper;

import squirrel.SQ;
import squirrel.SQVM;
import squirrel.SQstd;
import squirrel.SQ_Convert;

class Squirrel {
    public var vm(default, null):HSQUIRRELVM;

    // Creates a new Squirrel vm state
    public function new(){
        create();
    }

    // Close Squirrel vm state
    public function close(){
        _close(vm);
    }

    // Close Squirrel vm state
    public function create(){
        if(vm != null) close();
        vm = _create();
    }
    

    // Get the version string from Squirrel
    public static var version(get, never):Int;
    private inline static function get_version():Int {
        return SQ.getversion();
    }

    // Loads Squirrel libraries (io, math, blob, system, string)
    // @param libs An array of library names to load
    public function loadLibs(?libs:Array<String>):Void {
        if(libs == null) libs = ["io","blob","math","system","string"]; 

        SQ.pushroottable(vm);
        for (l in libs) {
            switch (l) {
                case "io":
                    SQstd.register_iolib(vm);
                case "blob":
                    SQstd.register_bloblib(vm);
                case "math":
                    SQstd.register_mathlib(vm);
                case "system":
                    SQstd.register_systemlib(vm);
                case "string":
                    SQstd.register_stringlib(vm);
            }
        }

        SQ.poptop(vm);
    }


// Variables

    // set global variable
    public function setVar(vname:String, v:Dynamic):Void {
        SQ.pushroottable(vm);               
        SQ.pushstring(vm, vname, -1);       
        SQ_Convert.haxe_value_to_sq(vm, v); 
        SQ.createslot(vm, -3);              
        SQ.poptop(vm);                      
    }

    // get global variable
    public function getVar(vname:String):Dynamic {
        var hv:Dynamic = null;
        SQ.pushroottable(vm);

        SQ.pushstring(vm,vname,-1);
        if(SQ.SUCCEEDED(SQ.get(vm,-2))) { //gets the field 'foo' from the global table
            hv = SQ_Convert.sq_value_to_haxe(vm, -1);
        } else {
            SQ.getlasterror(vm);
            trace("SQ GET VAR ERROR [" + SQ.getstring(vm, -1) + "]");
        }
        SQ.pop(vm, 2); // pop value or error, and root table

        return hv;
    }

    // delete global variable
    public function deleteVar(vname:String):Void {
        SQ.pushroottable(vm);
        SQ.pushstring(vm, vname, -1);
        SQ.deleteslot(vm, -2, false);
        SQ.poptop(vm);
    }


// Class

    // set class
    public function setClass(cname:String, v:Dynamic):Void {
        SQ.pushroottable(vm);                
        SQ.pushstring(vm, cname, -1);         
        SQ.newclass(vm, false);           
        SQ.createslot(vm, -3);                
        SQ.poptop(vm);                 
    }
/*
    // create class instance
    public function setInstance(cname:String, v:Dynamic):Void {
        SQ.pushroottable(vm);                
        SQ.pushstring(vm, cname, -1);  
        if(SQ.SUCCEEDED(SQ.get(vm,-2))) {
            SQ.createinstance( vm, -1 );
            SQ.poptop(vm);                 
        }
        // SQ.newclass(vm, false);           
        // SQ.createslot(vm, -3);                
        SQ.poptop(vm);                 
    }
*/

// Constant variables

    // set constant variable
    public function setConstVar(vname:String, v:Dynamic):Void {
        SQ.pushconsttable(vm);                
        SQ.pushstring(vm, vname, -1);         
        SQ_Convert.haxe_value_to_sq(vm, v);   
        // SQ.rawset(vm, -3);                 
        SQ.createslot(vm, -3);                
        SQ.poptop(vm);                        
    }

    // get constant variable
    public function getConstVar(vname:String):Dynamic {
        var hv:Dynamic = null;
        SQ.pushconsttable(vm);

        SQ.pushstring(vm,vname,-1);
        if(SQ.SUCCEEDED(SQ.get(vm,-2))) { //gets the field 'foo' from the global table
            hv = SQ_Convert.sq_value_to_haxe(vm, -1);
        } else {
            SQ.getlasterror(vm);
            trace("SQ GET CONST VAR ERROR [" + SQ.getstring(vm, -1) + "]");
        }
        SQ.pop(vm, 2); // pop value or error, and root table

        return hv;                 
    }

    // delete const variable
    public function deleteConstVar(vname:String):Void {
        SQ.pushconsttable(vm);
        SQ.pushstring(vm, vname, -1);
        SQ.deleteslot(vm, -2, false);
        SQ.poptop(vm);
    }


// Callback

    // register callback function
    
    // nparams : 
    // 1 = 0 arguments; 0 = any

    // typemask : 
    // The types are expressed as follows: 
    // 'o' null, 'i' integer, 'f' float, 'n' integer or float, 's' string, 
    // 't' table, 'a' array, 'u' userdata, 'c' closure and nativeclosure, 'g' generator, 
    // 'p' userpointer, 'v' thread, 'x' instance(class instance), 'y' class, 'b' bool. and '.' any type. 
    // The symbol '|' can be used as 'or' to accept multiple types on the same parameter.
    // first must be 't' = function
    public function setFunction(fname:String, f:Dynamic, nparams:Int = 0, typemask:String = null):Void {
        SQ.register(vm, fname, f, nparams, typemask);
    }

    // remove callback function
    public function removeFunction(fname:String):Void {
        SQ.unregister(vm, fname);
    }


// Functions

    // Runs a Squirrel script
    // @param script The Squirrel script to run in a string
    // @param retVal if true return script result
    // @return result from the Squirrel script or null
    public function execute(script:String, retVal:Bool = false):Dynamic {
        var hv:Dynamic = null;
        var oldtop:Int = SQ.gettop(vm);

        SQ.compilebuffer(vm, script, script.length, "compile", true); // <- very slow

        SQ.pushroottable(vm);

        if(SQ.FAILED(SQ.call(vm,1,retVal,true))){
            SQ.getlasterror(vm);
            trace("SQ EXECUTE ERROR [" + SQ.getstring(vm, -1) + "]");
        } else if(retVal){
            hv = SQ_Convert.sq_value_to_haxe(vm, -1);
        }

        SQ.settop(vm, oldtop);

        return hv;
    }

    // Calls a previously loaded Squirrel function
    // @param fname The Squirrel function name (globals only)
    // @param args A single argument or array of arguments
    // @param retVal if true return script result
    // @return return the result from the Squirrel script or null
    public function call(fname:String, args:Dynamic = null, retVal:Bool = false):Dynamic { // if retVal == false then 20% faster 

        var hv:Dynamic = null;
        var oldtop:Int = SQ.gettop(vm);

        SQ.pushroottable(vm);
        SQ.pushstring(vm, fname, -1);
        if(SQ.SUCCEEDED(SQ.get(vm, -2))){
            SQ.pushroottable(vm);

            if(args == null){
                if(SQ.FAILED(SQ.call(vm, 1, retVal, true))){
                    SQ.getlasterror(vm);
                    trace("SQ FUNCTION CALL ERROR [" + SQ.getstring(vm, -1) + "]");
                } else if(retVal){
                    hv = SQ_Convert.sq_value_to_haxe(vm, -1);
                }
            } else {
                if(Std.is(args, Array)){
                    var nargs:Int = 1;
                    var arr:Array<Dynamic>;
                    arr = cast args;
                    for (a in arr) {
                        if(SQ_Convert.haxe_value_to_sq(vm, a)){
                            nargs++;
                        }
                    }
                    if(SQ.FAILED(SQ.call(vm, nargs, retVal, true))){
                        SQ.getlasterror(vm);
                        trace("SQ FUNCTION CALL ERROR [" + SQ.getstring(vm, -1) + "]");
                    } else if(retVal){
                        hv = SQ_Convert.sq_value_to_haxe(vm, -1);
                    }
                } else {
                    if(SQ_Convert.haxe_value_to_sq(vm, args)){

                        if(SQ.FAILED(SQ.call(vm, 2, retVal, true))){
                            SQ.getlasterror(vm);
                            trace("\nSQ FUNCTION CALL ERROR [" + SQ.getstring(vm, -1) + "]");
                        } else if(retVal){
                            hv = SQ_Convert.sq_value_to_haxe(vm, -1);
                        }
                    } else {
                        trace('unknown type!');
                    }
                }
            }
        } else {
            SQ.getlasterror(vm);
            trace("SQ FUNCTION CALL ERROR [" + SQ.getstring(vm, -1) + "]");
        }

        SQ.settop(vm, oldtop);
        return hv;
    }

    // Calls a previously loaded Squirrel function from Table
    // @param tname The Squirrel table/class name (globals only)
    // @param fname The Squirrel function name
    // @param args A single argument or array of arguments
    // @param retVal if true return script result
    // @return return the result from the Squirrel script or null
    public function callft(tname:String, fname:String, args:Dynamic = null, retVal:Bool = false):Dynamic { // if retVal == false then 20% faster 
        var hv:Dynamic = null;
        var oldtop:Int = SQ.gettop(vm);

        SQ.pushroottable(vm);
        SQ.pushstring(vm, tname, -1);
        if(SQ.SUCCEEDED(SQ.get(vm, -2))){

            SQ.pushstring(vm, fname, -1);

            if(SQ.SUCCEEDED(SQ.get(vm, -2))){
                SQ.pushroottable(vm);

                if(args == null){
                    if(SQ.FAILED(SQ.call(vm, 1, retVal, true))){
                        SQ.getlasterror(vm);
                        trace("SQ FUNCTION CALL ERROR [" + SQ.getstring(vm, -1) + "]");
                    } else if(retVal){
                        hv = SQ_Convert.sq_value_to_haxe(vm, -1);
                    }
                } else {
                    if(Std.is(args, Array)){
                        var nargs:Int = 1;
                        var arr:Array<Dynamic>;
                        arr = cast args;
                        for (a in arr) {
                            if(SQ_Convert.haxe_value_to_sq(vm, a)){
                                nargs++;
                            }
                        }
                        if(SQ.FAILED(SQ.call(vm, nargs, retVal, true))){
                            SQ.getlasterror(vm);
                            trace("SQ FUNCTION CALL ERROR [" + SQ.getstring(vm, -1) + "]");
                        } else if(retVal){
                            hv = SQ_Convert.sq_value_to_haxe(vm, -1);
                        }
                    } else {
                        if(SQ_Convert.haxe_value_to_sq(vm, args)){

                            if(SQ.FAILED(SQ.call(vm, 2, retVal, true))){
                                SQ.getlasterror(vm);
                                trace("\nSQ FUNCTION CALL ERROR [" + SQ.getstring(vm, -1) + "]");
                            } else if(retVal){
                                hv = SQ_Convert.sq_value_to_haxe(vm, -1);
                            }
                        } else {
                            trace('unknown type!');
                        }
                    }
                }
            } else {
                SQ.getlasterror(vm);
                trace("SQ FUNCTION CALL ERROR [" + SQ.getstring(vm, -1) + "]");
            }

        } else {
            SQ.getlasterror(vm);
            trace("SQ FUNCTION CALL ERROR [" + SQ.getstring(vm, -1) + "]");
        }

        SQ.settop(vm, oldtop);

        return hv;

    }


// File
    
    // Runs a Squirrel file
    // @param path The path of the Squirrel file to run
    public function doFile(path:String):Bool {
        SQ.pushroottable(vm);
        var ret:Bool = SQ.SUCCEEDED(SQstd.dofile(vm, path, false, true));
        if(!ret){
            SQ.getlasterror(vm);
            trace("SQ DOFILE ERROR [" + SQ.getstring(vm, -1) + "]");
            SQ.poptop(vm);
        }
        SQ.poptop(vm);
        return ret;
    }


// Static
    
    // Convienient way to run a Squirrel script in Haxe without loading any libraries
    // @param script The Squirrel script to run in a string
    // @return The result from the Squirrel script in Haxe
    public static function run(script:String, retVal:Bool = false):Dynamic {
        var sq:Squirrel = new Squirrel();
        var ret:Dynamic = sq.execute(script, retVal);
        sq.close();
        return ret;
    }

    // Convienient way to run a Squirrel file in Haxe without loading any libraries
    // @param script The path of the Squirrel file to run
    public static function runFile(path:String):Bool {
        var sq:Squirrel = new Squirrel();
        var ret:Bool = sq.doFile(path);
        sq.close();
        return ret;
    }


// helpers


    function _create():HSQUIRRELVM {
        // trace('create new Squirrel VM');
        var _vm:HSQUIRRELVM = SQ.open(1024);

        SQ.pushroottable(_vm); //push the root table(were the globals of the script will be stored)

        SQstd.seterrorhandlers(_vm); //registers the default error handlers
        SQ.setprintfunc(_vm); //sets the print function
        SQ.init_callbacks(_vm); // initialise callbacks

        SQ.poptop(_vm); //pops the root table
        return _vm;
    }

    function _close(_vm:HSQUIRRELVM){
        if(_vm == null) return;
        // trace('close Squirrel VM');
        SQ.clear_callbacks(_vm); // clear callbacks
        SQ.settop(_vm, 0);
        SQ.close(_vm);  
        _vm = null;
    }


// Debug
    public function stackDump(){
        var top:Int = SQ.gettop(vm);
        trace("---------------- Stack Dump ----------------");
        if(top > 0){
            trace("stack size: " + top);
            while(top > 0){
                // trace( top + " " + SQ_Convert.sq_value_to_haxe(vm, top)); // bug ??? ftw
                var v:Dynamic = SQ_Convert.sq_value_to_haxe(vm, top); 
                trace( top + " " + v);
                top--;
            }
        }
        trace("---------------- Stack Dump Finished ----------------");
    }


    public function printGlobalVars(){
        trace("---------------- Print Root Table ----------------");

        SQ.pushroottable(vm); //push the root table(were the globals of the script will be stored)
        var gv:Int = 0;
        SQ.pushnull(vm);
        while(SQ.SUCCEEDED(SQ.next(vm,-2))) {
            // here -1 is the value and -2 is the key
            trace(Std.string(SQ_Convert.sq_value_to_haxe(vm, -2)) + " = " + print_sq_value_type(-1));

            SQ.pop(vm,2); //pops key and val before the next iteration
            gv++;
        }
        SQ.pop(vm,1); //pops the null iterator

        SQ.poptop(vm); //pops the root table
        trace("GLOBAL VARS: " + gv);
        trace("---------------- Print Root Table Finished ----------------");

    }


    function print_sq_value_type(sv:Int):String {

        var hv:String;

        switch(SQ.gettype(vm, sv)) {
            case OT_NULL: // done
                hv = "null";
            case OT_BOOL:
                hv = "Bool";
            case OT_INTEGER:
                hv = "Int";
            case OT_FLOAT:
                hv = "Float";
            case OT_STRING:
                hv = "String";
            case OT_TABLE:
                hv = "Table";
            case OT_ARRAY:
                hv = "Array";
            case OT_USERDATA:
                hv = "userdata";
            case OT_CLOSURE:
                hv = "closure";
            case OT_NATIVECLOSURE:
                hv = "nativeclosure";
            case OT_GENERATOR:
                hv = "generator";
            case OT_USERPOINTER:
                hv = "userpointer";
            case OT_CLASS:
                hv = "class";
            case OT_INSTANCE:
                hv = "instance";
            case OT_WEAKREF:
                hv = "weak reference";
            default:
                hv = "value not supported";
        }
        return hv;
    }

}
