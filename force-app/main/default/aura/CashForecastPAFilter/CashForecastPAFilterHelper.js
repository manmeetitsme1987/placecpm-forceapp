({
    searchHelper : function(component,event,term) {
       console.log(term);
        var excludeitemsListValues= component.get("v.lstSelectedRecords");
        /*var excludeitemsListValues = [];
        for(var i =0; i<excludeitemsList.length; i++){
            term.push(excludeitemsList[i].value);
        }*/
        console.log(term);
        var searchList = [];
        var searchList1 = [];
        term = term.toLowerCase();
        console.log(term);
        var listOfOptions = component.get("v.lstOptions");
        for(var i =0; i<listOfOptions.length; i++){
            var option = listOfOptions[i].label.toLowerCase();
            if(option.indexOf(term) !== -1 && excludeitemsListValues.indexOf(listOfOptions[i].value) < 0){
                searchList.push(listOfOptions[i]);
            }
            if(!term && excludeitemsListValues.indexOf(listOfOptions[i].value) < 0){
                searchList1.push(listOfOptions[i]);
            }
        }
        $A.util.removeClass(component.find("mySpinner"), "slds-show");
        component.set("v.listOfSearchRecords", searchList);
        if(!term){
            component.set("v.listOfSearchRecords", searchList1);
        }
    },
    callEventForParentCmpHelper: function(component){
        var cmpEvent = component.getEvent("mutiSelectEvnt"); 
        cmpEvent.setParams({ 
            "selectedItems" : component.get("v.lstSelectedRecords")
        }); 
        cmpEvent.fire();
    }
})