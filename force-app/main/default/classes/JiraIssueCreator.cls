/**
 * JiraIssueCreator is a utility class responsible for synchronizing a Case with Jira.
 * It creates the corresponding Jira issue, links it to the SF Case, and synchronizes existing comments and replies.
 */
public without sharing class JiraIssueCreator {
    private Case caseToSync;
    public Boolean updateCase;
    JiraObjects.CreateIssueResponse jiraResponse;
    List<FeedItem> existingComment;
    List<FeedComment> existingReplies;
  
    /**
     * Constructor for JiraIssueCreator class.
     * @param caseToSync Case object representing the Case to be synchronized with Jira.
     */
    public JiraIssueCreator(Case caseToSync) {
        this.caseToSync = caseToSync;
        updateCase = false;
    }

    /**
     * Initiates the process of creating the Case in Jira and synchronizing existing comments and replies.
     */
    public void createCaseInJira() {
        JiraObjects.CreateIssueRequest createIssueRequest = new JiraObjects.CreateIssueRequest(caseToSync.Subject, caseToSync.Description);
        jiraResponse = JiraIntegration.createIssueInJira(createIssueRequest);
        caseToSync.Jira_Id__c = jiraResponse.key;
        linkSFCaseToIssue();
        syncExistingComments();
        updateCase = true;
    }

    /**
     * Links the SF Case to the created Jira issue.
     */
    private void linkSFCaseToIssue() {
        JiraObjects.IssueRemoteLinkRequest linkSFCaseToIssueRequest = new JiraObjects.IssueRemoteLinkRequest(caseToSync.Id);
        JiraIntegration.linkSFCaseToJiraIssue(jiraResponse.key, linkSFCaseToIssueRequest);
    }

    /**
     * Synchronizes existing comments related to the SF Case with the Jira issue.
     */
    private void syncExistingComments() {
        existingComment = [SELECT Id, Type, Body, ParentId, CreatedBy.Name, CreatedDate, RelatedRecordId 
        FROM FeedItem 
        WHERE ParentId =: caseToSync.Id
        AND Type IN ('TextPost', 'ContentPost')];
        if (!existingComment.isEmpty()) {
            JiraCommentsParser commentParser = new JiraCommentsParser(existingComment);
            JiraIntegrationHelper.pushCommentsToJira(commentParser.parse(jiraResponse.key));  
            syncExistingReplies(); 
        }
    }

    /**
     * Synchronizes existing comment replies related to the SF Case with the Jira issue.
     */
    private void syncExistingReplies() {
        existingReplies = [SELECT Id, FeedItemId, CommentType, CommentBody, ParentId, CreatedBy.Name, CreatedDate, RelatedRecordId 
        FROM FeedComment 
        WHERE FeedItemId 
        IN: existingComment];
        if (!existingReplies.isEmpty()) {
            JiraCommentsParser commentParser = new JiraCommentsParser(existingReplies);
            JiraIntegrationHelper.pushCommentsToJira(commentParser.parse(jiraResponse.key));
        }
    }
}