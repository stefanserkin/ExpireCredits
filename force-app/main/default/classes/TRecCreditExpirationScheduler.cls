public with sharing class TRecCreditExpirationScheduler implements Schedulable {

    public static String schedule = '0 42 11 ? * *'; // Every day at 11:42am

    public static final String JOB_NAME = 'Expire Traction Rec Credits';

    public static String run() {
        TRecCreditExpirationScheduler sched = new TRecCreditExpirationScheduler();
        return System.schedule(JOB_NAME, schedule, sched);
    }

    public void execute(SchedulableContext context) {
        TRecCreditExpirationBatch batch = new TRecCreditExpirationBatch();
        Id batchId = Database.executeBatch(batch, 50);
    }

}