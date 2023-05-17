public with sharing class TRecCreditExpirationBatch implements Database.Batchable<sObject> {
    
    public static final String BATCH_NAME = 'TRec Credit Expiration Batch';
    private static final String ADJUSTMENT_DESCRIPTION = 'Expired credits';

    private static Id tliRecTypeId = Schema.SObjectType.TREX1__Transaction_Line_Item__c.getRecordTypeInfosByDeveloperName().get('Manual_Adjustment').getRecordTypeId();
    private static Id gbgId;

    private static String arGlCode;
    private static String arGlAccountName;
    private static String expiredCreditGlCode;
    private static String expiredCreditGlAccountName;
    private static Decimal daysUntilCreditExpiration;
    private static Boolean globalGlInfoIsSet = false;

    private static Integer batchCounter = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Set global gl info
        if (!globalGlInfoIsSet) {
            setGlInfo();
            globalGlInfoIsSet = true;
            System.debug(':::::: expiration gl code after global accs are set: ' + expiredCreditGlCode);
            System.debug(':::::: expiration gl account name after global accs are set: ' + expiredCreditGlAccountName);
            System.debug(':::::: num days until expiration after global accs are set: ' + String.valueOf(daysUntilCreditExpiration));
        }
        // Get all account ids with credits to expire
        // Accounts will be re-queried for journal entry details within the execute method
        String strQuery = 'SELECT Id FROM Account WHERE Id IN (SELECT TREX1__Account__c FROM TREX1__Journal_Entry__c' +
            ' WHERE TREX1__Unapplied_Credit_Amount__c > 0' +
            ' AND TREX1__Effective_Date_Time__c < LAST_N_DAYS:' + String.valueOf(daysUntilCreditExpiration) + ')';
        return Database.getQueryLocator(strQuery);
    }

    public void execute(Database.BatchableContext bc, List<Account> lstAccounts) {
        // Increment batch counter
        batchCounter++;

        // Set GBG id
        if (gbgId == null) {
            gbgId = [SELECT Id FROM TREX1__Global_Billing_Group__c WHERE Name = 'Asphalt Green' LIMIT 1].Id;
            System.debug(':::::: set gbgId: ' + gbgId);
        }
        
        // Get a list of accounts with expired credit child jes
        List<Account> lstAccsWithCredits = getAccountWithCredits(lstAccounts);

        // Set map of account amounts to expire
        Map<Id, Decimal> mapAccountIdsToAmount = new Map<Id, Decimal>();
        for (Account acc : lstAccsWithCredits) {
            Decimal totalToExpire = 0;
            for (TREX1__Journal_Entry__c je : acc.TREX1__Journal_Entries__r) {
                totalToExpire += je.TREX1__Unapplied_Credit_Amount__c;
            }
            mapAccountIdsToAmount.put(
                acc.Id,
                totalToExpire
            );
        }

        // Create one transaction for each account
        List<TREX1__Transaction__c> lstTransactions = new List<TREX1__Transaction__c>();
        for (Account acc : lstAccsWithCredits) {
            lstTransactions.add( 
                getTransaction(acc)
            );
        }
        insert lstTransactions;
        System.debug(':::::: Created ' + lstTransactions.size() + ' transactions in batch ' + String.valueOf(batchCounter));

        // Create one transaction line item for each transaction
        List<TREX1__Transaction_Line_Item__c> lstTlis = new List<TREX1__Transaction_Line_Item__c>();
        for (TREX1__Transaction__c trans : lstTransactions) {
            lstTlis.add( 
                getTli(trans, mapAccountIdsToAmount.get(trans.TREX1__Account__c)) 
            );
        }
        insert lstTlis;
        System.debug(':::::: Created ' + lstTlis.size() + ' tlis in batch ' + String.valueOf(batchCounter));

        // Create one accounting event for each transaction line item
        List<TREX1__Accounting_Event__c> lstAccountingEvents = new List<TREX1__Accounting_Event__c>();
        for (TREX1__Transaction_Line_Item__c tli : lstTlis) {
            lstAccountingEvents.add(
                getAccountingEvent(tli, mapAccountIdsToAmount.get(tli.TREX1__Account__c) )
            );
        }
        insert lstAccountingEvents;
        System.debug(':::::: Created ' + lstAccountingEvents.size() + ' accounting events in batch ' + String.valueOf(batchCounter));

        // Create two journal entries for each accounting event
        List<TREX1__Journal_Entry__c> lstJEs = new List<TREX1__Journal_Entry__c>();
        for (TREX1__Accounting_Event__c ae : lstAccountingEvents) {
            lstJEs.addAll(
                getJournalEntries(ae, mapAccountIdsToAmount.get(ae.TREX1__Account__c))
            );
        }
        insert lstJEs;
        System.debug(':::::: Created ' + lstJEs.size() + ' journal entries in batch ' + String.valueOf(batchCounter));
        
        // Add debit jes to map for easier assignment in links
        Map<Id, Id> mapAccIdToDebitArJeId = new Map<Id, Id>();
        for (TREX1__Journal_Entry__c je : lstJEs) {
            mapAccIdToDebitArJeId.put(je.TREX1__Account__c, je.Id);
        }

        // Link debit jes to expiring credits
        List<TREX1__Payment_Link__c> lstPaymentLinks = new List<TREX1__Payment_Link__c>();
        for (Account acc : lstAccsWithCredits) {
            for (TREX1__Journal_Entry__c je : acc.TREX1__Journal_Entries__r) {
                lstPaymentLinks.add(
                    new TREX1__Payment_Link__c(
                        TREX1__AR_Debit__c = mapAccIdToDebitArJeId.get(acc.Id), 
                        TREX1__AR_Credit__c = je.Id, 
                        TREX1__Amount__c = je.TREX1__Unapplied_Credit_Amount__c
                    )
                );
            }
        }
        insert lstPaymentLinks;
        System.debug(':::::: Created ' + lstPaymentLinks.size() + ' payment links in batch ' + String.valueOf(batchCounter));

    }

    public void finish(Database.BatchableContext bc) {
        AsyncApexJob apexJob = [
            SELECT Id, 
                   Status, 
                   NumberOfErrors, 
                   JobItemsProcessed, 
                   TotalJobItems, 
                   CreatedBy.Email
              FROM AsyncApexJob 
             WHERE Id = :bc.getJobId()
        ];
        
        // Send email to job creator with batch results
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {apexJob.CreatedBy.Email};
        email.setToAddresses(toAddress);
        email.setSubject(apexJob.Status + ': ' + BATCH_NAME);
        email.setPlainTextBody('The ' + BATCH_NAME + ' ran and processed ' + apexJob.TotalJobItems + ' batches with ' + apexJob.NumberOfErrors + ' failures. Job Id: ' + apexJob.Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }

    private List<Account> getAccountWithCredits(
        List<Account> lstAccounts
    ) {
        return [
            SELECT Id, 
                   npe01__One2OneContact__c, 
                   TREX1__Unapplied_Credit_Amount__c, 
                   TREX1__Outstanding_Account_Balance__c, 
                   (SELECT Id, 
                           TREX1__Credit__c, 
                           TREX1__Unapplied_Credit_Amount__c, 
                           TREX1__Effective_Date_Time__c
                      FROM TREX1__Journal_Entries__r 
                     WHERE TREX1__Unapplied_Credit_Amount__c > 0 
                       AND TREX1__Effective_Date_Time__c < LAST_N_DAYS:365) 
              FROM Account
             WHERE Id IN :lstAccounts
        ];
    }

    private TREX1__Transaction__c getTransaction(
        Account acc
    ) {
        return new TREX1__Transaction__c(
            TREX1__Account__c = acc.Id, 
            TREX1__Contact__c = acc.npe01__One2OneContact__c, 
            TREX1__Created_Online__c = false, 
            TREX1__Status__c = 'Close', 
            TREX1__Exclude_From_Automatic_Cleanup__c = false 
        );
    }

    private TREX1__Transaction_Line_Item__c getTli(
        TREX1__Transaction__c trans, 
        Decimal amount
    ) {
        return new TREX1__Transaction_Line_Item__c(
            TREX1__Account__c = trans.TREX1__Account__c,                          // Account
            TREX1__Effective_Date__c = Date.today(),                // Effective Date
            TREX1__Contact__c = trans.TREX1__Contact__c,                          // Contact
            TREX1__Transaction__c = trans.Id,                       // Transaction
            TREX1__Transaction_Contact__c = trans.TREX1__Contact__c,              // Transaction Contact
            RecordTypeId = tliRecTypeId,                              // Record Type
            TREX1__Description__c = ADJUSTMENT_DESCRIPTION,                // Description
            TREX1__Status__c = 'Complete',                            // Status
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
            TREX1__Deferred_Revenue_Recognition_Finished__c = false,  // Deferred Revenue Recognition Finished
            TREX1__Total_Deferred_Revenue__c = 0.00                   // Total Deferred Revenue
        );
    }

    private TREX1__Accounting_Event__c getAccountingEvent(
        TREX1__Transaction_Line_Item__c tli, 
        Decimal amount
    ) {
        return new TREX1__Accounting_Event__c(
            TREX1__System_Generated__c = false,                                          // System Generated
            TREX1__Type__c = 'Manual Adjustment',                                        // Type
            TREX1__Transaction__c = tli.TREX1__Transaction__c,                           // Transaction
            TREX1__Effective_Date_Time__c = Datetime.now(),  // Effective Date Time
            TREX1__Transaction_Line_Item__c = tli.Id,                                    // Transaction Line Item
            TREX1__Total__c = amount,                                                    // Total
            TREX1__Annotation__c = ADJUSTMENT_DESCRIPTION,                                   // Annotation
            TREX1__Account__c = tli.TREX1__Account__c,                                   // Account
            TREX1__Contact__c = tli.TREX1__Contact__c
        );
    }

    private List<TREX1__Journal_Entry__c> getJournalEntries(
        TREX1__Accounting_Event__c ae, 
        Decimal amount
    ) {
        List<TREX1__Journal_Entry__c> lstJEs = new List<TREX1__Journal_Entry__c>();

        TREX1__Journal_Entry__c debitJe = new TREX1__Journal_Entry__c(
            TREX1__Effective_Date_Time__c = Datetime.now(),  // Effective Date Time
            TREX1__Account__c = ae.TREX1__Account__c,                                             // Account
            TREX1__Contact__c = ae.TREX1__Contact__c,                                             // Contact
            TREX1__Type__c = 'Manual Adjustment',                                        // Type
            TREX1__Accounting_Event__c = ae.Id,                                    // Accounting Event
            TREX1__GL_Code__c = arGlCode,                                       // GL Code
            TREX1__Annotation__c = ADJUSTMENT_DESCRIPTION,                                    // Annotation
            TREX1__Debit__c = amount,                                                    // Debit
            TREX1__Credit__c = 0.00,                                                     // Credit
            TREX1__Is_Tax__c = false,                                                    // Is Tax
            GL_Account_Name__c = arGlAccountName,                                  // GL Account Name
            TREX1__Allow_Unapply_Cred_In_Comm_Tx__c = false,                             // Allow Credit Amount usage in Community
            TREX1__Transaction_Line_Item__c = ae.TREX1__Transaction_Line_Item__c,                               // Transaction Line Item
            TREX1__Available_Billing_Payment_Credit__c = false,                          // Credit Available For Billing Payment
            TREX1__Total_Reversed__c = 0.00,                                             // Total Reversed or Refunded
            TREX1__Has_Been_Summarized__c = false                                        // Has Been Summarized
        );
        lstJEs.add(debitJe);

        TREX1__Journal_Entry__c creditJe = new TREX1__Journal_Entry__c(
            TREX1__Effective_Date_Time__c = Datetime.now(),  // Effective Date Time
            TREX1__Account__c = ae.TREX1__Account__c,                                             // Account
            TREX1__Contact__c = ae.TREX1__Contact__c,                                             // Contact
            TREX1__Type__c = 'Manual Adjustment',                                        // Type
            TREX1__Accounting_Event__c = ae.Id,                                    // Accounting Event
            TREX1__GL_Code__c = expiredCreditGlCode,                                       // GL Code
            TREX1__Annotation__c = ADJUSTMENT_DESCRIPTION,                                    // Annotation
            TREX1__Debit__c = 0.00,                                                      // Debit
            TREX1__Credit__c = amount,                                                   // Credit
            TREX1__Is_Tax__c = false,                                                    // Is Tax
            GL_Account_Name__c = expiredCreditGlAccountName,                 // GL Account Name
            TREX1__Allow_Unapply_Cred_In_Comm_Tx__c = false,                             // Allow Credit Amount usage in Community
            TREX1__Transaction_Line_Item__c = ae.TREX1__Transaction_Line_Item__c,                               // Transaction Line Item
            TREX1__Available_Billing_Payment_Credit__c = false,                          // Credit Available For Billing Payment
            TREX1__Total_Reversed__c = 0.00,                                             // Total Reversed or Refunded
            TREX1__Has_Been_Summarized__c = false                                        // Has Been Summarized
        );
        lstJEs.add(creditJe);

        return lstJEs;
    }

    private void setGlInfo() {
        // Get map of gl codes to account names from singleton
        Map<String, String> mapGlCodeToAccount = TRecGLAccountUtility.getInstance().mapGlCodeToName;
        // Get Traction Rec default global gl accounts from custom setting
        TREX1__Global_GL_Accounts__c globalGls = TREX1__Global_GL_Accounts__c.getOrgDefaults();
        // Set static variables for AR and expired credit gl codes and number of days policy
        arGlCode = globalGls.TREX1__Accounts_Receivable__c;
        expiredCreditGlCode = globalGls.Expired_Credits__c;
        daysUntilCreditExpiration = globalGls.Days_Until_Credit_Expiration__c;
        // Set gl account names from map
        arGlAccountName = mapGlCodeToAccount.get(arGlCode);
        expiredCreditGlAccountName = mapGlCodeToAccount.get(expiredCreditGlCode);
    }

}