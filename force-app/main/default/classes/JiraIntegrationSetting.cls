/**
 * JiraIntegrationSetting class provides methods to access Jira Integration Settings custom metadata type records.
 * It allows retrieval of specific settings based on their names.
 */
public without sharing class JiraIntegrationSetting {

    private static Map<String, Jira_Integration_Setting__mdt> jiraSettings;
    
    /**
     * Retrieves a specific Jira Integration Setting based on its name.
     * @param settingName The name of the Jira Integration Setting to retrieve.
     * @return Jira_Integration_Setting__mdt object representing the requested setting, if found; otherwise, null.
     */
    public static Jira_Integration_Setting__mdt getJiraIntegrationSetting(String settingName) {
        if (jiraSettings == null) {
            populateJiraSettings();
        }
        return jiraSettings.get(settingName);
    }

    /**
     * Populates the map of Jira Integration Settings from the custom metadata type.
     * Fetches all records and stores them in a map with DeveloperName as the key.
     */
    private static void populateJiraSettings() {
        jiraSettings = new Map<String, Jira_Integration_Setting__mdt>();
        for (Jira_Integration_Setting__mdt jiraSetting : Jira_Integration_Setting__mdt.getAll().values()) {
            jiraSettings.put(jiraSetting.DeveloperName, jiraSetting);
        }
    }
}