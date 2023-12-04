/**
 * JiraIntegrationMockService is an implementation of the HttpCalloutMock interface used for mocking HTTP callouts to Jira in unit tests.
 * It provides mock responses for different request endpoints to simulate Jira API responses.
 */
global class JiraIntegrationMockService implements HttpCalloutMock {

    private HTTPRequest request;

    /**
     * Responds to the HTTP request with a mock HTTPResponse.
     * @param request The HTTPRequest object containing the request details.
     * @return HTTPResponse object representing the mock response for the request.
     */
    global HTTPResponse respond(HTTPRequest request) {
        this.request = request;
        HTTPResponse response = new HTTPResponse();
        response.setStatus('OK');
        response.setStatusCode(200);
        response.setBody(getResponseBody());
        return response;      
    }

    /**
     * Generates the response body based on the request endpoint to provide appropriate mock data.
     * @return String representing the mock response body for the request.
     */
    private String getResponseBody() {
        String endpointEnd = request.getEndpoint().RIGHT(JiraObjects.CREATE_ISSUE_ENDPOINT.length());
        if(endpointEnd == JiraObjects.CREATE_ISSUE_ENDPOINT) {
            return getNewIssueResponseBody();
        }
        return '';
    }

    /**
     * Provides a mock response body for creating a new issue in Jira.
     * @return String representing the mock response body for creating a new issue in Jira.
     */
    private String getNewIssueResponseBody() {
        JiraObjects.CreateIssueResponse newIssueResponse = new JiraObjects.CreateIssueResponse('1', 'Issue-1');
        return JSON.serialize(newIssueResponse);
    }
}