({
    doInit: function(component, event, helper) {
        if(component.getType().split(':')[0] != 'c'){
            component.set('v.namespaceString',component.getType().split(':')[0]+'__');
        }
        helper.fetchPl(component);
    },

    onSingleSelectChange: function(component, event, helper) {
        helper.fetchPl(component);
    },
    deleteRevenueAcc : function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner") , "slds-hide");
        $A.util.addClass(component.find("mySpinner") , "slds-show");
        
        helper.removeAccHelper(component, event);
    },
    confimationBox : function(component, event, helper) {
        var modalBody;
        $A.createComponent("c:Pl_Account_Delete_Confirmation_Box", {"accId" : event.currentTarget.dataset.id},
            function(content, status) {
                if (status === "SUCCESS") {

                    modalBody = content;

                    component.find('overlayLib').showCustomModal({
                        header: "Delete Account",
                        body: $A.get("$Label.c.PL_Account_Delete_Message"),
                        footer : modalBody,
                        showCloseButton: true,
                        cssClass: "mymodal",
                        closeCallback: function() {

                        }

                    });
                }
            });
    },
    changeTimeFrame: function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner"), "slds-hide");
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var tFrame = event.getParam("message");
        var viewVal = component.get('v.filterType');
        component.set('v.timeFrame', tFrame);
        var dateRangeKey = 'dateRange' + ':' + tFrame;
        var dateRangeValue = localStorage.getItem(dateRangeKey);
        var action = component.get("c.applyTimeFrame");
        action.setParams({
            timeFrame: tFrame,
            view: viewVal,
            dateRangesAttr : dateRangeValue,
        });
        action.setCallback(this, function(response) {
            component.set('v.plStatement', response.getReturnValue().plsWrapper);
            component.set('v.plStatementHeader', response.getReturnValue().tableHeader);
            component.set('v.dateRange', response.getReturnValue().dateRange);
            component.set('v.monthAndYearList', response.getReturnValue().monthAndYearList);
            component.set('v.showdDetail', []);
            var timeFrameVal = component.get('v.timeFrame');
            var dateRange = response.getReturnValue().dateRange;
            var startYear = response.getReturnValue().startYear;
            var endYear = response.getReturnValue().endYear;
            var dateRange = response.getReturnValue().dateRange;
            var startMonth = dateRange[startYear][0];
            var endYearArray = dateRange[endYear];
            var endMonth = dateRange[endYear][endYearArray.length-1];
            component.set('v.startMonth' , helper.getMonthLabel(startMonth , component));
            component.set('v.endMonth' , helper.getMonthLabel(endMonth , component));
            component.set('v.startYear' , startYear);
            component.set('v.endYear' , endYear);
            $A.util.removeClass(component.find("mySpinner"),"slds-show");
            $A.util.addClass(component.find("mySpinner"),"slds-hide");
        });
        $A.enqueueAction(action);
    },

    applyFilters: function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner"), "slds-hide");
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var sm = event.getParam("startMonth");
        var sy = event.getParam("startYear");
        var em = event.getParam("endMonth");
        var ey = event.getParam("endYear");
        var tFrame = component.get('v.timeFrame');
        var action = component.get("c.applyFiltersPL");
        if (tFrame == undefined) {
            tFrame = 'Month';
        }
        var viewVal = component.get('v.filterType');
        action.setParams({
            startMonth: sm,
            endMonth: em,
            startYear: sy,
            endYear: ey,
            timeFrame: tFrame,
            view: viewVal
        });
        action.setCallback(this, function(response) {
            component.set('v.plStatement', response.getReturnValue().plsWrapper);
            component.set('v.plStatementHeader', response.getReturnValue().tableHeader);
            component.set('v.dateRange', response.getReturnValue().dateRange);
            component.set('v.monthAndYearList', response.getReturnValue().monthAndYearList);
            component.set('v.showdDetail', []);
            var startYear = response.getReturnValue().startYear;
            var endYear = response.getReturnValue().endYear;
            component.set('v.startYear' , startYear);
            component.set('v.endYear' , endYear);
            var dateRange = response.getReturnValue().dateRange;
            var startMonth = dateRange[startYear][0];
            var endYearArray = dateRange[endYear];
            var endMonth = dateRange[endYear][endYearArray.length-1];
            component.set('v.startMonth' , helper.getMonthLabel(startMonth , component));
            component.set('v.endMonth' , helper.getMonthLabel(endMonth , component));
            var dateRangeKey = 'dateRange' + ':' + tFrame;
            localStorage.setItem(dateRangeKey , JSON.stringify(response.getReturnValue().dateRange));
            $A.util.removeClass(component.find("mySpinner"),"slds-show");
            $A.util.addClass(component.find("mySpinner"),"slds-hide");
        });
        $A.enqueueAction(action);
    },

    coulmnExpand: function(component, event, helper) {
        var headerList = component.get('v.plStatementHeader');
        var target = event.currentTarget;
        var columnIndex = target.getAttribute("data-conId");
        if (headerList[columnIndex].expanded == true) {
            headerList[columnIndex].expanded = false;
        } else {
            headerList[columnIndex].expanded = true;
        }
        component.set('v.plStatementHeader', headerList);
        var plList = component.get('v.plStatement');
        var plsw;
        for (plsw of plList) {
            if (plsw.pls.valuesList[columnIndex].columnExpanded == true) {
                plsw.pls.valuesList[columnIndex].columnExpanded = false;
            } else {
                plsw.pls.valuesList[columnIndex].columnExpanded = true;
            }
        }
        component.set('v.plStatement', plList);
        var target = event.currentTarget;
        var month = target.getAttribute("data-conId");
        var arr = component.get('v.showdDetail', month);
        if (arr[month]) {
            arr[month] = false;
        } else {
            arr[month] = true;
        }
        component.set('v.showdDetail', arr);
    },

    expandRow: function(component, event, helper) {
        var alreadyClicked = component.get('v.isExpanded');
        if (!alreadyClicked) {
            component.set('v.isExpanded', true);
            var target = event.currentTarget;
            var glcodeAndIndex = target.getAttribute("data-conId");
            var glCodeId = glcodeAndIndex.split(':')[0];
            var childclass = glCodeId + '_child';
            var chileElements = document.getElementsByClassName(
                childclass);
            var isAlreadyExpanded = document.getElementById(glCodeId +
                '_dash');
            var parentIndex = target.getAttribute("data-parentIndex");
            var isTotal = target.getAttribute("data-type");
            var index = parseInt(glcodeAndIndex.split(':')[1]);
            var tempIndex = parseInt(glcodeAndIndex.split(':')[1]);
            if (parentIndex == null && isTotal == null) {
                if (chileElements.length > 0 || isAlreadyExpanded !=
                    null) {
                    var plList = component.get('v.plStatement');
                    var index = parseInt(glcodeAndIndex.split(':')[1]);
                    var element;
                    for (element of chileElements) {
                        element.classList.toggle("slds-hide");
                    }
                    if (element != null && element.classList.contains(
                            "slds-hide")) {
                        plList[index].isExpanded = false;
                        plList[index].pls.noOfChildRecords = 0;
                        var indexExpanded = plList[tempIndex].wrapId;
                        var expandedRowArr = new Set(component.get(
                            'v.expandedRows'));
                        expandedRowArr.delete(indexExpanded);
                        component.set('v.expandedRows', expandedRowArr);
                    } else if (element != null && !element.classList.contains(
                            "slds-hide")) {
                        plList[index].isExpanded = true;
                        plList[index].pls.noOfChildRecords = element.length;
                        var indexExpanded = plList[tempIndex].wrapId;
                        var expandedRowArr = new Set(component.get(
                            'v.expandedRows'));
                        expandedRowArr.add(indexExpanded);
                        component.set('v.expandedRows', expandedRowArr);
                    } else {
                        plList[index].isExpanded = false;
                        plList[index].pls.noOfChildRecords = 0;
                        var indexExpanded = plList[tempIndex].wrapId;
                        var expandedRowArr = new Set(component.get(
                            'v.expandedRows'));
                        expandedRowArr.delete(indexExpanded);
                        component.set('v.expandedRows', expandedRowArr);
                    }
                    component.set('v.plStatement', plList);
                } else {
                    $A.util.removeClass(component.find("mySpinner"),
                        "slds-hide");
                    $A.util.addClass(component.find("mySpinner"),
                        "slds-show");
                    var action = component.get("c.addPL");
                    var parentIndex = target.getAttribute("data-wrapId");
                    var plList = component.get('v.plStatement');
                    var viewVal = component.get('v.filterType');
                    var tFrame = component.get('v.timeFrame');
                    var dateRange = component.get('v.dateRange');
                    action.setParams({
                        glCode: glcodeAndIndex.split(':')[0],
                        view: viewVal,
                        parentIndex: parentIndex,
                        dateRangesAttr: dateRange,
                        monthAndYearListAttr: component.get(
                            'v.monthAndYearList'),
                        timeFrame: tFrame
                    });
                    action.setCallback(this, function(response) {
                        var plResponse = response.getReturnValue();
                        var columnExpanded = component.get(
                            'v.showdDetail');
                        plList[index].isExpanded = true;
                        plList[index].pls.noOfChildRecords =
                            plResponse.length;
                        for (var pls of plResponse) {
                            for (var i in columnExpanded) {
                                if (columnExpanded[i] == true) {
                                    pls.pls.valuesList[i].columnExpanded =
                                        true;
                                }
                            }
                            plList.splice(index + 1, 0, pls);
                            index++;
                        }
                        if (plResponse.length > 0) {
                            var indexExpanded = plList[
                                tempIndex].wrapId;
                            var expandedRowArr = new Set(
                                component.get(
                                    'v.expandedRows'));
                            expandedRowArr.add(indexExpanded);
                            component.set('v.expandedRows',
                                expandedRowArr);
                        }
                        component.set('v.plStatement', plList);
                        component.set('v.isExpanded', false);
                        $A.util.removeClass(component.find(
                            "mySpinner"), "slds-show");
                        $A.util.addClass(component.find(
                            "mySpinner"), "slds-hide");
                    });
                    $A.enqueueAction(action);
                }
            }
            component.set('v.isExpanded', false);
        }
    },

    collapsRow: function(component, event, helper) {
        var target = event.currentTarget;
        var glcodeAndIndex = target.getAttribute("data-conId");
        var index = parseInt(glcodeAndIndex.split(':')[1]);
        var plList = component.get('v.plStatement');
        plList[index].isExpanded = false;
        plList[index].pls.noOfChildRecords = 0;
        var glCodeId = glcodeAndIndex.split(':')[0];
        component.set('v.plStatement', plList);
        var childclass = glCodeId + '_child';
        var chileElements = document.getElementsByClassName(childclass);
        for (var element of chileElements) {
            element.classList.toggle("slds-hide");
        }
        var indexExpanded = plList[index].wrapId;
        var expandedRowArr = new Set(component.get('v.expandedRows'));
        expandedRowArr.delete(indexExpanded);
        component.set('v.expandedRows', expandedRowArr);
    },

    inLineEditSave: function(component, event, helper) {
        var target = event.currentTarget;
        var amount = target.getAttribute("data-value");
        if(amount != 'null'){
            $A.util.removeClass(component.find("mySpinner"), "slds-hide");
            $A.util.addClass(component.find("mySpinner"), "slds-show");
            var index = target.getAttribute("data-row");
            var attributes = target.getAttribute("data-accounIdAndMonth").split(':');
            var accountId = attributes[0];
            var month = parseInt(attributes[1]);
            var dataColumn = target.getAttribute("data-column");
            var year = target.getAttribute("data-year");
            var fieldName = target.getAttribute("data-name");
            var index = target.getAttribute("data-row");
            var glcode = target.getAttribute("data-glcode");
            var viewVal = component.get('v.filterType');
            var action = component.get("c.savePL");
            var plList = component.get('v.plStatement');
            var yearList = component.get('v.yearsTobeFetched');
            var isActual;
            if (fieldName == 'inLineEditActual') {
                isActual = true;
            } else if (fieldName == 'inLineEditForecast') {
                isActual = false;
            }
            var expandedRowArr = Array.from(component.get('v.expandedRows'));
            var dateRange = component.get('v.dateRange');
            action.setParams({
                'AccountId': accountId,
                'month': month,
                'isActual': isActual,
                'amount': amount,
                'year': year,
                'glcode': glcode,
                dateRangesAttr: dateRange,
                monthAndYearListAttr: component.get('v.monthAndYearList'),
                expandedRowsList: expandedRowArr,
                yearListAttr : yearList,
                view : viewVal
            });
            action.setCallback(this, function(response) {
                if (response.getReturnValue() != null) {
                    var plList = response.getReturnValue().plsWrapper;
                    var columnExpanded = component.get('v.showdDetail');
                    for (var pls of plList) {
                        for (var i in columnExpanded) {
                            if (columnExpanded[i] == true) {
                                pls.pls.valuesList[i].columnExpanded = true;
                            }
                        }
                    }
                    component.set('v.plStatement', plList);
                    var fieldUpdated = index + ':' + dataColumn + ':' + fieldName;
                    component.set('v.FieldIdUpdated', fieldUpdated);
                } else {
                    helper.getNewAllocation(component,accountId,glcode,month,year,amount,isActual,index,dataColumn,fieldName);
                }
                $A.util.removeClass(component.find("mySpinner"),"slds-show");
                $A.util.addClass(component.find("mySpinner"),"slds-hide");
            });
            $A.enqueueAction(action);
        }
        else{
            var staticLabel = $A.get("$Label.c.Please_enter_a_valid_amount");
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "title": "Error!",
                "message": staticLabel
            });
            toastEvent.fire();
        }
    },

    viewChange: function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner"), "slds-hide");
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var filterType = event.getParam("filterType");
        var isExpandNeeded = filterType.toLowerCase() == 'actuals to date & forecast';
        component.set("v.isExpandNeeded", isExpandNeeded);

        if(!isExpandNeeded){
            var headerList = component.get('v.plStatementHeader');
            for(var a=0;a<headerList.length;a++){
                headerList[a].expanded = false;
            }
            component.set('v.plStatementHeader', headerList);

            var plList = component.get('v.plStatement');
            var plsw;
            for (plsw of plList) {
                if(plsw.pls.valuesList && plsw.pls.valuesList.length){
                    for(var i=0;i<plsw.pls.valuesList.length;i++){
                        plsw.pls.valuesList[i].columnExpanded = false;    
                    }
                }
            }
            component.set('v.plStatement', plList);

            var arr = component.get('v.showdDetail');
            if(arr && arr.length){
                for(var b=0;b<arr.length;b++){
                    arr[b] = false;
                }
            }
            component.set('v.showdDetail', arr);
        }
        component.set('v.filterType', filterType);
        var action = component.get("c.changeview");
        var plList = component.get('v.plStatement');
        action.setParams({
            'view': filterType,
            'plsWrapperList': JSON.stringify(plList)
        });
        action.setCallback(this, function(response) {
            component.set('v.plStatement', response.getReturnValue());
            $A.util.removeClass(component.find("mySpinner"),
                "slds-show");
            $A.util.addClass(component.find("mySpinner"),
                "slds-hide");
        });
        $A.enqueueAction(action);
    },

    openAccount: function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner"), "slds-hide");
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        var target = event.currentTarget;
        var recordId = target.getAttribute("data-conId");
        component.set('v.historyListSplit', '');
        component.set('v.sobjectApiName', '');
        component.set('v.fieldSet1', '');
        component.set('v.fieldSet2', '');
        component.set('v.recordId', '');
        helper.getSplitScreenData(component, event, recordId);
        var cmpTarget = component.find('mainComponent');
        $A.util.addClass(cmpTarget, 'width60');
        var cmpTarget = component.find('recordDetail');
        component.set("v.isAddNew", false);
        $A.util.removeClass(cmpTarget, 'slds-hide');
        $A.util.removeClass(component.find("tabLayout"), "slds-hide");
        $A.util.addClass(component.find("tabLayout"), "slds-show");
        $A.util.addClass(component.find("newAccount"), "slds-hide");
        document.getElementById('recordDetail').scrollIntoView(true);

    },
    closeSplit: function(component, event, helper) {
        var cmpTarget = component.find('mainComponent');
        $A.util.removeClass(cmpTarget, 'width60');
        var cmpTarget = component.find('filterComponent');
        $A.util.removeClass(cmpTarget, 'width60');
        var cmpTarget = component.find('recordDetail');
        $A.util.addClass(cmpTarget, 'slds-hide');
    },
    inlineEdit: function(component, event, helper) {
        var timeFrame = component.get('v.timeFrame');
        if (timeFrame == 'Month') {
            var target = event.currentTarget;
            var fieldName = target.getAttribute("data-name");
            var index = target.getAttribute("data-row");
            var month = parseInt(target.getAttribute("data-month"));
            var plList = component.get('v.plStatement');
            plList[index].isEdited = true;
            if (fieldName == 'inLineEditActual') {
                plList[index].pls.valuesList[month].inlineEditActual =
                    true;
                plList[index].pls.valuesList[month].actualold = plList[
                    index].pls.valuesList[month].actual;
                if (plList[index].pls.valuesList[month].actual == 0)
                    plList[index].pls.valuesList[month].actual = null;
            } else if (fieldName == 'inLineEditForecast') {
                plList[index].pls.valuesList[month].inlineEditForecast =
                    true;
                plList[index].pls.valuesList[month].forecastOld =
                    plList[index].pls.valuesList[month].forecast;
                if (plList[index].pls.valuesList[month].forecast == 0)
                    plList[index].pls.valuesList[month].forecast = null;
            }
            component.set('v.plStatement', plList);
        }
    },

    inLineEditCancel: function(component, event, helper) {
        var target = event.currentTarget;
        var fieldName = target.getAttribute("data-name");
        var plList = component.get('v.plStatement');
        var index = target.getAttribute("data-row");
        var month = parseInt(target.getAttribute("data-month"));
        if (fieldName == 'inLineEditActual') {
            plList[index].pls.valuesList[month].inlineEditActual =
                false;
            plList[index].pls.valuesList[month].actual = plList[index].pls
                .valuesList[month].actualold;
        } else if (fieldName == 'inLineEditForecast') {
            plList[index].pls.valuesList[month].inlineEditForecast =
                false;
            plList[index].pls.valuesList[month].forecast = plList[index]
                .pls.valuesList[month].forecastOld;
        }
        component.set('v.plStatement', plList);
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
    handleSuccess : function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner") , "slds-show");
        $A.util.addClass(component.find("mySpinner") , "slds-hide");
        var payload = event.getParams().response;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The record has been updated successfully.",
            "type" : "success"
        });
        toastEvent.fire();
        helper.fetchPlWithFilteredData(component);
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
    handleRelatedComponentEvent: function(component, event, helper) {
        $A.util.addClass(component.find("mySpinner") , "slds-show");
        $A.util.removeClass(component.find("mySpinner") , "slds-hide");
        //alert("refresh from parent")
        var recordId = event.getParam("recordId");
        var message = event.getParam("message");
        if(message === 'openED'){
            component.set('v.sobjectApiName','');
            component.set('v.fieldSet1','');
            component.set('v.fieldSet2','');
            component.set('v.recordId','');
            helper.getSplitScreenData(component, event,recordId);
        } 
        else if(message==='refresh'){
            helper.fetchPlWithFilteredData(component);
        }
        //component.set('v.recordId',message);
    },
    handleHistoryInSplit: function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner") , "slds-hide");
        $A.util.addClass(component.find("mySpinner") , "slds-show");
        var target = event.currentTarget;
        var recordId = target.getAttribute("data-conId");
        var historyList = new Array();
        historyList = component.get('v.historyListSplit');
        var istrue = 'false';
        for(var i=0;i<historyList.length;i++){
            if(historyList[i].key === recordId){
                historyList.splice(i+1, historyList.length);
                break;
            }
        }
        var target = event.currentTarget;
        var recordId = target.getAttribute("data-conId");
        /*window.open('/' + recordId);  */
        component.set('v.sobjectApiName','');
        component.set('v.fieldSet1','');
        component.set('v.fieldSet2','');
        component.set('v.recordId','');
        helper.getSplitScreenData(component,event,recordId);
    },
    addAccount: function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner") , "slds-hide");
        $A.util.addClass(component.find("mySpinner") , "slds-show");
        var target = event.currentTarget;

        var glCodeIndex = target.getAttribute("data-conId");
        component.set('v.glCodeId',glCodeIndex);
        var action = component.get("c.getPLCategoryType");
        action.setParams({ recordId : glCodeIndex });
        component.set('v.showRelated',false);

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS" ) {

                component.set('v.isAddNew',false);
                component.set('v.isAddNew',true);
                var PlCateforyType = response.getReturnValue();
                component.set('v.sobjectApiName',PlCateforyType.sobjectType);
                component.set('v.sobjectApiLabel',PlCateforyType.sobjectLabel);
                
                var rtInfo = new Array();
                var rtRadio = new Array();
                rtInfo = PlCateforyType.rtInfoList;
                console.log(rtInfo);
                if(rtInfo.length >0){
                    component.set("v.isRTAvailable",true);
                    for(var i = 0; i<rtInfo.length;i++){
                        if(rtInfo[i].Description != undefined){
                            rtRadio.push({'label': rtInfo[i].rtName+'\n('+rtInfo[i].Description+')', 'value': rtInfo[i].rtId});
                        }
                        else{
                            rtRadio.push({'label': rtInfo[i].rtName, 'value': rtInfo[i].rtId});
                        }
                    	
                    }
                	component.set("v.lstOfRecordType", rtRadio);
                	component.set("v.selectedValue",rtInfo[0].rtId);
                }
                else{
                    //component.set("v.isRTAvailable",false);
                    helper.fetchPageLayout(component, event,null);
                }
            }
            $A.util.removeClass(component.find("mySpinner") , "slds-show");
            $A.util.addClass(component.find("mySpinner") , "slds-hide");
        });
        $A.enqueueAction(action); 
        //helper.getSplitScreenData(component,event,recordId);
        
        var cmpTarget = component.find('mainComponent');
        console.log(cmpTarget);
        $A.util.addClass(cmpTarget, 'width60');
        var cmpTarget = component.find('recordDetail');
        console.log(cmpTarget);
        $A.util.removeClass(cmpTarget, 'slds-hide');
        document.getElementById('recordDetail').scrollIntoView(true);
        
    },
    handleSuccessNew :function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner") , "slds-show");
        $A.util.addClass(component.find("mySpinner") , "slds-hide");
        var payload = event.getParams().response;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The record has been created successfully.",
            "type" : "success"
        });
        toastEvent.fire();
        helper.getSplitScreenData(component,event,payload.id);
    },

    createRecord :function(component, event, helper) {
        $A.util.removeClass(component.find("mySpinner") , "slds-hide");
        $A.util.addClass(component.find("mySpinner") , "slds-show");
        //515 /CPM-569
        var recordTypeId = component.get('v.selectedValue');
        var lstOfRecordType = component.get('v.lstOfRecordType');
        for(var i in lstOfRecordType){
            if(lstOfRecordType[i].value == recordTypeId){ 
                var labelWithRecordTypeName = '';
                if(lstOfRecordType[i].label.includes('(')){
                    labelWithRecordTypeName = lstOfRecordType[i].label.split('(')[0] +' - ';
                }else{
                    labelWithRecordTypeName = lstOfRecordType[i].label+' - ';
                }
               component.set('v.selectedRecordTypeName',labelWithRecordTypeName);
            }
        }
        helper.fetchPageLayout(component, event, recordTypeId);
        
    },
    
    onRender: function(component, event, helper) {
        var elementId = component.get('v.FieldIdUpdated');
        if (elementId) {
            var element = document.getElementById(component.get(
                'v.FieldIdUpdated'));
            if(element){
                if (element.classList.contains('FocusIn')) {
                    element.classList.remove('FocusIn');
                    component.set('v.FieldIdUpdated', '');
                } else {
                    element.className += " " + 'FocusIn';
                }
            }
        }
    },
    closeModal: function(component, event, helper) {
        // set "isOpen" attribute to false for hide/close model box 
        component.set("v.isOpen", false);
    },
    handleSuccessAllocation :function(component, event, helper) {
        
        var action = component.get("c.saveAllocation");
        var plList = component.get('v.plStatement');
        var yearList = component.get('v.yearsTobeFetched');
        var expandedRowArr = Array.from(component.get('v.expandedRows'));
        var dateRange = component.get('v.dateRange');
        action.setParams({
            dateRangesAttr: dateRange,
            monthAndYearListAttr: component.get('v.monthAndYearList'),
            expandedRowsList: expandedRowArr,
            yearListAttr : yearList
        });
        action.setCallback(this, function(response) {
            console.log(response);
            if (response.getReturnValue() != null) {
                var plList = response.getReturnValue().plsWrapper;
                var columnExpanded = component.get('v.showdDetail');
                for (var pls of plList) {
                    console.log(1+pls);
                    for (var i in columnExpanded) {
                        if (columnExpanded[i] == true) {
                            console.log(pls);
                            pls.pls.valuesList[i].columnExpanded = true;
                        }
                    }
                }
                component.set('v.plStatement', plList);
                var fieldUpdated = component.get('v.index') + ':' + component.get('v.dataColumn') + ':' + component.get('v.fieldName');
        		component.set('v.FieldIdUpdated', fieldUpdated);
                $A.util.removeClass(component.find("mySpinner") , "slds-show");
        		$A.util.addClass(component.find("mySpinner") , "slds-hide");
            }
        });
        $A.enqueueAction(action);
        component.set("v.isOpen", false);
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "The record has been created successfully.",
            "type" : "success"
        });
        toastEvent.fire();
        
    },
    onSuccess : function(component, event, helper){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            message: $A.get('$Label.c.AssumptionSuccess'),
            type : 'success'
        });
        toastEvent.fire();
    },
    onError : function(component, event, helper){
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title: "Error!",
            type: "error",
            message: $A.get('$Label.c.ErrorInAssumptionSave')
        });
        toastEvent.fire();
    },
    closeNav : function(component, event, helper){
        document.getElementById("mySidenav").style.width = "0";
        component.set("v.showAssumption", false);
    },
    openNav : function(component, event, helper){
        var showAssumption = !component.get("v.showAssumption");
        component.set("v.showAssumption", showAssumption);
        if(showAssumption){
            document.getElementById("mySidenav").style.width = "30rem";
        }
        else{
            document.getElementById("mySidenav").style.width = "0";
        }
    },
    onLoad : function(component, event, helper){
        var recUi = event.getParam("recordUi");
    }
})