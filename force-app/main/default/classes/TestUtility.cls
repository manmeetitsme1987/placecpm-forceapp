@isTest
public class TestUtility {
    public static Account createAccount(String Name,Boolean IsInsert){
        Account accountRec = new Account(Name = Name);
        if(IsInsert){
            insert accountRec;
        }
        return accountRec;
    }
    public static Assumption__c createAssumption(Integer ForecastDuration,Boolean IsInsert){
        Assumption__c assumptionRec = new Assumption__c(Forecast_Duration__c = ForecastDuration, Contract_Period__c = ForecastDuration, 
                                                       Discounted_Receipts__c  = 0.1, Hours_Per_day__c = 10, Forecasting_Quota__c = .8);
        if(IsInsert){
            insert assumptionRec;
        }
        return assumptionRec;
    }
    public static List<Assumption__c> createAssumptions(Integer ForecastDuration,Integer count,Boolean IsInsert){
        List<Assumption__c> assumptionList = new List<Assumption__c>();
        for(integer i = 0 ; i< count ; i ++) {
          assumptionList.add(new Assumption__c(Forecast_Duration__c = ForecastDuration, Contract_Period__c = ForecastDuration, 
                                                       Discounted_Receipts__c  = 0.1, Hours_Per_day__c = 10, Forecasting_Quota__c = .8));  
        }
        if(IsInsert){
            insert assumptionList;
        }
        return assumptionList;
    }
    public static P_L_Category__c createPlCategory(String name,String type,Boolean IsInsert){
        P_L_Category__c plCategory = new P_L_Category__c(Name=name, Type__c = type);
        plCategory.sequence__c = 1;
        if(IsInsert){
            insert plCategory;
        }
        return plCategory;
    }
    
     public static GL_Code__c createGLCode(String Name, Integer accountNumber, Id pLCategory,Boolean isInsert){
        GL_Code__c glaccount = new GL_Code__c(Name=name, GL_Code__c = accountNumber, PL_Category__c = pLCategory);
        glaccount.sequence__c = 1;
        if(IsInsert){
            insert glaccount;
        }
        return glaccount;
    }
     public static Expense_PL_Allocation__c createExpensePlAllocation(Id glCodeId, Id plId,Boolean isInsert){
        Expense_PL_Allocation__c expenseAllocation = new Expense_PL_Allocation__c(GL_Code__c=glCodeId, P_L__c = plId);
        if(IsInsert){
            insert expenseAllocation;
        }
        return expenseAllocation;
    }
    //PCPM-235
    /*public static Employee_Role_Profile__c createERP(String Name,String Department, String Role, Id GLAccount,Boolean IsInsert){
        Employee_Role_Profile__c erp = new Employee_Role_Profile__c(Name =Name, Department__c = Department, Role__c = Role, GL_Account__c = GLAccount);
        if(IsInsert){
            insert erp;
        }
        return erp;
    }*/
    
    //PCPM-235
    public static Organisation__c createOrganisation(String Name, Boolean IsInsert){
        Organisation__c org = new Organisation__c(Name = Name);
        if(IsInsert){
            insert org;
        }
        return org;
    }
    
    //PCPM-235
    public static Department__c createDepartment(String Name, String OrganisationId, String GLAccountId, Boolean IsInsert){
        Department__c dept = new Department__c(Name =Name, Organisation__c = OrganisationId, GL_Account__c = GLAccountId );
        if(IsInsert){
            insert dept;
        }
        return dept;
    }
    
    //PCPM-235
    public static Role__c createRole(String Name, String DepartmentId, Boolean IsInsert){
        Role__c role = new Role__c(Name =Name, Department__c = DepartmentId);
        if(IsInsert){
            insert role;
        }
        return role;
    }
    
    //PCPM-235 & 299
    public static Expense_Allocation__c  createExpenseAllocation(String ExpenseAccountId, Boolean IsInsert){
        Expense_Allocation__c expenseAlloc  = new Expense_Allocation__c (Expense_Account__c = ExpenseAccountId);
        if(IsInsert){
            insert expenseAlloc;
        }
        return expenseAlloc;
    }
    
