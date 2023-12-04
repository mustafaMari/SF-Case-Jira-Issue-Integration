/**
 * The JiraObjects class contains inner classes and constants representing objects and endpoints related to Jira integration.
 * It provides structured representations of requests, responses, and objects required for Jira interactions.
 */
public without sharing class JiraObjects {

    // Constants representing Jira endpoints
    public static final String CREATE_ISSUE_ENDPOINT = 'issue';
    public static final String CREATE_COMMENT_ENDPOINT = 'issue/{!issueId}/comment';
    public static final String REMOTE_LINK_ENDPOINT = 'issue/{!issueId}/remotelink';
    public static final String ISSUE_ATTACHMENT_ENDPOINT = 'issue/{!issueId}/attachments';
    
    // Constants representing comment types and settings
    public static final String CONTENT_COMMENT = 'Content';
    public static final String TEXT_COMMENT = 'Text';
    public static final String SF_CASE_LINK = 'SF Case Link';
    public static final String JIRA_SETTING_NAME = 'Jira_Case';

    public class CreateIssueRequest {
        public Fields fields;
        public CreateIssueRequest(String summary, String description) { 
            fields = new Fields(summary, description);
        }
    }

    public class Fields {
        public JiraIdObject project;
        public String summary;
        public DocContent description;  
        public JiraIdObject issuetype;
        public JiraIdObject reporter;
        public JiraIdObject assignee;
        public ParentIssue parent;
        public Fields(String summary, String description) {
            assignProjectAndIssue();
            this.summary = summary;
            this.description = new DocContent(description);
        }

        private void assignProjectAndIssue() {
            Jira_Integration_Setting__mdt jiraSetting = JiraIntegrationSetting.getJiraIntegrationSetting(JIRA_SETTING_NAME);
            this.project = new JiraIdObject(jiraSetting.Project_Id__c);
            this.issuetype = new JiraIdObject(jiraSetting.Issue_Type_Id__c);
            if (String.isNotBlank(jiraSetting.Reporter_Account_Id__c)) {
                this.reporter = new JiraIdObject(jiraSetting.Reporter_Account_Id__c);
            }
            if (String.isNotBlank(jiraSetting.Assignee_Account_Id__c)) {
                this.assignee = new JiraIdObject(jiraSetting.Assignee_Account_Id__c);
            }
            this.parent = new ParentIssue(jiraSetting.Parent_Key__c);
        }
    }

    public class ParentIssue {
        public String key;
        public ParentIssue(String key) {
            this.key = key;
        }
    }

    public class DocContent {
        public List<ParagraphContent> content;
        public String type = 'doc';
        public Integer version = 1;
        public DocContent(String description) {
            this.content = new List<ParagraphContent>{new ParagraphContent(description)};
        }
        public DocContent(List<TextContent> comments) {
            this.content = new List<ParagraphContent>{new ParagraphContent(comments)};
        }
    }

    public class JiraIdObject {
        public String id;
        public JiraIdObject(String id) {
            this.id = id;
        }
    }

    public class ParagraphContent {
        public List<TextContent> content;
        public String type;

        public ParagraphContent(String description) {
            this.content = new List<TextContent>{new TextContent(description)};
            this.type = 'paragraph';
        }

        public ParagraphContent(List<TextContent> comments) {
            this.content = comments;
            this.type = 'paragraph';
        }
    }

    public class TextContent {
        public String type;
        public String text;

        public TextContent(String description) {
            this.text = description;
            this.type = 'text';
        }
    }

    public class SFCaseComment {
        public String type;
        public String comment;
        public String relatedRecordId;
        public DateTime createdDate;
        public String author;
        public String prefix;
        public String commentId;


        public SFCaseComment(FeedItem caseComment) {
            this.type = getType(caseComment.Type);
            this.comment = caseComment.Body;
            this.relatedRecordId = caseComment.RelatedRecordId;
            this.author = caseComment.CreatedBy.Name;
            this.createdDate = caseComment.CreatedDate;
            this.commentId = caseComment.Id;
            this.prefix = 'New';
        }

        private String getType(String type) {
            if (type == 'ContentComment' || type == 'ContentPost') {
                return CONTENT_COMMENT;
            }
            return TEXT_COMMENT;
        }

        public SFCaseComment(FeedComment caseReply) {
            this.type = getType(caseReply.CommentType);
            this.comment = caseReply.CommentBody;
            this.relatedRecordId = caseReply.RelatedRecordId;
            this.author = caseReply.CreatedBy.Name;
            this.createdDate = caseReply.CreatedDate;
            this.commentId = caseReply.FeedItemId;
            this.prefix = 'Reply';
        }
    }

    public class CreateIssueResponse {
        public String id;
        public String key;

        public CreateIssueResponse(String id, String key) {
            this.id = id;
            this.key = key;
        }
    }

    public class CommentRequest {
        public DocContent body; 
        public CommentRequest(List<TextContent> comments) {
            this.body = new DocContent(comments);
        }
    }

    public class IssueRemoteLinkRequest {
        public JiraLinkObject object_r;
        public IssueRemoteLinkRequest(String caseId) {
            this.object_r = new JiraLinkObject(caseId);
        }
    }

    public class JiraLinkObject {
        private String url_r;
        private String title;
        public JiraLinkObject(String caseId) {
            this.title = JiraObjects.SF_CASE_LINK;
            this.url_r = getOrgBaseURL().replace('{!caseId}', caseId);
        }

        private String getOrgBaseURL() {
            return URL.getOrgDomainURL().toExternalForm() + '/{!caseId}';
        }
    }
}