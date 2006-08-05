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
}
)