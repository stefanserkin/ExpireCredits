// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

/*
TRecCreditExpirationBatch batch = new TRecCreditExpirationBatch();
Id batchId = Database.executeBatch(batch, 50);
*/

String strQuery = 'SELECT Id FROM Account WHERE RecordType.DeveloperName = 'HH_Account' AND (TREX1__Outstanding_Account_Balance__c = NULL OR TREX1__Outstanding_Account_Balance__c = 0)' + 
            ' AND Id IN (SELECT TREX1__Account__c FROM TREX1__Journal_Entry__c WHERE TREX1__Unapplied_Credit_Amount__c > 0 AND TREX1__Effective_Date_Time__c < LAST_N_DAYS:' + 365 + ')';

// Check bypass for accounts with active billing schedules
if (true) {
    strQuery += ' AND Id NOT IN (SELECT TREX1__Account__c FROM TREX1__Journal_Entry__c WHERE TREX1__Billing_Schedule__r.TREX1__Is_Billable__c = true)';
}

Account[] lstAccs = Database.query(strQuery);

String strAccQuery = 'SELECT Id, npe01__One2OneContact__c, TREX1__Unapplied_Credit_Amount__c, (SELECT Id, TREX1__Credit__c, TREX1__Unapplied_Credit_Amount__c, TREX1__Effective_Date_Time__c, Revenue_GL_Account__c FROM TREX1__Journal_Entries__r' + 
            ' WHERE TREX1__Unapplied_Credit_Amount__c > 0 ';
        strAccQuery += ' AND TREX1__Effective_Date_Time__c < LAST_N_DAYS:' + daysUntilCreditExpiration + ' ORDER BY Revenue_GL_Account__c ASC LIMIT 10000)' + 
            ' FROM Account WHERE Id IN :lstAccounts';
Account[] lstAccsToReturn = Database.query(strAccQuery);

/*
Decimal amt = 520;
TREX1__GL_Account__c revAcc = [SELECT Id, TREX1__GL_Account_Number__c FROM TREX1__GL_Account__c WHERE TREX1__Type__c = 'Income' ORDER BY CreatedDate DESC LIMIT 1];
Contact ct = [SELECT Id, FirstName, LastName, AccountId FROM Contact WHERE FirstName = 'Beethoven' AND LastName = 'Dogg' LIMIT 1];

TREX1__Accounting_Event__c accEv = new TREX1__Accounting_Event__c(         
    TREX1__Effective_Date_Time__c = Datetime.now().addYears(-2),                              // Effective Date Time
    TREX1__Total__c = amt,
    TREX1__Account__c = ct.AccountId,                                   // Account
    TREX1__Contact__c = ct.Id                                  // Contact
);
insert accEv;

List<TREX1__Journal_Entry__c> lstJEs = new List<TREX1__Journal_Entry__c>();

TREX1__Journal_Entry__c debitJe = new TREX1__Journal_Entry__c();
debitJe.TREX1__Debit__c = amt;
debitJe.TREX1__GL_Code__c = revAcc.TREX1__GL_Account_Number__c;
debitJe.TREX1__Effective_Date_Time__c = Datetime.now().addYears(-2);
debitJe.TREX1__Account__c = ct.AccountId;
debitJe.TREX1__Contact__c = ct.Id;
debitJe.TREX1__Accounting_Event__c = accEv.Id;
lstJEs.add(debitJe);

TREX1__Journal_Entry__c creditJe = new TREX1__Journal_Entry__c();
creditJe.TREX1__Credit__c = amt;
creditJe.TREX1__GL_Code__c = '10-10-000-12504';
creditJe.TREX1__Effective_Date_Time__c = Datetime.now().addYears(-2);
creditJe.TREX1__Account__c = ct.AccountId;
creditJe.TREX1__Contact__c = ct.Id;
creditJe.TREX1__Accounting_Event__c = accEv.Id;
lstJEs.add(creditJe);

insert lstJEs;
*/
// TRecCreditExpirationScheduler.run();

