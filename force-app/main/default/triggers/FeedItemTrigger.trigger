trigger FeedItemTrigger on FeedItem (after insert) {

    Set<Id> caseCommentIds = new Set<Id>();

    for(FeedItem comment : Trigger.new) {
        if (comment.ParentId.getSObjectType() == Case.SObjectType && (comment.Type == 'TextPost' || comment.Type == 'ContentPost')) {
            caseCommentIds.add(comment.Id);
        }
    }

    if (!caseCommentIds.isEmpty()) {
        JiraIntegrationHelper.syncCaseCommentsToJira(caseCommentIds);
    }   
    
}