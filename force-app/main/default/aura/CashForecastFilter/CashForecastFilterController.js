({
	doInit : function(component, event, helper) {
		var buttonNames = new Array();
        if(component.get("v.IsCash")){
            buttonNames.push({'label': $A.get("$Label.c.WEEK"), 'value': $A.get("$Label.c.WEEK")});
        }
        buttonNames.push({'label': $A.get("$Label.c.MONTH"), 'value': $A.get("$Label.c.MONTH")});
        buttonNames.push({'label': $A.get("$Label.c.QUARTER"), 'value': $A.get("$Label.c.QUARTER")});
        buttonNames.push({'label': $A.get("$Label.c.YEAR"), 'value': $A.get("$Label.c.YEAR")});
        component.set("v.buttonList",buttonNames);
        component.set("v.value",$A.get("$Label.c.MONTH"));
        var yearRangeArray = component.get('v.yearList');
        component.set("v.minyear" , yearRangeArray[0]);
        component.set("v.maxYear" , yearRangeArray[yearRangeArray.length-1]);
        
	},
	
    getWeekData: function(cmp , event, helper) {
        debugger;
        if(cmp.get('v.calendarView') == 'Week'){
            var action = cmp.get("c.yearAndWeekDates");
            action.setCallback(this, function(response) {
                debugger;
                var weekDatesMap = [];
                var weekDatesMapApex = response.getReturnValue();
                for(var i in weekDatesMapApex){
                    weekDatesMap.push({key:i , value:weekDatesMapApex[i]});
                }
                cmp.set('v.weekDatesMap',weekDatesMap);
            });
            $A.enqueueAction(action);
        }
    },
    
    handleFilterChange : function(component, event, helper) {
        var currentYear = component.get('v.currentYearInput');
        var changeValue = event.getParam("value");
        component.set('v.calendarView' , changeValue);
        var cmpEvent = component.getEvent("cashForecastFilterEvent");
        cmpEvent.setParams( { "message" : changeValue } );
        cmpEvent.fire();
    },
    applyFilters : function(component, event, helper) {
        debugger;
        var startDateComponent = component.find('startDate');
        var startMonth = startDateComponent.get('v.selectedMonthInteger');
        var startYear = startDateComponent.get('v.selectedYear');
        var weekStartDate = startDateComponent.get('v.weekDate');
        var endDateComponent = component.find('endDate');
        var endMonth = endDateComponent.get('v.selectedMonthInteger');
        var endYear = endDateComponent.get('v.selectedYear');
        var compEvent = component.getEvent("plFilters");
        var weekEndDate = endDateComponent.get('v.weekDate');
        var flag = true;
        if(startYear > endYear || (startMonth != undefined && endMonth != undefined && startYear == endYear && startMonth > endMonth)){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
            "title": "Warning!",
            "type": "warning",
            "message": "End date can not be less then start date"
            });
            flag = false;
            toastEvent.fire();
        }
        if(component.get('v.calendarView') == 'Week'){
            var startDateArr = weekStartDate.split(' ');
            var endDateArr = weekEndDate.split(' ');
            if(startYear > endYear || (startYear == endYear && helper.getMonthInInteger(startDateArr[1]) > helper.getMonthInInteger(endDateArr[1])) ||
                                (startYear == endYear && helper.getMonthInInteger(startDateArr[1]) == helper.getMonthInInteger(endDateArr[1]) 
                                                        && parseInt(startDateArr[0]) > parseInt(startDateArr[1])) ){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                "title": "Warning!",
                "type": "warning",
                "message": "End date can not be less then start date"
                });
                flag = false;
                toastEvent.fire()
            } 
        }
        if(flag){
            compEvent.setParams({"startMonth" : startMonth , "startYear" : startYear , "endMonth" : endMonth , "endYear" : endYear , "startdate" : weekStartDate , "endDate" : weekEndDate});
            compEvent.fire();
        }
    },
    
    
    viewChange : function(component, event, helper) {
        var changeValue = component.find('InputSelectView').get('v.value');
        var cmpEvent = component.getEvent("actualForecastViewEvent");
        cmpEvent.setParams( { "filterType" : changeValue } );
        cmpEvent.fire();
    }
})