//Throbber for Ajax events
Ajax.Responders.register({
	onCreate: function(request) {
		var throbber = $('throbber');
	    throbber.style.display = 'block';
	},
	onComplete: function(request)
	{
		var throbber = $('throbber');
	    throbber.style.display = 'none';
	}
	onFailure: function(request)
	{
		alert('Error contacting server.');
		//add exception notification here 
	}
}
)