public class OrderTriggerHandler {

    public Void OnBeforeInsert(List<Order> lstOrder){
        //System.debug('lstOrder --> '+lstOrder.size());
        try{

            Set<Id> accountIds = new Set<Id>();
            Set<Id> productIds = new Set<Id>();
            for (Order order : lstOrder) {
                accountIds.add(order.AccountId);
                productIds.add(order.Product__c);
            }

            // Get list of all accounts in the order
            Map<Id, Account> accountsMap = new Map<Id, Account>([
                SELECT Id, BillingCity, BillingState, BillingPostalCode,Loyalty_Discount__c FROM Account WHERE Id IN :accountIds
            ]);

            
            //System.debug('accountsMap -->' +accountsMap);

            // Get list of all products in the order
            Map<Id, Product2> productsMap = new Map<Id, Product2>([
                SELECT Id, Name, Quantity__c, Unit_Price__c FROM Product2 WHERE IsActive = true and Id IN :productIds
            ]);

            //System.debug('productsMap -->' +productsMap);

            // Maintain Quantity of Products
            Map<Id,Integer> quantityMap = new Map<Id,Integer>();
            for (Id key : productsMap.keySet()) {
                quantityMap.put(key, (Integer)productsMap.get(key).Quantity__c);
            }

            //System.debug('quantityMap -->' +quantityMap);

            //Get all promo code
            // Get list of all accounts in the order
            Map<String, Decimal> promoCodeMap = new Map<String, Decimal>();
            for (Promo_Code__c p : [SELECT Name, Discount__c FROM Promo_Code__c WHERE active__c = true]){
                    promoCodeMap.put(p.Name, p.Discount__c);
                }
        
            //System.debug('promoCodeMap -->' +promoCodeMap);

            for(Order ord : lstOrder){

                //System.debug('productsMap.get(ord.Product__c) -->' +productsMap.get(ord.Product__c));
                //System.debug('quantityMap.get(ord.Product__c) -->' +quantityMap.get(ord.Product__c));
                //System.debug('ord.Quantity__c -->' +ord.Quantity__c);

                //validate Product
                if(productsMap.get(ord.Product__c) != null && quantityMap.get(ord.Product__c) >= ord.Quantity__c){
                    
                    //do account address validation
                    if(validateAddress(ord, accountsMap.get(ord.AccountId))){

                        Decimal promoDiscount = (promoCodeMap.get(ord.Promo_Code__c) != null ? promoCodeMap.get(ord.Promo_Code__c) : 0);
                        Decimal loyaltyDiscount = accountsMap.get(ord.AccountId).Loyalty_Discount__c;
                        decimal discount = promoDiscount + loyaltyDiscount;

                        calculateCost(ord, discount, productsMap.get(ord.Product__c).Unit_Price__c );

                        //Check product Quantity
                        quantityMap.put(ord.Product__c, (Integer)(quantityMap.get(ord.Product__c)-ord.Quantity__c));


                    }else{
                        ord.addError('Address does not match');
                    }

                }else{
                    ord.addError('Product is out of stock.');
                }
            }


        }catch(Exception ex){

        }
    }

    public Void OnAfterInsert(List<Order> lstOrder){
        try{
            List<Shipment__c> shipmentList = new List<Shipment__c>();
            List<Account> accountList = new List<Account>();
            List<Product2> productList = new List<Product2>();
            Set<Id> products = new Set<Id>();
            Map<Id, Decimal> productsMap = new Map<Id, Decimal>();
            Map<Id,Decimal> accountMap = new Map<Id, Decimal>();

            for (Order order : lstOrder) {
                products.add(order.Product__c);
            }

            for(Product2 prd : [Select Id, Quantity__c from Product2 where id in : products]){
                productsMap.put(prd.Id, prd.Quantity__c);
            }

            for (Order order : lstOrder) {
                
                Shipment__c ship = createShipment(order);
                
                shipmentList.add(ship);
                accountMap.put(order.AccountId, (accountMap.get(order.AccountId) == null ? 0 : accountMap.get(order.AccountId) ) + (order.Total_Cost__c/100));
 
                //System.debug(' Quantity --> '+order.Quantity__c);
                //System.debug(' productsMap.get(order.Product__c)) --> '+productsMap.get(order.Product__c));
                productsMap.put(order.Product__c, productsMap.get(order.Product__c) - order.Quantity__c);
                //System.debug(' productsMap --> '+productsMap);
            }

            for (Id key : accountMap.keySet()) {

                Account acc = new Account();
                acc.Id  = key;
                acc.Loyalty_Points__c  = accountMap.get(key);
                accountList.add(acc);
            }

            for (Id key : productsMap.keySet()) {

                Product2 prd = new Product2();
                prd.Id = key;
                prd.Quantity__c = productsMap.get(key);
                productList.add(prd);
            }

            System.debug(' productList --> '+productList);

            Database.insert(shipmentList,false);
            Database.update(accountList, false);
            Database.update(productList, false);

            List<Product2> prdList = [Select Id, Quantity__c from product2 where id in: productsMap.keySet()];
            System.debug(' prdList --> '+prdList);

            sendShipmentDetails(accountList);

        }catch(Exception ex){

        }
    }

    public boolean validateAddress(Order orderitem, Account account){

        //some logic to validate address

        return true;
    }

    public void calculateCost(Order orderItem, Decimal discount, Decimal unitPrice){

        //System.debug('discount --> ' +discount);
        //System.debug('unitPrice --> ' +unitPrice);

        decimal totalCost = orderItem.Quantity__c * unitPrice;
        
        //System.debug('totalCost --> ' +totalCost); 
        decimal discountedCost = totalCost - (totalCost * discount)/100;

        //System.debug('discountedCost --> ' +discountedCost);

        orderItem.Total_Cost__c = discountedCost;
    }

    public Shipment__c createShipment(Order orderItem){
        Shipment__c ship = new Shipment__c();
        ship.Account__c  = orderItem.AccountId;
        ship.Order__c  = orderItem.Id;
        ship.Status__c  = 'Shipped';

        return ship;
    }

    public void sendShipmentDetails(List<Account> lstAccount){

        //Email Logic
        //Messaging.MassEmailMessage emails=new Messaging.MassEmailMessage(); 
        // ... (set email fields)
        //Messaging.SendEmail(New Messaging.MassEmailMessage[]{emails});

    }
}