/*


private static Id hhRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();
String strQuery = 'SELECT Id FROM Account WHERE RecordTypeId = :hhRecTypeId AND Id IN (SELECT TREX1__Account__c FROM TREX1__Journal_Entry__c' +
            ' WHERE TREX1__Unapplied_Credit_Amount__c > 0' +
            // ' AND TREX1__Effective_Date_Time__c < LAST_N_DAYS:' + daysUntilExpiration + ')';
            ' AND TREX1__Effective_Date_Time__c >= 2023-05-01T00:00:00.000-04:00 ' + 
            ' AND TREX1__Effective_Date_Time__c < 2023-06-01T00:00:00.000-04:00)';

        // Check bypass for accounts with active billing schedules
        if (true) {
            strQuery += ' AND Id NOT IN (SELECT TREX1__Account__c FROM TREX1__Journal_Entry__c WHERE TREX1__Billing_Schedule__r.TREX1__Is_Billable__c = true)';
        }
        System.debug('::::::: size of list --> ' + Database.query(strQuery).size());
*/
/*
Id gbgId = [SELECT Id FROM TREX1__Global_Billing_Group__c WHERE Name = 'Asphalt Green' LIMIT 1].Id;
private static Id recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();
Id tliRecTypeId = Schema.SObjectType.TREX1__Transaction_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Manual_Adjustment').getRecordTypeId();

Decimal amount = 444.00;
Id accId = '0015900000ZVYGJAA5';
Id ctId  = '0035900000TystgAAB';
Id tId   = 'a3G59000000XmFREA0';
Id tliId = 'a3F590000003XmGEAU';
Id aeId  = 'a1F59000001ICTiEAO';
*/

/*
String strQuery = 'SELECT Id FROM Account WHERE RecordTypeId = :recTypeId AND Id IN (SELECT TREX1__Account__c FROM TREX1__Journal_Entry__c' +
            ' WHERE TREX1__Unapplied_Credit_Amount__c > 0' +
            // ' AND TREX1__Effective_Date_Time__c < LAST_N_DAYS:' + daysUntilExpiration + ')';

            // TEST ONLY
            ' AND TREX1__Effective_Date_Time__c <= 2023-06-07T00:00:00.000-04:00' + 
            ' AND TREX1__Effective_Date_Time__c >= 2023-06-05T00:00:00.000-04:00)';

Account[] lstAccs = Database.query(strQuery);
System.debug('::::: size of list --> ' + lstAccs.size());

*/

/*
insert new TREX1__Transaction_Line_Item__c(
    RecordTypeId = tliRecTypeId,                              // Record Type (manual adjustment)
    TREX1__Account__c = accId,                          // Account
    TREX1__Effective_Date__c = Date.today(),                // Effective Date
    TREX1__Contact__c = ctId,                          // Contact
    TREX1__Transaction__c = tId,                       // Transaction
    TREX1__Transaction_Contact__c = ctId,              // Transaction Contact
    TREX1__Description__c = 'Some description',                // Description
    TREX1__Status__c = 'Draft',                            // Status
    TREX1__Type__c = 'Item Event',                            // Type
    TREX1__Event_Type__c = 'Manual Adjustment',               // Event Type
    TREX1__Prorated_Recurring_Fee_Percentage__c = 0.00,       // Prorated_Recurring_Fee_Percentage
    TREX1__Prorated_Recurring_Fee_Amount__c = 0.00,           // Prorated Recurring Fee Amount
    TREX1__Charge_Purchase_Billing_Immediately__c = false,    // Charge Purchase Billing Immediately
    TREX1__Net_Price__c = amount,                     // Net Price
    TREX1__Initial_Fee_Amount__c = amount,            // Initial Fee Amount
    TREX1__Is_Edited__c = false,                              // Is Edited
    TREX1__Override_Price__c = false,                         // Override Price
    TREX1__tli_Global_Billing_Group__c = gbgId,               // Global Billing Group
    TREX1__Override_Prerequisites__c = false,                 // Override Prerequisites
    TREX1__Deferred_Revenue_Recognition_Finished__c = true,  // Deferred Revenue Recognition Finished
    TREX1__Total_Deferred_Revenue__c = 0.00,                    // Total Deferred Revenue
    TREX1__Legacy_Id__c = 'someId00101'             // Wrapper id
);
*/


