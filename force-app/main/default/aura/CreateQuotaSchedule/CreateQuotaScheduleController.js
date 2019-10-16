({
	openAddQuotaComponent : function(component, event, helper) {
		 $A.createComponent(
             "c:AddQuotaSchedule",
             {},
            function(newButton, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newButton);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    // Show offline error
                }
                else if (status === "ERROR") {
                    // Show error message
                }
            }
        );
	}
})