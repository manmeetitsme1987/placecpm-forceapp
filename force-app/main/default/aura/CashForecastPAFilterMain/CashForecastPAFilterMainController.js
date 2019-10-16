({
	doInit : function(component, event, helper) {
        helper.getPaymentAcc(component, event, helper);
        
        //component.set("v.selectedItemOptions", [{"label":"Apple", "value":"444"}, {"label":"Dell", "value":"111"}]);
	},
    evntCalled : function(component, event, helper) {
        console.log('====selectedItems===',event.getParam('selectedItems'));
        var selectedOptionValue = event.getParam('selectedItems');
        component.set("v.selectedBrandOptions", selectedOptionValue);
    }
})