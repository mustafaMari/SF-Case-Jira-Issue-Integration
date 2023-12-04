/**
 * JiraIssueCommentsCreator is a utility class responsible for creating and organizing comments for a Jira issue.
 * It facilitates the creation of text-based comments and attachment uploads to the specified Jira issue.
 */
public without sharing class JiraIssueCommentsCreator {
    private static final String JIRA_COMMENT_TEMPLATE = '{0} - {1} - {2}\n\n{3}\n\n{4}\n\n';
    private static final String HTML_TAGS_REGEX = '<[^>]*>';
    private String issueId;
    private List<JiraObjects.SFCaseComment> caseComments;
    private Map<String, List<JiraObjects.SFCaseComment>> caseCommentsBasedOnType;

    /**
     * Constructor for JiraIssueCommentsCreator class.
     * @param issueId The ID of the Jira issue for which comments are to be created.
     * @param caseComments List of SFCaseComment representing comments related to the issue.
     */
    public JiraIssueCommentsCreator(String issueId, List<JiraObjects.SFCaseComment> caseComments) {
        this.issueId = issueId;
        this.caseComments = caseComments;
        caseCommentsBasedOnType = new Map<String, List<JiraObjects.SFCaseComment>>();
    }

    /**
     * Initiates the process of creating issue comments in Jira by segregating comments based on their type,
     * uploading comment files, and creating text-based comments.
     */
    public void createIssueCommentsInJira() {
        segregateCommentsBasedOnType();
        uploadCommentFiles();
        createTextPostComments();
    }

    /**
     * Segregates comments based on their type for further processing.
     */
    private void segregateCommentsBasedOnType() {
         for(JiraObjects.SFCaseComment caseComment : caseComments) {
            if (!caseCommentsBasedOnType.containsKey(caseComment.Type)) {
                caseCommentsBasedOnType.put(caseComment.Type, new List<JiraObjects.SFCaseComment>());
            }
            caseCommentsBasedOnType.get(caseComment.Type).add(caseComment);
         }
    }

    /**
     * Creates text-based comments for the Jira issue.
     */
    private void createTextPostComments() {
        if(!caseCommentsBasedOnType.containsKey(JiraObjects.TEXT_COMMENT)) {
            return;
        }
        List<JiraObjects.TextContent> jiraComments = getJiraComments(); 
        JiraObjects.CommentRequest createCommentRequests = new JiraObjects.CommentRequest(jiraComments);
        JiraIntegration.addCommentToIssue(issueId, createCommentRequests);
    }

    /**
     * Retrieves text-based comments and converts them into JiraObjects.TextContent for Jira integration.
     * @return List of JiraObjects.TextContent representing the text-based comments.
     */
    private List<JiraObjects.TextContent>  getJiraComments() {
        List<JiraObjects.TextContent> jiraComments = new List<JiraObjects.TextContent>();
        for (JiraObjects.SFCaseComment caseComment : caseCommentsBasedOnType.get(JiraObjects.TEXT_COMMENT)) {
            jiraComments.add(convertCaseCommentToJiraComment(caseComment));
        }
        return jiraComments;
    }

    /**
     * Converts SFCaseComment object to JiraObjects.TextContent for Jira integration.
     * @param caseComment SFCaseComment object to be converted.
     * @return JiraObjects.TextContent representing the converted comment.
     */
    private JiraObjects.TextContent convertCaseCommentToJiraComment(JiraObjects.SFCaseComment caseComment) {
        String body = String.format(JIRA_COMMENT_TEMPLATE,
        new String[]{
            caseComment.prefix,
            caseComment.commentId,
            caseComment.author,
            caseComment.comment,
            String.valueOf(caseComment.createdDate)
        });
        return new JiraObjects.TextContent(body.replaceAll(HTML_TAGS_REGEX, ''));
    }

    /**
     * Uploads comment attachment files to Jira if available.
     */
    private void uploadCommentFiles() {
        if (!caseCommentsBasedOnType.containsKey(JiraObjects.Content_COMMENT)) {
            return;
        }
        Set<Id> sfAttachmentIds = new Set<Id>();
        for (JiraObjects.SFCaseComment caseAttachment : caseCommentsBasedOnType.get(JiraObjects.Content_COMMENT)) {
            if (String.isNotBlank(caseAttachment.comment)) {
                appendContentCommentToTextComment(caseAttachment);
            }
            if(String.isNotBlank(caseAttachment.RelatedRecordId)) {
                sfAttachmentIds.add(caseAttachment.RelatedRecordId);
            }
        }
        retrieveSFFilesAndUploadToJira(sfAttachmentIds);
    }

    /**
     * Appends content comment attachments to the text-based comments for unified processing.
     * @param caseAttachment SFCaseComment representing an attachment to be appended.
     */
    private void appendContentCommentToTextComment(JiraObjects.SFCaseComment caseAttachment) {
        if (!caseCommentsBasedOnType.containsKey(JiraObjects.TEXT_COMMENT)) {
            caseCommentsBasedOnType.put(JiraObjects.TEXT_COMMENT, new List<JiraObjects.SFCaseComment>());
        }
        caseCommentsBasedOnType.get(JiraObjects.TEXT_COMMENT).add(caseAttachment);
    }

    /**
     * Retrieves SF attachment files and uploads them to Jira.
     * @param sfAttachmentIds Set of ContentVersion IDs representing SF attachment files.
     */
    private void retrieveSFFilesAndUploadToJira(Set<Id> sfAttachmentIds) {
        if (sfAttachmentIds.isEmpty()) {
            return;
        }
        for (ContentVersion sfFile : [SELECT Id, PathOnClient, VersionData FROM ContentVersion WHERE Id IN: sfAttachmentIds]) {
            uploadSFAttachment(sfFile);
        }
    }

    /**
     * Uploads SF attachment file to Jira using JiraFileIntegration.
     * @param sfFile ContentVersion object representing the SF attachment file.
     */
    private void uploadSFAttachment(ContentVersion sfFile) {
        JiraFileIntegration jiraFileUploader = new JiraFileIntegration(issueId, sfFile.VersionData, sfFile.PathOnClient);
        jiraFileUploader.uploadFileToJira();
    }

}