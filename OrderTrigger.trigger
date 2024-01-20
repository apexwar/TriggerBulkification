trigger OrderTrigger on Order (before insert, after insert) {

    OrderTriggerHandler handler = new OrderTriggerHandler();

    if(trigger.isBefore){
      //System.debug('ord.Quantity__c -->1');
        if(trigger.isInsert){
          //System.debug('ord.Quantity__c -->2');
          handler.OnBeforeInsert(Trigger.New);
        }
    }

    if(trigger.isAfter){
      //System.debug('ord.Quantity__c -->1');
        if(trigger.isInsert){
          //System.debug('ord.Quantity__c -->2');
          handler.OnAfterInsert(Trigger.New);
        }
    }
}