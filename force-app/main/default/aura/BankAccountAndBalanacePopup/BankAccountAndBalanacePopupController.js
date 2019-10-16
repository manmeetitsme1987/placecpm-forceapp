({
    doInit: function(cmp) {
        var action = cmp.get('c.fetchAccountAndBalance');
        action.setCallback(this, function(response) {
            cmp.set('v.responseList' , response.getReturnValue());
        });
        $A.enqueueAction(action);
    },
    
    handleChange:function(component, event, helper) {
        var selectedVal = component.find('paymentAccoundInput').get('v.value');
        for(var res of component.get('v.responseList')){
            if(res.paymentAccoundId == selectedVal){
                component.set('v.openingBalance' , res.amount);
            }
        }
    },
    
    closePopup:function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    },
    
    submitDetails: function(component, event, helper) {
        var action = component.get('c.savePaymentAccount');
        action.setParams({
            bankAccountWrapper : JSON.stringify(component.get('v.responseList')),
        });
        action.setCallback(this, function(response) {
            debugger;
            if(response.getReturnValue() == 'Success'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "message": "The record has been updated successfully.",
                    "type" : "success"
                });
                $A.get("e.c:OpeningBalanceUpdate").setParams({"isSuccess": true}).fire();
                component.find("overlayLib").notifyClose();
                toastEvent.fire();
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Some Error occured while savingp. Please try again later",
                    "type" : "error"
                });
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    }
})