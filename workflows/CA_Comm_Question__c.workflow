<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>FUQuestion255</fullName>
        <description>Copy &apos;Question&apos; a long text field to text area. Only used by formula fields.</description>
        <field>Question_255_chars__c</field>
        <formula>Question__c</formula>
        <name>FUQuestion255</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WFQuestion255</fullName>
        <actions>
            <name>FUQuestion255</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Copy &apos;Question&apos; a long text field to text area. Only used by formula fields.</description>
        <formula>ISNEW() || ISCHANGED(Question__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
