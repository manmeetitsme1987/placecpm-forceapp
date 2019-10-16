trigger EmployeeDepartmentAllocationTrigger on Employee_Department_Allocation__c (after insert, 
                                                                                  after update, 
                                                                                  before update, 
                                                                                  before insert,
                                                                                  after delete,
                                                                                  before delete,
                                                                                  after undelete) {
    TriggerDispatcher.Run(new EmployeeDepartmentAllocationHandler()); 
}