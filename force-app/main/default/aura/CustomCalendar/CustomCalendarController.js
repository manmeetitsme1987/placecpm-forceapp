({
    doInit: function(cmp , event, helper) {
        debugger;
        cmp.set('v.currentYear' , cmp.get('v.selectedYear'));
        var monthInteger = helper.getMonthInteger(cmp.get('v.selectedMonth') , cmp);
        cmp.set('v.selectedMonthInteger' , monthInteger);
    },
    
    selectWeekDate: function(cmp , event, helper) {
        debugger;
        var target = event.currentTarget;
        var selectedDate = target.getAttribute("data-date");
        cmp.set('v.weekDate' , selectedDate);
        cmp.set('v.selectedYear' , cmp.get('v.currentYear'));
    },
    
    showCalendar : function(cmp, event, helper) {
        var calendarVisible = cmp.get('v.showCalendar');
        if(calendarVisible == false){
            cmp.set('v.showCalendar' , true);
        }
        else{
            cmp.set('v.showCalendar' , false);
        }
        cmp.set('v.currentYear' , cmp.get('v.selectedYear'));
    },
    hideCalendar : function(cmp, event, helper) {
        cmp.set('v.showCalendar' , false);
    },
    increaseYear : function(cmp, event, helper) {
        var view = cmp.get('v.view');
        if(view != 'Year'){
            var currentYear = cmp.get('v.currentYear');
            if(++currentYear <= cmp.get('v.maxYear'))
                cmp.set('v.currentYear' , currentYear); 
        }
        event.preventDefault();
    },
    decreaseYear : function(cmp, event, helper) {
        var view = cmp.get('v.view');
        if(view != 'Year'){
            var currentYear = cmp.get('v.currentYear');
            if(--currentYear >= cmp.get('v.minYear'))
                cmp.set('v.currentYear' , currentYear);
        }
        event.preventDefault();
    },
    selectMonth : function(cmp, event, helper) {
        var target = event.currentTarget;
        var selectedMonth = target.getAttribute("data-month");
        cmp.set('v.selectedMonth' , selectedMonth);
        cmp.set('v.selectedYear' , cmp.get('v.currentYear'));
    },
    setSelectMonthInteger : function(cmp, event, helper) {
        var val = event.getParam("value");
        var monthInteger = helper.getMonthInteger(val , cmp);
        cmp.set('v.selectedMonthInteger' , monthInteger);
    },
    selectYear : function(cmp, event, helper) {
        var target = event.currentTarget;
        var selectedYear = target.getAttribute("data-year");
        cmp.set('v.selectedYear' , parseInt(selectedYear));
    },
    inputKeydown : function(cmp, event, helper) {
        event.preventDefault()
    },
})