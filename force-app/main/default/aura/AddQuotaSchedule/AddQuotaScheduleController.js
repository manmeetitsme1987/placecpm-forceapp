({
    init : function(component, event, helper) {
        //helper.loadOption(component);
        helper.fetchExistingQuotas(component);
    },
    add : function(component, event, helper) {
        helper.addQuotaSchedule(component);
    },
    create : function( component, event, helper ) {
        helper.createQuotaSchedule(component, event, helper);
    },
    onChange : function( component, event, helper ) {
        var target = event.getSource();  
        var selectedValue = target.get("v.value") ;
        //var index = target.get("v.name")
        //var wrapperList = component.get('v.wrappers');
        //wrapperList[index].selectedType =  selectedValue;
        component.set('v.typeValue' , selectedValue);
        helper.calculateMonthlyAmount(component, event,selectedValue);
    },
    close : function( component, event, helper ) {
        component.destroy();
    },
    delete : function( component, event, helper ) {
        var rectarget = event.currentTarget;
        var idstr = rectarget.getAttribute("data-conId");
        var quotaresponse = component.get("v.quotaScheduleList");
        quotaresponse.splice(idstr , 1);
        component.set("v.quotaScheduleList" , quotaresponse);
    },
 //#102
 	updateMonthlyAmount : function( component, event, helper ) {
     var selectedTypeValue = component.get('v.typeValue');
     helper.calculateMonthlyAmount(component, event,selectedTypeValue);
    },
        // function automatic called by aura:waiting event  
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for displaying loading spinner 
        component.set("v.spinner", true); 
    },
     
    // function automatic called by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hiding loading spinner    
        component.set("v.spinner", false);
    }
    
})