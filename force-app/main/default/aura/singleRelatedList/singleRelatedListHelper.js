({
    fetchData: function (cmp, event, helper) {
 		var action = cmp.get("c.initData")
 		var relatedFieldApiName = cmp.get("v.relatedFieldApiName")
        var numberOfRecords = cmp.get("v.numberOfRecords")
        var jsonData = JSON.stringify({fields:cmp.get("v.fields"),
                                       relatedFieldApiName:cmp.get("v.relatedFieldApiName"),
                                       recordId:cmp.get("v.recordId"),
                                       numberOfRecords:numberOfRecords + 1,
                                       sobjectApiName: cmp.get("v.sobjectApiName"),
                                       sortedBy: cmp.get("v.sortedBy"),
                                       sortedDirection: cmp.get("v.sortedDirection")
        });
        action.setParams({jsonData : jsonData});

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var jsonData = JSON.parse(response.getReturnValue())
                var records = jsonData.records;
                // 563
                var fieldsArray = [];
                fieldsArray = cmp.get("v.fields").split(',');
                for(var i=0;i<records.length;i++){
                    var record = records[i];
                    for(var j = 0;j<fieldsArray.length;j++){
                        var field = fieldsArray[j];
                        if(field.includes('__r')){
                            var child = record[field.substr(0, field.indexOf('.'))];
                            if(child != undefined){
                                record[field] = child.Name;
                            }
                        }
                        else{
                            if(record[field] != undefined){
                               record[field] = record[field]+'';
                            }
                            
                        }
                        
                    }
                }

                if(records.length > numberOfRecords){
                    records.pop()
                    cmp.set('v.numberOfRecordsForTitle', numberOfRecords + "+")
                }else{
                    cmp.set('v.numberOfRecordsForTitle', Math.min(numberOfRecords,records.length))
                }
                
                cmp.set('v.isNewButton',jsonData.isNew)
                cmp.set('v.records', records)
                cmp.set('v.iconName', jsonData.iconName)
                cmp.set('v.sobjectLabel', jsonData.sobjectLabel)
                cmp.set('v.sobjectLabelPlural', jsonData.sobjectLabelPlural)
                cmp.set('v.parentRelationshipApiName', jsonData.parentRelationshipApiName)
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

        $A.enqueueAction(action);        
    },
    flattenStructure : function (helper,topObject, prefix, toBeFlattened) {
      for (const prop in toBeFlattened) {
        const curVal = toBeFlattened[prop];
        if (typeof curVal === 'object') {
          helper.flattenStructure(helper, topObject, prefix + prop + '_', curVal);
        } else {
          topObject[prefix + prop] = curVal;
        }
      }
    },    
    
   initColumnsWithActions: function (cmp, event, helper) {
        var customActions = cmp.get('v.customActions')
        if( !customActions.length){
            customActions = [
                { label: 'Edit', name: 'edit' },
                { label: 'Delete', name: 'delete' }
	        ]         
        }
        
        var columns = cmp.get('v.columns')        
        var columnsWithActions = []
        columnsWithActions.push(...columns)
        columnsWithActions.push({ type: 'action', typeAttributes: { rowActions: customActions } })
        console.log(columnsWithActions);
        cmp.set('v.columnsWithActions',  columnsWithActions)
    },    
    
    removeRecord: function (cmp, row) {
        var modalBody;
        var modalFooter;
        var sobjectLabel = cmp.get('v.sobjectLabel')
        $A.createComponents([
            ["c:deleteRecordContent",{sobjectLabel:sobjectLabel}],
            ["c:deleteRecordFooter",{record: row, sobjectLabel:sobjectLabel}]
        ],
        function(components, status){
            if (status === "SUCCESS") {
                modalBody = components[0];
                modalFooter = components[1];
                cmp.find('overlayLib').showCustomModal({
                   header: "Delete " + sobjectLabel,
                   body: modalBody, 
                   footer: modalFooter,
                   showCloseButton: true
               })
            }
        }
       );
        
    },
    
	editRecord : function (cmp, row) {
        var createRecordEvent = $A.get("e.force:editRecord");
        createRecordEvent.setParams({
            "recordId": row.Id
        });
        createRecordEvent.fire();
        
	}, 
    openED : function(cmp,row){
        console.log('testt');
        var cmpEvent = cmp.getEvent("singleRelatedListEveny");
        // Get the value from Component and set in Event
        cmpEvent.setParams( { "recordId" : row.Id,
                             "message" : "openED"} );
        cmpEvent.fire();
    },
    createRecordHelper: function(component, event, changeValue) {
        component.set("v.selectedRecordType",changeValue);
        var action = component.get("c.getEditPageLayoutSections");
        action.setParams({ sObjectName : component.get('v.sobjectApiName'),
                          recordTypeId : changeValue});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS" ) {
                console.log(response.getReturnValue());
                var layoutInfo = new Array();
                var fs1Map = [];
                var fs2Map = [];
                var reqFieldSet = new Array();
                layoutInfo = response.getReturnValue();
                for(var i=0;i<layoutInfo.length;i++){
                    var fieldsInfo = layoutInfo[i].lstFields;
                    console.log(fieldsInfo)
                    for(var j in fieldsInfo){
                        if(fieldsInfo[j].fieldName != null && fieldsInfo[j].fieldName != ''){
                            if(fieldsInfo[j].isRequired){
                                reqFieldSet.push(fieldsInfo[j].fieldName);
                            }
                            if ( j % 2 == 0){
                                fs1Map.push({key:fieldsInfo[j].fieldName ,value:fieldsInfo[j].isRequired}); 
                            }
                            else{
                                fs2Map.push({key:fieldsInfo[j].fieldName,value:fieldsInfo[j].isRequired});
                            }
                        }
                    }
                }
                component.set('v.fieldSet4',fs2Map);
                component.set('v.fieldSet3',fs1Map);
                component.set("v.isRtAvailable",false);
                component.set('v.requiredFields',reqFieldSet);
            }
            $A.util.removeClass(component.find("mySpinner") , "slds-show");
            $A.util.addClass(component.find("mySpinner") , "slds-hide");
        });
        $A.enqueueAction(action); 
       
   },
})