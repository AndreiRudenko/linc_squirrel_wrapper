import wrapper.Squirrel;

class Test {

    static function main() {

        var sq:Squirrel = new Squirrel();
        sq.loadLibs(); // load all libs ["io","blob","math","system","string"]

        sq.setVar("myFloatVar", 1.618 );
        trace(sq.getVar("myFloatVar"));

        sq.deleteVar("myFloatVar"); // delete variable

        sq.execute("return 146", true); // if true return script result

        sq.execute("function test(a, b){ return a + b }");
        trace(sq.call('test', [236.067, 381.966], true)); // if true return function result

        sq.doFile("script.nut"); // load and run script
        sq.call('foo', [1, 2.0, "three"], true);

        // callbacks
        sq.setFunction(
            "callBack", 
            function (a:String) { 
                trace(a);
                return 123;
            },
            0, // arguments number: 0 = any, 1 = 0 args, 2 = 1 arg; 
            "" // typemask, look into wrapper.Squirrel.hx
        );

        trace(sq.call('callBack', "haxe callback !!!", true));

        sq.close();

    }

}