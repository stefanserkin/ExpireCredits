/************************************************
 * A staged credit expiration for use in the TRec Credit Expiration Batch
 *   TRecCreditExpirationBatch.cls
 ************************************************/
public class TRecExpiredCreditWrapper {

    /*******************************************
     * Wrapper Id
     *******************************************/
    public String wrapperId;

    /*******************************************
     * Account Id
     *******************************************/
    public Id accountId;

    /*******************************************
     * Primary Contact Id
     *******************************************/
    public Id contactId;

    /*******************************************
     * Amount of credit to expire
     *******************************************/
    public Decimal amountToExpire;

    /*******************************************
     * GL code to credit in the expiration
     * Accounts Receivable will be debited
     *******************************************/
    public String glCodeToCredit;

    /*******************************************
     * List of journal entries to expire
     * Should all represent debits to AR with a positive value of unlinked credits
     * Expiration debits to AR will be linked to these AR credits
     *******************************************/
    public List<TREX1__Journal_Entry__c> lstJEsToExpire;
    
}