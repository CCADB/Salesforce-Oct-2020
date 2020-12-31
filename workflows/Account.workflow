<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <alerts>
        <fullName>WFSendEmailInterCertOwnedByInternalUser</fullName>
        <description>WFSendEmailInterCertOwnedByInternalUser</description>
        <protected>false</protected>
        <recipients>
            <recipient>poonam@mozilla.org</recipient>
            <type>user</type>
        </recipients>
        <senderType>CurrentUser</senderType>
        <template>unfiled$public/Inter_Cert_Owned_By_Internal_User_Email_Template</template>
    </alerts>
    <fieldUpdates>
        <fullName>FURevocationStatus</fullName>
        <description>If blank set Revocation Status to &apos;Not Revoked&apos; for all intermediate certs</description>
        <field>Revocation_Status__c</field>
        <literalValue>Not Revoked</literalValue>
        <name>FURevocationStatus</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetAccountStatusInText</fullName>
        <field>Status_In_Text__c</field>
        <formula>CASE(Status__c , 
&quot;Not Yet Included&quot;, &quot;Not Yet Included&quot;,
&quot;Change Requested&quot;, &quot;Change Requested&quot;,
&quot;Included&quot;,         &quot;Included&quot;,
&quot;Provided by CA&quot;,   &quot;Provided by CA&quot;,
&quot;Verified&quot;,         &quot;Verified&quot;,
&quot;Removed&quot;,          &quot;Removed&quot;,
&quot;Obsolete&quot;,         &quot;Obsolete&quot;,
&quot;&quot;)</formula>
        <name>FUSetAccountStatusInText</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetAccountTypeAsIntermediateCert</fullName>
        <field>Type</field>
        <literalValue>Intermediate Certificate</literalValue>
        <name>FUSetAccountTypeAsIntermediateCert</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetAccountTypeAsOwner</fullName>
        <field>Type</field>
        <literalValue>Owner</literalValue>
        <name>FUSetAccountTypeAsOwner</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetAccountTypeAsRoot</fullName>
        <field>Type</field>
        <literalValue>Root</literalValue>
        <name>FUSetAccountTypeAsRoot</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetBRAuditInternalLink</fullName>
        <field>BR_Audit_Statement_Internal_Link__c</field>
        <name>FUSetBRAuditInternalLink</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetBRAuditUpdateMessage</fullName>
        <field>BR_Audit_Update_Message__c</field>
        <name>FUSetBRAuditUpdateMessage</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetBRAuditUpdateStatus</fullName>
        <field>BR_Audit_Update_Status__c</field>
        <literalValue>Not Processed</literalValue>
        <name>FUSetBRAuditUpdateStatus</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetCP255</fullName>
        <description>Set Certificate Policy (CP) a long field to Text Area field. This field will be used by in formula fields</description>
        <field>Certificate_Policy_CP_255_char__c</field>
        <formula>Certificate_Policy_CP__c</formula>
        <name>FUSetCP255</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetCPS255</fullName>
        <description>Certification Practice Statement (CPS)
