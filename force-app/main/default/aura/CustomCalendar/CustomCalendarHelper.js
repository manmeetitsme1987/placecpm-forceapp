({
	getMonthInteger : function(selectedMonth , component) {
        var monthInteger;
        var timeFrame = component.get('v.view');
        if(timeFrame == 'Month'){
            switch(selectedMonth) {
                case 'January':
                    monthInteger = 1;
                    break;
                case 'February':
                    monthInteger = 2;
                    break;
                case 'March':
                    monthInteger = 3;
                    break;
                case 'April':
                    monthInteger = 4;
                    break;
                case 'May':
                    monthInteger = 5;
                    break;
                case 'June':
                    monthInteger = 6;
                    break;
                case 'July':
                    monthInteger = 7;
                    break;
                case 'August':
                    monthInteger = 8;
                    break;
                case 'September':
                    monthInteger = 9;
                    break;
                case 'Ocotober':
                    monthInteger = 10;
                    break;
                case 'November':
                    monthInteger = 11;
                    break;
                case 'December':
                    monthInteger = 12;
            }
        }
        else if(timeFrame == 'Quarter'){
            switch(selectedMonth) {
                case 'Q1':
                    monthInteger = 1;
                    break;
                case 'Q2':
                    monthInteger = 2;
                    break;
                case 'Q3':
                    monthInteger = 3;
                    break;
                case 'Q4':
                    monthInteger = 4;
            }
        }
        return monthInteger;
    }
})