    //PCPM-235 | Removed from parameter and code | Id erp & Employee_Role_Profile__c =erp  added RoleId
    public static Employee__c createEmployee(String Name, String RoleId, Date EmployeeStartDate, String PrimaryOffice, String EmployeeType,String recordTypeId, Boolean IsInsert){
        Employee__c employeeRec = new Employee__c(Name= Name, Role__c = RoleId,Employee_Status__c = 'Active', Employee_Start_Date__c = EmployeeStartDate, Primary_Office__c = PrimaryOffice,Employee_Type__c = EmployeeType, RecordTypeId = recordTypeId );
        if(IsInsert){
            //Database.insert(employeeRec, false);
            insert employeeRec;
        }
        return employeeRec;
    }
    
    //PCPM-235 | Removed Id EmployeeRoleProfile from parameter
    public static Expense_Account__c createExpenseAccount(Id AccountVendor, Id GLCode, String PaymentFrequency, Boolean IsInsert){
        Expense_Account__c expenseAccountRec = new Expense_Account__c(Vendor__c = AccountVendor, GL_Code__c = GLCode, Payment_Frequency__c = PaymentFrequency);
        if(IsInsert){
            insert expenseAccountRec;
        }
        return expenseAccountRec;
    }
    
    public static Expense_Detail__c createExpenseDetail(Id ExpId, Date StartDate, Date EndDate, Date InvoiceDate, Decimal MonthlyExpenseAmount, String PaymentTermAfterDays, Boolean IsInsert){
        Expense_Detail__c expenseDetailRec = new Expense_Detail__c(Expense_Account__c =ExpId, End_Date__c = EndDate, Start_Date__c = StartDate, Invoice_Date__c = InvoiceDate, Expense_Amount__c =MonthlyExpenseAmount, Payment_Term_After_Days__c =PaymentTermAfterDays);
        if(IsInsert){
            insert expenseDetailRec;
        }
        return expenseDetailRec;
    }

    public static List<Expense_Detail__c> createExpenseDetailList(List<Expense_Detail__c> listExpDetails, Boolean IsInsert){
        //Expense_Detail__c expenseDetailRec = new Expense_Detail__c(Expense_Account__c =ExpId, Start_Date__c = StartDate, Invoice_Date__c = InvoiceDate, Expense_Amount__c =MonthlyExpenseAmount, Payment_Term_After_Days__c =PaymentTermAfterDays);
        if(IsInsert){
            insert listExpDetails;
        }
        return listExpDetails;
    }
    
    public static Compensation__c createCompensation(Date StartDate, Date EndDate, Id EmployeeId, Decimal MonthlyBaseSalary, String BasePaySchedule, Id BonusPlan,Boolean IsInsert){
    Compensation__c  compensationRec = new Compensation__c(Start_Date__c = StartDate, End_Date__c = EndDate,Employee__c =EmployeeId, Monthly_Base_Salary__c =MonthlyBaseSalary,Base_Pay_Schedule__c=BasePaySchedule, Bonus_Plan__c =BonusPlan);
    if(IsInsert){
            insert compensationRec;
        }
        return compensationRec;
    }
    
    public static Profit_Loss__c createPL(String name, Date periodStartDate, Date periodEndDate,Boolean IsInsert){
        Profit_Loss__c plRecord= new Profit_Loss__c(Name = name, Period_Start_Date__c = PeriodStartDate, Period_End_Date__c = periodEndDate);
    if(IsInsert){
            insert plRecord;
        }
        return plRecord;
    }
    
     public static Cash_Forecast__c createCashForecast(String name, Date PeriodStartDate, Date periodEndDate,Boolean IsInsert){
        Cash_Forecast__c cashForecastRecord= new Cash_Forecast__c(Name = name, Period_Start_Date__c = PeriodStartDate, Period_End_Date__c = periodEndDate);
    if(IsInsert){
            insert cashForecastRecord;
        }
        return cashForecastRecord;
    }
     //#124
    public static Payment_Account__c createPaymentAccount(String paymentAccountName,Boolean IsInsert){
        Payment_Account__c paRecord= new Payment_Account__c(Name  = paymentAccountName );
    	if(IsInsert){
            insert paRecord;
        }
        return paRecord;
    }
    //#124
    public static Revenue_Account__c createRevenueAccount(String accountId, String glAccountId, String paymentAccountId, 
                                                          String billingCycle,Boolean IsInsert){
        Revenue_Account__c raRecord= new Revenue_Account__c(Account__c  = accountId,
                                                           GL_Code__c  = glAccountId,
                                                           Payment_Account__c = paymentAccountId,
                                                            Billing_Cycle__c = billingCycle);
    	if(IsInsert){
            insert raRecord;
        }
        return raRecord;
    }
    
