N = NodeList.prototype
E = Element.prototype
N.map = function(f,a){for(var i=0,l=this.length;i<l;i++) f.apply(this[i],a);return this}
E.on = function(b,f){
    this.addEventListener(b,f,false)
    return this}
E.attr = function(a,v){
    if(v){ this.setAttribute(a,String(v))
	   return this
  } else { return this.getAttribute(a)}}

N.on = function(){return this.map(E.on,arguments)}

