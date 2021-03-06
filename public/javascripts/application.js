// Throbber for Ajax events

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
    // add exception notification here 
  }
}
)


Content ={
  // TODO: This is where the toggling of display options should be implemented.
  cache: [],
  display_as: function(str){
    switch(str){
      case 'thumbnails' : 
        $('details').hide();
        $('thumbnails').show();
      break;
      case 'details' : 
        $('details').show();
        $('thumbnails').hide();
      break;
    }
    new Ajax.Request('/account/display_as/'+str);
  },
  in_cache: function(element){
    if(Content.cache.include(element)){
      return true;
    }else{
      return false;
    }
  },
  add_to_cache: function(e){
    Content.cache.push(e);
  }
}

// Collection of helper methods for common view functionality
View = {
  HasManySortHelper : null,
  
  // Assumes either id_1 or id_2 is set visible and the other is hidden
  flip_flop : function(id_1,id_2){
    $(id_1).toggle();
    $(id_2).toggle();
    return false;
  },
  show_hide : function(show_id,hide_id){
    $(show_id).show();
    $(hide_id).hide();
    return false;
  }
}

View.Onload = {
  loaded: false,
  addEvent: function(fn) {
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

// Fade any flash messages after a certain amount of time.
View.FadeFlash = function(){
  new Element.scrollTo('page_flash');
  window.setTimeout('Effect.Fade(\'page_flash\', {duration:.5})',3000);
}

View.SelectRow = function(checkbox, parent_row,unselected_class,selected_class){
  if(checkbox.checked){
    $(parent_row).className= selected_class;
    $(parent_row).onmouseout='';  
  }else{
    $(parent_row).className= unselected_class;
  }
}
View.CheckAll = function(list,name,toggle){
  
  toggle_val = toggle.checked
  for(var i = 0; i < list.length;i++){
    list[i].checked = toggle_val
  }
  
}
View.HasManySortHelper ={
  sort_items : true,
  hidden_selected_items_to_submit : null,
  selelected_items_to_display : null,
  
  move_all : function(fbox,tbox){
    while(fbox.options.length > 0){
      this.swap_option(tbox , fbox.options[0])
    }
  this.clone_select(
            this.selelected_items_to_display ,
            this.hidden_selected_items_to_submit
          )
    },

  move : function(fbox,tbox)
    {
    // If no items were selected then implicity they probably want to move the top one
    if (fbox.selectedIndex == -1 && fbox.options.length > 0){
      this.swap_option(tbox , fbox.options[0])
    }
    
      for(var i=0; i<fbox.options.length; i++){
          if(fbox.options[i].selected){
        this.swap_option(tbox , fbox.options[i])
      }
      }
    this.clone_select(
              this.selelected_items_to_display ,
              this.hidden_selected_items_to_submit
            )
    },

  clone_select : function(fbox, tbox ){
    while(tbox.options.length > 0){
      this.remove_option(tbox,tbox.options[0])
    }
    for(var i =0; i < fbox.options.length; i++){
      tbox.appendChild(new Option(fbox.options[i].text,fbox.options[i].value));
      tbox.options[tbox.options.length-1].selected = true;
    }
    
  },
  
  swap_option : function(tbox , opt){
    tbox.appendChild(opt)
    opt.selected = false;
  },
  
  remove_option : function(sel, opt){
    sel.removeChild(opt);
  },
  
  remove_all_options : function(sel){
    while(sel.options.length > 0){
      this.remove_option(sel,sel.options[0])
    }
  },

  update_collection : function(fbox, tbox) {
    this.remove_all_options(this.hidden_selected_items_to_submit)

    for(var i=0; i<tbox.options.length; i++){
      var no = new Option();
      no.value = tbox.options[i].value;
      no.text = tbox.options[i].text;
      this.hidden_selected_items_to_submit.options[i] = no;
      this.hidden_selected_items_to_submit.options[i].selected = true;
    }
  }
}
