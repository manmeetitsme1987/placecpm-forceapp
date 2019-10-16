public class CustomCalendarCntrl {
    
    @AuraEnabled
    public static Map<Integer , List<String>> yearAndWeekDates(){
        Map<Integer , String> mapOfMonthAndName = new Map<Integer , String>();
        mapOfMonthAndName.put(1 , 'Jan');
        mapOfMonthAndName.put(2 , 'Feb');
        mapOfMonthAndName.put(3 , 'Mar');
        mapOfMonthAndName.put(4 , 'Apr');
        mapOfMonthAndName.put(5 , 'May');
        mapOfMonthAndName.put(6 , 'Jun');
        mapOfMonthAndName.put(7 , 'Jul');
        mapOfMonthAndName.put(8 , 'Aug');
        mapOfMonthAndName.put(9 , 'Sep');
        mapOfMonthAndName.put(10 , 'Oct');
        mapOfMonthAndName.put(11 , 'Nov');
        mapOfMonthAndName.put(12 , 'Dec');
        Map<Integer , List<String>> dateMap = new Map<Integer , List<String>>();
        Integer noOfYears = 0;
        Date startDate;
        Date tempDateSunday = Date.newInstance(1900, 1, 7);
        Integer mod;
        Date firstSunday;
        List<String> tempList = new List<String>();
        if(PlaceCPM_Utility.assumptionForecastDuration > 0){
            Date dateAfterAssumptionDuration = System.today().addMonths(PlaceCPM_Utility.assumptionForecastDuration);
            noOfYears = dateAfterAssumptionDuration.year();
        }
        for(Integer i = System.today().year() - 1 ; i<=noOfYears ; i++){
            startDate = Date.newInstance(i, 1, 1);
            mod =  Math.mod(tempDateSunday.daysBetween(startDate) , 7);
            firstSunday = mod == 0 ? startDate : startDate.addDays(7 - mod);
            for( ; firstSunday.year() <= i ; firstSunday = firstSunday+7){
                if(!dateMap.containsKey(i)){
                    dateMap.put(i , new List<String>{});
                }
                tempList = dateMap.get(i);
                tempList.add(firstSunday.day() + ' ' + mapOfMonthAndName.get(firstSunday.month()) + ' ' + i);
                dateMap.put(i , tempList);
            }
        }
        return dateMap;
    }
}