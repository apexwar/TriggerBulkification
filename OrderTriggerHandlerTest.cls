@isTest
public class OrderTriggerHandlerTest {
    
   @isTest 
   static void createOrders() {

        Account[] accts = DataFactory.createAccounts(2);
        List<Product2> prdList = new List<Product2>();

        Product2 prd1 = new Product2();
        prd1.Name = 'Test Prod 1';
        prd1.ProductCode = 'Prd1';
        prd1.Quantity__c = 1200;
        prd1.Unit_Price__c = 25;
        prd1.IsActive = true;
        prdList.add(prd1);

        Product2 prd2 = new Product2();
        prd2.Name = 'Test Prod 2';
        prd2.ProductCode = 'Prd2';
        prd2.Quantity__c = 100;
        prd2.Unit_Price__c = 10;
        prd2.IsActive = false;
        prdList.add(prd2);

        insert prdList;

        List<Order> orderList = new List<Order>();
        // Perform test
        Test.startTest();
        
        for(Integer i =0; i< 200; i++){
     
            Integer rndmAcc = Integer.valueof((Math.random() * 2));
            Integer quantity = Integer.valueof((Math.random() * 10));
            Order ord = new Order();
            ord.AccountId  = accts[rndmAcc].Id ;
            ord.Product__c  = prdList[System.Math.mod(i, 2) == 0 ? 1 : 0].Id;
            ord.Quantity__c  = quantity ;
            ord.EffectiveDate  = System.Today() ;
            ord.Status  = 'Draft' ;
            orderList.add(ord);
        }

        //System.debug('orderList 0--> '+orderList);
        Database.insert(orderList,false);
        

        Product2 prod = [Select Id, Quantity__c from Product2 where ProductCode = 'Prd1'];
        System.debug('prod.Quantity__c --> '+prod.Quantity__c);
        System.assertNotEquals(500, prod.Quantity__c, 'Products not used');

        List<Order> ordrList = [Select Id,AccountId from Order];
        System.debug('orderList 1--> '+ordrList);
        System.assertEquals(100, ordrList.size(), 'Orders not created');

        Account currentAcc = [Select Id, Loyalty_Points__c from Account where id =: ordrList[0].AccountId]; 
        System.debug('currentAcc 1--> '+currentAcc.Loyalty_Points__c);
        System.assertNotEquals(0, currentAcc.Loyalty_Points__c, 'Account not updated');

        Test.stopTest();
    }
}
