public with sharing class TRecCreditExpirationScheduler implements Schedulable {

    public static String schedule = '0 24 20 ? * *'; // Every day at 8:24pm

    public static final String JOB_NAME = 'Expire Traction Rec Credits';

    public static String run() {
        TRecCreditExpirationScheduler sched = new TRecCreditExpirationScheduler();
        return System.schedule(JOB_NAME, schedule, sched);
    }

    public void execute(SchedulableContext context) {
        // Activate trigger bypass for manual adjustment sobject types
        TRecTriggerBypass bypass = new TRecTriggerBypass();
        bypass.addObject('TREX1__Transaction__c');
        bypass.addObject('TREX1__Transaction_Line_Item__c');
        bypass.addObject('TREX1__Accounting_Event__c');
        bypass.addObject('TREX1__Journal_Entry__c');
        bypass.bypassAll(JOB_NAME);

        // Execute batch
        TRecCreditExpirationBatch batch = new TRecCreditExpirationBatch();
        Id batchId = Database.executeBatch(batch, 50);

        // Disable Traction Rec trigger bypass for the sobject types
        bypass.disableAllBypasses();
    }

}