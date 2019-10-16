({
    init: function (cmp, event, helper) {
        helper.fetchData(cmp, event, helper);
        helper.initColumnsWithActions(cmp, event, helper)
    },
    
    handleColumnsChange: function (cmp, event, helper) {
        helper.initColumnsWithActions(cmp, event, helper)
    },
    
    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        var onRowActionHandler = cmp.get('v.onRowActionHandler');
        
        if(onRowActionHandler){
            $A.enqueueAction(onRowActionHandler)                       
        }else{   
            console.log(row);
            switch (action.name) {
                case 'edit':
                    helper.editRecord(cmp, row)
                    break;
                case 'delete':
                    helper.removeRecord(cmp, row)
                    break;
                case 'openFD':
                    helper.openED(cmp, row)
                    break;
            }
        }
    },
    
    handleGotoRelatedList : function (cmp, event, helper) {
        var relatedListEvent = $A.get("e.force:navigateToRelatedList");
        relatedListEvent.setParams({
            "relatedListId": cmp.get("v.parentRelationshipApiName"),
            "parentRecordId": cmp.get("v.recordId")
        });
        relatedListEvent.fire();
    },
    
    handleCreateRecord : function (cmp, event, helper) {
        var action = cmp.get("c.fetchRecordTypeValues");
        action.setParams({sobjectApiName : cmp.get("v.sobjectApiName"),
                          parentSobjectName : cmp.get("v.parentSobjectApiName"),
                          parentRecordId : cmp.get("v.recordId")});
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS" ) {
                var rtInfo = new Array();
                var rtRadio = new Array();
                rtInfo = response.getReturnValue();
                if(rtInfo.length >1){
                    for(var i = 0; i<rtInfo.length;i++){
                        rtRadio.push({'label': rtInfo[i].rtName, 'value': rtInfo[i].rtId});
                    }
                    cmp.set("v.lstOfRecordType", rtRadio);
                    cmp.set("v.value",rtInfo[0].rtId);
                    cmp.set("v.isOpen", true);
                    cmp.set("v.isRtAvailable", true);
                }
                else if(rtInfo.length === 1){
                    cmp.set("v.isOpen", true);
                    helper.createRecordHelper(cmp, event,rtInfo[0].rtId);
                    
                }
                    else{
                        cmp.set("v.isOpen", true);
                        helper.createRecordHelper(cmp, event,null);
                    }
                
            }
        });
        $A.enqueueAction(action);
        /*var createRecordEvent = $A.get("e.force:createRecord");
        createRecordEvent.setParams({
            "entityApiName": cmp.get("v.sobjectApiName"),
            "defaultFieldValues": {
                [cmp.get("v.relatedFieldApiName")] : cmp.get("v.recordId")
            }
        });
        createRecordEvent.fire();*/
    },   
    createRecord: function(component, event, helper) {
        //component.set("v.isOpen", true);
        var changeValue = component.find("rtSelect").get("v.value");
        
        helper.createRecordHelper(component, event,changeValue);
        
    },
    closeModal: function(component, event, helper) {
        // set "isOpen" attribute to false for hide/close model box 
        component.set("v.isOpen", false);
    },    
    handleToastEvent  : function (cmp, event, helper) {
        var eventType = event.getParam('type');
        var eventMessage= event.getParam('message');
        if(eventType == 'SUCCESS' && eventMessage.includes(cmp.get('v.sobjectLabel'))){
            helper.fetchData(cmp, event, helper)
            var cmpEvent = cmp.getEvent("singleRelatedListEveny");
            // Get the value from Component and set in Event
            cmpEvent.setParams( { "recordId" : null,
                                 "message" : "refresh"} );
            cmpEvent.fire();
            event.stopPropagation();            
        }        
    },   
    save : function(component, event, helper) {
        $A.util.addClass(component.find("mySpinner") , "slds-show");
        $A.util.removeClass(component.find("mySpinner") , "slds-hide");
        var reqFieldList = new Array();
        reqFieldList = component.get('v.requiredFields');
        var eventFields = event.getParam("fields");
        for(var i = 0;i<reqFieldList.length;i++){
            if(eventFields[reqFieldList[i]]===null || eventFields[reqFieldList[i]]==='' ){
                event.preventDefault(); // stop form submission
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "message": "Please populate the required fields.",
                    "type" : "error"
                });
                toastEvent.fire();
                $A.util.removeClass(component.find("mySpinner") , "slds-show");
                $A.util.addClass(component.find("mySpinner") , "slds-hide");
            }
        }
    },
    
    handleSuccessNew :function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner") , "slds-show");
        $A.util.addClass(component.find("mySpinner") , "slds-hide");
        component.set("v.isOpen", false);
        var payload = event.getParams().response;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The record has been created successfully.",
            "type" : "success"
        });
        toastEvent.fire();
        var cmpEvent = component.getEvent("singleRelatedListEveny");
        // Get the value from Component and set in Event
        cmpEvent.setParams( { "recordId" : component.get("v.recordId"),
                             "message" : "openED"} );
        cmpEvent.fire();
        //helper.getSplitScreenData(component,event,payload.id);
    },
    handleOnError : function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner") , "slds-show");
        $A.util.addClass(component.find("mySpinner") , "slds-hide");
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Error!",
            "message": "Some Error Occured!",
            "type" : "error"
        });
        toastEvent.fire();
    },
})