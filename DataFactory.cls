@isTest
public class DataFactory {

    public static List<Account> createAccounts(Integer numAccts) {
        List<Account> accts = new List<Account>();
        for(Integer i=0;i<numAccts;i++) {
        Account a = new Account(Name='TestAccount' + i);
        accts.add(a);
        }
        insert accts;
        return accts;
    }
}