/*
insert new TREX1__Accounting_Event__c(
    TREX1__System_Generated__c = false,                                          // System Generated
    TREX1__Type__c = 'Manual Adjustment',                                        // Type
    TREX1__Transaction__c = tId,                           // Transaction
    TREX1__Effective_Date_Time__c = Datetime.now(),                              // Effective Date Time
    TREX1__Transaction_Line_Item__c = tliId,                                    // Transaction Line Item
    TREX1__Total__c = amount,                              // Total
    TREX1__Annotation__c = 'Some description',                               // Annotation
    TREX1__Account__c = accId,                                   // Account
    TREX1__Contact__c = ctId,                                   // Contact
    TREX1__Legacy_Id__c = 'some id set by the batch'                                // Wrapper id
);

*/


/*
List<TREX1__Journal_Entry__c> lstJEs = new List<TREX1__Journal_Entry__c>();

TREX1__Journal_Entry__c debitJe = new TREX1__Journal_Entry__c(
    TREX1__Effective_Date_Time__c = Datetime.now(),                              // Effective Date Time
    TREX1__Account__c = accId,                                    // Account
    TREX1__Contact__c = ctId,                                    // Contact
    TREX1__Type__c = 'Manual Adjustment',                                        // Type
    TREX1__Accounting_Event__c = aeId,                                          // Accounting Event
    TREX1__GL_Code__c = '10-10-000-12504',                                                // GL Code
    TREX1__Annotation__c = 'Expiring stuff for funsies',                               // Annotation
    TREX1__Debit__c = amount,                                                    // Debit
    TREX1__Credit__c = 0.00,                                                     // Credit
    TREX1__Is_Tax__c = false,                                                    // Is Tax
    TREX1__Allow_Unapply_Cred_In_Comm_Tx__c = false,                             // Allow Credit Amount usage in Community
    TREX1__Transaction_Line_Item__c = tliId,        // Transaction Line Item
    TREX1__Transaction__c = tId,                            // Transaction
    TREX1__Available_Billing_Payment_Credit__c = false,                          // Credit Available For Billing Payment
    TREX1__Total_Reversed__c = 0.00,                                             // Total Reversed or Refunded
    TREX1__Has_Been_Summarized__c = false                                        // Has Been Summarized
);
lstJEs.add(debitJe);

TREX1__Journal_Entry__c creditJe = new TREX1__Journal_Entry__c(
    TREX1__Effective_Date_Time__c = Datetime.now(),  // Effective Date Time
    TREX1__Account__c = accId,                                    // Account
    TREX1__Contact__c = ctId,                                    // Contact
    TREX1__Type__c = 'Manual Adjustment',                                        // Type
    TREX1__Accounting_Event__c = aeId,                                          // Accounting Event
    TREX1__GL_Code__c = '10-10-205-54005',                                     // GL Code
    TREX1__Annotation__c = 'Expiring stuff for funsies',                               // Annotation
    TREX1__Debit__c = 0.00,                                                      // Debit
    TREX1__Credit__c = amount,                                                   // Credit
    TREX1__Is_Tax__c = false,                                                    // Is Tax
    TREX1__Allow_Unapply_Cred_In_Comm_Tx__c = false,                             // Allow Credit Amount usage in Community
    TREX1__Transaction_Line_Item__c = tliId,        // Transaction Line Item
    TREX1__Transaction__c = tId,                            // Transaction
    TREX1__Available_Billing_Payment_Credit__c = false,                          // Credit Available For Billing Payment
    TREX1__Total_Reversed__c = 0.00,                                             // Total Reversed or Refunded
    TREX1__Has_Been_Summarized__c = false,                                       // Has Been Summarized
    TREX1__Legacy_Id__c = 'some legacy id set by the batch'
);
lstJEs.add(creditJe);

insert lstJEs;

*/