    //#124
    public static Revenue_Contract__c createRevenueContract(String revenueAccountId, Date contractStartDate,
                                                            Date invoiceDate, String paymentTermAfterDays,
                                                            Date contractEndDate, Boolean IsInsert){
        Revenue_Contract__c rcRecord= new Revenue_Contract__c(Revenue_Account__c  = revenueAccountId,
                                                              Contract_Start_Date__c = contractStartDate,
                                                              Contract_End_Date__c = contractEndDate,
                                                              Invoice_Date__c = invoiceDate,
                                                              Payment_Term_After_Days__c = paymentTermAfterDays);
    	if(IsInsert){
            insert rcRecord;
        }
        return rcRecord;
    }
    //#124
    public static Product__c createProduct(String name, String productType, Double unitPrice, 
                                           String unitType, Boolean IsInsert){
        Product__c prodRecord= new Product__c(Name = name,
                                              Product_Type__c =productType,
                                             Unit_Price__c = unitPrice,
                                             Unit_Type__c = unitType);
    	if(IsInsert){
            insert prodRecord;
        }
        return prodRecord;
    }
    //#124
    public static Contract_Line_Items__c createContractLineItem(String Name ,String revenueContractId,
                                                                Integer quantity, String productId, Boolean IsInsert){
 Contract_Line_Items__c cliRecord= new Contract_Line_Items__c(Product__c = productId,
                                                                    Quantity__c = quantity,
                                                                    Revenue_Contract_Details__c = revenueContractId
                                                                    );
    	if(IsInsert){
            insert cliRecord;
        }
        return cliRecord;
    }
    
    //#PCPM 121
    public static Wages__c createWages(Date CashDate, Date PLDate, Id EmployeeId, Decimal wageAmount, Id compensationRecId, Decimal BonusPerWage, Decimal BonusAmount, Boolean IsInsert){
    Wages__c  wage = new Wages__c(Cash_Date__c = CashDate, P_L_Date__c = PLDate,Employee_Number__c =EmployeeId, Wage_Amount__c =wageAmount, Bonus_Per_Wage__c =BonusPerWage, Bonus_Amount__c=BonusAmount, compensation__c = compensationRecId);
    if(IsInsert){
            insert wage;
        }
        return wage;
    }
    
    public static Quota__c createQuota(Id empId , Decimal quotaAmount , Date startDate , Date endDate , Id glAccountId , Boolean IsInsert){
        Quota__c quota = new Quota__c();
        quota.Employee__c = empId;
        quota.Monthly_Quota_Amount__c = quotaAmount;
        quota.Quota_Start_Date__c = startDate;
        quota.Quota_End_Date__c = endDate;
        quota.Revenue_GL_Account__c = glAccountId;
            if(IsInsert){
                    insert quota;
            }
        return quota;
    }
    
    public static Employee_Department_Allocation__c createExpenseDepartmentAllocation(Decimal allocationPercent, String category, Boolean isInsert){
        Employee_Department_Allocation__c  allocation = new Employee_Department_Allocation__c ();
        allocation.Allocation_percentage__c  = allocationPercent;
        allocation.Wage_Category__c  = category;
        if(IsInsert){
            Database.insert(allocation, false);
        }
        return allocation;
    }
    //#124
    public static SOW_Line_Item__c  createSOWLineItem(String sowId,
                                                      String month, String year,Double totalAmount, Boolean IsInsert){
 	SOW_Line_Item__c sowliRecord= new SOW_Line_Item__c(Month__c  = month,
                                                       Year__c = year,
                                                       Revenue_Contract_Statement_of_Work__c = sowId,
                                                       Line_Item_Amount__c = totalAmount
                                                      );
    	if(IsInsert){
            Database.insert(sowliRecord, false);
        }
        return sowliRecord;
    }

    public static Equity__c createEquity(string types, string name, string account, string glAccount, decimal amount, date dateToAdd, boolean isInsert){
        Equity__c equity = new Equity__c(Type__c = types, Name = name, Account__c = account, GL_Account__c = glAccount, Amount__c = amount, Date__c = dateToAdd);
        if(isInsert)
            Database.insert(equity, false);
        return equity;
    }
}