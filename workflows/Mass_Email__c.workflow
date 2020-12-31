<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>FUSetMassEmailFromAddress</fullName>
        <field>From_In_Text__c</field>
        <formula>Text (From__c)</formula>
        <name>FUSetMassEmailFromAddress</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetMassEmailReplyToAddress</fullName>
        <field>Reply_To_In_Text__c</field>
        <formula>Text(Reply_To__c)</formula>
        <name>FUSetMassEmailReplyToAddress</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WFSetMassEmailFromAndReplyToInText</fullName>
        <actions>
            <name>FUSetMassEmailFromAddress</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetMassEmailReplyToAddress</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <booleanFilter>1 AND 2</booleanFilter>
        <criteriaItems>
            <field>Mass_Email__c.From__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <criteriaItems>
            <field>Mass_Email__c.Reply_To__c</field>
            <operation>notEqual</operation>
        </criteriaItems>
        <description>Set Mass Email &apos;From&apos; &amp; &apos;Reply To&apos; field in text format</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
