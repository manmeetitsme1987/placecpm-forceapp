({
    fetchPl : function(component , paymentAccountIdList) {
        $A.util.removeClass(component.find("mySpinner") , "slds-hide");
        $A.util.addClass(component.find("mySpinner") , "slds-show");
        var action = component.get("c.getPLStatement");
        var timeFrameVal = component.get('v.timeFrame');
        var dateRangeKey = 'dateRangeCash' + ':' + timeFrameVal;
        var dateRangeValue = localStorage.getItem(dateRangeKey);
        if(dateRangeValue)
        action.setParams({dateRangesAttr : dateRangeValue});
        if(paymentAccountIdList !=null){
            action.setParams({paymentAccountIdList : paymentAccountIdList});
        }
        var buttonNames = new Array();
        buttonNames.push({'label': $A.get("$Label.c.Acutal_Forecast_UTD") , 'value': $A.get("$Label.c.Acutal_Forecast_UTD") , selected:true});
        buttonNames.push({'label': $A.get("$Label.c.Only_Forecast") , 'value': $A.get("$Label.c.Only_Forecast")});
        buttonNames.push({'label': $A.get("$Label.c.Only_Actual") , 'value': $A.get("$Label.c.Only_Actual")});
        buttonNames.push({'label': 'Variance' , 'value': 'Variance'});
        component.set("v.buttonListForecast", buttonNames);
        component.set("v.viewValue", $A.get("$Label.c.Acutal_Forecast_UTD"));
        action.setCallback(this, function(response) {
            component.set('v.plStatement' , response.getReturnValue().plsWrapper);
            component.set('v.plStatementHeader' , response.getReturnValue().tableHeader);
            component.set('v.dateRange' , response.getReturnValue().dateRange);
            component.set('v.monthAndYearList' , response.getReturnValue().monthAndYearList);
            component.set('v.yearList' , response.getReturnValue().years);
            component.set('v.currentYear' , response.getReturnValue().currentYear);
            component.set('v.yearsTobeFetched' , response.getReturnValue().yearsTobeFetched);
            var startYear = response.getReturnValue().startYear;
            var endYear = response.getReturnValue().endYear;
            var dateRange = response.getReturnValue().dateRange;
            component.set('v.startYear' , startYear);
            component.set('v.endYear' , endYear);
            component.set('v.dateRange' , dateRange);
            var startMonth = dateRange[startYear][0];
            var endYearArray = dateRange[endYear];
            var endMonth = dateRange[endYear][endYearArray.length-1];
            component.set('v.startMonth' , this.getMonthLabel(startMonth , component));
            component.set('v.endMonth' , this.getMonthLabel(endMonth , component));
            component.set('v.minyearStart' , response.getReturnValue().years[0]);
            component.set('v.minyearEnd' , response.getReturnValue().years[0]);
            var length = response.getReturnValue().years.length;
            component.set('v.maxYearStart' , response.getReturnValue().years[length-1]);
            component.set('v.maxYearEnd' , response.getReturnValue().years[length-1]);
            component.set("v.ForecastAndActualViewButtom", buttonNames);
            $A.util.removeClass(component.find("mySpinner") , "slds-show");
            $A.util.addClass(component.find("mySpinner") , "slds-hide");
        });
        $A.enqueueAction(action); 
    },
    
    fetchPlWithFilteredData : function(component  , paymentAccountIdList) {
        $A.util.removeClass(component.find("mySpinner") , "slds-hide");
        $A.util.addClass(component.find("mySpinner") , "slds-show");
        var action = component.get("c.getPLStatementWithFilterAndExpansion");
        var viewVal= component.get('v.filterType');
        var timeFrameVal = component.get('v.timeFrame');
        var dateRangesAttrVal = component.get('v.dateRange');
        var monthAndYearListAttrVal = component.get('v.monthAndYearList');
        var expandedRowsListVal;
        if(component.get('v.expandedRows') != null){
            expandedRowsListVal = Array.from(component.get('v.expandedRows'));
        }
        var yearList = component.get('v.yearsTobeFetched');
        action.setParams({ view : viewVal , 
            timeFrame : timeFrameVal, 
            dateRangesAttr : dateRangesAttrVal, 
            monthAndYearListAttr : monthAndYearListAttrVal, 
            expandedRowsList : expandedRowsListVal,
            yearListAttr : yearList,
            paymentAccIdList : paymentAccountIdList
        });        
        action.setCallback(this, function(response) {
            component.set('v.plStatement' , response.getReturnValue().plsWrapper);
            component.set('v.plStatementHeader' , response.getReturnValue().tableHeader);
            $A.util.removeClass(component.find("mySpinner") , "slds-show");
            $A.util.addClass(component.find("mySpinner") , "slds-hide");
        });
        $A.enqueueAction(action); 
    },
    
    getSplitScreenData : function(component,event,recordId) {
        var action = component.get("c.getSplitScreenData");
        action.setParams({ recordId : recordId });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS" ) {
                var plResponse = response.getReturnValue();
                console.log('plResponse'+plResponse);
                var historyList = new Array();
                var found = false;
                historyList =  component.get('v.historyListSplit');
                for(var i=0;i<historyList.length;i++){
                    if(historyList[i].key === recordId){
                        found = true;
                        break;
                    }
                }
                if(!found){
                    historyList.push({value:plResponse.sobjectLabel, key:recordId});
                }
                
                component.set('v.historyListSplit',historyList);
                component.set('v.sobjectApiName',plResponse.sobjectType);
                component.set('v.requiredFields',plResponse.requiredFields);
                
                //563
                var layoutInfo = new Array();
                var fs1Map = [];
                var fs2Map = [];
                var reqFieldSet = new Array();
                layoutInfo = plResponse.editPageInfo;
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
                component.set('v.fieldSet2',fs2Map);
                component.set('v.fieldSet1',fs1Map);
                component.set('v.requiredFields',reqFieldSet);
                component.set('v.recordId',recordId);
                
                var updatedList = new Array();
                var relatedInfo = new Array();
                relatedInfo = plResponse.relatedListWrap;
                
                if(relatedInfo.length>0 && relatedInfo != null){
                    
                    for(var i = 0; i<relatedInfo.length;i++){
                        var fieldApinamesList = new String();
                        var fieldDetails = new Array();
                        var fieldAttributesList = new Array();
                        var fieldDetails = relatedInfo[i].fieldAPINames;
                        for(var j = 0; j< fieldDetails.length;j++ ){
                            fieldApinamesList = fieldApinamesList + fieldDetails[j].apiName +',';
                            if(fieldDetails[j].apiName === 'Name'){
                                var fieldAttributes = {
                                    label : fieldDetails[j].label,
                                    fieldName : fieldDetails[j].apiName,
                                    type : 'button',
                                    typeAttributes: {label: { fieldName: 'Name' }, name: 'openFD'}
                                };
                            }
                            else if( fieldDetails[j].fieldType  === 'CURRENCY'){
                                var fieldAttributes = {
                                    label : fieldDetails[j].label,
                                    fieldName : fieldDetails[j].apiName,
                                    type : 'currency',
                                };
                            }
                                else{
                                    var fieldAttributes = {
                                        label : fieldDetails[j].label,
                                        fieldName : fieldDetails[j].apiName,
                                        type : 'text',
                                    };
                                }
                            
                            fieldAttributesList.push(fieldAttributes);
                        }
                        var child = {
                            childObjectName: relatedInfo[i].childObjectName,
                            relationshipField: relatedInfo[i].relationshipField ,
                            fieldList: fieldApinamesList.slice(0, -1),
                            fieldAttributeList : fieldAttributesList
                            
                        };
                        updatedList.push(child);
                    }
                    component.set('v.showRelated',true);
                    component.set('v.listRelatedList',updatedList);                
                }
                else{
                    component.set('v.showRelated',false);
                }
                $A.util.removeClass(component.find("mySpinner") , "slds-show");
            	$A.util.addClass(component.find("mySpinner") , "slds-hide");
            }
        });
        $A.enqueueAction(action); 
    },
    
    fetchPageLayout :function(component,event,recordTypeId){
        var action = component.get("c.getEditPageLayoutSections");
        action.setParams({ sObjectName : component.get('v.sobjectApiName'),
                          recordTypeId : recordTypeId});
        
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
                component.set('v.isAddNew',false);
                component.set('v.isAddNew',true);
                component.set("v.isRTAvailable",false);
                component.set('v.requiredFields',reqFieldSet);
            }
            $A.util.removeClass(component.find("mySpinner") , "slds-show");
            $A.util.addClass(component.find("mySpinner") , "slds-hide");
        });
        $A.enqueueAction(action); 
    },
    removeAccHelper : function(component, event) {
        var action = component.get("c.removeAcc");
        action.setParams({
            'recId' : event.getParam("accId")
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === 'SUCCESS') {
                var toastEvent = $A.get("e.force:showToast");
                if(response.getReturnValue() == null) {
                    this.fetchPlWithFilteredData(component);
                    toastEvent.setParams({
                        "type ": "success",
                        "message": $A.get('$Label.c.Successfully_Delete_Mesaage')
                    });
                } else {
                    let fieldCustom = $A.get('$Label.c.Field_Custom_validation_exception');
                    let errorToShow = response.getReturnValue();
                    if(errorToShow.includes(fieldCustom)) {
                        let startSubStrIndex = errorToShow.indexOf(fieldCustom) + fieldCustom.length +1 ;
                        let endSubStrIndex = errorToShow.length - 4;
                          errorToShow = errorToShow.substring(startSubStrIndex, endSubStrIndex);
                    }
                    toastEvent.setParams({
                        "title": "Error!",
                        "type ": "error",
                        "message": errorToShow
                    });
                    $A.util.removeClass(component.find("mySpinner") , "slds-show");
                    $A.util.addClass(component.find("mySpinner") , "slds-hide");
                }
                toastEvent.fire();
            }
        });
        $A.enqueueAction(action);
    },
    getMonthLabel : function(selectedMonth , component) {
        var monthLabel;
        var timeFrame = component.get('v.timeFrame');
        if(timeFrame == 'Month'){
            switch(selectedMonth) {
                case 1 : {
                    monthLabel = 'January';
                    break;
                }      
                case 2 : {
                    monthLabel = 'February';
                    break;
                }
                case 3 : {
                    monthLabel = 'March';
                    break;
                }
                case 4 : {
                    monthLabel = 'April';
                    break;
                }
                case 5 : {
                    monthLabel = 'May';
                    break;
                }
                case 6 : {
                    monthLabel = 'June';
                    break;
                }
                case 7 : {
                    monthLabel = 'July';
                    break;
                }
                case 8 : {
                    monthLabel = 'August';
                    break;
                }
                case 9 : {
                    monthLabel = 'September';
                    break;
                }
                case 10 : {
                    monthLabel = 'Ocotober';
                    break;
                }
                case 11 : {
                    monthLabel = 'November';
                    break;
                }
                case 12 : {
                    monthLabel = 'December';
                    break;
                }
            }
        }
         if(timeFrame == 'Quarter'){
            switch(selectedMonth) {
                case 1 : {
                    monthLabel = 'Q1';
                    break;
                }      
                case 2 : {
                    monthLabel = 'Q2';
                    break;
                }
                case 3 : {
                    monthLabel = 'Q3';
                    break;
                }
                case 4 : {
                    monthLabel = 'Q4';
                    break;
                }
            }
        }
        return monthLabel;
    }
})