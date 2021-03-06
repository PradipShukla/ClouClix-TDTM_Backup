/*
    When a recurring donation is updated and the amount is different, update the new amount to each allocation
    percentage = allocation.Value / donation.OldAmount;
    allocation.Value = donation.NewAmout * percentage;
*/

trigger updateRDAllocationsTrigger on Recurring_Donation__c (before update, before insert) {
    if(Trigger.isBefore && Trigger.isupdate) {
        List<Gift__c> GiftIds = new List<Gift__c>();
        set<Id> RDIds = new Set<id>();

        for(Recurring_Donation__c Rd : trigger.New)
        {
            Recurring_Donation__c RDold = Trigger.oldMap.get(Rd.Id);

            if((Rd.Frequency__c != Rdold.Frequency__c)|| (Rd.New_Payment_Start_Date__c != Rdold.New_Payment_Start_Date__c) ||(Rd.Start_Date__c != Rdold.Start_Date__c) )
            {
                RDIds.add(Rd.Id);
            }
            else if((RD.Schedule_Date__c != Rdold.Schedule_Date__c))
            {
                for(Recurring_Donation__c r:Trigger.New)
                {
                    if(r.Next_Payment_Date__c != null){
                        r.Next_Payment_Date__c = Date.newinstance((r.Next_Payment_Date__c).Year(),(r.Next_Payment_Date__c).month(), Integer.Valueof(r.Schedule_Date__c));
                    }
                }
            }
        }

     if(RDIds.size() > 0 )
     {
       String fields = 'id,name,'+ Utilities.PackageNamespace + 'Status__c,'+ Utilities.PackageNamespace + 'Frequency__c,'+ Utilities.PackageNamespace + 'New_Payment_Start_Date__c,'+ Utilities.PackageNamespace + 'Next_Payment_Date__c ,'+ Utilities.PackageNamespace + 'Schedule_Date__c, '+ Utilities.PackageNamespace + 'Start_Date__c';
       String subFields = 'Id,Name,'+ Utilities.PackageNamespace + 'Status__c,'+ Utilities.PackageNamespace + 'Gift_Date__c';
       String inFields = Converter.ConvertListSetToString(RDIds);
       String clause = ' WHERE Id IN ('+ inFields +') and Status__c =\'Active\'';
       String subClause = ' where Status__c=\'active\' and Gift_Date__c = THIS_YEAR ORDER BY Gift_Date__c DESC limit 1';

        Map<Id,Recurring_Donation__c> RDMap =  new Map<Id,Recurring_Donation__c>((List<Recurring_Donation__c>)new GenericQueryBuilder().QueryBuilderWithSubQuery(Recurring_Donation__c.sObjectType, fields, clause, Gift__c.sObjectType, 'Orders__r', subFields, subClause));

        fields = 'id,name,Recurring_Donation__c';
        subFields = 'Id,Name,Date__c';
        inFields = Converter.ConvertListSetToString(RDIds);
        clause = ' WHERE Recurring_Donation__c IN ('+ inFields +')';
        subClause = ' Order By Date__c DESC NULLS LAST limit 1';

        Map<Id,Gift__c>  GiftMap = new map<Id,Gift__c>((List<Gift__c>)new GenericQueryBuilder().QueryBuilderWithSubQuery(Gift__c.sObjectType, fields, clause, Payment__c.sObjectType, 'Recurring_Payments__r', subFields, subClause));
        for(Recurring_Donation__c Rd : trigger.New)
        {
             if(RDmap.containsKey(Rd.Id) && (RDmap.get(Rd.Id).Orders__r != null && RDmap.get(Rd.Id).Orders__r.size()>0 ) )
             {
                Gift__c  gift = RDmap.get(Rd.Id).Orders__r;
                if(GiftMap.get(gift.Id).Recurring_Payments__r != null && GiftMap.get(gift.Id).Recurring_Payments__r.size() > 0 )
                {
                Payment__c  p= GiftMap.get(gift.Id).Recurring_Payments__r;

                Integer addmm = 0;

                if(Rd.Frequency__c == 'Monthly') {
                     addmm = 01;
                }
                else if (Rd.Frequency__c == 'Quarterly') {
                      addmm = 03;
                }
                else {
                      addmm = 12;
                }

                if(Rd.New_Payment_Start_Date__c != null){
                    Rd.Next_Payment_Date__c = Date.newinstance((Rd.New_Payment_Start_Date__c).Year() , (p.Date__c).month()+addmm, (Rd.New_Payment_Start_Date__c).day());
                }
                else if(Rd.Start_Date__c > system.Today()) {
                    Rd.Next_Payment_Date__c = Rd.Start_Date__c;
                }
                else{
                    Rd.Next_Payment_Date__c = Date.newinstance((Rd.Start_Date__c).Year() , (p.Date__c).month()+addmm, (Rd.Start_Date__c).day());
                }
            }
            else {
                   if(Rd.Start_Date__c != null)
                   {
                     Rd.Next_Payment_Date__c = Rd.Start_Date__c;
                   }
                 else
                   {
                    Rd.Next_Payment_Date__c = Rd.New_Payment_Start_Date__c;
                    }
                  }

          }
       }
    }
 }

 if(Trigger.isBefore && Trigger.isInsert){
      for(Recurring_Donation__c Rd : trigger.New){
        if(Rd.Start_Date__c != null){
             Rd.Next_Payment_Date__c = Rd.Start_Date__c;
         }
         else{
             Rd.Next_Payment_Date__c = Rd.New_Payment_Start_Date__c;
         }

         if(Rd.Next_Payment_Date__c !=null){
             Rd.Schedule_Date__c=(Rd.Next_Payment_Date__c).day();
         }
       }
  }

  if(Trigger.isBefore && Trigger.isupdate){
      for(Recurring_Donation__c Rd : trigger.New){
          if(Rd.Next_Payment_Date__c!=trigger.oldMap.get(RD.id).Next_Payment_Date__c && Rd.Status__c == 'Active'){
              if(Rd.Next_Payment_Date__c != null){
                Rd.Schedule_Date__c=(Rd.Next_Payment_Date__c).day();
             }
          }
      }

  }

}