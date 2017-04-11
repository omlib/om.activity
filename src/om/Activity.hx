package om;

import js.Browser.document;
import js.Browser.window;
import js.html.DivElement;
import js.html.Element;

using StringTools;

/**
    A single, focused thing the user can do.
*/
@:require(js)
class Activity {

    static inline var NAME_POSTFIX = 'Activity';

    public var id(default,null) : String;
    public var element(default,null) : DivElement;

    var parent : Activity;

    public function new( ?id : String ) {

        if( id == null ) {
            var cname = Type.getClassName( Type.getClass( this ) );
            var i = cname.lastIndexOf( '.' );
            if( i != -1 ) cname = cname.substring( i+1 );
			if( cname.endsWith( NAME_POSTFIX ) ) {
                cname = cname.substring( 0, cname.length - NAME_POSTFIX.length );
            } else {
                #if debug
                trace( 'Activity class name should end with "Activity"' );
                #end
            }
            //TODO
            // MediaSet -> media_set
            // UIElement -> ui_element
            // Any_ ->
            //var expr = ~/([A-Z])/;
            //cname = expr.replace( cname, '#');
            id = cname.toLowerCase();
        } else {
            //TODO validate id conformity
        }

        this.id = id;

        element = document.createDivElement();
        element.classList.add( 'activity' );
        element.id = id;
    }

    public function push( activity : Activity ) {

        activity.parent = this;
        element.parentElement.appendChild( activity.element );

        activity.onCreate();

        onStop();

        activity.onStart();
    }

    public function replace( activity : Activity ) {

        element.parentElement.appendChild( activity.element );

        activity.onCreate();
        activity.onStart();

        onStop();
        onDestroy();
    }

    public function pop() {

        if( parent != null ) {

            element.parentElement.appendChild( parent.element );
            parent.onStart();

            onStop();
            onDestroy();
        }
    }

    function onCreate() {
        //trace( '$id.onCreate' );
    }

    function onStart() {
        //trace( '$id.onStart' );
        //element.parentElement.appendChild( activity.element );
    }

    function onResume() {
        //trace( '$id.onResume' );
    }

    function onPause() {
        //trace( '$id.onPause' );
    }

    function onStop() {
        //trace( '$id.onStop' );
        element.remove();
    }

    function onRestart() {
        //trace( '$id.onRestart' );
    }

    function onDestroy() {
        //trace( '$id.onDestroy' );
    }

    public static function boot( activity : Activity, ?parentElement : Element ) {

        if( parentElement == null ) parentElement = document.body;
        parentElement.appendChild( activity.element );

        activity.onCreate();
        activity.onStart();
    }

    /*
    function push( activity : Activity ) {

        //activity.container = container;
        activity.onCreate();
        activity.onStart();

        onStop();

        stack.push( activity );

        onDestroy();
    }

    function replace( activity : Activity ) {

        //activity.container = container;
        activity.onCreate();
        activity.onStart();

        onStop();

        stack.pop();
        stack.push( activity );

        onDestroy();
    }

    function pop() {

        if( stack.length >= 2 ) {

            stack.pop();

            var prev = stack[stack.length-1];
            prev.onStart();

            onStop();
            stack.push( prev );

            onDestroy();
            //replace( prev );
        }
    }

    function onCreate() {
        trace( '$id.onCreate' );
    }

    function onStart() {

        trace( '$id.onStart' );

        parentElement.appendChild( element );

        //window.addEventListener( 'popstate', handlePopState, false );

        //window.history.replaceState( null, Type.getClassName( Type.getClass( this ) ), null );
        //window.history.pushState( null, "DDDD", id );
    }

    function onStop() {

        trace( '$id.onStop' );

        parentElement.removeChild( element );

        //window.removeEventListener( 'popstate', handlePopState );
    }

    function onDestroy() {
        trace( '$id.onDestroy' );
    }

    function handlePopState(e) {
        trace(e);
        e.preventDefault();
        e.stopPropagation();
    }

    /*
    static var parentElement : Element;
    static var stack : Array<Activity>;

    public static function start( activity : Activity, ?parentElement : Element ) {

        if( parentElement == null ) parentElement = document.body;
        Activity.parentElement = parentElement;
        Activity.parentElement.appendChild( activity.element );

        stack = [];

        activity.onCreate();
        activity.onStart();
    }
    */
}
