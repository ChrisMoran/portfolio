$(document).ready(function ($) {
	$(".storebtn").click(function () {
		var nbr = this.className.split(" ")[0];
		var symbol = $("." + nbr + ".symbol").text()
			var dataToSend = {
			"symbol" : symbol
		};
		console.log(dataToSend);
		$.get('save-price.pl', dataToSend, function (data) {
			alert(data);
		});
	})
	
	closeCells=$(".close")
	for (i = 0; i < closeCells.length; i++) {
		symbolNbr=closeCells[i].className.split(" ")[0];
		closePrice=$("."+symbolNbr+".close").text();
		openPrice=$("."+symbolNbr+".open").text();
		if(closePrice>openPrice){
		$("."+symbolNbr+".close").css('color', 'green');
		}
		else{
			$("."+symbolNbr+".close").css('color', 'red');
		}
	}
	
});
