Element.prototype.on = function(b,f){this.addEventListener(b,f,false); return this}
NodeList.prototype.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a); return this}
NodeList.prototype.on = function(){return this.map(Element.prototype.on,arguments)}

document.addEventListener("keydown",function(e){

    console.log(e.keyCode);
    if(e.keyCode==37 || e.keyCode==80)
	window.history.back();

    if(e.keyCode==39 || e.keyCode==78){
	console.log('fwd');
    };

},false)
