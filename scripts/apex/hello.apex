// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents



TRecCreditExpirationScheduler.run();

/*
Id accountId = '0016u00000c3wHJAAY';
Id contactId = '0036u00000b2u81AAA';
Id tliRecTypeId = '0125e000000iYFiAAM';
Id gbgId = 'a2L5e000001nyNxEAI';
Decimal amountToExpire = 180;

TRecTriggerBypass bypass = new TRecTriggerBypass();
bypass.addObject('TREX1__Transaction__c');
bypass.addObject('TREX1__Transaction_Line_Item__c');
bypass.addObject('TREX1__Accounting_Event__c');
bypass.addObject('TREX1__Journal_Entry__c');
bypass.bypassAll('Expiring credits test');

TREX1__Transaction__c trans = new TREX1__Transaction__c(
  TREX1__Account__c = accountId,                          // Account
  TREX1__Contact__c = contactId,                          // Contact
  TREX1__Created_Online__c = false,                       // Created Online
  TREX1__Status__c = 'Draft',                             // Status
  TREX1__Exclude_From_Automatic_Cleanup__c = false        // Exclude From Automatic Cleanup
);
insert trans;

TREX1__Transaction_Line_Item__c tli = new TREX1__Transaction_Line_Item__c(
  TREX1__Account__c = accountId,                          // Account
  TREX1__Effective_Date__c = Date.today(),                // Effective Date
  TREX1__Contact__c = contactId,                          // Contact
  TREX1__Transaction__c = trans.Id,                       // Transaction
  TREX1__Transaction_Contact__c = contactId,              // Transaction Contact
  RecordTypeId = tliRecTypeId,                               // Record Type
  TREX1__Description__c = 'Expired credits',                // Description
  TREX1__Status__c = 'Complete',                            // Status
  TREX1__Type__c = 'Item Event',                            // Type
  TREX1__Event_Type__c = 'Manual Adjustment',               // Event Type
  TREX1__Prorated_Recurring_Fee_Percentage__c = 0.00,       // Prorated_Recurring_Fee_Percentage
  TREX1__Prorated_Recurring_Fee_Amount__c = 0.00,           // Prorated Recurring Fee Amount
  TREX1__Charge_Purchase_Billing_Immediately__c = false,    // Charge Purchase Billing Immediately
  TREX1__Net_Price__c = amountToExpire,                             // Net Price
  TREX1__Initial_Fee_Amount__c = amountToExpire,                    // Initial Fee Amount
  TREX1__Is_Edited__c = false,                              // Is Edited
  TREX1__Override_Price__c = false,                         // Override Price
  TREX1__tli_Global_Billing_Group__c = gbgId,               // Global Billing Group
  TREX1__Override_Prerequisites__c = false,                 // Override Prerequisites
  TREX1__Deferred_Revenue_Recognition_Finished__c = false,  // Deferred Revenue Recognition Finished
  TREX1__Total_Deferred_Revenue__c = 0.00                   // Total Deferred Revenue
);
insert tli;

TREX1__Accounting_Event__c ae = new TREX1__Accounting_Event__c(
  TREX1__System_Generated__c = false,                                          // System Generated
  TREX1__Type__c = 'Manual Adjustment',                                        // Type
  TREX1__Transaction__c = trans.Id,                                         // Transaction
  TREX1__Effective_Date_Time__c = Datetime.now(),  // Effective Date Time
  TREX1__Transaction_Line_Item__c = tli.Id,                               // Transaction Line Item
  TREX1__Total__c = amountToExpire,                                                    // Total
  TREX1__Annotation__c = 'Balance Transfer',                                   // Annotation
  TREX1__Account__c = accountId,                                             // Account
  TREX1__Contact__c = contactId                                              // Contact
);
insert ae;

TREX1__Journal_Entry__c debitJe = new TREX1__Journal_Entry__c(
  TREX1__Effective_Date_Time__c = Datetime.now(),  // Effective Date Time
  TREX1__Account__c = accountId,                                             // Account
  TREX1__Contact__c = contactId,                                             // Contact
  TREX1__Type__c = 'Manual Adjustment',                                        // Type
  TREX1__Accounting_Event__c = ae.Id,                                    // Accounting Event
  TREX1__GL_Code__c = '10-10-000-12504',                                       // GL Code
  TREX1__Annotation__c = 'Expired credits',                                    // Annotation
  TREX1__Debit__c = amountToExpire,                                                    // Debit
  TREX1__Credit__c = 0.00,                                                     // Credit
  TREX1__Is_Tax__c = false,                                                    // Is Tax
  GL_Account_Name__c = 'Accounts Receivable',                                  // GL Account Name
  TREX1__Allow_Unapply_Cred_In_Comm_Tx__c = false,                             // Allow Credit Amount usage in Community
  TREX1__Transaction_Line_Item__c = tli.Id,                               // Transaction Line Item
  TREX1__Available_Billing_Payment_Credit__c = false,                          // Credit Available For Billing Payment
  TREX1__Total_Reversed__c = 0.00,                                             // Total Reversed or Refunded
  TREX1__Has_Been_Summarized__c = false                                        // Has Been Summarized
);
insert debitJe;

TREX1__Journal_Entry__c creditJe = new TREX1__Journal_Entry__c(
  TREX1__Effective_Date_Time__c = Datetime.now(),  // Effective Date Time
  TREX1__Account__c = accountId,                                             // Account
  TREX1__Contact__c = contactId,                                             // Contact
  TREX1__Type__c = 'Manual Adjustment',                                        // Type
  TREX1__Accounting_Event__c = ae.Id,                                    // Accounting Event
  TREX1__GL_Code__c = '10-10-111-11111',                                       // GL Code
  TREX1__Annotation__c = 'Expired credits',                                    // Annotation
  TREX1__Debit__c = 0.00,                                                      // Debit
  TREX1__Credit__c = amountToExpire,                                                   // Credit
  TREX1__Is_Tax__c = false,                                                    // Is Tax
  GL_Account_Name__c = 'Little Piggy Bank of Expired Credits',                 // GL Account Name
  TREX1__Allow_Unapply_Cred_In_Comm_Tx__c = false,                             // Allow Credit Amount usage in Community
  TREX1__Transaction_Line_Item__c = tli.Id,                               // Transaction Line Item
  TREX1__Available_Billing_Payment_Credit__c = false,                          // Credit Available For Billing Payment
  TREX1__Total_Reversed__c = 0.00,                                             // Total Reversed or Refunded
  TREX1__Has_Been_Summarized__c = false                                        // Has Been Summarized
);
insert creditJe;

trans.TREX1__Status__c = 'Close';
update trans;


Id aeCreditId = 'a2S6u000000JwFNEA0';
Id aeDebitId = 'a2S6u000000JwFIEA0';
Decimal amountToExpire = 180;

TREX1__Payment_Link__c sobj = new TREX1__Payment_Link__c(
  TREX1__AR_Debit__c = aeDebitId, // AR Debit
  TREX1__AR_Credit__c = aeCreditId,  // AR Credit
  TREX1__Amount__c = amountToExpire        // Amount
);
insert sobj;

Id recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();

List<Account> lstAccs = [
  SELECT Id
    FROM Account 
   WHERE RecordTypeId = :recTypeId
     AND Id IN (SELECT TREX1__Account__c 
                  FROM TREX1__Journal_Entry__c 
                 WHERE TREX1__Unapplied_Credit_Amount__c > 0
                   AND TREX1__Effective_Date_Time__c < LAST_N_DAYS:365)
];
System.debug(':::: found ' + lstAccs.size() + ' accounts');
AggregateResult[] lstARs = [
  SELECT sum(TREX1__Unapplied_Credit_Amount__c) sumCredit
    FROM TREX1__Journal_Entry__c 
   WHERE TREX1__Account__c IN :lstAccs
     AND TREX1__Unapplied_Credit_Amount__c > 0
     AND TREX1__Effective_Date_Time__c < LAST_N_DAYS:365
];
System.debug('total credit: ' + lstARs[0].get('sumCredit'));
*/