<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>FUUpdateCPACanadaReportURLs</fullName>
        <description>Auto update Report URL from Report ID</description>
        <field>Report_URL__c</field>
        <formula>&apos;https://www.cpacanada.ca/generichandlers/aptifyattachmenthandler.ashx?attachmentid=&apos; &amp; Report_Id__c</formula>
        <name>FUUpdateCPACanadaReportURLs</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUUpdateCPACanadaSealURLs</fullName>
        <description>Auto update Seal URL from Seal ID</description>
        <field>Seal_URL__c</field>
        <formula>&apos;https://www.cpacanada.ca/webtrustseal?sealid=&apos; &amp; Name</formula>
        <name>FUUpdateCPACanadaSealURLs</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WFUpdateCPACanadaURLs</fullName>
        <actions>
            <name>FUUpdateCPACanadaReportURLs</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUUpdateCPACanadaSealURLs</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>Auto update Seal URL and Report URL from ID</description>
        <formula>ISNEW() || ISCHANGED(Name) || ISCHANGED(Report_Id__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
