/*
 Created Date :  21 June 2019
 Class Name   :  placeCPM_SchedulePLAndCashAllocations
 Description  :  PCPM-67 & 72 | Scheduler class for placeCPM_CreatePLAndCashRecords batch 

 Change 1     :
*/
global class placeCPM_SchedulePLAndCashAllocations implements Schedulable {
	
    /*global void schedulePLAndCashAllocations(){
        system.debug('***Inside schedulePLAndCashAllocations***');
        placeCPM_SchedulePLAndCashAllocations batchSch = new placeCPM_SchedulePLAndCashAllocations();
        //String sch1 = '[ &quot;$(date +%d -d tomorrow)&quot; = &quot;01&quot; ] &amp;&amp; execute_this';
        //String sch2 = '0 18 28-31 * * root [ $(date +\%d -d tomorrow) = 01 ] && my-command';
        String sch = '2 0 * * * ?' ;
        System.schedule('Batch Schedule', sch , batchSch);
    }*/
    
    global void execute(SchedulableContext sc){
        system.debug('***Inside execute***');
        placeCPM_CreatePLAndCashRecords createPLAndCashAlloc = new placeCPM_CreatePLAndCashRecords();
        database.executebatch(createPLAndCashAlloc,200);
    }

}