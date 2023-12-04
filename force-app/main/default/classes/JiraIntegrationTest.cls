/**
 * JiraIntegrationTest is an Apex test class that performs unit tests for Jira integration functionality.
 */
@IsTest
public class JiraIntegrationTest {


    @IsTest
    static void syncNewCaseToJiraTest() {
        Test.setMock(HttpCalloutMock.class, new JiraIntegrationMockService());
        Case newCase;
        Test.startTest();
        newCase = prepareACompleteCase();
        Test.stopTest();
        Case updatedCase = [SELECT Id, Jira_Id__c FROM Case WHERE Id =: newCase.Id];
        Assert.areEqual('Issue-1', updatedCase.Jira_Id__c);
    }

    private static Case prepareACompleteCase() {
        Case newCase = createTestCase(true);
        FeedItem caseComment = addTextCommentToCase(newCase.Id, true);
        addContentCommentToCase(newCase.Id);
        addCommentRelyToCase(caseComment.Id, true);
        return newCase;
    }

    private static Case createTestCase(Boolean insertCase){
        Case newCase = new Case(
            Description = 'Description Test',
            Origin = 'Web',
            Priority = 'Medium'
        );
        if (insertCase) {
            insert newCase;
        }
        return newCase;
    }

    private static FeedItem addTextCommentToCase(Id parentId, Boolean insertComment) {
        FeedItem caseComment = new FeedItem(
            Type = 'TextPost', 
            Body = '<p>Test Comment</p>',
            IsRichText = true,
            ParentId = parentId
        );
        if (insertComment) {
            insert caseComment;
        }
        return caseComment;
    }

    private static void addContentCommentToCase(Id parentId) {
        ContentVersion testFile = new ContentVersion(
            Title = 'Test Attachment',
            PathOnClient = 'test.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert testFile;
        
        ContentVersion contentVersionTest = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :testFile.Id LIMIT 1];
        FeedItem caseComment = new FeedItem(
            Type = 'ContentPost', 
            Body = '<p>Test Comment</p>',
            IsRichText = true,
            ParentId = parentId,
            RelatedRecordId = contentVersionTest.Id
        );
        insert caseComment;
    }

    private static FeedComment addCommentRelyToCase(Id parentCommentId, Boolean insetReply) {
        FeedComment newReply = new FeedComment(
            FeedItemId = parentCommentId, 
            CommentBody = 'Test reply',
            CommentType = 'TextComment',
            IsRichText = false
        );
        if (insetReply) {
            insert newReply;
        }
        return newReply;
    }

    @IsTest
    static void addNewCommentToAlreadySynchedCaseTest() {
        Test.setMock(HttpCalloutMock.class, new JiraIntegrationMockService());
        Case newCase = createAlreadyExistingCase();
        Test.startTest();
        try {
            addTextCommentToCase(newCase.Id, true);
        } catch (Exception e) {
            Assert.isTrue(e == null);
        }        
        Test.stopTest();
    }

    private static Case createAlreadyExistingCase() {
        Case newCase = createTestCase(false);
        newCase.Jira_Id__c = 'Issue-1';
        insert newCase;
        return newCase;
    }

    @IsTest
    static void addNewFileToAlreadySynchedCaseTest() {
        Test.setMock(HttpCalloutMock.class, new JiraIntegrationMockService());
        Case newCase = createAlreadyExistingCase();
        Test.startTest();
        try {
            addContentCommentToCase(newCase.Id);
        } catch (Exception e) {
            Assert.isTrue(e == null);
        }        
        Test.stopTest();
    }

    @IsTest
    static void addNewCommentReplyToAlreadySynchedCaseTest() {
        Test.setMock(HttpCalloutMock.class, new JiraIntegrationMockService());
        Case newCase = createAlreadyExistingCase();
        FeedItem caseComment = addTextCommentToCase(newCase.Id, true);
        Test.startTest();
        try {
            addCommentRelyToCase(caseComment.Id, true);
        } catch (Exception e) {
            Assert.isTrue(e == null);
        }        
        Test.stopTest();
    }
}