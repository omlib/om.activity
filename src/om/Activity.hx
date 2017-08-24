package om;

import js.Promise;
import js.html.Element;
import js.html.DivElement;
import js.Browser.console;
import js.Browser.document;
import om.DOM.*;

using om.DOM;
using StringTools;

@:enum abstract State(String) to String {
    var create = "create";
    var start = "start";
    var stop = "stop";
    var destroy = "destroy";
}

/*
interface IActivity {

    var id(default,null) : String;
    var element(default,null) : Element;
    var state(default,null) : State;

    private var parent : IActivity;

    private function push<A:IActivity,T>( activity : A ) : Promise<T>;
    private function pop<A:IActivity>() : Promise<A>;
    //private function replace<A:IActivity,T>( activity : A, ?data : T ) : Promise<A>;
    private function replace<A:IActivity>( activity : A ) : Promise<A>;
    //private function back<A:IActivity>( activity : A ) : Promise<A>;
    //private function forward<A:IActivity>( activity : A ) : Promise<A>;
    //private function finish() : Void;

    private function setState( state : State ) : Void;

    private function onCreate<A:IActivity,T>() : Promise<T>;
    private function onStart<A:IActivity,T>() : Promise<T>;
    private function onStop<A:IActivity,T>() : Promise<T>;
    private function onDestroy<A:IActivity,T>() : Promise<T>;
}
*/

class Root {

    public var element(default,null) : Element;
    public var activity(default,null) : Activity;

    public function new( ?element : Element ) {
        if( element == null ) element = document.body;
        this.element = element;
    }

    @:access(om.Activity)
    //public function init<A:Activity,T>( activity : A ) : Promise<T> {
    public function init<A:Activity>( activity : A ) : Promise<A> {

        if( element == null ) element = document.body;

        activity.element.classList.add( Activity.CLASS_CREATE );
        element.append( activity.element );
        return cast activity.onCreate().then( a->{
            this.activity = activity;
            activity.element.swapClasses( Activity.CLASS_CREATE, Activity.CLASS_START );
            return activity.onStart();
        });
    }

    @:access(om.Activity)
    public function dispose<T>() : Promise<T> {
        return if( activity == null )
            cast Promise.reject( 'no activity' );
            else cast activity.onStop().then( cast activity.onDestroy );
    }
}

/**
    A single, focused thing the user can do.
**/
#if !macro
@:autoBuild(om.macro.BuildActivity.complete())
#end
//class Activity implements Activity {
class Activity {

    public static inline var CLASSNAME_POSTFIX = 'Activity';

    public static inline var CLASS_CREATE = 'create';
    public static inline var CLASS_RESTART = 'restart';
    public static inline var CLASS_START = 'start';
    public static inline var CLASS_RESUME = 'resume';
    public static inline var CLASS_PAUSE = 'pause';
    public static inline var CLASS_STOP = 'stop';
    public static inline var CLASS_DESTROY = 'destroy';

    /*
    public static function init<A:Activity>( activity : A, ?element : Element ) : Promise<A> {

        if( element == null ) element = document.body;

        activity.element.classList.add( Activity.CLASS_CREATE );
        element.append( activity.element );

        return cast activity.onCreate().then( function(a){
            activity.element.swapClasses( Activity.CLASS_CREATE, Activity.CLASS_START );
            return activity.onStart();
        });
        /*
        return activity.onCreate().then( function(a){

            activity.element.swapClasses( Activity.CLASS_CREATE, Activity.CLASS_START );

            return activity.onStart().then( function(a){
                trace( ">>>>>>>>" );
                return activity.onResume().then( function(a){
                });

            });
        });
    }
    */

    public var id(default,null) : String;
    public var element(default,null) : Element;
    public var state(default,null) : State;

    var parent : Activity;

    public function new( ?id : String ) {
        if( id == null ) {
            var clName = Type.getClassName( Type.getClass( this ) );
            var i = clName.lastIndexOf( '.' );
            if( i != -1 ) clName = clName.substring( i+1 );
			if( clName.endsWith( CLASSNAME_POSTFIX ) ) {
                clName = clName.substring( 0, clName.length - CLASSNAME_POSTFIX.length );
            } else {
                //#if debug
                throw 'invalid class name';
                //#end
            }
            id = clName.toLowerCase();
        } else {
            //TODO validate id conformity
        }
        this.id = id;
        element = createRootElement();
    }

    function setState( state : State ) {
        if( this.state != null ) element.classList.remove( this.state );
        element.classList.add( this.state = state );
    }

