
Element.prototype.on = function(b,f){this.addEventListener(b,f,false); return this}
NodeList.prototype.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a); return this}
NodeList.prototype.on = function(){return this.map(Element.prototype.on,arguments)}

var jumpDoc = function(direction, start) {
    var doc = document.querySelector("head > link[rel='"+direction+"']");
    if(doc)
	window.location = doc.getAttribute('href') + start;
};
var prevDoc = function() {jumpDoc('prev','#last')}
var nextDoc = function() {jumpDoc('next','#first')}

var focusNode = function(e){
    var loc = window.location.hash.slice(1);
    var id = this.getAttribute("id");
    if(loc == id && this.hasAttribute('href')){ // already selected and tapped again, goto
	window.location = this.getAttribute('href');
    } else {
	window.location.hash = id;
    };
    e.stopPropagation();
};

// find navigable (whitelisted via @selectable) nodes
var pointer = document.querySelector('#pointer');
var items = {};
var prior = null;
var first = null;
var last = null;
document.addEventListener("DOMContentLoaded", function(){
    var loc = window.location.hash.slice(1);
    var selectable = document.querySelectorAll("[selectable][id]");
    selectable.on("click",focusNode);

    // first node
    first = selectable[0].getAttribute('id');
    if(loc=='first')
	window.location.hash = first;

    // link graph of traversible nodes
    selectable.map(function(){
	var id = this.getAttribute('id');
	var re = {};
	re['id'] = id;
	if(prior){
	    re['prev'] = prior;
	    re['prev']['next'] = re;
	};
	items[id] = prior = re;
    });
    
    // last node
    last = prior['id'];
    if(loc=='last')
	window.location.hash = last;
});

// keyboard control
document.addEventListener("keydown",function(e){
    var href = null;
    var resource = null;
    var id = window.location.hash.slice(1);
    if(id)
	resource = document.getElementById(id)
    if(resource) {

	var prev = function() {
	    var p = items[id]['prev'];
	    if(p) { // previous item
		window.location.hash = p['id'];
	    } else { // out of previous items -> previous page
		prevDoc();
	    };
	};

	var next = function() {
	    var n = items[id]['next'];
	    if(n) { // next item
		window.location.hash = n['id'];
	    } else { // out of next-items -> next page
		nextDoc();
	    };
	};

	// key: p
	if(e.keyCode==80) {
	    e.preventDefault();
	    if (e.getModifierState("Shift")) {
		prevDoc(); // <shift-p>  previous (page)
	    } else {
		prev(); // <p>  previous (resource)
	    };
	};
	// key: n
	if(e.keyCode==78){
	    e.preventDefault();
	    if (e.getModifierState("Shift")) {
		nextDoc(); // <shift-n> next (page)
	    } else {
		next(); // <n> next (resource)
	    };
	};
	// key: tab
	if(e.keyCode==9){
	    e.preventDefault();
	    if (e.getModifierState("Shift")) {
		prev(); // <shift-tab> previous (resource)
	    } else {
		next(); // <tab> next (resource)
	    };
	};
	// key: enter
	if(e.keyCode==13) {
	    var href = resource.getAttribute('href');
	    if(href)
		window.location.href = href;
	};
    } else { // no selection
	if(e.keyCode==80) {
	    window.location.hash = last;
	} else {
	    window.location.hash = first;
	};
    };
},false);

window.addEventListener("hashchange",function(e){
    var id = window.location.hash.slice(1);
    var resource = document.getElementById(id);
    if(resource) {
	var resTitle = resource.getAttribute('href');
	document.querySelector('title').innerText = resTitle;
	window.scrollTo(resource.offsetLeft + (resource.clientWidth / 2) - (window.width / 2), window.scrollY);
    };
});
