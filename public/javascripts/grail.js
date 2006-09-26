//Grail is a rails-based notification framework for AJAX events based on Growl.
var Grail = Class.create();
Grail.prototype = {
	initialize: function(){
		this.to_s = "Grail"
		this.skin = new GrailSkin()
		this.register_events();
		//uncomment to test grail
		this.notify({type:this.skin, subject:'Alert', body:'Something awesome just happened.'});
	}
}
//Register Grail to listen for AJAX Callback events
Grail.prototype.register_events = function(){
	Ajax.Responders.register(
		{
			onCreate   : this.on_remote_create,
			onComplete : this.on_remote_complete,
			onFailure  : this.on_remote_failure
		}
	);
}
Grail.prototype.on_remote_create = function(callback){

}
Grail.prototype.on_remote_complete = function(callback){

}
Grail.prototype.on_remote_failure = function(callback){

}

//Call this method to render a Grail notification event to the interface
Grail.prototype.notify = function(msg){
	this.skin.show(msg.subject, msg.body)
}

//The Message is the container, which Grail uses to render text and image to the interface.
var GrailMessage = Class.create();
GrailMessage.prototype = {
	initialize: function(){
		this.to_s  = "GrailMessage"
		this.type  = null
		this.subject = null
		this.body  = null
	}
}

var GrailSkin = Class.create();
GrailSkin.prototype = {
	initialize: function(){
		this.to_s        = "GrailSkin"
		this.selected    = 'music_video'
		this.transitions = []
		this.container   = null
		this.opts        = {style:{},transitions:{}}
		this.index       = 0
		this.current_message = new GrailMessage();
		if(arguments.length > 0 && arguments[0] != null ){this.selected = arguments[0]}
		
		var items = [['container','div'], ['background','div'],['icon','div'],['message','dl'],['body','dd'],['subject','dt']]
		for(var i in items){
			this[items[i][0]] = document.createElement(items[i][1]);
			this[items[i][0]].className = this.selected+"_"+items[i][0]
			this[items[i][0]].id = "grail_"+items[i][0]
		}
		
		this.container.appendChild(this.background);
		this.container.appendChild(this.icon);
		this.container.appendChild(this.message);
		this.message.appendChild(this.subject);
		this.message.appendChild(this.body);
		document.body.appendChild(this.container);
		this.render();
	}
}

GrailSkin.prototype.render = function(){
	skin = {};
	switch(this.selected){
		case 'music_video' : this.opts = this.music_video();
	}
	//apply inline css
	for(var n in this.opts.style){
		(typeof(this.opts.style[n]) == "number")? this.container.style[n] = this.opts.style[n]+"px" : this.container.style[n] = this.opts.style[n];
	}
	this.background.style.width  = this.opts.style.width+"px"
	this.background.style.height = this.opts.style.height+"px"
	if(this.opts.transitions){
		for(var i in this.opts.transitions){
			this.transitions[i] = this.opts.transitions[i]
		}
	}	
}

GrailSkin.prototype.onMotionFinished = function(){
	//callBack by Tween class
	if(this.index >= this.transitions.length){
		this.index = 0;
		this.hide();
	}else{
		this.start_transition(this.transitions[this.index]);
		this.index++;
	}
}

GrailSkin.prototype.show = function(subject,body){
	//TODO instead of setting subject and body they should be put into a queue for delivery
	if(!subject){subject = ""}
	this.current_message.subject = subject
	this.current_message.body = body
	this.subject.innerHTML = subject
	this.body.innerHTML    =  body
	
	this.container.show();
	this.onMotionFinished();
}

GrailSkin.prototype.start_transition = function(o){
	var pos = Position.cumulativeOffset(this.container);
	t1 = new Tween(this.container.style,o.property,o.tween,pos[1] + o.start,pos[1] + o.end,o.duration,'px');
	t1.addListener(this);
	t1.start();
}

GrailSkin.prototype.hide = function(){
	this.container.hide()
}

GrailSkin.prototype.music_video = function(){
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

/*
Grail = {
	to_s    : "Grail",
	skin    : null,
	init    : function(){
		this.skin = Skin.init();
		Grail.register_events();
		//uncomment to test grail
		Grail.notify({type:this.skin});
	},
	on_remote_create : function(callback){
		//TODO
	},
	on_remote_complete : function(callback){
		//TODO		
	},
	on_remote_failure : function(callback){
		//TODO
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
	notify: function(msg){
		obj = this.skin
		this.skin.show(msg.title,msg.body);
	}
}
*/
/*
	Skin controls the look and feel of the Grail interface
*/
/*
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
		this.message = document.createElement("dl");
		this.title   = document.createElement("dt");
		this.body    = document.createElement("dd");
		this.container.appendChild(this.background);
		this.container.appendChild(this.icon);
		this.container.appendChild(this.message);
		this.message.appendChild(this.title);
		this.message.appendChild(this.body);
		this.container.style.display = "none";
		this.message.id              = "grail_message"
		this.title.id                = "grail_title"
		this.body.id                 = "grail_body"
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
*/

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
Loader.addOnLoad( function(){grail = new Grail(); });