<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>FUCaseAssignmentForMicrosoft</fullName>
        <description>Set &apos;Case Assigned To&apos; to Microsoft Root Store Mgr if included by Microsoft</description>
        <field>Case_Assigned_To__c</field>
        <lookupValue>karina.sirota@microsoft.com</lookupValue>
        <lookupValueType>User</lookupValueType>
        <name>FUCaseAssignmentForMicrosoft</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUCaseAssignmentForMozilla</fullName>
        <description>Set &apos;Case Assigned To&apos; to Mozilla Root Store Mgr if included by Mozilla</description>
        <field>Case_Assigned_To__c</field>
        <lookupValue>bwilson@mozilla.com</lookupValue>
        <lookupValueType>User</lookupValueType>
        <name>FUCaseAssignmentForMozilla</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>LookupValue</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetSubjectForAuditUpdateRequest</fullName>
        <field>Subject</field>
        <formula>TEXT(YEAR(TODAY())) + &apos; Audit &apos; + Account.Name</formula>
        <name>FUSetSubjectForAuditUpdateRequest</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetSubjectForRootInclusionRequest</fullName>
        <field>Subject</field>
        <formula>&apos;Root Inclusion For &apos; +Account.Name</formula>
        <name>FUSetSubjectForRootInclusionRequest</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WFCaseAssignmentForMicrosoft</fullName>
        <actions>
            <name>FUCaseAssignmentForMicrosoft</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>CA Audit Update Request</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Case_Progress__c</field>
            <operation>equals</operation>
            <value>Verification by Root Store</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Microsoft_Status_Root_Certs__c</field>
            <operation>equals</operation>
            <value>Included</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Mozilla_Status_Root_Certs__c</field>
            <operation>notEqual</operation>
            <value>Included</value>
        </criteriaItems>
        <description>Set &apos;Case Assigned To&apos; to Microsoft Root Store Mgr if included by Microsoft</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>WFCaseAssignmentForMozilla</fullName>
        <actions>
            <name>FUCaseAssignmentForMozilla</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>CA Audit Update Request,CA Root Inclusion Request</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Case_Progress__c</field>
            <operation>equals</operation>
            <value>Verification by Root Store</value>
        </criteriaItems>
        <criteriaItems>
            <field>Case.Mozilla_Status_Root_Certs__c</field>
            <operation>equals</operation>
            <value>Included</value>
        </criteriaItems>
        <description>Set &apos;Case Assigned To&apos; to Mozilla Root Store Mgr if included by Mozilla</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>WFSetSubjectForAuditUpdateRequest</fullName>
        <actions>
            <name>FUSetSubjectForAuditUpdateRequest</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.Subject</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>CA Audit Update Request</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetSubjectForRootInclusionCase</fullName>
        <actions>
            <name>FUSetSubjectForRootInclusionRequest</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Case.Subject</field>
            <operation>equals</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Case.RecordTypeId</field>
            <operation>equals</operation>
            <value>CA Root Inclusion Request</value>
        </criteriaItems>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
