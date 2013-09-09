var histogram = function(){
    var showBin =  function(e){
	var b = e.target.attr('class')
	var s = document.querySelector('.histBin.' + b)
         if (s) {s.scrollIntoView()}
	var s = document.querySelector('.histogram style')
	 if (s) {s.remove() }
	document.querySelector('.histogram').append(el('style').txt('.histBin.'+b+'{background-color:#0f0;color:#000}'))
    }

    var bins = document.querySelectorAll('table.histogram td');
    bins.on("click",showBin,false)
    bins.on("mouseover",showBin,false)
}

document.addEventListener("DOMContentLoaded", histogram, false)
