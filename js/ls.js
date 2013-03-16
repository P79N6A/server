var ls = function(){
    qa('a').click(function(){
	qa('a').map(function(){this.style.backgroundColor='#233';this.style.color='#fff';})
	this.style.backgroundColor='#fff';this.style.color='#000';
    })
};
document.addEventListener("DOMContentLoaded", ls, false);
