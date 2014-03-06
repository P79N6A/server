var histogram = function(){
    var showBin =  function(e){
	var b = e.target.attr('class')
	var s = document.querySelector('.histBin.' + b)
         if (s){ s.scrollIntoView()
		 if (window.scrollByLines)
	             window.scrollByLines(-5)}
	var s = document.querySelector('.histogram style')
	 if (s) {s.remove() }
	document.querySelector('.histogram').append(el('style').txt('.histBin.'+b+'{border-color:#0f0;border-width:.5em;border-style:solid;}'))
    }

    var bins = document.querySelectorAll('table.histogram td');
    bins.on("click",showBin,false)
    bins.on("mouseover",showBin,false)
}

document.addEventListener("DOMContentLoaded", histogram, false)