Set Certification Practice Statement (CPS) a long field to Text Area field. This field will be used by in formula fields</description>
        <field>Certification_Practice_Stat_CPS_255_char__c</field>
        <formula>Certification_Practice_Statement_CPS__c</formula>
        <name>FUSetCPS255</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetCodeSigningAuditInternalLink</fullName>
        <field>Code_Signing_Statement_Internal_Link__c</field>
        <name>FUSetCodeSigningAuditInternalLink</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetCodeSigningAuditUpdateMessage</fullName>
        <field>Code_Signing_Audit_Update_Message__c</field>
        <name>FUSetCodeSigningAuditUpdateMessage</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetCodeSigningAuditUpdateStatus</fullName>
        <field>Code_Signing_Audit_Update_Status__c</field>
        <literalValue>Not Processed</literalValue>
        <name>FUSetCodeSigningAuditUpdateStatus</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetEVCodeSigningAuditInternalLink</fullName>
        <field>EV_Code_Signing_Audit_Stmt_Int_Link__c</field>
        <formula>null</formula>
        <name>FUSetEVCodeSigningAuditInternalLink</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetEVCodeSigningAuditUpdateMessage</fullName>
        <field>EV_Code_Signing_Audit_Update_Message__c</field>
        <formula>null</formula>
        <name>FUSetEVCodeSigningAuditUpdateMessage</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetEVCodeSigningAuditUpdateStatus</fullName>
        <field>EV_Code_Signing_Audit_Update_Status__c</field>
        <literalValue>Not Processed</literalValue>
        <name>FUSetEVCodeSigningAuditUpdateStatus</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetEVSSLAuditInternalLink</fullName>
        <field>EV_Audit_Statement_Internal_Link__c</field>
        <name>FUSetEVSSLAuditInternalLink</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetEVSSLAuditUpdateMessage</fullName>
        <field>EV_Audit_Update_Message__c</field>
        <name>FUSetEVSSLAuditUpdateMessage</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetEVSSLAuditUpdateStatus</fullName>
        <field>EV_Audit_Update_Status__c</field>
        <literalValue>Not Processed</literalValue>
        <name>FUSetEVSSLAuditUpdateStatus</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetGeographicFocus255</fullName>
        <field>Geographic_Focus_255_char__c</field>
        <formula>Geographic_Focus__c</formula>
        <name>FUSetGeographicFocus255</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetMicrosoftAccountStatusInText</fullName>
        <field>Microsoft_Status_In_Text__c</field>
        <formula>CASE(Microsoft_Status__c , 
&quot;Not Yet Included&quot;, &quot;Not Yet Included&quot;,
&quot;Not Included&quot;, &quot;Not Included&quot;,
&quot;Included&quot;, &quot;Included&quot;,
&quot;Change Requested&quot;, &quot;Change Requested&quot;,
&quot;Provided by CA&quot;, &quot;Provided by CA&quot;,
&quot;Pending&quot;,&quot;Pending&quot;,
&quot;Verified&quot;, &quot;Verified&quot;,
&quot;Removed&quot;, &quot;Removed&quot;,
&quot;Obsolete&quot;, &quot;Obsolete&quot;,
&quot;NotBefore&quot;,&quot;NotBefore&quot;,
&quot;Inactive&quot;,&quot;Inactive&quot;,
&quot;&quot;)</formula>
        <name>FUSetMicrosoftAccountStatusInText</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetSHA1Fingerprint</fullName>
        <description>If SHA-1 Fingerprint is entered as a string of 40 characters then convert to a string of 59 characters with &apos;:&apos; between every two characters</description>
        <field>SHA_1_Fingerprint__c</field>
        <formula>UPPER( 
IF (REGEX(SHA_1_Fingerprint__c, &quot;[\\w]{40}&quot;),
LEFT(SHA_1_Fingerprint__c,2) &amp; &quot;:&quot; &amp; 
MID (SHA_1_Fingerprint__c,3,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,5,2) &amp; &quot;:&quot; &amp; 
MID (SHA_1_Fingerprint__c,7,2) &amp; &quot;:&quot; &amp; 
MID (SHA_1_Fingerprint__c,9,2) &amp; &quot;:&quot; &amp; 
MID (SHA_1_Fingerprint__c,11,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,13,2) &amp; &quot;:&quot; &amp; 
MID (SHA_1_Fingerprint__c,15,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,17,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,19,2) &amp; &quot;:&quot; &amp; 
MID (SHA_1_Fingerprint__c,21,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,23,2) &amp; &quot;:&quot; &amp; 
MID (SHA_1_Fingerprint__c,25,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,27,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,29,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,31,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,33,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,35,2) &amp; &quot;:&quot; &amp;
MID (SHA_1_Fingerprint__c,37,2) &amp; &quot;:&quot; &amp;
RIGHT (SHA_1_Fingerprint__c,2),
SHA_1_Fingerprint__c)
)</formula>
        <name>FUSetSHA1Fingerprint</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetSHA256Fingerprint</fullName>
        <description>If SHA-1 Fingerprint is entered as a string of 64 characters then convert to a string of 95 characters with &apos;:&apos; between every two characters</description>
        <field>SHA_256_Fingerprint__c</field>
        <formula>UPPER( 
IF (REGEX(SHA_256_Fingerprint__c, &quot;[\\w]{64}&quot;), 
LEFT(SHA_256_Fingerprint__c,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,3,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,5,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,7,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,9,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,11,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,13,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,15,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,17,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,19,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,21,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,23,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,25,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,27,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,29,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,31,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,33,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,35,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,37,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,39,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,41,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,43,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,45,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,47,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,49,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,51,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,53,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,55,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,57,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,59,2) &amp; &quot;:&quot; &amp; 
MID (SHA_256_Fingerprint__c,61,2) &amp; &quot;:&quot; &amp; 
RIGHT (SHA_256_Fingerprint__c,2), 
SHA_256_Fingerprint__c) 
)</formula>
        <name>FUSetSHA256Fingerprint</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Formula</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetStandardAuditInternalLink</fullName>
        <field>Standard_Audit_Statement_Internal_Link__c</field>
        <name>FUSetStandardAuditInternalLink</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetStandardAuditUpdateMessage</fullName>
        <field>Standard_Audit_Update_Message__c</field>
        <name>FUSetStandardAuditUpdateMessage</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Null</operation>
        <protected>false</protected>
    </fieldUpdates>
    <fieldUpdates>
        <fullName>FUSetStandardAuditUpdateStatus</fullName>
        <field>Standard_Audit_Update_Status__c</field>
        <literalValue>Not Processed</literalValue>
        <name>FUSetStandardAuditUpdateStatus</name>
        <notifyAssignee>false</notifyAssignee>
        <operation>Literal</operation>
        <protected>false</protected>
    </fieldUpdates>
    <rules>
        <fullName>WFSendEmailInterCertOwnedByInternalUser</fullName>
        <actions>
            <name>WFSendEmailInterCertOwnedByInternalUser</name>
            <type>Alert</type>
        </actions>
        <active>false</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Intermediate Certificate</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Inter_Cert_Owned_By_Internal_User__c</field>
            <operation>equals</operation>
            <value>True</value>
        </criteriaItems>
        <description>Notify system admin when an intermediate cert is created by internal user</description>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>WFSetAccountGeographicFocus</fullName>
        <actions>
            <name>FUSetGeographicFocus255</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Set GeographicFocus a long field to Text Area field. This field will be used by Root records in formula fields</description>
        <formula>ISNEW() || ISCHANGED( Geographic_Focus__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetAccountMicrosoftStatusInText</fullName>
        <actions>
            <name>FUSetMicrosoftAccountStatusInText</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Workflow to convert Status picklist value to text.</description>
        <formula>ISNEW() || ISCHANGED( Microsoft_Status__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetAccountStatusInText</fullName>
        <actions>
            <name>FUSetAccountStatusInText</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Workflow to convert Status picklist value to text.</description>
        <formula>ISNEW() || ISCHANGED( Status__c )</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetAccountTypeAsIntermediateCertific</fullName>
        <actions>
            <name>FUSetAccountTypeAsIntermediateCert</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Intermediate Certificate</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>WFSetAccountTypeAsOwner</fullName>
        <actions>
            <name>FUSetAccountTypeAsOwner</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>CA Owner</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>WFSetAccountTypeAsRoot</fullName>
        <actions>
            <name>FUSetAccountTypeAsRoot</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Root Certificate</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <rules>
        <fullName>WFSetAuditorAndStandardAuditArchiveFields</fullName>
        <actions>
            <name>FUSetStandardAuditInternalLink</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetStandardAuditUpdateMessage</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetStandardAuditUpdateStatus</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Whenever auditor, auditor location, external link/stmt dt/start dt/end dt is changed, update Internal Link, Status, Message fields with null</description>
        <formula>ISCHANGED (Auditor_New__c) ||  ISCHANGED (Auditor_Location_New__c) ||  ISCHANGED (Standard_Audit__c) ||  ISCHANGED (Standard_Audit_Statement_Date__c) ||  ISCHANGED (Standard_Audit_Period_Start_Date__c) ||  ISCHANGED (Standard_Audit_Period_End_Date__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetBRAuditArchiveFields</fullName>
        <actions>
            <name>FUSetBRAuditInternalLink</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetBRAuditUpdateMessage</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetBRAuditUpdateStatus</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Whenever extrenal link/stmt dt/start dt/enf dt is changed, update Internal Link, Status, Message fields with null</description>
        <formula>ISCHANGED(BR_Audit__c)|| ISCHANGED( BR_Audit_Statement_Date__c) || ISCHANGED( BR_Audit_Period_Start_Date__c) || ISCHANGED( BR_Audit_Period_End_Date__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetCP255</fullName>
        <actions>
            <name>FUSetCP255</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Set Certificate Policy (CP) a long field to Text Area field. This field will be used by in formula fields</description>
        <formula>ISNEW() || ISCHANGED(Certificate_Policy_CP__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetCPS255</fullName>
        <actions>
            <name>FUSetCPS255</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Set Certification Practice Statement (CPS) a long field to Text Area field. This field will be used by in formula fields</description>
        <formula>ISNEW() || ISCHANGED(Certification_Practice_Statement_CPS__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetCodeSigningAuditArchiveFields</fullName>
        <actions>
            <name>FUSetCodeSigningAuditInternalLink</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetCodeSigningAuditUpdateMessage</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetCodeSigningAuditUpdateStatus</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Whenever extrenal link/stmt dt/start dt/enf dt is changed, update Internal Link, Status, Message fields with null</description>
        <formula>ISCHANGED(Code_Signing_Audit__c)|| ISCHANGED( Code_Signing_Audit_Statement_Date__c) || ISCHANGED( Code_Signing_Audit_Period_Start_Date__c) || ISCHANGED( Code_Signing_Audit_Period_End_Date__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetEVCodeSigningAuditArchiveFields</fullName>
        <actions>
            <name>FUSetEVCodeSigningAuditInternalLink</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetEVCodeSigningAuditUpdateMessage</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetEVCodeSigningAuditUpdateStatus</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Whenever extrenal link/stmt dt/start dt/enf dt is changed, update Internal Link, Status, Message fields with null</description>
        <formula>ISCHANGED(EV_Code_Signing_Audit__c) || ISCHANGED( EV_Code_Signing_Audit_Statement_Date__c) || ISCHANGED( EV_Code_Signing_Audit_Period_Start_Date__c) || ISCHANGED( EV_Code_Signing_Audit_Period_End_Date__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetEVSSLAuditArchiveFields</fullName>
        <actions>
            <name>FUSetEVSSLAuditInternalLink</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetEVSSLAuditUpdateMessage</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetEVSSLAuditUpdateStatus</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Whenever extrenal link/stmt dt/start dt/enf dt is changed, update Internal Link, Status, Message fields with null</description>
        <formula>ISCHANGED(EV_Audit__c) || ISCHANGED( EV_Audit_Statement_Date__c) || ISCHANGED( EV_Audit_Period_Start_Date__c) || ISCHANGED( EV_Audit_Period_End_Date__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetRevocationStatus</fullName>
        <actions>
            <name>FURevocationStatus</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <criteriaItems>
            <field>Account.RecordTypeId</field>
            <operation>equals</operation>
            <value>Intermediate Certificate</value>
        </criteriaItems>
        <criteriaItems>
            <field>Account.Revocation_Status__c</field>
            <operation>equals</operation>
        </criteriaItems>
        <description>If blank set Revocation Status to &apos;Not Revoked&apos; for all intermediate certs</description>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetSHA1Fingerprint</fullName>
        <actions>
            <name>FUSetSHA1Fingerprint</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>If SHA-1 Fingerprint is entered as a string of 40 characters then convert to a string of 59 characters with &apos;:&apos; between every two characters</description>
        <formula>ISNEW() || ISCHANGED(SHA_1_Fingerprint__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetSHA256Fingerprint</fullName>
        <actions>
            <name>FUSetSHA256Fingerprint</name>
            <type>FieldUpdate</type>
        </actions>
        <active>false</active>
        <description>If SHA-1 Fingerprint is entered as a string of 64 characters then convert to a string of 95 characters with &apos;:&apos; between every two characters</description>
        <formula>ISNEW() || ISCHANGED(SHA_256_Fingerprint__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
    <rules>
        <fullName>WFSetStandardAuditArchiveFields</fullName>
        <actions>
            <name>FUSetStandardAuditInternalLink</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetStandardAuditUpdateMessage</name>
            <type>FieldUpdate</type>
        </actions>
        <actions>
            <name>FUSetStandardAuditUpdateStatus</name>
            <type>FieldUpdate</type>
        </actions>
        <active>true</active>
        <description>Whenever extrenal link/stmt dt/start dt/enf dt is changed, update Internal Link, Status, Message fields with null</description>
        <formula>ISCHANGED(Standard_Audit__c) || ISCHANGED( Standard_Audit_Statement_Date__c) || ISCHANGED( Standard_Audit_Period_Start_Date__c) || ISCHANGED( Standard_Audit_Period_End_Date__c)</formula>
        <triggerType>onAllChanges</triggerType>
    </rules>
</Workflow>
