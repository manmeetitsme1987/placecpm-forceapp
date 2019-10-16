({
    doInit : function(component, event, helper) {
        var today = new Date();
        component.set('v.currentDate', today);
    },
	getRefresh : function(component, event, helper) {
        var today = new Date();
        component.set('v.currentDate', today);
        var cmpEvent = component.getEvent("cashForecastHeaderEvent");
        // Get the value from Component and set in Event
        cmpEvent.setParams( { "message" : "refresh" } );
        cmpEvent.fire();
	}
})