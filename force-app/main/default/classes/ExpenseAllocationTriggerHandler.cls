/*
 * Class : ExpenseAllocationTriggerHandler
 * Date  : 12 July 2019
 * Description -  Handler class for ExpenseAllocationTrigger
 * 
 * Change 1 : Namita  | PCPM-329 | 24 July 19
 */
public with sharing class ExpenseAllocationTriggerHandler implements CommonTriggerHandler{
	
    public void BeforeInsert(List<SObject> newItems){
        fetchEmployees((List<Expense_Allocation__c >)newItems);
    }
    
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterInsert(Map<Id, SObject> newItems){
        
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
      
    }
    
    public void AfterDelete(Map<Id, SObject> oldItems){
        
    }
    
    public void AfterUndelete(Map<Id, SObject> oldItems){
        
    }
    
    public Boolean IsDisabled(){
        return false;
    }
    
    /*
     * Description - fetch employees on the basis of organisations,departments and roles )
     * @parameter newExpenseAllocationRecords, List of new Expense Allocation Records
     * @returns void
    */
    private static void fetchEmployees(List<Expense_Allocation__c > newExpenseAllocationRecords){
        Map<String, List<Employee__c>> expenseAccToEmployeesMap = new Map<String, List<Employee__c>>();
        Set<String> expenseAccountIds = new Set<String>();
        //CPM-741
        Map<String, ExpenseAllocationOrgDeptRoleWrapper > expenseAccToExpenseAllocsMap = new Map<String, ExpenseAllocationOrgDeptRoleWrapper >();
        Map<String, Organisation__c> organisationsMap = new Map<String, Organisation__c>();
        Map<String, Department__c> departmentsMap = new Map<String, Department__c>();
        Map<String, Role__c> rolesMap = new Map<String, Role__c>();
        
        for(Expense_Allocation__c expenseAlloc : newExpenseAllocationRecords){
            expenseAccountIds.add(expenseAlloc.Expense_Account__c);
            if(expenseAlloc.Organisation__c != null){
                organisationsMap.put(expenseAlloc.Organisation__c, new Organisation__c());  
            }
            if(expenseAlloc.Department__c != null){
                departmentsMap.put(expenseAlloc.Department__c, new Department__c());  
            }
            if(expenseAlloc.Role__c != null){
                rolesMap.put(expenseAlloc.Role__c, new Role__c());  
            }
        }
       
        for(Organisation__c org : [SELECT Id, (SELECT Id FROM Departments__r) 
                                   FROM Organisation__c WHERE Id IN: organisationsMap.keySet()] ){
           organisationsMap.put(org.Id, org);
           if(org.Departments__r.size() > 0){
               for(Department__c dept : org.Departments__r){
                  departmentsMap.put(dept.Id, new Department__c());
               }
           }
        }
        
        for(Department__c dept : [SELECT Id, (SELECT Id FROM Roles__r) 
                                  FROM Department__c WHERE Id IN : departmentsMap.keySet()]){
              departmentsMap.put(dept.Id, dept);
              if(dept.Roles__r.size() > 0){
                  for(Role__c role : dept.Roles__r){
                     rolesMap.put(role.Id, new Role__c());
                  }                 
              }
        }
        
        for(Role__c role : [SELECT Id FROM Role__c WHERE Id IN: rolesMap.keySet()]){
            rolesMap.put(role.Id, role);
        }
       
        for(Expense_Account__c expenseAcc : [SELECT Id,(SELECT Id, Organisation__c, Department__c, Role__c FROM Expense_Allocations__r) 
                                             FROM Expense_Account__c WHERE Id IN : expenseAccountIds]){
            //CPM-741
            if(expenseAcc.Expense_Allocations__r.size() > 0){
                ExpenseAllocationOrgDeptRoleWrapper wrap = new ExpenseAllocationOrgDeptRoleWrapper();   
                Set<String> orgIds = new Set<String>();
                Set<String> deptIds = new Set<String>();
                Set<String> roleIds = new Set<String>();
                for(Expense_Allocation__c expAlloc : expenseAcc.Expense_Allocations__r){
                    if(expAlloc.Organisation__c != null){
                        orgIds.add(expAlloc.Organisation__c);
                    }
                    if(expAlloc.Department__c != null){
                        deptIds.add(expAlloc.Department__c);
                    }
                    if(expAlloc.Role__c != null){
                        roleIds.add(expAlloc.Role__c);
                    }
                }
                wrap.organisationIds = orgIds;
                wrap.departmentIds = deptIds;
                wrap.roleIds = roleIds;
                expenseAccToExpenseAllocsMap.put(expenseAcc.Id, wrap);
            } 
        }
        
        for(Expense_Allocation__c expenseAlloc : newExpenseAllocationRecords){
            //CPM-741
            if(expenseAccToExpenseAllocsMap.containskey(expenseAlloc.Expense_Account__c)){
                if(expenseAccToExpenseAllocsMap.get(expenseAlloc.Expense_Account__c).organisationIds.contains(expenseAlloc.Organisation__c) || 
				   expenseAccToExpenseAllocsMap.get(expenseAlloc.Expense_Account__c).departmentIds.contains(expenseAlloc.Department__c) ||
                   expenseAccToExpenseAllocsMap.get(expenseAlloc.Expense_Account__c).roleIds.contains(expenseAlloc.Role__c) ){

                    expenseAlloc.addError(System.Label.ExpenseAllocation_AlreadyExists);
                }
            }
            List<Employee__c> employeeList = new List<Employee__c>();
            List<String> existingEEAEmployeeIds = new List<String>();
            for(Employee_Expense_Allocation__c eea : [SELECT Id, Name, Employee__c, Expense_Account__c 
                                                      FROM Employee_Expense_Allocation__c 
                                                      WHERE Expense_Account__c =: expenseAlloc.Expense_Account__c]){
                existingEEAEmployeeIds.add(eea.Employee__c);
            }
            //CPM-741
            for(Employee__c emp : [SELECT Id, Name, Role__c, Monthly_Base_Salary__c, Employee_Start_Date__c, Employee_End_Date__c
                                   FROM Employee__c 
                                   WHERE Role__c IN: rolesMap.keySet() AND Id NOT IN:existingEEAEmployeeIds]){
                  employeeList.add(emp);
            }
            if(!expenseAccToEmployeesMap.containsKey(expenseAlloc.Expense_Account__c)){
                expenseAccToEmployeesMap.put(expenseAlloc.Expense_Account__c,new List<Employee__c>());
            }
            expenseAccToEmployeesMap.put(expenseAlloc.Expense_Account__c, employeeList);
        }
        createEmployeeExpenseAllocation(expenseAccToEmployeesMap );
    } 
    
    /*
     * Description - Create Employee Expense Allocations records on Expense Account associated with that Role )
     * @parameter expenseAccToEmployeesMap, Map of Expense Account Id and List of Employee
     * @returns void
    */
    private static void createEmployeeExpenseAllocation( Map<String, List<Employee__c>> expenseAccToEmployeesMap ){
        List<Employee_Expense_Allocation__c> empExpAllocList = new List<Employee_Expense_Allocation__c>();
        //PCPM-322
        Map<String, Date> expenseAccAndMinExpDetailStartDateMap = new Map<String, Date>(); 
        Map<String, Date> expenseAccAndLargestExpDetailEndDateMap = new Map<String, Date>();
        
        //PCPM-322
        if(expenseAccToEmployeesMap.keySet() != null){
            for(Expense_Account__c expenseAcc : [SELECT Id, (SELECT Id, Start_Date__c, End_Date__c FROM Expense_Details__r) 
                                                 FROM Expense_Account__c 
                                                 WHERE Id IN : expenseAccToEmployeesMap.keySet()]){
                 //PCPM-322
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
            for(String expenseAcc : expenseAccToEmployeesMap.keyset()){                
                for(Employee__c emp : expenseAccToEmployeesMap.get(expenseAcc) ){
                    //PCPM-322
                    Date empStartDate = null;
                    Date empEndDate = null;
                    if(expenseAccAndMinExpDetailStartDateMap.get(expenseAcc) != null && emp.Employee_Start_Date__c < expenseAccAndMinExpDetailStartDateMap.get(expenseAcc)){
                        empStartDate = expenseAccAndMinExpDetailStartDateMap.get(expenseAcc);
                    }else{
                        empStartDate = emp.Employee_Start_Date__c;
                    }
                    if(emp.Employee_End_Date__c != null && expenseAccAndLargestExpDetailEndDateMap.get(expenseAcc) != null && emp.Employee_End_Date__c < expenseAccAndLargestExpDetailEndDateMap.get(expenseAcc)){
                        empEndDate = emp.Employee_End_Date__c;
                    }else{
                        empEndDate = expenseAccAndLargestExpDetailEndDateMap.get(expenseAcc);
                    }
		    if(Schema.sObjectType.Employee_Expense_Allocation__c.fields.Expense_Account__c.isCreateable() && 
		       Schema.sObjectType.Employee_Expense_Allocation__c.fields.Start_Date__c.isCreateable() &&
		       Schema.sObjectType.Employee_Expense_Allocation__c.fields.End_Date__c.isCreateable()) {
			    
                    	empExpAllocList.add(new Employee_Expense_Allocation__c(Employee__c = emp.Id, Expense_Account__c = expenseAcc,
                                                                           Start_Date__c = empStartDate,
                                                                           End_Date__c = empEndDate));
		    }
                }
            }
        }
        try{
            PlaceCPM_Utility.insertRecords(empExpAllocList, CONSTANT.EMPLOYEE_EXPENSE_ALLOCATION_OBJECT, false); //520
        }catch(Exception ex){
            PlaceCPM_Utility.debugLog(ex.getMessage() + ' at line number ' + ex.getLineNumber());
        }
   }
   
    public class ExpenseAllocationOrgDeptRoleWrapper{//CPM-741
        public Set<String> organisationIds;
        public Set<String> departmentIds;
        public Set<String> roleIds;
    } 
}