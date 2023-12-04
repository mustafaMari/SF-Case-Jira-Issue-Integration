trigger JiraCaseTrigger on Case (after insert, after update) {
    Set<Id> casesToSync = new Set<Id>();
    for (Case newCase : trigger.new) {
        if (JiraIntegrationHelper.shouldCaseBySynchedToJira(newCase)) {
            casesToSync.add(newCase.Id);
        }
    }
    if (!casesToSync.isEmpty()) { 
        JiraIntegrationHelper.syncCasesToJira(casesToSync);
    }
}