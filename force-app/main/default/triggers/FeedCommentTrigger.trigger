trigger FeedCommentTrigger on FeedComment (after insert) {

    Set<Id> caseReplyIds = new Set<Id>();

    for(FeedComment comment : Trigger.new) {
        if (comment.ParentId.getSObjectType() == Case.SObjectType) {
            caseReplyIds.add(comment.Id);
        }
    }

    if (!caseReplyIds.isEmpty()) {
        JiraIntegrationHelper.syncCaseRepliesToJira(caseReplyIds);
    }   

}