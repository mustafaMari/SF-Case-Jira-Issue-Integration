/**
 * JiraIntegration class provides static methods for interacting with Jira through HTTP callouts.
 * It offers functionalities to create issues, add comments, and link Salesforce Cases to Jira issues.
 */
public without sharing class JiraIntegration {

    /**
     * Creates a new issue in Jira based on the provided CreateIssueRequest.
     * @param createIssueRequest The request object containing details for creating a Jira issue.
     * @return CreateIssueResponse object representing the response from Jira after issue creation.
     */
    public static JiraObjects.CreateIssueResponse createIssueInJira(JiraObjects.CreateIssueRequest createIssueRequest) {
        HTTPResponse httpResponse = makeCalloutToJira(JiraObjects.CREATE_ISSUE_ENDPOINT, JSON.serialize(createIssueRequest));
        return (JiraObjects.CreateIssueResponse) JSON.deserialize(httpResponse.getBody(), JiraObjects.CreateIssueResponse.class);
    }

    /**
     * Adds a comment to a specific issue in Jira.
     * @param issueId The ID of the Jira issue to which the comment will be added.
     * @param commentRequest The request object containing the comment details.
     */
    public static void addCommentToIssue(String issueId, JiraObjects.CommentRequest commentRequest) {
        String endpoint = JiraObjects.CREATE_COMMENT_ENDPOINT.replace('{!issueId}', issueId);
        HTTPResponse httpResponse = makeCalloutToJira(endpoint, JSON.serialize(commentRequest));
    }

    /**
     * Links a Salesforce Case to a Jira issue through a remote link.
     * @param issueId The ID of the Jira issue to which the Salesforce Case will be linked.
     * @param linkSFCaseToIssueRequest The request object containing details for linking the Case to the issue.
     */
    public static void linkSFCaseToJiraIssue(String issueId, JiraObjects.IssueRemoteLinkRequest linkSFCaseToIssueRequest) {
        String endpoint = JiraObjects.REMOTE_LINK_ENDPOINT.replace('{!issueId}', issueId);
        HTTPResponse httpResponse = makeCalloutToJira(endpoint, JSON.serialize(linkSFCaseToIssueRequest));
    }

    /**
     * Makes an HTTP callout to Jira with the provided endpoint path and request body.
     * @param endpointPath The path of the Jira endpoint for the callout.
     * @param requestBody The request body to be sent in the callout.
     * @return HTTPResponse object representing the response from the callout.
     */
    private static HTTPResponse makeCalloutToJira(String endpointPath, String requestBody) {
        HTTPRequest httpRequest = setHTTPRequestParameters(endPointPath, requestBody);
        HTTP http = new HTTP();
        return http.send(httpRequest);
    }

    /**
     * Sets HTTP request parameters for the Jira callout.
     * Configures endpoint, method, body, headers, and content type.
     * @param endpointPath The path of the Jira endpoint for the HTTP request.
     * @param requestBody The request body content to be sent in the request.
     * @return HTTPRequest object with set parameters.
     */
    private static HTTPRequest setHTTPRequestParameters(String endpointPath, String requestBody) {
        HTTPRequest httpRequest  = new HTTPRequest(); 
        httpRequest.setEndpoint('callout:Jira_Integration/' + endpointPath);
        httpRequest.setMethod('POST');
        httpRequest.setBody(requestBody.replace('_r', ''));
        httpRequest.setHeader('Content-Type', 'application/json');
        return httpRequest;
    }  
}