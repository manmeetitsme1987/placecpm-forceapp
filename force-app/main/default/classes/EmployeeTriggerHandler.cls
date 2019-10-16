/*
 * Description  : This class holds all the trigger functions for Employee object 
 *                Please write all the functions inside if it is being used more then once in the code.  
 * Date Created :
 * Change 1 : PCPM-235 | Namita | 12 July 
 * Change 2 : PCPM-316 | Namita | 22 July 
 * Change 3 : PCPM-322 | Namita | 29 August 19 
*/
public with sharing class EmployeeTriggerHandler implements CommonTriggerHandler{
    public static List<Employee_Department_Allocation__c> empDeptAllocationToBeDeleted = new List<Employee_Department_Allocation__c>();
    public static List<Quota_Schedule__c> quoataSchdule;
    public void BeforeInsert(List<SObject> newItems){
        handleBeforeInsert((List<Employee__c>)newItems);
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        handleBeforeUpdate((Map<Id, Employee__c>)newItems , (Map<Id, Employee__c>)oldItems);
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        handleBeforeDelete((Map<Id, Employee__c>)oldItems);
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        handleAfterInsert((List<Employee__c>)newItems.values() , (Map<Id, Employee__c>)newItems);
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        handleAfterUpdate((Map<Id, Employee__c>)newItems , (Map<Id, Employee__c>)oldItems);
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
        handleAfterDelete((Map<Id, Employee__c>)oldItems);
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
    public static void handleBeforeInsert(list<Employee__c> newEmployees){     
    }
    public static void handleBeforeDelete(map<Id, Employee__c> oldEmployees){
       deleteCompensation(oldEmployees);
       deleteQuotas(oldEmployees.values());
       deleteEmployeeExpenseAllocation(oldEmployees.values());
       employeeDeptAllocationDelete(oldEmployees.values());
    }
    
    public static void handleAfterDelete(map<Id, Employee__c> oldEmployees){
        deleteEmployeeDepartmentAllocation(empDeptAllocationToBeDeleted);
    }

    /*
     * This method will will run for all the before update events
     * @parameter newEmployees, Map of new Employee Id and Employee Record
     * @parameter oldEmployees, Map of old Employee Id and Employee Record
     * @returns void
    */
    public static void handleBeforeUpdate(map<Id, Employee__c> newEmployees, map<Id, Employee__c> oldEmployees){
        for(Employee__c emp : newEmployees.values()){
            if(emp.Employee_Status__c != oldEmployees.get(emp.Id).Employee_Status__c && emp.Employee_Status__c == CONSTANT.EMPLOYEE_STATUS_TERMINATED && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_OBJECT,'Employee_End_Date__c',Constant.ACTION_TYPE_UPDATE)){
                emp.Employee_End_Date__c = System.today();
            }else if(emp.Employee_Status__c != oldEmployees.get(emp.Id).Employee_Status__c && emp.Employee_Status__c == CONSTANT.EMPLOYEE_STATUS_ACTIVE && oldEmployees.get(emp.Id).Employee_Status__c == CONSTANT.EMPLOYEE_STATUS_TERMINATED && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_OBJECT,'Employee_End_Date__c',Constant.ACTION_TYPE_UPDATE)){
                emp.Employee_End_Date__c = NULL;
            }
        }
    }

    /*
     * This method will will run for all the after insert events.
     * @parameter newEmployees, List of Employee__c
     * @parameter newEmployeesMap, new map of Employee__c
     * @returns void
   */
    public static void handleAfterInsert(List<Employee__c> newEmployees, Map<Id, Employee__c> newEmployeesMap){
        try{
            List<Employee_Department_Allocation__c> listEmpDeptAllocation = new List<Employee_Department_Allocation__c>();
            //PCPM-235 | 322 | Namita
            Map<String,List<Employee__c>> roleIdToEmployeeMap = new Map<String, List<Employee__c>>();
            List<Employee__c> employeeList = new List<Employee__c>();
            List<Employee__c> quotaEmployees = new List<Employee__c>();
            Boolean isEmployee = false, isAllocationPercentage = false, isRole = false;
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_DEPARTMENT_ALLOCATION_OBJECT,'Employee__c',Constant.ACTION_TYPE_INSERT)){
                isEmployee = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_DEPARTMENT_ALLOCATION_OBJECT,'Allocation_percentage__c',Constant.ACTION_TYPE_INSERT)){
                isAllocationPercentage = true;
            }
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_DEPARTMENT_ALLOCATION_OBJECT,'Role__c',Constant.ACTION_TYPE_INSERT)){
                isRole = true;
            }

            for(Employee__c e : newEmployees){
                if(e.Is_Quota_Applicable__c){
                    quotaEmployees.add(e);
                }
                if(e.Role__c != null ){
                    Employee_Department_Allocation__c empDeptAlloc = new Employee_Department_Allocation__c();
                    if(isEmployee){
                        empDeptAlloc.Employee__c = e.Id;
                    }
                    if(isAllocationPercentage){
                        empDeptAlloc.Allocation_percentage__c = 100;
                    }
                    if(isRole){
                        empDeptAlloc.Role__c = e.Role__c;
                    }
                    listEmpDeptAllocation.add(empDeptAlloc);
                    //PCPM: 462
                    if(!roleIdToEmployeeMap.containsKey(e.Role__c)) {
                        roleIdToEmployeeMap.put(e.Role__c, new List<Employee__c>());
                    }
                    roleIdToEmployeeMap.get(e.Role__c).add(e);
                    employeeList.add(e);
                }
            }

            placeCPM_Utility.insertRecords(listEmpDeptAllocation, CONSTANT.EMPLOYEE_DEPARTMENT_ALLOCATION_OBJECT, false); //520

            Map<String,List<Expense_Account__c>> roleIdToExpenseAccountMap = new Map<String, List<Expense_Account__c>>();
            Map<String,List<Expense_Allocation__c>> empIdToExpenseAllocMap = new Map<String, List<Expense_Allocation__c>>();
            Map<String,List<Expense_Allocation__c>> roleIdToExpenseAllocationMap = new Map<String, List<Expense_Allocation__c>>();
            Map<String, Role__c> rolesMap = new Map<String, Role__c>();
            Map<String, String> orgIdToRoleMap = new Map<String, String>();
            Map<String, String> deptsIdToRoleMap = new Map<String, String>();
            Set<String> expenseAccountIds = new Set<String>(); //562
            
            // Create Map of Role and their Departments and Organisations with role Id
            // Poornima
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.ROLE_OBJECT,'Department__c',Constant.ACTION_TYPE_ACCESS)){
                for(Role__c role : [SELECT Id, Department__c, Department__r.Organisation__r.Id 
                                    FROM Role__c 
                                    WHERE Id IN: roleIdToEmployeeMap.keySet()]){
                    rolesMap.put(role.Id, role);
                    deptsIdToRoleMap.put(role.Department__c, role.Id);
                    orgIdToRoleMap.put(role.Department__r.Organisation__r.Id, role.Id);
                }
        	}
            // Create map roleIdToExpenseAllocationMap - Role Id and all the expense allocations related to that role, role's department or role's department's organisation
            // Create map roleIdToExpenseAccountMap - Role Id and all the expense accounts of expense allocations related to that role, role's department or role's department's organisation 
            // Poornima
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_ALLOCATION_OBJECT,'Id, Expense_Account__c,Organisation__c ,Department__c ,Role__c',Constant.ACTION_TYPE_ACCESS)){
                for(Expense_Allocation__c  expenseAlloc : [SELECT Id, Expense_Account__c,Expense_Account__r.Id, 
                                                           Organisation__c ,Department__c ,Role__c  
                                                           FROM Expense_Allocation__c 
                                                           WHERE Role__c IN : rolesMap.keySet() 
                                                              OR Department__c IN : deptsIdToRoleMap.keySet()
                                                              OR Organisation__c IN : orgIdToRoleMap.keySet()]){
                                                                
                       if(expenseAlloc.Role__c != null && rolesMap.containsKey(expenseAlloc.Role__c)){
                           if(!roleIdToExpenseAllocationMap.containsKey(expenseAlloc.Role__c)){
                               roleIdToExpenseAllocationMap.put(expenseAlloc.Role__c, new List<Expense_Allocation__c>());
                           }
                           roleIdToExpenseAllocationMap.get(expenseAlloc.Role__c).add(expenseAlloc);
                           
                           if(!roleIdToExpenseAccountMap.containsKey(expenseAlloc.Role__c)){
                               roleIdToExpenseAccountMap.put(expenseAlloc.Role__c, new List<Expense_Account__c>());
                           }
                           roleIdToExpenseAccountMap.get(expenseAlloc.Role__c).add(expenseAlloc.Expense_Account__r);
                       }
                       if(expenseAlloc.Department__c != null && deptsIdToRoleMap.containsKey(expenseAlloc.Department__c)){
                           if(!roleIdToExpenseAllocationMap.containsKey(deptsIdToRoleMap.get(expenseAlloc.Department__c))){
                               roleIdToExpenseAllocationMap.put(deptsIdToRoleMap.get(expenseAlloc.Department__c), new List<Expense_Allocation__c>());
                           }
                           roleIdToExpenseAllocationMap.get(deptsIdToRoleMap.get(expenseAlloc.Department__c)).add(expenseAlloc);
                           
                           if(!roleIdToExpenseAccountMap.containsKey(deptsIdToRoleMap.get(expenseAlloc.Department__c))){
                               roleIdToExpenseAccountMap.put(deptsIdToRoleMap.get(expenseAlloc.Department__c), new List<Expense_Account__c>());
                           }
                           roleIdToExpenseAccountMap.get(deptsIdToRoleMap.get(expenseAlloc.Department__c)).add(expenseAlloc.Expense_Account__r);
                       }
                       if(expenseAlloc.Organisation__c != null && orgIdToRoleMap.containsKey(expenseAlloc.Organisation__c)){
                           if(!roleIdToExpenseAllocationMap.containsKey(orgIdToRoleMap.get(expenseAlloc.Organisation__c))){
                               roleIdToExpenseAllocationMap.put(orgIdToRoleMap.get(expenseAlloc.Organisation__c), new List<Expense_Allocation__c>());
                           }
                           roleIdToExpenseAllocationMap.get(orgIdToRoleMap.get(expenseAlloc.Organisation__c)).add(expenseAlloc);
                           
                           if(!roleIdToExpenseAccountMap.containsKey(orgIdToRoleMap.get(expenseAlloc.Organisation__c))){
                               roleIdToExpenseAccountMap.put(orgIdToRoleMap.get(expenseAlloc.Organisation__c), new List<Expense_Account__c>());
                           }
                           roleIdToExpenseAccountMap.get(orgIdToRoleMap.get(expenseAlloc.Organisation__c)).add(expenseAlloc.Expense_Account__r);
                       } 
                       expenseAccountIds.add(expenseAlloc.Expense_Account__r.Id); //562                                          
                }
        	}
            // Create Map empIdToExpenseAllocMap - Employee Id and all the expense allocations related to that employee
            for(String role : roleIdToExpenseAllocationMap.keySet()){
                for(Employee__c employee: roleIdToEmployeeMap.get(role)){
                    if(!empIdToExpenseAllocMap.containsKey(employee.Id)){
                        empIdToExpenseAllocMap.put(employee.Id , new List<Expense_Allocation__c>());
                    }
                    empIdToExpenseAllocMap.put(employee.Id, roleIdToExpenseAllocationMap.get(role));
                }
            }
            
            // Create Employee Expense Allocations records for the employees
            createEmployeeExpenseAllocation(roleIdToEmployeeMap, roleIdToExpenseAccountMap, expenseAccountIds); //562
            
            if(quotaEmployees.size()> 0){
                createQuotaRecord(null , quotaEmployees);
            }
       }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
       }
    }
    /*
     * This method will create employee Expense Allocation(number of expense account associated with that Expense Role Profile)
     * @parameter erpIdEmployeeMap, Map of Employee Role Profile Id and List of Employee
     * @parameter erpIdExpenseAccountMap, Map of Employee Role Profile Id and List of Expense Account
     * @returns List of Employee Expense Allocation
    */
    //PCPM-235
    public static void createEmployeeExpenseAllocation(Map<String,List<Employee__c>> roleIdToEmployeeMap, Map<String, List<Expense_Account__c>> roleIdToExpenseAccountMap, Set<String> expenseAccountIds){ //562
        List<Employee_Expense_Allocation__c> eeaList = new List<Employee_Expense_Allocation__c>();
        //562
        Map<String, Date> expenseAccAndMinExpDetailStartDateMap = new Map<String, Date>(); 
        Map<String, Date> expenseAccAndLargestExpDetailEndDateMap = new Map<String, Date>();
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'Id, Start_Date__c, End_Date__c',Constant.ACTION_TYPE_ACCESS)){
            for(Expense_Account__c expenseAcc : [SELECT Id, (SELECT Id, Start_Date__c, End_Date__c FROM Expense_Details__r) 
                                                     FROM Expense_Account__c 
                                                     WHERE Id IN : expenseAccountIds]){
                    Date minStartDate = null;
                    Date largestEndDate = null;
                    if(expenseAcc.Expense_Details__r.size() > 0){
                        minStartDate = expenseAcc.Expense_Details__r[0].Start_Date__c; 
                        if(expenseAcc.Expense_Details__r[0].End_Date__c != null){
                            largestEndDate = expenseAcc.Expense_Details__r[0].End_Date__c;
                        }   
                        for(Expense_Detail__c expenseDetail : expenseAcc.Expense_Details__r){
                            if(expenseDetail.Start_Date__c < minStartDate){
                                minStartDate = expenseDetail.Start_Date__c;
                            } 
                            if(expenseDetail.End_Date__c != null){
                                if(largestEndDate == null || (largestEndDate != null && expenseDetail.End_Date__c > largestEndDate)){
                                    largestEndDate = expenseDetail.End_Date__c;
                                }
                            }
                        }      
                    }
                 expenseAccAndMinExpDetailStartDateMap.put(expenseAcc.Id, minStartDate);
                 expenseAccAndLargestExpDetailEndDateMap.put(expenseAcc.Id, largestEndDate);
            }
    	} 
        Map<String, List<Expense_Account__c>> empToExpenseAccMap = new Map<String, List<Expense_Account__c>>();
        Boolean isEmployee = false, isExpenseAccount = false, isStartDate = false, isEndDate =false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_EXPENSE_ALLOCATION_OBJECT,'Employee__c',Constant.ACTION_TYPE_INSERT)){
            isEmployee = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_EXPENSE_ALLOCATION_OBJECT,'Expense_Account__c',Constant.ACTION_TYPE_INSERT)){
            isExpenseAccount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_EXPENSE_ALLOCATION_OBJECT,'Start_Date__c',Constant.ACTION_TYPE_INSERT)){
            isStartDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_EXPENSE_ALLOCATION_OBJECT,'End_Date__c',Constant.ACTION_TYPE_INSERT)){
            isEndDate = true;
        }
        try{
            if(!roleIdToEmployeeMap.keyset().isEmpty()){
                for(String roleId : roleIdToEmployeeMap.keyset()){
                	for(Employee__c e : roleIdToEmployeeMap.get(roleId)){
                        empToExpenseAccMap.put(e.Id, new List<Expense_Account__c>());
                        List<String> expenseAccIdsList = new List<String>();
                        if(roleIdToExpenseAccountMap.get(roleId).Size() > 0){
                            for(Expense_Account__c ea : roleIdToExpenseAccountMap.get(roleId)){
                                // Create Unique Employee Expense Allocations record in respect of expense account for the employee
                                if( ea != null && 
                                    (expenseAccIdsList.size() == 0 || 
                                    (expenseAccIdsList.size() > 0 && !expenseAccIdsList.contains(ea.Id)))){
                                    //562
                                    Date empStartDate = null;
                                    Date empEndDate = null;
                                    if(expenseAccAndMinExpDetailStartDateMap.get(ea.Id) != null && e.Employee_Start_Date__c < expenseAccAndMinExpDetailStartDateMap.get(ea.Id)){
                                        empStartDate = expenseAccAndMinExpDetailStartDateMap.get(ea.Id);
                                    }else{
                                        empStartDate = e.Employee_Start_Date__c;
                                    }
                                    if(e.Employee_End_Date__c != null && expenseAccAndLargestExpDetailEndDateMap.get(ea.Id) != null && e.Employee_End_Date__c < expenseAccAndLargestExpDetailEndDateMap.get(ea.Id)){
                                        empEndDate = e.Employee_End_Date__c;
                                    }else{
                                        empEndDate = expenseAccAndLargestExpDetailEndDateMap.get(ea.Id);
                                    }    
                                        
                                    Employee_Expense_Allocation__c empExpAlloc = new Employee_Expense_Allocation__c();
                                    if(isEmployee){
                                        empExpAlloc.Employee__c = e.Id;
                                    }
                                    if(isExpenseAccount){
                                        empExpAlloc.Expense_Account__c = ea.Id;
                                    }
                                    if(isStartDate){
                                        empExpAlloc.Start_Date__c = empStartDate;
                                    }
                                    if(isEndDate){
                                        empExpAlloc.End_Date__c = empEndDate;
                                    }
                                    eeaList.add(empExpAlloc);
                                    expenseAccIdsList.add(ea.Id);
                                    empToExpenseAccMap.get(e.Id).add(ea);    
                                }
                            }//ea for
                        }// if
                    }//emp for
                }
            } 
            // Insert list of employee expense allocations
            PlaceCPM_Utility.insertRecords(eeaList, CONSTANT.EMPLOYEE_EXPENSE_ALLOCATION_OBJECT, false); //520
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }
    
    /*
     * This method will run to handle after update events on Employee object
     * @parameter newEmployees, new Map of Employee__c
     * @parameter oldEmployees, old Map of oldEmployees
     * @returns void
    */
    public static void handleAfterUpdate(Map<Id, Employee__c> newEmployees, Map<Id, Employee__c> oldEmployees){
        updateRevenueAccNameOnAccountExecUpdate(newEmployees.values(), oldEmployees); //PCPM-316
        updateEndDateAndPaymentDateOnCompensation(newEmployees, oldEmployees);
        createQuotaRecord(oldEmployees , newEmployees.values());
    }
    
    /*
     * This method create the Quota records when a value is changed on Employee object
     * @parameter employeeMap, Map of Employee__c
     * @parameter listEmployee, List of Employees
     * @returns void
    */
    public static void createQuotaRecord(Map<Id , Employee__c> employeeMap , List<Employee__c> listEmployee){
        Boolean isInsert = employeeMap == null;
        List<Employee__c> employeeQuotaToInserted = new List<Employee__c>();
        Map<String, Quota__c> employeeToQuotaMap = new  Map<String, Quota__c>();
        List<Quota__c> quotaListToDelete = new List<Quota__c>();
    List<Employee__c> quotaEmployeeToDelete = new List<Employee__c>();
        List<Employee__c> quotaEmployeeToDeleteWithDate = new List<Employee__c>();// PCPM-265
        Quota__c quota ;
        List<Quota__c> quotasToBeInserted = new List<Quota__c>();
        List<GL_Code__c> glAccount = [Select id from GL_Code__c where Name =: CONSTANT.RECURRING_GL_CODE];
        Date tempDate;
        Date endDate;
        Integer noOfQuotaForSameSchedule;
        Integer monthPassed = 0;
        PlaceCPM_Utility.EmployeeRevenueDetailWrapper erDetail = new PlaceCPM_Utility.EmployeeRevenueDetailWrapper();
        //PCPM-235
        for(Employee__c emp : listEmployee){
            if(isInsert){
                if(emp.Is_Quota_Applicable__c){
                    employeeQuotaToInserted.add(emp);
                }
            }
            else{
                //PCPM-265
                if(emp.Employee_End_Date__c != employeeMap.get(emp.Id).Employee_End_Date__c
                    ||  emp.Employee_Start_Date__c != employeeMap.get(emp.Id).Employee_Start_Date__c 
                    || emp.Role__c != employeeMap.get(emp.Id).Role__c){
                       if(emp.Employee_Start_Date__c != employeeMap.get(emp.Id).Employee_Start_Date__c) {
                           quotaEmployeeToDelete.add(emp);
                       }
                       if(emp.Is_Quota_Applicable__c) {
                          employeeQuotaToInserted.add(emp);
                       } else {
                          quotaEmployeeToDeleteWithDate.add(emp); 
                       }
                }
            }
        }
        //PCPM -265
        if(quotaEmployeeToDeleteWithDate.size() > 0) {
            deleteQuotas(quotaEmployeeToDeleteWithDate, System.today());
        }
        if(quotaEmployeeToDelete.size() > 0) {
            deleteQuotas(quotaEmployeeToDelete);
        }
        if(!isInsert && employeeQuotaToInserted.size() > 0){
            
            if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_OBJECT,'Id,Quota_Start_Date__c,Employee__c,Quota_End_Date__c,Revenue_GL_Account__c',Constant.ACTION_TYPE_ACCESS)){
                for(Quota__c qt: [Select Id, 
                                     Quota_Start_Date__c,
                                     Employee__c,
                                     Quota_End_Date__c,
                                     Revenue_GL_Account__c
                                     From Quota__c 
                                     where Employee__c In : employeeQuotaToInserted]) {
                                         if(qt.Quota_Start_Date__c != null) {
                                             employeeToQuotaMap.put(qt.Employee__c +':'+String.valueOf(qt.Quota_Start_Date__c), qt);
                                         }
                                     }
        	}   
        }
        quoataSchdule = PlaceCPM_Utility.getQuotaSchedule();
        Boolean isQuotaEmployee = false, isMonthlyQuotaAmount = false, isQuotaStartDate = false, isQuotaSchedule = false, isRevenueGLAccount = false;
        Boolean isQuotaEndDate = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_OBJECT,'Employee__c',Constant.ACTION_TYPE_INSERT)){
            isQuotaEmployee = true; 
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_OBJECT,'Monthly_Quota_Amount__c',Constant.ACTION_TYPE_INSERT)){
            isMonthlyQuotaAmount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_OBJECT,'Quota_Start_Date__c',Constant.ACTION_TYPE_INSERT)){
            isQuotaStartDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_OBJECT,'Quota_Schedule__c',Constant.ACTION_TYPE_INSERT)){
            isQuotaSchedule = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_OBJECT,'Revenue_GL_Account__c',Constant.ACTION_TYPE_INSERT)){
            isRevenueGLAccount = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.QUOTA_OBJECT,'Quota_End_Date__c',Constant.ACTION_TYPE_INSERT)){
            isQuotaEndDate = true;
        }
        For(Employee__c emp : employeeQuotaToInserted){
            tempDate = emp.Employee_Start_Date__c;
            For(Quota_Schedule__c qs : quoataSchdule){
                if(qs.Range_End__c != Null){
                    noOfQuotaForSameSchedule = Integer.valueOf(qs.Range_End__c) - Integer.valueOf(qs.Range_Start__c) + 1;
                }
                else if(qs.Range_End__c == Null){
                    if(PlaceCPM_Utility.assumptionForecastDuration == 0) {
                        emp.addError(Label.placeCPM_Required_Forecast);
                    } else {
                        if(qs.Type__c != null){
                            noOfQuotaForSameSchedule = (PlaceCPM_Utility.assumptionForecastDuration - monthPassed)/Integer.valueOf(qs.Type__c);
                        }
                    }
                }
                For(Integer i = 0 ; i < noOfQuotaForSameSchedule ; i++ ){
                    quota = new Quota__c();
                    if(isQuotaEmployee){
                      quota.Employee__c = emp.Id;
                    }
                    if(isMonthlyQuotaAmount){
                      quota.Monthly_Quota_Amount__c = qs.Monthly_Amount__c;
                    }
                    if(isQuotaStartDate){
                      quota.Quota_Start_Date__c = tempDate;
                    }
                    if(isQuotaSchedule){
                      quota.Quota_Schedule__c = qs.Id;
                    }
                    if(isRevenueGLAccount){
                      quota.Revenue_GL_Account__c = PlaceCPM_Utility.assumptionRevenueGLAccount;
                    }
                    if(qs.Type__c != null){
                        endDate = tempDate.addMonths(Integer.valueOf(qs.Type__c)).addDays(-1);
                        
                        if(isQuotaEndDate){
                          quota.Quota_End_Date__c = endDate;
                        }
                        
                        if(emp.Employee_End_Date__c != null && emp.Employee_End_Date__c < quota.Quota_End_Date__c && isQuotaEndDate){
                            quota.Quota_End_Date__c = emp.Employee_End_Date__c;
                        }
                        
                        if(emp.Employee_Status__c.trim() == CONSTANT.EMPLOYEE_STATUS_TERMINATED && date.today() < quota.Quota_End_Date__c && isQuotaEndDate) {
                            quota.Quota_End_Date__c  = date.today();
                        }
                        erDetail.maxContractEndDate = quota.Quota_End_Date__c;
                        tempDate = endDate.addDays(1);
                        monthPassed = monthPassed + Integer.valueOf(qs.Type__c);
                    }
                    if(!isInsert && quota.Quota_Start_Date__c != null && employeeToQuotaMap.containsKey(quota.Employee__c +':'+String.valueOf(quota.Quota_Start_Date__c))) {
                        quota.Id = employeeToQuotaMap.get(quota.Employee__c +':'+String.valueOf(quota.Quota_Start_Date__c)).Id;
                    }
                    if((emp.Employee_Status__c.trim() != CONSTANT.EMPLOYEE_STATUS_TERMINATED || 
                        ( emp.Employee_Status__c.trim() == CONSTANT.EMPLOYEE_STATUS_TERMINATED && quota.Quota_Start_Date__c < date.today()))
                       && (emp.Employee_End_Date__c == null || emp.Employee_End_Date__c > quota.Quota_Start_Date__c)
                      ) {
                          quotasToBeInserted.add(quota);
                      } else {
                          if(!isInsert && quota.Id != null){
                              quotaListToDelete.add(quota);
                          }
                      }
                }
            }
            PlaceCPM_Utility.empRevDetailWrapper.put(emp.Id, erDetail);
        }
        try{
            PlaceCPM_Utility.upsertRecords(quotasToBeInserted, CONSTANT.QUOTA_OBJECT, false); //520
            PlaceCPM_Utility.deleteRecords(quotaListToDelete, CONSTANT.QUOTA_OBJECT, false); //520
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }

    /*
     * This method will delete the quotas
     * @parameter employeeList, List of Employees
     * @returns void
    */
    public static void deleteQuotas(List<Employee__c> employeeList){
        try{
            PlaceCPM_Utility.deleteRecords([Select Id From Quota__c where Employee__c In : employeeList], CONSTANT.QUOTA_OBJECT, false); //520
        }
        catch(DmlException ex){
          PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }

    /*
     * This method will update End Date and Payment Date on Compensation
     * @parameter newEmployees, Map of new Employee Id and Employee Record
     * @parameter oldEmployees, Map of old Employee Id and Employee Record
     * @returns void
    */
    public static void updateEndDateAndPaymentDateOnCompensation(Map<Id, Employee__c> newEmployees, Map<Id, Employee__c> oldEmployees){
        List<Compensation__c> listCompensationToBeUpdated = new list<Compensation__c>();
        Set<Compensation__c> setCompensations = new Set<Compensation__c>();
        Set<String> setExpenseAccountId = new Set<String>();
        Map<String,Expense_Detail__c> mapExpenseAccountExpenseDetail = new Map<String,Expense_Detail__c>();
        Boolean isPaymentDate = false, isEndDate = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'Payment_Date__c',Constant.ACTION_TYPE_UPDATE)){
            isPaymentDate = true;
        }
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'End_Date__c',Constant.ACTION_TYPE_UPDATE)){
            isEndDate = true;
        }
        for(Employee__c emp : newEmployees.values()){
            setExpenseAccountId.add(emp.Expense_Account__c);
        }
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EXPENSE_DETAIL_OBJECT,'Id, Invoice_Date__c, Payment_Term_After_Days__c',Constant.ACTION_TYPE_ACCESS)){
            for(Expense_Account__c ea : [Select Id, (Select Id, Invoice_Date__c, Payment_Term_After_Days__c from Expense_Details__r ORDER BY Start_Date__c DESC LIMIT 1) from Expense_Account__c where Id IN : setExpenseAccountId]){
                for(Expense_Detail__c ed : ea.Expense_Details__r){
                    mapExpenseAccountExpenseDetail.put(ea.Id,ed);
                }
            }
    	}
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.EMPLOYEE_OBJECT,'Id, Expense_Account__c,Employee_Status__c, Employee_Type__c',Constant.ACTION_TYPE_ACCESS) && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'Id,End_Date__c,Payment_Date__c',Constant.ACTION_TYPE_ACCESS)){
            for(Employee__c emp : [Select Id, Expense_Account__c,Employee_Status__c, Employee_Type__c,
                                        (Select Id,End_Date__c,Payment_Date__c from Compensations__r ORDER BY Start_Date__c DESC),
                                        /*Expense_Account__r.Invoice_Date__c,*/ Employee_End_Date__c
                                        from Employee__c 
                                        where Id IN: oldEmployees.keySet()]){
                if(emp.Compensations__r.size()  > 0){
                    
                    if(emp.Employee_Status__c != oldEmployees.get(emp.Id).Employee_Status__c && emp.Employee_Status__c == CONSTANT.EMPLOYEE_STATUS_TERMINATED && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.COMPENSATION_OBJECT,'End_Date__c',Constant.ACTION_TYPE_UPDATE)){
                        emp.Compensations__r[0].End_Date__c = System.today();
                        setCompensations.add(emp.Compensations__r[0]);
                    }
                    
                    for(Compensation__c com : emp.Compensations__r){
            				if(oldEmployees != Null && (oldEmployees.get(emp.Id).Expense_Account__c != emp.Expense_Account__c) && emp.Employee_Type__c != Null && emp.Employee_Type__c == CONSTANT.EMPLOYEE_TYPE_HOURLY_CONTRACTORS ){
                                
                                if(emp.Expense_Account__c != Null && isPaymentDate){
                                    com.Payment_Date__c = mapExpenseAccountExpenseDetail.get(emp.Expense_Account__c).Invoice_Date__c.addDays(Integer.valueOf(mapExpenseAccountExpenseDetail.get(emp.Expense_Account__c).Payment_Term_After_Days__c));
                                }else{
                                    
                                    if(isPaymentDate){
                                      com.Payment_Date__c = null;
                                    }
                                }
                                setCompensations.add(com);
                        } 
                        if((oldEmployees.get(emp.Id).Employee_End_Date__c != emp.Employee_End_Date__c) && emp.Employee_End_Date__c != Null && com.End_Date__c == Null){
                            
                            if(isEndDate){
                              com.End_Date__c = emp.Employee_End_Date__c;
                            }
                            setCompensations.add(com);
                        }
                    }
                }
           }
    	}


        if(setCompensations.size() > 0 ){
            listCompensationToBeUpdated.addAll(setCompensations);
            PlaceCPM_Utility.updateRecords(listCompensationToBeUpdated, CONSTANT.COMPENSATION_OBJECT, false); //520
        }
    }
    
    /*
     * This method will delete Employee Expense Allocation on Employee Deletion
     * @parameter employeeList, List of Employee
     * @returns void
    */
    public static void deleteEmployeeExpenseAllocation(List<Employee__c> employeeList){
        try{
            PlaceCPM_Utility.deleteRecords([Select Id From Employee_Expense_Allocation__c where Employee__c In : employeeList], CONSTANT.EMPLOYEE_EXPENSE_ALLOCATION_OBJECT, false); //520
        }
        catch(DmlException ex){
          PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }

    /*
     * This method will delete the compensation
     * @parameter oldEmployees, map of old employee id and employee
     * @returns void
    */
    public static void deleteCompensation(map<Id, Employee__c> oldEmployees){ 
        
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.WAGES_OBJECT,'id, Employee_Number__c',Constant.ACTION_TYPE_ACCESS)){
            for(Wages__c wg : [Select id, Employee_Number__c from wages__c where Employee_Number__c IN: oldEmployees.keySet() and cash_date__c < : system.today()]){
                oldEmployees.get(wg.Employee_Number__c ).addError(System.Label.Cannot_delete_employee_as_some_wages_related_to_employee_has_been_paid_out);
            }
    	}
        try{
          PlaceCPM_Utility.deleteRecords([Select Id from Compensation__c where Employee__c IN : oldEmployees.values()], CONSTANT.COMPENSATION_OBJECT, false); //520
        }catch(DmlException ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }    
    }

    /*
     * This method will delete the quotas
     * @parameter employeeList, List of Employees
     * @returns void 
     * PCPM-265
    */
    public static void deleteQuotas(List<Employee__c> employeeList, Date startDate){
        try{
            PlaceCPM_Utility.deleteRecords([Select Id From Quota__c where Employee__c In : employeeList AND Quota_Start_Date__c  >: startDate],  CONSTANT.QUOTA_OBJECT, false); //520
        }
        catch(DmlException ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }

    /*
     * This method will get all the department allocation that needs to be deleted
     * @parameter employeeList, list of employees
     * @returns void
    */
    public static void employeeDeptAllocationDelete(List<Employee__c> employeeList){
        empDeptAllocationToBeDeleted = [Select Id From Employee_Department_Allocation__c where Employee__c In : employeeList];
    }

    /*
     * This method will delete the Employee_Department_Allocation__c
     * @parameter empDepartmentAlloList, list of Employee_Department_Allocation__c
     * @returns void
    */
    public static void deleteEmployeeDepartmentAllocation(List<Employee_Department_Allocation__c> empDepartmentAlloList){
        PlaceCPM_Utility.deleteRecords(empDepartmentAlloList, CONSTANT.EMPLOYEE_DEPARTMENT_ALLOCATION_OBJECT, false); //520
    }
    
    /* PCPM-316
     * This method will update the Revenue Account's Name
     * @param1 newEmployeeList is list of new employee
     * @param2 mapOldEmployees is map of old employees
     * @returns void
    */
    public static void updateRevenueAccNameOnAccountExecUpdate(List<Employee__c> newEmployeeList, Map<Id, Employee__c> mapOldEmployees){
        List<Revenue_Account__c> vendorRevenueAccountList = new List<Revenue_Account__c>(); 
        Map<String, Employee__c> employeeMap = new Map<String, Employee__c>();
        
        for(Employee__c emp : newEmployeeList){
            if(emp.Name != mapOldEmployees.get(emp.Id).Name){
                employeeMap.put(emp.Id, emp);
            }
        }
        Boolean isRevenueName = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Name',Constant.ACTION_TYPE_UPDATE)){
            isRevenueName = true;
        }
        
        if(employeeMap.size() > 0 && PlaceCPM_Utility.checkAccessiblityOfFields(Constant.revenueAccountObject,'Id, Name, Account_Executive__c',Constant.ACTION_TYPE_ACCESS)){
            for(Revenue_Account__c revenueAcc : [SELECT Id, Name, Account_Executive__c , Account_Executive__r.Name 
                                                 FROM Revenue_Account__c
                                                 WHERE Account_Executive__c  IN : employeeMap.keySet()]){
                                                     
                  if(isRevenueName){
                    revenueAcc.Name = revenueAcc.Name.replace(mapOldEmployees.get(revenueAcc.Account_Executive__c).Name + ' - ', employeeMap.get(revenueAcc.Account_Executive__c).Name + ' - ');    
                    vendorRevenueAccountList.add(revenueAcc);
                  }
                                                     
      		}
    	}
        try{
            RevenueAccountTriggerHandler.isRunRevenueAccountTriggerHandler = false;
            PlaceCPM_Utility.updateRecords(vendorRevenueAccountList, CONSTANT.revenueAccountObject, false);//520
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
    }
}