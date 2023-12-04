/**
 * JiraCommentsParser class helps parse Jira comments and associate them with Salesforce Case comments.
 * It can parse either feed comment replies or case comments and retrieve parent cases with Jira IDs.
 */
public without sharing class JiraCommentsParser {
    private List<FeedComment> commentReplies;
    private List<FeedItem> caseComments;
    private Map<String, List<JiraObjects.SFCaseComment>> parsedJiraComments;
    private String issueId;

    /**
     * Constructs a JiraCommentsParser object with a list of comment replies.
     * @param commentReplies The list of comment replies to be parsed.
     */
    public JiraCommentsParser(List<FeedComment> commentReplies) {
        this.commentReplies = commentReplies;
    }

    /**
     * Constructs a JiraCommentsParser object with a list of case comments.
     * @param caseComments The list of case comments to be parsed.
     */
    public JiraCommentsParser(List<FeedItem> caseComments) {
        this.caseComments = caseComments;
    }

    /**
     * Parses comments associated with a specified Jira issue ID.
     * @param issueId The Jira issue ID.
     * @return A map containing associated comments with the specified Jira ID.
     */
    public Map<String, List<JiraObjects.SFCaseComment>> parse(String issueId) {
        this.issueId = issueId;
        return parse();
    }

    /**
     * Parses either comments or replies associated with the stored issue ID.
     * @return A map containing associated comments with the stored Jira ID.
     */
    public Map<String, List<JiraObjects.SFCaseComment>> parse() {
        if (caseComments != null) {
            return parseCaseComments();
        }
        return parseCommentReplies();
    }

    /**
     * Parses case comments and associates them with Jira IDs if available.
     * @return A map containing associated comments with Jira IDs, based on the stored issue ID.
     */
    private Map<String, List<JiraObjects.SFCaseComment>> parseCaseComments() {
        Map<Id, List<JiraObjects.SFCaseComment>> parsedSFCaseComments = parseSFComments();
        if (String.isNotBlank(issueId)) {
            return new Map<String, List<JiraObjects.SFCaseComment>>{
                issueId => parsedSFCaseComments.values()[0]
            };
        }
        return getSFCasesWithJiraId(parsedSFCaseComments);
    }

    /**
     * Parses comment replies and associates them with Jira IDs if available.
     * @return A map containing associated comments with Jira IDs, based on the stored issue ID.
     */
    private Map<String, List<JiraObjects.SFCaseComment>> parseCommentReplies() {
        Map<Id, List<JiraObjects.SFCaseComment>> parsedSFCommentReplies = parseSFCommentReplies();
        if (String.isNotBlank(issueId)) {
            return new Map<String, List<JiraObjects.SFCaseComment>>{
                issueId => parsedSFCommentReplies.values()[0]
            };
        }
        return getSFCasesWithJiraId(parsedSFCommentReplies);
    }

    /**
     * Parses Salesforce case comments and associates them with their parent IDs.
     * @return A map containing comments associated with their parent Case IDs.
     */
    public Map<Id, List<JiraObjects.SFCaseComment>> parseSFComments() {
        Map<Id, List<JiraObjects.SFCaseComment>> caseFeedComments = new Map<Id, List<JiraObjects.SFCaseComment>>();
        for (FeedItem comment : caseComments) {
            if (!caseFeedComments.containsKey(comment.ParentId)) {
                caseFeedComments.put(comment.ParentId, new List<JiraObjects.SFCaseComment>());
            }
            caseFeedComments.get(comment.ParentId).add(new JiraObjects.SFCaseComment(comment));
        }
        return caseFeedComments;
    }

    /**
     * Retrieves Salesforce Cases with associated Jira IDs.
     * @param caseComments The map of case comments to be processed.
     * @return A map containing comments associated with their Jira IDs.
     */
    private Map<String, List<JiraObjects.SFCaseComment>> getSFCasesWithJiraId(Map<Id, List<JiraObjects.SFCaseComment>> caseComments) {
        if (caseComments.isEmpty()) {
            return new Map<String, List<JiraObjects.SFCaseComment>>();
        }
        Map<String, List<JiraObjects.SFCaseComment>> commentsToSync = new Map<String, List<JiraObjects.SFCaseComment>>();
        for (Case parentCase : [SELECT Id, Jira_Id__c FROM Case WHERE Id IN: caseComments.keySet()]) {
            if(String.isNotBlank(parentCase.Jira_Id__c)) {
                commentsToSync.put(parentCase.Jira_Id__c, caseComments.get(parentCase.Id));
            }
        }
        return commentsToSync;
    }

    /**
     * Parses Salesforce case comment replies and associates them with their parent IDs.
     * @return A map containing comment replies associated with their parent Case IDs.
     */
    private Map<Id, List<JiraObjects.SFCaseComment>> parseSFCommentReplies() {
        Map<Id, List<JiraObjects.SFCaseComment>> caseFeedComments = new Map<Id, List<JiraObjects.SFCaseComment>>();
        for (FeedComment commentReply : commentReplies) {
            if (!caseFeedComments.containsKey(commentReply.ParentId)) {
                caseFeedComments.put(commentReply.ParentId, new List<JiraObjects.SFCaseComment>());
            }
            caseFeedComments.get(commentReply.ParentId).add(new JiraObjects.SFCaseComment(commentReply));
        }
        return caseFeedComments;
    }
}