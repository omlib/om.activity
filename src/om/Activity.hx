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
    var restart = "restart";
    var start = "start";
    var resume = "resume";
    var pause = "pause";
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
        this.element = (element == null) ? document.body : element;
    }

    @:access(om.Activity)
    public function init<A:Activity>( activity : A ) : Promise<A> {

        if( element == null ) element = document.body;

        activity.element.classList.add( create );
        element.append( activity.element );

        return cast activity.onCreate().then( a->{
            this.activity = activity;
            activity.root = this;
            activity.element.swapClasses( create, start );
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

    public var id(default,null) : String;
    public var state(default,null) : State;
    public var element(default,null) : Element;

    var root : Root;
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

    function push<A:Activity>( activity : A ) : Promise<A> {

        activity.setState( create );

        return cast activity.onCreate().then( function(a){

            activity.parent = this;
            activity.setState( start );
            element.parentElement.append( activity.element );

            setState( stop );
            onStop().then( function(a){
            });

            return activity.onStart().then( function(a){
                //root.activity = activity;
            });
        });
    }

    function replace<A:Activity>( activity : A ) : Promise<A> {

        activity.parent = parent;
        activity.setState( create );
        element.parentElement.append( activity.element );

        return cast activity.onCreate().then( function(a){

            setState( stop );
            onStop().then( function(a){
                element.remove();
                return onDestroy();
            });

            activity.setState( start );
            //root.activity = activity;

            return activity.onStart();
        });
    }

    function pop<A:Activity>() : Promise<A> {

        if( parent == null )
            return Promise.reject( 'no parent' );

        parent.setState( start );
        element.parentElement.append( parent.element );

        setState( stop );
        onStop().then( function(a){
            element.remove();
            setState( destroy );
            onDestroy();
        });

        return parent.onStart();
    }

    /*
    function startForResult<A:Activity>( activity : A ) : Promise<A> {
    }

    function finish() {
    }
    */

    function setState( state : State ) {
        if( this.state != null ) element.classList.remove( this.state );
        element.classList.add( this.state = state );
    }

    function onCreate<T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onStart<T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onRestart<T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onResume<T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onPause<T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onStop<T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    function onDestroy<T>() : Promise<T> {
        return Promise.resolve( cast this );
    }

    /*
    function onActivityResult<T>( result : T ) {
    }
    */

    function createRootElement<T:Element>( _class = 'activity' ) : T {
        var e = div();
        if( _class != null ) e.classList.add( _class );
        e.id = id;
        return cast e;
    }
}
