({
    getMonthInInteger : function(months){
        var monthInteger;
        switch(months) {
            case 'Jan':
                monthInteger =  1;
                break;
            case 'Feb':
                monthInteger =  2;
                break;
            case 'Mar':
                monthInteger =  3;
                break;
            case 'Apr':
                monthInteger =  4;
                break;
            case 'May':
                monthInteger =  5;
                break;
            case 'Jun':
                monthInteger =  6;
                break;
            case 'Jul':
               monthInteger =  7;
                break;
            case 'Aug':
                monthInteger =  8;
                break;
            case 'Sep':
                monthInteger =  9;
                break;
            case 'Oct':
                monthInteger =  10;
                break;
            case 'Nov':
                monthInteger =  11;
                break;
            case 'Dec':
                monthInteger =  12;
        }
        return monthInteger;
    },

})