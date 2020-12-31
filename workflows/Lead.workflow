<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>Notify_Applicant_when_Access_Request_for_CCADB_is_submitted</fullName>
        <description>Notify Applicant when Access Request for CCADB is submitted</description>
        <protected>false</protected>
        <recipients>
            <field>Email</field>
            <type>email</type>
        </recipients>
        <senderAddress>support@ccadb.org</senderAddress>
        <senderType>OrgWideEmailAddress</senderType>
        <template>unfiled$public/Leads_Access_to_CCADB_Request_Response</template>
    </alerts>
    <rules>
        <fullName>WFCCADBAccessFormNotifications</fullName>
        <actions>
            <name>Notify_Applicant_when_Access_Request_for_CCADB_is_submitted</name>
            <type>Alert</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Lead.Email</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Notify applicant and Root Store Operator when Access Request for CCADB is submitted and Lead record is created</description>
        <triggerType>onCreateOnly</triggerType>
    </rules>
</Workflow>
