package om;

import js.Browser.document;
import js.Browser.window;
import js.html.DivElement;
import js.html.Element;

using StringTools;

/**
    A single, focused thing the user can do.
**/
@:require(js)
class Activity {

    public static inline var POSTFIX = 'Activity';

    public static function boot( activity : Activity, ?container : Element ) {

        if( container == null ) container = document.body;
        container.appendChild( activity.element );

        activity.onCreate();
        activity.onStart();
    }

    public var id(default,null) : String;
    public var element(default,null) : DivElement;

    var parent : Activity;

    public function new( ?id : String ) {

        if( id == null ) {
            var className = Type.getClassName( Type.getClass( this ) );
            var i = className.lastIndexOf( '.' );
            if( i != -1 ) className = className.substring( i+1 );
			if( className.endsWith( POSTFIX ) ) {
                className = className.substring( 0, className.length - POSTFIX.length );
            } else {
                #if debug
                throw 'Activity class name should end with "Activity"';
                #end
            }
            //TODO
            // MediaSet -> media_set
            // UIElement -> ui_element
            // Any_ ->
            //var expr = ~/([A-Z])/;
            //className = expr.replace( className, '#');
            id = className.toLowerCase();
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
        activity.element.classList.add( 'onCreate' );
        element.parentElement.appendChild( activity.element );

        activity.onCreate();

        element.classList.remove( 'onStart' );
        element.classList.add( 'onStop' );
        onStop();
        element.remove();

        activity.element.classList.remove( 'onCreate' );
        activity.element.classList.add( 'onStart' );
        activity.onStart();
    }

    public function replace( activity : Activity ) {

        activity.parent = parent;
        activity.element.classList.add( 'onCreate' );
        element.parentElement.appendChild( activity.element );

        activity.onCreate();

        element.classList.remove( 'onStart' );
        element.classList.add( 'onStop' );
        onStop();
        element.remove();

        activity.element.classList.remove( 'onCreate' );
        activity.element.classList.add( 'onStart' );
        activity.onStart();

        onDestroy();
    }

    public function pop() {

        if( parent != null ) {

            parent.parent = parent;
            parent.element.classList.remove( 'onStop' );
            parent.element.classList.add( 'onCreate' );
            element.parentElement.appendChild( parent.element );

            parent.element.classList.remove( 'onCreate' );
            parent.element.classList.add( 'onStart' );
            parent.onStart();

            element.classList.remove( 'onStart' );
            element.classList.add( 'onStop' );
            onStop();
            element.remove();

            onDestroy();
        }
    }

    function onCreate() {
        //trace( '$id.onCreate' );
    }

    function onStart() {
        //trace( '$id.onStart' );
    }

    function onResume() {
        //trace( '$id.onResume' );
    }

    function onPause() {
        //trace( '$id.onPause' );
    }

    function onStop() {
        //trace( '$id.onStop' );
        //element.remove();
    }

    function onRestart() {
        //trace( '$id.onRestart' );
    }

    function onDestroy() {
        //trace( '$id.onDestroy' );
    }

}
