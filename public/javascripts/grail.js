//Grail is a rails-based notification framework for AJAX events based on Growl.
var Grail = Class.create();
Grail.prototype = {
  initialize: function(){
    this.to_s = "Grail"
    this.skin = null;
    this.register_events();
    //uncomment to test grail
    //this.notify({skin:this.skin, type:'confirm', subject:'Alert', body:'Something awesome just happened.'});
  }
}
//Register Grail to listen for AJAX Callback events
Grail.prototype.register_events = function(){
  level = this
  Ajax.Responders.register(
    {
      onCreate   : function(){level['on_remote_create']()},
      onComplete : function(){level['on_remote_complete']()},
      onFailure  : function(){level['on_remote_failure']()}
    }
  );
}
Grail.prototype.on_remote_create = function(callback){
  //this.notify({subject:'Contacting Server',body:'Please wait...'})
}
Grail.prototype.on_remote_complete = function(callback){
  //this.hide()
}
Grail.prototype.on_remote_failure = function(callback){
  //this.notify({subject:'Server Error',body:'There was a network error.'})
}

//Call this method to render a Grail notification event to the interface
Grail.prototype.notify = function(msg){
  //this.skin.show(msg.subject, msg.body)
  //msg.type = "music_video"
  if(msg.skin){
    this.skin = new GrailSkin(msg.skin)
  }else{
    this.skin = new GrailSkin()
  }
  //this.skin = new GrailSkin()
  this.skin.show({subject:msg.subject, body:msg.body,type:msg.type})
}

Grail.prototype.hide = function(){
  //alert(this.to_s)
  //TODO clear these out.
}

//The Message is the container, which Grail uses to render text and image to the interface.
var GrailMessage = Class.create();
GrailMessage.prototype = {
  initialize: function(){
    this.to_s = "GrailMessage"
    this.body = null
    this.type = null
    this.subject = null
  }
}


var GrailSkin = Class.create();
GrailSkin.prototype = {
  initialize: function(){
    this.to_s        = "GrailSkin"
    this.selected    = 'music_video'
    this.type        = {}
    this.transitions = []
    this.id          = new Date().getTime();
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
    case 'music_video' : 
      this.opts = this.music_video();
      break;
    default:
      alert('style not found');
      this.opts = this.music_video();
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
    Element.remove($(this.container))
  }else{
    this.advance_frame();
  }
}


GrailSkin.prototype.advance_frame = function(){
  this.start_transition(this.type.transitions[this.index]);
  this.index++;
}


GrailSkin.prototype.show = function(msg){
  //TODO instead of setting subject and body they should be put into a queue for delivery
  if(!msg.subject){msg.subject = ""}
  if(!msg.type){msg.type = 'alert'}
  this.type = this.opts.types[msg.type]
  this.current_message.subject = msg.subject
  this.current_message.body = msg.body
  this.subject.innerHTML = unescape(msg.subject)
  this.body.innerHTML    = unescape(msg.body)
  this.index = 0;
  this.advance_frame();
}


GrailSkin.prototype.start_transition = function(o){
  var pos = Position.cumulativeOffset(this.container);
  t1 = new Tween(this.container.style,o.property,o.tween,pos[1] + o.start,pos[1] + o.end,o.duration,'px');
  t1.addListener(this);
  t1.start();
}


GrailSkin.prototype.music_video = function(){
  this.height = 100;
  this.skin = {
   style:{
     height : this.height,
     width : BrowserMetrics.windowDimensions()[0]-30,
     top   : BrowserMetrics.windowDimensions()[1]
   },
  types:{
     'alert'  : {transitions:this.transitions},
     'confirm': {transitions:this.transitions}
    },
  transitions : [
          {property:'top',tween:Tween.easeIn,start:0,end:(this.height*-1),duration:0.5},
          {property:'top',tween:Tween.easeIn,start:0,end:0,duration:2},
          {property:'top',tween:Tween.easeIn,start:0,end:this.height,duration:0.5}
        ]
  }
  return this.skin;
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
Loader.addOnLoad( function(){grail = new Grail(); });