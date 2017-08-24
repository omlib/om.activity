package om.macro;

import haxe.macro.Context;
import haxe.macro.Expr;

class BuildActivity {

    static function complete() : Array<Field> {

        var fields = Context.getBuildFields();
        var pos = Context.currentPos();

        for( field in fields ) {
            switch field.kind {
            case FFun(fun):

                switch field.name {

                case 'onCreate','onRestart','onStart','onresume','onPause','onStop','onDestroy':

                    if( fun.params.length == 0 ) {
                        //fun.params.push( { name: 'A', constraints:[TPath({name:'IActivity',pack:['om']})] } );
                        //fun.params.push( { name: 'T' } );
                        //fun.params.push( { name: 'A' } );
                    }

                    // Add ?state argument if missing
                    /*
                    if( fun.args.length == 0 ) {
                        fun.args.push({
                            name: '_',
                            opt: true,
                            //type: TPath( { name: 'Dynamic', pack:[] } )
                            type: TPath( { name: '', pack: [] } )
                        });
                    }
                    */

                    // Add return if missing
                    var hasReturn = false;
                    switch fun.expr.expr {
                    case EBlock(exprs):
                        var last = exprs[exprs.length-1];
                        switch last.expr {
                        case EReturn(ret):
                            hasReturn = true;
                            break;
                            /*
                            switch ret.expr {
                            case ECast(e,t):
                                switch e.expr {
                                case ECall(e,params):
                                    switch e.expr {
                                    case EField(e,dield):
                                        trace( e );
                                        trace( field );
                                    case _:
                                    }
                                case _:
                                }
                            case _:
                            }
                            */
                        case _:
                        }
                        if( !hasReturn ) {
                            //var fieldName = field.name;
                            //exprs.push( macro return cast super.$fieldName() );
                            exprs.push( macro return Promise.resolve( cast this ) );
                        }
                    case _:
                    }
                }
            case _:
            }
        }

        return fields;
    }
}