    function push<A:Activity,T>( activity : A ) : Promise<T> {

        activity.parent = this;
        activity.setState( create );
        element.parentElement.append( activity.element );

        return cast activity.onCreate().then( function(a){

            activity.setState( start );
            setState( stop );

            return Promise.all([
                activity.onStart(),
                onStop()
                //onStop().then( a->element.remove() )
            ]);
            /*
            return activity.onStart().then( function(a){
                return onStop().then( function(a){
                    element.remove();
                });
            });
            */
        });
    }

    function replace<A:Activity>( activity : A ) : Promise<A> {

        activity.parent = parent;
        activity.setState( create );
        element.parentElement.append( activity.element );

        return cast activity.onCreate().then( function(a){

            activity.setState( start );
            setState( stop );

            return Promise.all([
                activity.onStart(),
                onStop().then( function(a){
                    element.remove();
                    return onDestroy().then( function(a){
                        return Promise.resolve( cast activity );
                    });
                })
            ]);

            /*
            return activity.onStart().then( function(a){

                setState( stop );
                //activity.element.swapClasses( CLASS_START, CLASS_RESUME );
                //activity.onResume( function(_){});

                return onStop().then( function(a){
                    element.remove();
                    return onDestroy().then( function(a){
                        return Promise.resolve( cast activity );
                    });
                });
            });
            */

            /*
            return onStop().then( function(a){

                //element.swapClasses( CLASS_STOP, CLASS_DESTROY );
                element.remove();
                onDestroy();

                return activity.onStart().then( function(a){
                    //activity.element.swapClasses( CLASS_START, CLASS_RESUME );
                    //activity.onResume( function(_){});
                    //return Promise.resolve( activity );
                });
            });
            */
        });
    }

    function pop<A:Activity>() : Promise<A> {

        if( parent == null )
            return Promise.reject( 'no parent' );

        parent.state = start;
        parent.element.swapClasses( CLASS_STOP, CLASS_START );
        element.parentElement.append( parent.element );

        element.swapClasses( CLASS_START, CLASS_STOP );
        state = stop;

        return cast Promise.all([
            parent.onStart(),
            onStop().then( function(a){
                element.swapClasses( CLASS_STOP, CLASS_DESTROY );
                element.remove();
                onDestroy();
            })
        ]).then( function(e){
            trace(e);
        });

        /*
        return cast parent.onStart().then( function(a){
            return onStop().then( function(a){
                element.swapClasses( CLASS_STOP, CLASS_DESTROY );
                element.remove();
                onDestroy();
            });
        });
        */
    }


    /*
    public function push<A:Activity>( activity : A ) : Promise<A> {
        return cast _changeCurrent( activity, this );
    }

    public function replace<A:Activity,T>( activity : A, ?data : T ) : Promise<A> {
        return cast _changeCurrent( activity, parent, data ).then( function(_){
            return onDestroy();
            //return onDestroy().then( function(_){
                //return Promise.resolve( activity );
            //});
        });
    }

    function _changeCurrent<A:Activity,T>( next : A, ?parent : Activity, ?data : T ) : Promise<A> {

        next.parent = parent;
        next.element.classList.add( CLASS_CREATE );
        element.parentElement.appendChild( next.element );

        element.classList.remove( CLASS_START );
        element.classList.add( CLASS_STOP );

        return next.onCreate().then( function(a){

            next.element.classList.remove( CLASS_CREATE );
            next.element.classList.add( CLASS_START );

            /*
            return cast Promise.all( [
                next.onStart(),
                onStop().then( function(a){
                    element.classList.remove( CLASS_STOP );
                    element.remove();
                }),
            ] );
            * /

            next.onStart();
            onStop().then( function(a){
                element.classList.remove( CLASS_STOP );
                element.remove();
            });

            return Promise.resolve( next );
        });
    }

    function pop<A:Activity>() : Promise<A> {

        if( parent == null )
            return Promise.reject( 'no parent' );

        parent.element.classList.add( CLASS_START );
        element.parentElement.appendChild( parent.element );

        element.classList.add( CLASS_STOP );

        return cast Promise.all( [
            parent.onStart(),
            onStop().then( function(a){
                element.classList.remove( CLASS_STOP );
                element.remove();
                return onDestroy();
            }),
        ] );
    }
    */

    /*
    function finish() {
        //TODO
    }
    */

    //function onCreate<A:Activity,T>( ?data : T ) : Promise<A> {
    function onCreate<A:Activity,T>() : Promise<T> {
        //return Promise.resolve(  this );
        return null;
    }

    function onStart<A:Activity,T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onRestart<A:Activity,T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onResume<A:Activity,T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onPause<A:Activity,T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onStop<A:Activity,T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onDestroy<A:Activity,T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    //function onActivityResult<A:Activity>( activity : T ) {

    function createRootElement<T:Element>( cl = 'activity' ) : T {
        var e = div();
        if( cl != null ) e.classList.add( cl );
        e.id = id;
        return cast e;
    }
}
