({
	
    fetchExistingQuotas: function( component ) {
        var action = component.get( "c.fetchAllData" );
        action.setCallback( this, function( response ) {
            var state = response.getState();
            if ( state === "SUCCESS" ) {
                
                var response = response.getReturnValue();
                var quotaresponse = response.quotaList;
                console.log('quotaresponse:'+quotaresponse);
                var typeMap = response.mapOfTypePicklist;
                var options = [];
                var i = 0;
                for(var key in typeMap){
                    if(quotaresponse.length > 0 && quotaresponse[0].Type__c == typeMap[key]){
                        options.push({value:typeMap[key] , label:key , selected:"true"});
                        component.set('v.typeValue' , quotaresponse[0].Type__c);
                    }
                    else
                    options.push({value:typeMap[key] , label:key});
                    if(quotaresponse.length == 0 && i++==0){
                        options[0].selected="true";
                        component.set('v.typeValue' , options[0].value);
                    }
                }
                component.set("v.options", options);
                component.set("v.quotaScheduleList", quotaresponse);
                component.set("v.forecastDuration", response.forecastDuration);
            }
        });
        $A.enqueueAction(action);  
    },
    
    addQuotaSchedule : function( component ) {
        var action = component.get( "c.addQuotaSchedule" );
        action.setCallback( this, function( response ) {
            
            var state = response.getState();
            if ( state === "SUCCESS" ) {
                var newQuota = response.getReturnValue();
                var quotaList = component.get( "v.quotaScheduleList" );
                quotaList.push(newQuota);
                component.set("v.quotaScheduleList", quotaList);  
            }
        } );
        $A.enqueueAction(action);  
    },
    
    createQuotaSchedule : function( component, event, helper ) {
        
        var isValid = true;
        var wrappers = component.get( "v.quotaScheduleList" );
        var forecastDuration = parseInt(component.get( "v.forecastDuration"));
        var selectedType = component.get("v.typeValue");
        var allowedRange = forecastDuration/selectedType;
        var errorMessage = '';
        //#102
        for(var key=0; key< wrappers.length;key++){
            	  if(wrappers[key].Range_Start__c !== undefined && wrappers[key].Range_Start__c != null &&
                     wrappers[key].Range_Start__c != 0 && wrappers[key].Quota_Amount__c !== undefined 
                     && wrappers[key].Quota_Amount__c != null){
                      
                      if(wrappers[key].Quota_Amount__c >= 0){
                         if(key != 0){
                          var endRange = parseInt(wrappers[key].Range_Start__c) -1;
                          wrappers[key-1].Range_End__c = endRange.toString();
                        }
                        wrappers[key].Range_End__c = '';
                        isValid = true; 
                      }else{
                          isValid = false; 
                          errorMessage = $A.get("$Label.c.Quota_Amount_greater_than_zero");
                    	  break;
                      }
                        
                }else if(wrappers[key].Range_Start__c == 0){
                    isValid = false;
                    errorMessage = $A.get("$Label.c.Error_Range_Start_cannot_be_zero");
                    break;
                }else{
                    isValid = false;
                    errorMessage = $A.get("$Label.c.Invalid_range_error");
                    break;
                }
        }
        if(isValid){
            var action = component.get( "c.createQuotaSchedule" );
            action.setParams({
                "quotaList": component.get( "v.quotaScheduleList" ),
                "typeValue" : component.get("v.typeValue")
            });
            action.setCallback( this, function( response ) {
                var state = response.getState();
                if ( state === "SUCCESS" ) {
                    var message = response.getReturnValue(); 
                    if(message.includes('Success')){
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            "title": "Success!",
                            "type": "success",
                            "message": $A.get("$Label.c.Success_message_Quota_Schedule")
                        });
                        toastEvent.fire();
                       component.destroy();
                    } else {
                        component.set("v.error", true);
                        component.set("v.message", message);
                    }
                }
            } );
            $A.enqueueAction(action);
        }
        else{
            component.set("v.error", true);
            component.set("v.message", errorMessage);
        }
    },
    calculateMonthlyAmount : function(component, event,selectedValue){
        var wrappers = component.get( "v.quotaScheduleList" );
        
        for(var i=0;i<wrappers.length;i++){
            if(wrappers[i].Quota_Amount__c )
                wrappers[i].Monthly_Amount__c = Math.round(((wrappers[i].Quota_Amount__c / 12)/selectedValue)*100)/100;
            else{
                wrappers[i].Monthly_Amount__c = 0;
            }
        }
        component.set( "v.quotaScheduleList", wrappers)
        
    }
})