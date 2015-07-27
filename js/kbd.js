Element.prototype.on = function(b,f){this.addEventListener(b,f,false); return this}
NodeList.prototype.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a); return this}
NodeList.prototype.on = function(){return this.map(Element.prototype.on,arguments)}

document.addEventListener("keydown",function(e){

    console.log(e.keyCode);
    // next-prev resource navigation
    if((e.keyCode==37) || (e.keyCode==39)) {
	var next = null;
	var curID = window.location.hash.slice(1);
	var cur = document.getElementById(curID);

	if(cur) {
	    if(e.keyCode == 37) // left
		next = cur.previousSibling;
	    if(e.keyCode == 39) // right
		next = cur.nextSibling;
	} else {
	    next = document.querySelector('[selectable][id]');
	};

	if(next) {
	    window.location.hash = next.id;
	    e.preventDefault();
	};

	return false;
    };
},false)
