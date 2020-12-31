<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>FUSetBugzillaUserName</fullName>
        <description>Set &apos;Bugzilla Username&apos; from Email field when &apos;Has Bugzilla Account&apos; is checked</description>
        <field>Bugzilla_Username__c</field>
        <formula>Email</formula>
        <name>FUSetBugzillaUserName</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetContactTypeInText</fullName>
        <field>Type_In_Text__c</field>
        <formula>CASE(Type__c , 
&quot;Primary POC&quot;, &quot;Primary POC&quot;,
&quot;POC&quot;,         &quot;POC&quot;,
&quot;Auditor&quot;,     &quot;Auditor&quot;,
&quot;Obsolete&quot;,    &quot;Obsolete&quot;,
&quot;Other&quot;,       &quot;Other&quot;,
&quot;&quot;)</formula>
        <name>FUSetContactTypeInText</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WFSetBugzillaUserName</fullName>
        <actions>
            <name>FUSetBugzillaUserName</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Set &apos;Bugzilla Username&apos; from Email field when &apos;Has Bugzilla Account&apos; is checked</description>
        <formula>AND (
OR (ISNEW(), ISCHANGED(Has_Bugzilla_Account__c)), Has_Bugzilla_Account__c = TRUE,
ISBLANK(Bugzilla_Username__c) 
)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetContactTypeInText</fullName>
        <actions>
            <name>FUSetContactTypeInText</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Work flow to update Contact.TypeInText in text form from Contact.Type which is a picklist</description>
        <formula>ISNEW() || ISCHANGED(Type__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
