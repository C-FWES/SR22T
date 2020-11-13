var flaps_cmd = "/controls/flight/flaps-cmd";

var flapsDown = func(i){
	if(i>0){
		if(getprop(flaps_cmd)<=0.5){
			setprop(flaps_cmd, getprop(flaps_cmd)+0.5);
		}
	}else if(i<0){
		if(getprop(flaps_cmd)>=0.5){
			setprop(flaps_cmd, getprop(flaps_cmd)-0.5);
		}
	}
}
