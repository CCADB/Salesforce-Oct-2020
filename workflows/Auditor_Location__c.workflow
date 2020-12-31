<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>FUSetAuditorLocationStatusInText</fullName>
        <description>Workflow to convert Auditor Location Status picklist to text</description>
        <field>Auditor_Location_Status_In_Text__c</field>
        <formula>CASE(Auditor_Location_Status__c, 
&quot;Unknown&quot;, &quot;Unknown&quot;, 
&quot;Confidence - High&quot;, &quot;Confidence - High&quot;, 
&quot;Confidence - Medium&quot;, &quot;Confidence - Medium&quot;, 
&quot;Confidence - Low&quot;, &quot;Confidence - Low&quot;, 
&quot;&quot;)</formula>
        <name>FUSetAuditorLocationStatusInText</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WFSetAuditorLocationStatusInText</fullName>
        <actions>
            <name>FUSetAuditorLocationStatusInText</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Field update to convert Auditor Location Status picklist to text</description>
        <formula>ISNEW() || ISCHANGED(Auditor_Location_Status__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
