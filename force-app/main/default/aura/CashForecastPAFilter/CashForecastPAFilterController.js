({
    onblur : function(component,event,helper){
        var isblur = component.get("v.isblur");
        if(component.get("v.isblur")){
            component.set("v.SearchKeyWord", '');
        	var forclose = component.find("searchRes");
        	$A.util.addClass(forclose, 'slds-is-close');
        	$A.util.removeClass(forclose, 'slds-is-open');
        }
        else{
            component.set("v.isblur",true);
        }
    },
    onfocus : function(component,event,helper){
		var forOpen = component.find("searchRes");
        var isOpen = $A.util.hasClass(forOpen, "slds-is-open");
        if(isOpen){
            
        	$A.util.addClass(forOpen, 'slds-is-close');
        	$A.util.removeClass(forOpen, 'slds-is-open');
        }
        else{
            $A.util.addClass(component.find("mySpinner"), "slds-show");
            var listOfOptions = component.get("v.lstOptions");
            var selectedOptions = [];
             selectedOptions = component.get("v.lstSelectedRecords");
            console.log('selectedOptions'+selectedOptions);
            if(component.get("v.listOfSearchRecords") == '' || component.get("v.listOfSearchRecords") == null){
                component.set("v.listOfSearchRecords", listOfOptions ); 
            }
            
            var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
            
            // Get Default 5 Records order by createdDate DESC 
            var getInputkeyWord = '';
            //helper.searchHelper(component,event,getInputkeyWord);
        }
    },
    
    keyPressController : function(component, event, helper) {
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        // get the search Input keyword   
        var getInputkeyWord = component.get("v.SearchKeyWord");
        // check if getInputKeyWord size id more then 0 then open the lookup result List and 
        // call the helper 
        // else close the lookup result List part.   
        if(getInputkeyWord.length > 0){
            var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component,event,getInputkeyWord);
        }
        else{  
            component.set("v.listOfSearchRecords", null ); 
            var forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
        }
    },
    
    // function for clear the Record Selaction 
    clear :function(component,event,helper){
        var selectedPillId = event.getSource().get("v.name");
        var AllPillsList = component.get("v.lstSelectedRecords"); 
        
        for(var i = 0; i < AllPillsList.length; i++){
            if(AllPillsList[i] == selectedPillId){
                AllPillsList.splice(i, 1);
                component.set("v.lstSelectedRecords", AllPillsList);
            }  
        }
        helper.callEventForParentCmpHelper(component);
        component.set("v.SearchKeyWord",null);
        component.set("v.listOfSearchRecords", null );      
    },
    onmouseDown: function(component, event, helper) {
        component.set("v.isblur",false);
    },
    selectRecord: function(component, event, helper) {
        component.set("v.SearchKeyWord",null);
        
        var selectedItem = event.currentTarget;
        
        var listSelectedItems =  component.get("v.lstSelectedRecords");
        var chkboxVal = document.getElementById(selectedItem.dataset.value).checked;
        if(chkboxVal && !listSelectedItems.includes(selectedItem.dataset.value)){
            listSelectedItems.push(selectedItem.dataset.value);
            component.set("v.lstSelectedRecords" , listSelectedItems); 
        	helper.callEventForParentCmpHelper(component);
        }
        else{
            var listSelectedItems1 = new Array();
            listSelectedItems1 = listSelectedItems;
            var index = listSelectedItems1.indexOf(selectedItem.dataset.value);
            if(index != -1){
                listSelectedItems1.splice(index, 1);
            }
            component.set("v.lstSelectedRecords" , listSelectedItems1); 
        	helper.callEventForParentCmpHelper(component);
        }
        
        
    },
    inputKeydown : function(cmp, event, helper) {
        event.preventDefault()
    }
})