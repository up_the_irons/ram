/*
 * Content-seperated javascript tree widget
 * Copyright (C) 2005 SilverStripe Limited
 * Feel free to use this on your websites, but please leave this message in the fies
 * http://www.silverstripe.com/blog
*/

/*
 * Initialise all trees identified by <ul class="tree">
 */
function autoInit_trees() {
	var candidates = document.getElementsByTagName('ul');
	for(var i=0;i<candidates.length;i++) {
		
		//normal trees
		if(candidates[i].className && candidates[i].className.indexOf('tree') != -1) {
			initTree(candidates[i], treeToggle, 'closed', 'spanClosed');
			candidates[i].className = candidates[i].className.replace(/ ?unformatted ?/, ' ');
		}
		
		//selectable trees
		if(candidates[i].className && candidates[i].className.indexOf('selectableTree') != -1) {
			initTree(candidates[i], treeSelectionToggle, 'unselected', 'spanUnselected');
			candidates[i].className = candidates[i].className.replace(/ ?unformatted ?/, ' ');
		}
		
	}
}
 
/*
 * Initialise a tree node, converting all its LIs appropriately
 */
function initTree(el, onclick_method, klass, spanKlass) {
	var i,j;
	var spanA, spanB, spanC;
	var startingPoint, stoppingPoint, childUL;
	
	// Find all LIs to process
	for(i=0;i<el.childNodes.length;i++) {
		if(el.childNodes[i].tagName && el.childNodes[i].tagName.toLowerCase() == 'li') {
			var li = el.childNodes[i];

			// Create our extra spans
			spanA = document.createElement('span');
			spanB = document.createElement('span');
			spanC = document.createElement('span');
			spanA.appendChild(spanB);
			spanB.appendChild(spanC);
			spanA.className = 'a ' + li.className.replace(klass, spanKlass);
			spanA.onMouseOver = function() {}
			spanB.className = 'b';
			spanC.onclick   = onclick_method;
			spanC.className = 'c';
			
			
			// Find the UL within the LI, if it exists
			stoppingPoint = li.childNodes.length;
			startingPoint = 0;
			childUL = null;
			for(j=0;j<li.childNodes.length;j++) {
				if(li.childNodes[j].tagName && li.childNodes[j].tagName.toLowerCase() == 'div') {
					startingPoint = j + 1;
					continue;
				}

				if(li.childNodes[j].tagName && li.childNodes[j].tagName.toLowerCase() == 'ul') {
					childUL = li.childNodes[j];
					stoppingPoint = j;
					break;					
				}
			}
				
			// Move all the nodes up until that point into spanC
			for(j=startingPoint;j<stoppingPoint;j++) {
				spanC.appendChild(li.childNodes[startingPoint]);
			}
			
			// Insert the outermost extra span into the tree
			if(li.childNodes.length > startingPoint) li.insertBefore(spanA, li.childNodes[startingPoint]);
			else li.appendChild(spanA);
			
			// Process the children
			if(childUL != null) {
				if(initTree(childUL, onclick_method, klass, spanKlass)) {
					addClass(li, 'children', klass);
					addClass(spanA, 'children', spanKlass);
				}
			}
		}
	}
	
	if(li) {
		// li and spanA will still be set to the last item

		addClass(li, 'last', klass);
		addClass(spanA, 'last', spanKlass);
		return true;
	} else {
		return false;
	}
		
}
 

/*
 * +/- toggle the tree, where el is the <span class="b"> node
 * force, will force it to "open" or "close"
 */
function treeToggle(el, force) {
	el = this;
	
	while(el != null && (!el.tagName || el.tagName.toLowerCase() != "li")) el = el.parentNode;
	
	// Get UL within the LI
	var childSet = findChildWithTag(el, 'ul');
	var topSpan  = findChildWithTag(el, 'span');

	if( force != null ){
		
		if( force == "open"){
			treeOpen( topSpan, el )
		}
		else if( force == "close" ){
			treeClose( topSpan, el )
		}
		
	}
	
	else if( childSet != null) {
		// Is open, close it
		if(!el.className.match(/(^| )closed($| )/)) {		
			treeClose( topSpan, el )
		// Is closed, open it
		} else {			
			treeOpen( topSpan, el )
		}
	}
}

