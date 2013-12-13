package webviewex;
	
class WebView  {

	private static var APIInit:Dynamic=null;
	private static var APISetCallback:Dynamic=null;
	private static var APINavigate:Dynamic=null;
	private static var APIDestroy:Dynamic=null;
	#if android
	public static var APILastURL(default,null):Void->String=null;
	public static var APIIsDisplaying(default,null):Void->Bool=null;
	#end
	private static var listener:WebViewListener;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public static var onClose:Void->Void=null;
	public static var onURLChanging:String->Void=null;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	public static function open(url:String=null, withPopup:Bool = false):Void {
		if (listener == null) {
			listener = new WebViewListener();
			//Disable this on Android since AdMob Extension conflicts and I don't know why
			//APICall("callback", [listener]);
		}
		APICall("init", [listener, withPopup]);
		navigate(url);
		#if android
		listener.poolingMode();
		#end
	}
	
	public static function navigate(url:String):Void {
		if (url==null) return;
		if (listener != null) APICall("navigate", [url]);
	}
	
	public static function close():Void {
		if (listener != null) APICall("destroy");
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	private static function init():Void {
		if(APIInit != null) return;
		try{
			#if android
			APIDestroy  = openfl.utils.JNI.createStaticMethod("webviewex/WebViewEx", "APIDestroy", "()V");
			APIInit     = openfl.utils.JNI.createStaticMethod("webviewex/WebViewEx", "APIInit", "(Z)V");
			APISetCallback = openfl.utils.JNI.createStaticMethod("webviewex/WebViewEx", "APISetCallback", "(Lorg/haxe/nme/HaxeObject;)V");
			APILastURL  = openfl.utils.JNI.createStaticMethod("webviewex/WebViewEx", "APILastURL", "()Ljava/lang/String;");
			APINavigate = openfl.utils.JNI.createStaticMethod("webviewex/WebViewEx", "APINavigate", "(Ljava/lang/String;)V");
			APIIsDisplaying = openfl.utils.JNI.createStaticMethod("webviewex/WebViewEx", "APIIsDisplaying", "()Z");
			#elseif ios
            APIInit     = cpp.Lib.load("webviewex","webviewAPIInit", 3);
			APINavigate = cpp.Lib.load("webviewex","webviewAPINavigate", 1);
			APIDestroy  = cpp.Lib.load("webviewex","webviewAPIDestroy", 0);
			#end
		}catch(e:Dynamic){
			trace("INIT Exception: "+e);
		}
	}
	
	private static function APICall(method:String, args:Array<Dynamic> = null):Void	{
		init();
		try{
			#if android
            if (method == "init") APIInit(args[1] == true);
            if (method == "callback") APISetCallback(args[0]);
            if (method == "navigate") APINavigate(args[0]);
            if (method == "destroy") APIDestroy();
			#elseif iphone
			if (method == "init") APIInit(args[0].onClose, args[0].onURLChanging, args[1]);
            if (method == "navigate") APINavigate(args[0]);
            if (method == "destroy") APIDestroy();
			#end
		}catch(e:Dynamic){
			trace("APICall Exception: "+e);
		}
	}
	
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class WebViewListener {

	public function new() {
		#if android
		showing=false;
		#end
	}
	
	public function onClose():Void {
		if(WebView.onClose!=null) WebView.onClose();
	}
	
	public function onURLChanging(url:Dynamic):Void {
		if(WebView.onURLChanging!=null) WebView.onURLChanging(url);
	}

	#if android
	public var showing:Bool;
	private var lastUrl:String; 
	public var opening:Bool;

	public function poolingMode(){
		if(showing) return;
		showing=true;
		opening=true;
		lastUrl=null;
		doPooling();
	}

	private function doPooling(){
		if(opening){
			opening=!WebView.APIIsDisplaying();
			haxe.Timer.delay(doPooling,100);
			return;
		}

		/*var url=WebView.APILastURL();
		if(url!=lastUrl && lastUrl!=null){
			onURLChanging(url);
		}
		lastUrl=url;*/

		if(!WebView.APIIsDisplaying()){
			onClose();
			showing=false;
		}else{
			haxe.Timer.delay(doPooling,100);
		}
	}
	#end
}
