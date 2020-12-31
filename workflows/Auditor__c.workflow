<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>FUSetAuditorStatusInText</fullName>
        <description>Field Update to convert Auditor Status picklist to text</description>
        <field>Auditor_Status_In_Text__c</field>
        <formula>CASE(Auditor_Status__c , 
&quot;Unknown&quot;, &quot;Unknown&quot;, 
&quot;Confidence - High&quot;, &quot;Confidence - High&quot;, 
&quot;Confidence - Medium&quot;, &quot;Confidence - Medium&quot;, 
&quot;Confidence - Low&quot;, &quot;Confidence - Low&quot;, 
&quot;&quot;)</formula>
        <name>FUSetAuditorStatusInText</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WFSetAuditorStatusInText</fullName>
        <actions>
            <name>FUSetAuditorStatusInText</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Workflow to convert Auditor Status picklist to text</description>
        <formula>ISNEW() || ISCHANGED(Auditor_Status__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
