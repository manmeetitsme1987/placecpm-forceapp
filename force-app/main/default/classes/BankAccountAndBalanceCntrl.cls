public with sharing class BankAccountAndBalanceCntrl {
    @auraenabled
    public static List<BankAccountWrapper> fetchAccountAndBalance(){
        List<BankAccountWrapper> listBankWrapper = new List<BankAccountWrapper>();
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PAYMENT_ACCOUNT_OBJECT,'id , Name , Balance__c',Constant.ACTION_TYPE_ACCESS)){
            for(Payment_Account__c paymentAccount : [select id , Name , Bank_Account__r.name , Balance__c  from Payment_Account__c where isActive__c = true]){
                BankAccountWrapper bankWrap = new BankAccountWrapper();
                bankWrap.accountName = paymentAccount.Name;
                bankWrap.amount = paymentAccount.Balance__c;
                bankWrap.paymentAccoundId = paymentAccount.Id;
                bankWrap.serialNumber = ++serialNo;
                listBankWrapper.add(bankWrap);
            }
        }    
        return listBankWrapper;
    }
    
    @auraenabled
    public static String savePaymentAccount(String bankAccountWrapper){
        List<BankAccountWrapper> baw = (List<BankAccountWrapper>)JSON.deserialize(bankAccountWrapper , List<BankAccountWrapper>.class);
        List<Payment_Account__c> paymentAccList = new List<Payment_Account__c>();
        Payment_Account__c paymentAccount;
        Boolean isPaymentAccount = false;
        if(PlaceCPM_Utility.checkAccessiblityOfFields(Constant.PAYMENT_ACCOUNT_OBJECT,'Balance__c',Constant.ACTION_TYPE_UPDATE)){
            isPaymentAccount = true;
        }  
        for(BankAccountWrapper bw : baw){
            paymentAccount = new Payment_Account__c(Id = (Id)bw.paymentAccoundId);
            if(isPaymentAccount){
            	paymentAccount.Balance__c = bw.amount;
            }    
            paymentAccList.add(paymentAccount);
        }
        try{
            PlaceCPM_Utility.updateRecords(paymentAccList , CONSTANT.PAYMENT_ACCOUNT_OBJECT , false);
            return 'Success';
        }
        catch(Exception ex){
            return 'Error';
        }
    }
    static Integer serialNo = 0;

    class BankAccountWrapper{
        @auraenabled
        public string accountName;
        @auraenabled
        public Decimal amount;
        @auraenabled
        public string paymentAccoundId;
        @auraenabled
        public Integer serialNumber;
    } 
}