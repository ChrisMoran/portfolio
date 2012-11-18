
nbr=this.id or something
var symbol=$("."+nbr+".btn.dropdown-toggle").text()
var date=$("."+nbr+".date").text()
var open=$("."+nbr+".open").text()
var high=$("."+nbr+".high").text()
var low=$("."+nbr+".low").text()
var close=$("."+nbr+".close").text()

dataToSend={"symbol": symbol,"date":date,"open":open,"high":high,"low":low,"close":close}; 


$.getJSON('save-price.pl', dataToSend, function(data){
		
	});