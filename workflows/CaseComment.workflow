<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldUpdates>
        <fullName>FULastetCaseComment</fullName>
        <description>Update &apos;Latest Case Comment&apos; field whenever a Case Comment is added to a Case.</description>
        <field>Latest_Case_Comment__c</field>
        <formula>&apos;Created By: &apos; + 
CreatedBy.FirstName + &apos; &apos; + 
CreatedBy.LastName + &apos; &apos; + 
&apos;Created On: &apos; + 
TEXT(MONTH(DATEVALUE(CreatedDate))) + &apos;/&apos; + 
TEXT(DAY(DATEVALUE(CreatedDate))) + &apos;/&apos; + 
TEXT(YEAR(DATEVALUE(CreatedDate))) + &apos; &apos; + 
&apos;Comment Text: &apos; + 
CommentBody</formula>
        <name>FULastetCaseComment</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
        <targetObject>ParentId</targetObject>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetCaseCommentPublic</fullName>
        <description>Case Comment should always be public</description>
        <field>IsPublished</field>
        <literalValue>1</literalValue>
        <name>FUSetCaseCommentPublic</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WFLatestCaseComment</fullName>
        <actions>
            <name>FULastetCaseComment</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetCaseCommentPublic</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Update &apos;Latest Case Comment&apos; field whenever a Case Comment is added to a Case.
Make Case Comment public</description>
        <formula>True</formula>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
</Workflow>
