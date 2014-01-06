var book = function(){
    qa('div[type="book"]').on('click',function(e){
	console.log(e.target)
	e.preventDefault()
	return false
    })
}

document.addEventListener("DOMContentLoaded", book, false);
