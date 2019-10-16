({
	handleCancel : function(component, event, helper) {
        //closes the modal or popover from the component
        component.find("overlayLib").notifyClose();
    },
    handleOK : function(component, event, helper) {
        //do something
        $A.get("e.c:Confirmation_Box_Event").setParams({"accId": component.get("v.accId")}).fire();
        component.find("overlayLib").notifyClose();
    }
})