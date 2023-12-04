/**
 * JiraIntegrationHelper class provides methods to synchronize Salesforce Case and Case Comments data with Jira through asynchronous callouts.
 * It facilitates syncing Cases, Case Comments, and their replies to Jira.
 */
public without sharing class JiraIntegrationHelper {
        
    /**
     * Asynchronously synchronizes Salesforce Cases to Jira.
     * Creates Jira issues for the provided Case IDs and updates Cases if necessary.
     * @param caseIds Set of Case IDs to be synchronized with Jira.
     */
    @future(callout=true)
    public static void syncCasesToJira(Set<Id> caseIds) {
        List<Case> casesToUpdate = new List<Case>();
        for (Case caseToSync : [SELECT Id, Subject, Description FROM Case WHERE Id IN: caseIds]) {
            JiraIssueCreator issueCreator = new JiraIssueCreator(caseToSync);
            issueCreator.createCaseInJira();
            if (issueCreator.updateCase) {
                casesToUpdate.add(caseToSync);
            }
        }
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }

    /**
     * Asynchronously synchronizes Case Comments to Jira.
     * Pushes Case Comments to Jira using JiraCommentsParser.
     * @param caseCommentToSync Set of Case Comment IDs to be synchronized with Jira.
     */
    @future(callout=true)
    public static void syncCaseCommentsToJira(Set<Id> caseCommentToSync) {
        pushCaseCommentToJira(getCaseComments(caseCommentToSync));
    }


    /**
     * Retrieves Case Comments based on the provided IDs.
     * @param caseCommentToSync Set of Case Comment IDs.
     * @return List of FeedItem representing Case Comments.
     */
    private static List<FeedItem> getCaseComments(Set<Id> caseCommentToSync) {
        return [SELECT Id, Type, Body, ParentId, CreatedBy.Name, CreatedDate, RelatedRecordId 
        FROM FeedItem 
        WHERE Id IN: caseCommentToSync];
    }

    /**
     * Pushes Case Comments to Jira using JiraCommentsParser.
     * @param caseComments List of FeedItem representing Case Comments.
     */
    public static void pushCaseCommentToJira(List<FeedItem> caseComments) {
        JiraCommentsParser commentParser = new JiraCommentsParser(caseComments);
        pushCommentsToJira(commentParser.parse());
    }

    /**
     * Pushes parsed Case Comments to Jira.
     * @param caseComments Map containing Jira Issue IDs mapped to lists of SFCaseComment objects.
     */
    public static void pushCommentsToJira(Map<String, List<JiraObjects.SFCaseComment>> caseComments) {
        for (String issueId : caseComments.keySet()) {
            JiraIssueCommentsCreator issusCommentsCreator = new JiraIssueCommentsCreator(issueId, caseComments.get(issueId));
            issusCommentsCreator.createIssueCommentsInJira(); 
        }
    }

    /**
     * Asynchronously synchronizes Case Comment replies to Jira.
     * Pushes Case Comment replies to Jira using JiraCommentsParser.
     * @param caseReplyIds Set of Case Comment Reply IDs to be synchronized with Jira.
     */
    @future(callout=true)
    public static void syncCaseRepliesToJira(Set<Id> caseReplyIds) {
        pushCommentRepliesToJira(getCaseReplies(caseReplyIds));
    }
        
    /**
     * Retrieves Case Comment replies based on the provided IDs.
     * @param caseRepliesIds Set of Case Comment Reply IDs.
     * @return List of FeedComment representing Case Comment Replies.
     */
    private static List<FeedComment> getCaseReplies(Set<Id> caseRepliesIds) {
        return [SELECT Id, FeedItemId, CommentType, CommentBody, ParentId, CreatedBy.Name, CreatedDate, RelatedRecordId 
        FROM FeedComment 
        WHERE Id IN: caseRepliesIds];
    }

    /**
     * Pushes Case Comment replies to Jira using JiraCommentsParser.
     * @param commentReplies List of FeedComment representing Case Comment Replies.
     */
    public static void pushCommentRepliesToJira(List<FeedComment> commentReplies) {
        JiraCommentsParser commentParser = new JiraCommentsParser(commentReplies);
        pushCommentsToJira(commentParser.parse());
    }

    /**
     * Determines if a Case should be synchronized to Jira.
     *
     * @param caseToCheck The Case object to check for synchronization.
     * @return Boolean value indicating whether the Case should be synchronized to Jira.
     */
    public static Boolean shouldCaseBySynchedToJira(Case caseToCheck) {
        return String.isBlank(caseToCheck.Jira_Id__c);
    }

}