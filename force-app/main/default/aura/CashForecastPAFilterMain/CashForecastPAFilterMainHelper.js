({
	getPaymentAcc : function(component, event, helper) {
		var action = component.get("c.getPaymentAccounts");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS" ) {
                var paInfo = new Array();
                var items = [];
        		paInfo = response.getReturnValue();
                for(var i=0; i<paInfo.length;i++){
                    items.push({"label": paInfo[i].Name, "value": paInfo[i].Id});
                }
                component.set("v.itemOptions", items);
            }
        });
        $A.enqueueAction(action);
	}
})