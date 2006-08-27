//Throbber for Ajax events
Ajax.Responders.register({
	onCreate: function(request) {
		var throbber = $('throbber');
	    throbber.style.display = 'block';
	},
	onComplete: function(request){
		var throbber = $('throbber');
	    throbber.style.display = 'none';
	},
	onFailure: function(request){
		alert('Error contacting server.');
		//add exception notification here 
	}
}
)

Content ={
	//TODO: This is where the toggling of display options should be implemented.
	display_as: function(str){
		alert('display content as: '+str);
	}
}

//Grail is a rails-based notification framework for AJAX events based on Growl.
Grail = {
	to_s    : "Grail",
	skin    : null,
	init    : function(){
		this.skin = Skin.init();
		Grail.register_events();
		//uncomment to test grail
		//Grail.notify(this.skin);
	},
	on_remote_create : function(callback){
	},
	on_remote_complete : function(callback){
		
	},
	on_remote_failure : function(callback){
		
	},
	register_events: function(){
		Ajax.Responders.register(
			{
				onCreate   : Grail.on_remote_create,
				onComplete : Grail.on_remote_complete,
				onFailure  : Grail.on_remote_failure
			}
		);
	},
	notify: function(obj,msg){
		obj.show(msg);
	}
}
/*
	Skin controls the look and feel of the Grail interface
*/
Skin = {
	to_s        : "Skin",
	selected    : 'music_video',
	transitions : [],
	container   : null,
	opts        : {style:{},transitions:{}},
	index       : 0,
	init: function(){
		if(arguments.length < 0 && arguments[0] == null ){this.selected = arguments[0]}
		var items = ['container', 'background', 'icon']
		for(var i in items){
			this[items[i]] = document.createElement("div");
			this[items[i]].className = this.selected+"_"+items[i]
			this[items[i]].id = "grail_"+items[i]
		}
		this.message = document.createElement("p");
		this.container.appendChild(this.background);
		this.container.appendChild(this.icon);
		this.container.appendChild(this.message);
		this.container.style.display = "none";
		this.message.id              = "grail_message"
		this.icon.id                 = "grail_icon";
		this.background.id           = "grail_background";
		this.container.id            = "grail";
		document.body.appendChild(this.container);
		this.render();
		return this;
	},
	render : function(){
		skin = {};
		switch(this.selected){
			case 'music_video' : this.opts = this.music_video();
		}
		//apply inline css
		for(var n in this.opts.style)
		{
			(typeof(this.opts.style[n]) == "number")? this.container.style[n] = this.opts.style[n]+"px" : this.container.style[n] = this.opts.style[n];
		}
		this.background.style.width  = this.opts.style.width+"px"
		this.background.style.height = this.opts.style.height+"px"

		if(this.opts.transitions){
			for(var i in this.opts.transitions){
				this.transitions[i] = this.opts.transitions[i]
			}
		}
	},
	onMotionFinished : function(){
		//callBack by Tween class
		if(this.index >= this.transitions.length){
			this.index = 0;
			this.hide();
		}else{
			this.start_transition(this.transitions[this.index]);
			this.index++;
		}
	},
	show : function(){
		this.container.show();
		this.onMotionFinished();
	},
	start_transition : function(o){
		var pos = Position.cumulativeOffset(this.container);
		t1 = new Tween(this.container.style,o.property,o.tween,pos[1] + o.start,pos[1] + o.end,o.duration,'px');
		t1.addListener(this);
		t1.start();
	},
	hide : function(){this.container.hide()},
	music_video : function(){
		var height = 100;
		var skin = {
			style:{
				height          : height,
				width           : BrowserMetrics.windowDimensions()[0]-20,
				top             : BrowserMetrics.windowDimensions()[1]
				},
			transitions : [
							{property:'top',tween:Tween.easeIn,start:0,end:(height*-1),duration:0.5},
							{property:'top',tween:Tween.easeIn,start:0,end:0,duration:2},
							{property:'top',tween:Tween.easeIn,start:0,end:height,duration:0.5}
						]
		}
		return skin;
	}

}

/*
	From Winton
	http://stu.dicio.us/
*/
BrowserMetrics = {
	putCenter: function(item) {
	  item = $(item);
	  var xy = item.getDimensions();
	  var win = this.windowDimensions();
	  var scrol = this.scrollOffset();
	  item.style.left = (win[0] / 2) + scrol[0] - (xy.width / 2) + "px";
	  item.style.top = (win[1] / 2) + scrol[1] - (xy.height / 2) + "px";
	},
	fullScreen: function(item) {
	  item = $(item);
	  var win = this.windowDimensions();
	  var scrol = this.scrollOffset();
	  item.style.height = scrol[1] + win[1] + "px";
	},
	windowDimensions: function() {
	  var x, y;
	  if (self.innerHeight) {
	    // all except Explorer
	    x = self.innerWidth;
	    y = self.innerHeight;
	  } else if (document.documentElement && document.documentElement.clientHeight) {
	    // Explorer 6 Strict Mode
	    x = document.documentElement.clientWidth;
	    y = document.documentElement.clientHeight;
	  } else if (document.body) {
	    // other Explorers
	    x = document.body.clientWidth;
	    y = document.body.clientHeight;
	  }
	  if (!x) x = 0;
	  if (!y) y = 0;
	  arrayWindowSize = new Array(x,y);
	  return arrayWindowSize;
	},
	scrollOffset: function() {
	  var x, y;
	  if (self.pageYOffset) {
	    // all except Explorer
	    x = self.pageXOffset;
	    y = self.pageYOffset;
	  } else if (document.documentElement && document.documentElement.scrollTop) {
	    // Explorer 6 Strict
	    x = document.documentElement.scrollLeft;
	    y = document.documentElement.scrollTop;
	  } else if (document.body) {
	    // all other Explorers
	    x = document.body.scrollLeft;
	    y = document.body.scrollTop;
	  }
	  if (!x) x = 0;
	  if (!y) y = 0;
	  arrayScrollOffset = new Array(x,y);
	  return arrayScrollOffset;
	}
	
}

/*
	From Winton
	http://stu.dicio.us/
*/
var Loader = {
  loaded: false,
  addOnLoad: function(fn) {
    if (this.loaded) fn();
    else {
      var oldonload = (window.onload) ? window.onload : function () {};
      window.onload = function () { oldonload(); fn(); };
    }
  },
  init: function() {
    this.loaded = true;
  }
};
Loader.addOnLoad(Loader.init);
Loader.addOnLoad(Grail.init);
