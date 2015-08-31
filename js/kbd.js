
Element.prototype.on = function(b,f){this.addEventListener(b,f,false); return this}
NodeList.prototype.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a); return this}
NodeList.prototype.on = function(){return this.map(Element.prototype.on,arguments)}

var jumpDoc = function(direction) {
    var doc = document.querySelector("head > link[rel='"+direction+"']");
    if(doc)
	window.location = doc.getAttribute('href') + '#first';
};
var prevDoc = function() {jumpDoc('prev');}
var nextDoc = function() {jumpDoc('next');}

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
var items = {};
var item = null;
var first = null;
var last = null;
document.addEventListener("DOMContentLoaded", function(){
    var selectable = document.querySelectorAll("[selectable][id]");
    first = selectable[0].getAttribute('id');
    if(window.location.hash.slice(1)=='first')
	window.location.hash = first;
    selectable.map(function(){
	var id = this.getAttribute('id');
	var re = {};
	re['id'] = id;
	if(item){ // link traversible nodes
	    re['prev'] = item;
	    re['prev']['next'] = re;
	};
	items[id] = item = re;
    });
    last = item;
    selectable.on("click",focusNode);
});

// keyboard-control
document.addEventListener("keydown",function(e){
    var resource = null;
    var id = window.location.hash.slice(1);

    if(id)
	resource = document.getElementById(id);

    if(resource) { // focused resource
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
    } else { // no selection
	// <n> <tab>  first entry
	if(e.keyCode==78||e.keyCode==9) {
	    window.location.hash = first;
	};
	// <p> last entry
	if(e.keyCode==80) {
	    window.location.hash = last;
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
