/**
 * JiraFileIntegration class facilitates uploading files to Jira as attachments through HTTP callouts.
 */
public without sharing class JiraFileIntegration {

    private final String BOUNDARY = '----------------------------741e90d31eff';
    private String requestBodyHeader = '--' + BOUNDARY + '\nContent-Disposition: form-data; name="file"; filename="{!fileName}";\nContent-Type: application/octet-stream';
    private String requestBodyFooter = '--' + BOUNDARY + '--';
    private String issueId;
    private Blob file;
    private String fileName;
    private String encodedRequestBodyHeader;
    private String encodedRequestBody;
    private String encodedRequestFooter;
    private Blob requestBlob;
    
    /**
     * Constructs a JiraFileIntegration object to upload a file to a specific Jira issue as an attachment.
     * @param issueId The ID of the Jira issue to which the file will be attached.
     * @param file The file content to be uploaded as a Blob.
     * @param fileName The name of the file to be uploaded.
     */
    public JiraFileIntegration(String issueId, Blob file, String fileName) {
        this.issueId = issueId;
        this.file = file;
        this.fileName = fileName;
        this.encodedRequestBody = EncodingUtil.base64Encode(file);
        requestBodyHeader = requestBodyHeader.replace('{!fileName}', fileName);
    }

    /**
     * Initiates the file upload process to Jira.
     * Prepares the request body and performs the HTTP callout.
     */
    public void uploadFileToJira() {
        prepareBlobRequestBody();
        makeCalloutToJira();
    }

    /**
     * Prepares the request body for the file upload.
     * Encodes the request body header and adjusts the body based on the last 4 bytes of the file content.
     */
    private void prepareBlobRequestBody() {
        encodeRequestBodyHeader();
        encodedRequestBodyBasedOnLast4Bytes();
    }

    /**
     * Makes an HTTP callout to Jira using the constructed request parameters.
     */
    private void makeCalloutToJira() {
        HTTPRequest httpRequest = setHTTPRequestParameters();
        HTTP http = new HTTP();
        http.send(httpRequest);
    }

    
    /**
     * Encodes the request body header for the multipart/form-data content.
     * Adjusts for proper base64 encoding and length.
     */
    private void encodeRequestBodyHeader() {
        encodedRequestBodyHeader = EncodingUtil.base64Encode(Blob.valueOf(requestBodyHeader+'\r\n\r\n'));
        while(encodedRequestBodyHeader.endsWith('='))
        {
            requestBodyHeader+=' ';
            encodedRequestBodyHeader = EncodingUtil.base64Encode(Blob.valueOf(requestBodyHeader+'\r\n\r\n'));
        }
    }

    /**
     * Adjusts the encoded request body based on the last 4 bytes of the file content.
     */
    private void encodedRequestBodyBasedOnLast4Bytes() {
        String last4BytesInEncodedRequestBody = encodedRequestBody.substring(encodedRequestBody.length() - 4 , encodedRequestBody.length());
        if(last4BytesInEncodedRequestBody.endsWith('==')) {
           adjustRequestBodyForDoubleEqual(last4BytesInEncodedRequestBody);
         } else if(last4BytesInEncodedRequestBody.endsWith('=')) {
            adjustRequestBodyForSingleEqual(last4BytesInEncodedRequestBody);         
         } else {
            adjustRequestBodyFoOtherCases(); 
         }
         encodedRequestFooter = EncodingUtil.base64Encode(Blob.valueOf(requestBodyFooter));
         requestBlob = EncodingUtil.base64Decode(encodedRequestBodyHeader + encodedRequestBody + encodedRequestFooter);
    }

    /**
     * Sets HTTP request parameters for the file upload callout.
     * Configures endpoint, method, body, headers, and timeouts.
     * @return HTTPRequest object with set parameters.
     */
    private HTTPRequest setHTTPRequestParameters() {
        HTTPRequest httpRequest  = new HTTPRequest(); 
        httpRequest.setEndpoint('callout:Jira_Integration/' + JiraObjects.ISSUE_ATTACHMENT_ENDPOINT.replace('{!issueId}', issueId));
        httpRequest.setMethod('POST');
        httpRequest.setBodyAsBlob(requestBlob);
        httpRequest.setHeader('Content-Type', 'multipart/form-data; boundary=' + BOUNDARY);
        httpRequest.setHeader('X-Atlassian-Token', 'no-check');
        httpRequest.setTimeout(120000);
        return httpRequest;
    }

    /**
     * Adjusts the request body for cases where the last 4 bytes end with '=='.
     * @param last4BytesInEncodedRequestBody Last 4 bytes of the encoded request body.
     */
    private void adjustRequestBodyForDoubleEqual(String last4BytesInEncodedRequestBody) {
        last4BytesInEncodedRequestBody = last4BytesInEncodedRequestBody.substring(0,2) + '0K';
        encodedRequestBody = encodedRequestBody.substring(0, encodedRequestBody.length() - 4) + last4BytesInEncodedRequestBody;
    }

    /**
     * Adjusts the request body for cases where the last 4 bytes end with '='.
     * @param last4BytesInEncodedRequestBody Last 4 bytes of the encoded request body.
     */
    private void adjustRequestBodyForSingleEqual(String last4BytesInEncodedRequestBody) {
        last4BytesInEncodedRequestBody = last4BytesInEncodedRequestBody.substring(0,3) + 'N';
        encodedRequestBody = encodedRequestBody.substring(0, encodedRequestBody.length() - 4) + last4BytesInEncodedRequestBody;
        requestBodyFooter = '\n' + requestBodyFooter;
    }
    
    /**
     * Adjusts the request body for other cases where no special conditions are met in the last 4 bytes.
     */
    private void adjustRequestBodyFoOtherCases() {
        requestBodyFooter = '\r\n' + requestBodyFooter;
    }
}