function treeSelectionToggle(el, force) {
	el = this;
	while(el != null && (!el.tagName || el.tagName.toLowerCase() != "li")) el = el.parentNode;
		// Get UL within the LI
    var childSet = findChildWithTag(el, 'ul');
    var topSpan = findChildWithTag(el, 'span');
    if( force != null ){
    	if( force == "select"){
    		treeSelect( topSpan, el )
    	}
    	else if( force == "unselect" ){
    		treeUnSelect( topSpan, el )
    	}
    
	}else if( childSet != null) {
    	// Is selected, unselect it
    	if(el.className.match(/(^| )selected($| )/)) {		
    		treeUnselect( topSpan, el )
    		// Is unselected, select it
    	} else {			
    		treeSelect( topSpan, el )
    	}
	
    }else{
		if(el.className.match(/(^| )selected($| )/)) {		
    		treeUnselect( topSpan, el )
    		// Is unselected, select it
    	} else {			
    		treeSelect( topSpan, el )
    	}
	}
}


function treeOpen( a, b ){
	removeClass(a,'spanClosed');
	removeClass(b,'closed');
}
	
	
function treeClose( a, b ){
	addClass(a,'spanClosed');
	addClass(b,'closed');
}


function treeUnselect( a, b ){
	toggleCheckbox(b);
	removeClass(a,'spanSelected');
	removeClass(b,'selected');
}
	
	
function treeSelect( a, b ){
	toggleCheckbox(b)
	addClass(a,'spanSelected');
	addClass(b,'selected');
}


function toggleCheckbox(tag,parents_new_value){
	var checkbox  = null
	this.new_value = null
	if(tag.tagName != null && tag.tagName.toLowerCase() == 'input'){
		checkbox = tag
		if(checkbox.checked != parents_new_value){
			if(checkbox.checked){
				this.new_value= false;
			}else{
				this.new_value= true;
			}
			checkbox.checked = this.new_value
			return this.new_value
		}
	}else{
		for(var i = 0; i < tag.childNodes.length; i++){
			//TODO. this is sort of a kludge to keep the search from going into nested lists
			toggle_results = toggleCheckbox(tag.childNodes[i], this.new_value)
			if( toggle_results != null){
				this.new_value = toggle_results
				return toggle_results
			}
		}
	}
}

/*
 * Find the a child of el of type tag
 */
function findChildWithTag(el, tag) {
	for(var i=0;i<el.childNodes.length;i++) {
		if(el.childNodes[i].tagName != null && el.childNodes[i].tagName.toLowerCase() == tag){
			return el.childNodes[i];
		}
	}
	return null;
}

/*
 * Functions to add and remove class names
 * Mac IE hates unnecessary spaces
 */
function addClass(el, cls, forceBefore) {
	if(forceBefore != null && el.className.match(new RegExp('(^| )' + forceBefore))) {
		el.className = el.className.replace(new RegExp("( |^)" + forceBefore), '$1' + cls + ' ' + forceBefore);

	} else if(!el.className.match(new RegExp('(^| )' + cls + '($| )'))) {
		el.className += ' ' + cls;
		el.className = el.className.replace(/(^ +)|( +$)/g, '');
	}
}
function removeClass(el, cls) {
	var old = el.className;
	var newCls = ' ' + el.className + ' ';
	newCls = newCls.replace(new RegExp(' (' + cls + ' +)+','g'), ' ');
	el.className = newCls.replace(/(^ +)|( +$)/g, '');
} 

/*
 * Handlers for automated loading
 */ 
 _LOADERS = Array();

function callAllLoaders() {
	var i, loaderFunc;
	for(i=0;i<_LOADERS.length;i++) {
		loaderFunc = _LOADERS[i];
		if(loaderFunc != callAllLoaders) loaderFunc();
	}
}

function appendLoader(loaderFunc) {
	if(window.onload && window.onload != callAllLoaders)
		_LOADERS[_LOADERS.length] = window.onload;

	window.onload = callAllLoaders;

	_LOADERS[_LOADERS.length] = loaderFunc;
}

appendLoader(autoInit_trees);
